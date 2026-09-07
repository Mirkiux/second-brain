#!/usr/bin/env node
// sb-search — reliable local search over the second-brain knowledge base.
//
// WHY THIS EXISTS
// Notion's /v1/search matches page TITLES only, tokenised as an OR of words, with no
// stopword removal and no relevance score (verified 2026-09-06). A natural-language query
// like "MS Data Science" pulls in every title containing "data"; "search before write"
// against it is unreliable. Until build_order.md step 4 (own API + embeddings) exists, this
// script is the bridge: it pulls the whole KB to a local cache once, then searches title +
// body text + topic tags locally, ranked.
//
// USAGE
//   node harnessing/scripts/sb-search.mjs "<query words>" [options]
//     --refresh            rebuild the local cache before searching
//     --limit <n>          max results (default 10)
//     --type <Name>        restrict to a database (repeatable): Note, Decision,
//                          "Research Question", Experiment, Source, Repo, Project,
//                          "Work Item", Topic, Workplace, Person
//     --max-age <hours>    auto-refresh if the cache is older than this (default 12)
//     --json               emit raw JSON instead of the formatted list
//     --list-types         print the databases discovered in the cache and exit
//   node harnessing/scripts/sb-search.mjs --refresh          (just rebuild the cache)
//
// Auth: shells out to `ntn` for every API call, so it reuses whatever auth `ntn` already
// has (keychain login or NOTION_API_TOKEN). Run `ntn whoami` first if unsure.
//
// Cache: ~/.cache/second-brain/kb.json  (delete it to force a full rebuild)

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const CACHE_DIR = path.join(os.homedir(), '.cache', 'second-brain');
const CACHE_FILE = path.join(CACHE_DIR, 'kb.json');

// The 11 canonical databases (data-model.md) plus Person. Anything else Notion returns
// (e.g. unrelated workspace DBs) is ignored.
const KNOWN_DBS = new Set([
  'Notes', 'Decisions', 'Research Questions', 'Experiments', 'Sources',
  'Repos', 'Projects', 'Work Items', 'Topics', 'Workplaces', 'People',
]);
// Singular aliases accepted on --type
const TYPE_ALIASES = {
  note: 'Notes', decision: 'Decisions', 'research question': 'Research Questions',
  experiment: 'Experiments', source: 'Sources', repo: 'Repos', project: 'Projects',
  'work item': 'Work Items', topic: 'Topics', workplace: 'Workplaces', person: 'People',
};

// Query-scoring stopwords — ignored when scoring so "and"/"the"/"data" don't dominate.
// (They are NOT stripped from the cached documents, only from the query.)
const STOPWORDS = new Set([
  'a', 'an', 'and', 'or', 'the', 'of', 'to', 'in', 'on', 'for', 'is', 'are', 'be', 'was',
  'with', 'as', 'at', 'by', 'it', 'this', 'that', 'from', 'how', 'what', 'when', 'why',
  'do', 'does', 'can', 'i', 'my', 'we', 'our',
]);

// ---------------------------------------------------------------------------- ntn shell

function ntn(apiPath, body) {
  const args = ['api', apiPath];
  if (body !== undefined) args.push('-d', JSON.stringify(body));
  let out;
  try {
    out = execFileSync('ntn', args, { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  } catch (e) {
    const msg = (e.stderr || e.stdout || e.message || '').toString().trim();
    throw new Error(`ntn api ${apiPath} failed:\n${msg}`);
  }
  try {
    return JSON.parse(out);
  } catch {
    throw new Error(`ntn api ${apiPath} did not return JSON:\n${out.slice(0, 500)}`);
  }
}

function queryAll(dataSourceId) {
  const rows = [];
  let cursor;
  do {
    const body = { page_size: 100 };
    if (cursor) body.start_cursor = cursor;
    const res = ntn(`v1/data_sources/${dataSourceId}/query`, body);
    rows.push(...(res.results || []));
    cursor = res.has_more ? res.next_cursor : undefined;
  } while (cursor);
  return rows;
}

// ---------------------------------------------------------------------------- extraction

function plain(rich) {
  return (rich || []).map((t) => t.plain_text || t?.text?.content || '').join('');
}

function extractPage(page, dbName, topicNames) {
  const props = page.properties || {};
  let title = '';
  const textParts = [];
  const selects = {};
  let urlProp = '';
  const topicIds = [];

  for (const [key, v] of Object.entries(props)) {
    switch (v.type) {
      case 'title': title = plain(v.title); break;
      case 'rich_text': {
        const s = plain(v.rich_text);
        if (s) textParts.push(`${key}: ${s}`);
        break;
      }
      case 'select': if (v.select) selects[key] = v.select.name; break;
      case 'status': if (v.status) selects[key] = v.status.name; break;
      case 'multi_select':
        if (v.multi_select?.length) selects[key] = v.multi_select.map((o) => o.name).join(', ');
        break;
      case 'url': if (v.url) urlProp = v.url; break;
      case 'relation':
        if (/topic/i.test(key)) topicIds.push(...v.relation.map((r) => r.id));
        break;
      default: break;
    }
  }

  const topics = topicIds.map((id) => topicNames.get(id)).filter(Boolean);

  return {
    id: page.id,
    type: dbName,
    title,
    text: textParts.join('\n'),
    topics,
    status: selects.Status || selects['Epistemic Status'] || '',
    subtype: selects.Subtype || selects.Kind || selects.Type || '',
    reusability: selects.Reusability || '',
    provenance: selects.Provenance || '',
    selects,
    url: urlProp || page.url || '',
    created: page.created_time || '',
    edited: page.last_edited_time || '',
  };
}

// ---------------------------------------------------------------------------- cache

function buildCache() {
  process.stderr.write('sb-search: rebuilding cache from Notion…\n');
  const dsList = ntn('v1/search', {
    filter: { property: 'object', value: 'data_source' },
    page_size: 50,
  }).results || [];

  const dsByName = new Map();
  for (const ds of dsList) {
    const name = plain(ds.title);
    if (KNOWN_DBS.has(name) && !dsByName.has(name)) dsByName.set(name, ds.id);
  }

  // Topics first, so relations elsewhere resolve to names.
  const topicNames = new Map();
  if (dsByName.has('Topics')) {
    for (const t of queryAll(dsByName.get('Topics'))) {
      topicNames.set(t.id, plain(t.properties?.Name?.title));
    }
  }

  const rows = [];
  for (const [name, dsId] of dsByName) {
    const pages = queryAll(dsId);
    for (const p of pages) rows.push(extractPage(p, name, topicNames));
    process.stderr.write(`  ${name}: ${pages.length}\n`);
  }

  const cache = { fetchedAt: new Date().toISOString(), count: rows.length, rows };
  fs.mkdirSync(CACHE_DIR, { recursive: true });
  fs.writeFileSync(CACHE_FILE, JSON.stringify(cache));
  process.stderr.write(`sb-search: cached ${rows.length} rows -> ${CACHE_FILE}\n`);
  return cache;
}

function loadCache({ refresh, maxAgeHours }) {
  if (refresh) return buildCache();
  if (!fs.existsSync(CACHE_FILE)) return buildCache();
  const cache = JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8'));
  const ageH = (Date.now() - Date.parse(cache.fetchedAt)) / 3.6e6;
  if (ageH > maxAgeHours) {
    process.stderr.write(`sb-search: cache is ${ageH.toFixed(1)}h old (> ${maxAgeHours}h)\n`);
    return buildCache();
  }
  return cache;
}

// ---------------------------------------------------------------------------- scoring

const WORD = /[a-z0-9]+/g;

function tokenize(s) {
  return (s.toLowerCase().match(WORD) || []);
}

function scoreRow(row, terms, rawQuery) {
  const titleLc = row.title.toLowerCase();
  const textLc = row.text.toLowerCase();
  const topicLc = row.topics.join(' ').toLowerCase();
  const titleTokens = new Set(tokenize(row.title));
  const textTokens = new Set(tokenize(row.text));

  let score = 0;

  // whole-phrase hits
  const q = rawQuery.toLowerCase().trim();
  if (q.length > 2 && titleLc.includes(q)) score += 60;
  if (q.length > 2 && textLc.includes(q)) score += 12;

  for (const term of terms) {
    if (titleTokens.has(term)) score += 12;
    else if (titleLc.includes(term)) score += 6; // prefix / substring
    if (topicLc.includes(term)) score += 8;
    if (textTokens.has(term)) score += 3;
    else if (textLc.includes(term)) score += 1;
  }

  // small bump for confirmed / active knowledge over superseded
  if (/superseded|deprecated|disputed|abandoned/i.test(row.status)) score *= 0.5;

  return score;
}

function snippet(row, terms) {
  const hay = row.text || '';
  if (!hay) return '';
  const lc = hay.toLowerCase();
  let at = -1;
  for (const t of terms) {
    const i = lc.indexOf(t);
    if (i !== -1 && (at === -1 || i < at)) at = i;
  }
  if (at === -1) at = 0;
  const start = Math.max(0, at - 90);
  const end = Math.min(hay.length, at + 160);
  return (start > 0 ? '…' : '') + hay.slice(start, end).replace(/\s+/g, ' ').trim()
    + (end < hay.length ? '…' : '');
}

// ---------------------------------------------------------------------------- CLI

function parseArgs(argv) {
  const opts = { limit: 10, types: [], maxAgeHours: 12, refresh: false, json: false,
    listTypes: false, query: '' };
  const words = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--refresh') opts.refresh = true;
    else if (a === '--json') opts.json = true;
    else if (a === '--list-types') opts.listTypes = true;
    else if (a === '--limit') opts.limit = parseInt(argv[++i], 10) || 10;
    else if (a === '--max-age') opts.maxAgeHours = parseFloat(argv[++i]) || 12;
    else if (a === '--type') {
      const raw = (argv[++i] || '').trim();
      opts.types.push(TYPE_ALIASES[raw.toLowerCase()] || raw);
    } else if (a.startsWith('--')) {
      process.stderr.write(`sb-search: unknown flag ${a}\n`);
      process.exit(2);
    } else words.push(a);
  }
  opts.query = words.join(' ').trim();
  return opts;
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  const cache = loadCache(opts);

  if (opts.listTypes) {
    const counts = {};
    for (const r of cache.rows) counts[r.type] = (counts[r.type] || 0) + 1;
    console.log(`cache fetched ${cache.fetchedAt}`);
    for (const [k, v] of Object.entries(counts).sort()) console.log(`  ${k}: ${v}`);
    return;
  }

  if (!opts.query) {
    if (opts.refresh) return; // `--refresh` alone is a valid "just rebuild" call
    process.stderr.write('sb-search: no query given. See --help header in the script.\n');
    process.exit(2);
  }

  const terms = [...new Set(tokenize(opts.query).filter((t) => !STOPWORDS.has(t)))];
  if (terms.length === 0) {
    process.stderr.write(
      `sb-search: query "${opts.query}" is all stopwords — give a distinctive word ` +
      `(a tool name, an identifier, an error string).\n`);
    process.exit(2);
  }

  let rows = cache.rows;
  if (opts.types.length) {
    const want = new Set(opts.types);
    rows = rows.filter((r) => want.has(r.type));
  }

  const scored = rows
    .map((r) => ({ r, score: scoreRow(r, terms, opts.query) }))
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, opts.limit);

  if (opts.json) {
    console.log(JSON.stringify(
      scored.map((x) => ({ score: x.score, ...x.r })), null, 2));
    return;
  }

  if (scored.length === 0) {
    console.log(`No matches for "${opts.query}" (terms: ${terms.join(', ')}).`);
    console.log('Cache age OK; try a broader term or --refresh if you just wrote the entry.');
    return;
  }

  console.log(`${scored.length} match(es) for "${opts.query}"  [cache ${cache.fetchedAt}]\n`);
  for (const { r, score } of scored) {
    const meta = [r.status, r.subtype, r.reusability, r.provenance].filter(Boolean).join(' · ');
    console.log(`[${score}] ${r.type.replace(/s$/, '')}: ${r.title}`);
    if (meta) console.log(`      ${meta}`);
    if (r.topics.length) console.log(`      topics: ${r.topics.join(', ')}`);
    const sn = snippet(r, terms);
    if (sn) console.log(`      ${sn}`);
    console.log(`      ${r.id}${r.url ? '  ' + r.url : ''}`);
    console.log('');
  }
}

main();
