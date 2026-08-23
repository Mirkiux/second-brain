# Every edge from data-model.md's relation tables. Two things to verify on
# first apply, both called out in the project README:
#
#   1. The provider's notion_database_property_relation resource doesn't
#      expose a two-way/synced flag. Where both sides genuinely need to
#      browse the relation (Project<->Repo, Repo<->Work Item) this file
#      defines both directions explicitly rather than assuming Notion
#      auto-mirrors one from the other. For the rest, only the direction
#      matching data-model.md's arrow is defined — add the reverse
#      resource for any relation you find yourself wanting from the other
#      side too.
#   2. Self-relations (database == related_database) are just two string
#      IDs that happen to match — not a dependency cycle. Notion itself
#      auto-generates the back-pointer column on these in the product UI.

# --- structural spine ---

resource "notion_database_property_relation" "project_workplace" {
  database         = notion_database.project.id
  name             = "Workplace"
  related_database = notion_database.workplace.id
}

resource "notion_database_property_relation" "project_repos" {
  database         = notion_database.project.id
  name             = "Repos"
  related_database = notion_database.repo.id
}

resource "notion_database_property_relation" "repo_projects" {
  database         = notion_database.repo.id
  name             = "Projects"
  related_database = notion_database.project.id
}

resource "notion_database_property_relation" "repo_work_items" {
  database         = notion_database.repo.id
  name             = "Work Items"
  related_database = notion_database.work_item.id
}

resource "notion_database_property_relation" "work_item_repos" {
  database         = notion_database.work_item.id
  name             = "Repos"
  related_database = notion_database.repo.id
}

resource "notion_database_property_relation" "repo_topics" {
  database         = notion_database.repo.id
  name             = "Topics"
  related_database = notion_database.topic.id
}

# --- optional, most-specific scope: Note / Decision / Source -> spine ---
# One for_each instead of twelve hand-written blocks — fill in only the
# most specific level that applies per entry; Terraform creates all four
# optional properties, the "most specific only" rule is a usage discipline,
# not something Notion can enforce structurally.

locals {
  spine_levels = {
    workplace = notion_database.workplace.id
    project   = notion_database.project.id
    repo      = notion_database.repo.id
    work_item = notion_database.work_item.id
  }

  scoped_entities = {
    note     = notion_database.note.id
    decision = notion_database.decision.id
    source   = notion_database.source.id
  }

  scope_relations = merge([
    for entity_key, entity_id in local.scoped_entities : {
      for level_key, level_id in local.spine_levels :
      "${entity_key}_${level_key}" => {
        database         = entity_id
        related_database = level_id
        name             = title(replace(level_key, "_", " "))
      }
    }
  ]...)
}

resource "notion_database_property_relation" "scope" {
  for_each          = local.scope_relations
  database          = each.value.database
  name              = each.value.name
  related_database  = each.value.related_database
}

# --- research question / experiment ---

resource "notion_database_property_relation" "research_question_project" {
  database         = notion_database.research_question.id
  name             = "Project"
  related_database = notion_database.project.id
}

resource "notion_database_property_relation" "research_question_topics" {
  database         = notion_database.research_question.id
  name             = "Topics"
  related_database = notion_database.topic.id
}

resource "notion_database_property_relation" "experiment_research_question" {
  database         = notion_database.experiment.id
  name             = "Research Question"
  related_database = notion_database.research_question.id
}

resource "notion_database_property_relation" "experiment_work_item" {
  database         = notion_database.experiment.id
  name             = "Work Item"
  related_database = notion_database.work_item.id
}

resource "notion_database_property_relation" "experiment_branches_from" {
  database         = notion_database.experiment.id
  name             = "Branches From"
  related_database = notion_database.experiment.id
}

# --- note ---

resource "notion_database_property_relation" "note_topics" {
  database         = notion_database.note.id
  name             = "Topics"
  related_database = notion_database.topic.id
}

resource "notion_database_property_relation" "note_author" {
  database         = notion_database.note.id
  name             = "Author"
  related_database = notion_database.person.id
}

resource "notion_database_property_relation" "note_source" {
  database         = notion_database.note.id
  name             = "Source"
  related_database = notion_database.source.id
}

resource "notion_database_property_relation" "note_supersedes" {
  database         = notion_database.note.id
  name             = "Supersedes"
  related_database = notion_database.note.id
}

# --- decision ---

resource "notion_database_property_relation" "decision_topics" {
  database         = notion_database.decision.id
  name             = "Topics"
  related_database = notion_database.topic.id
}

resource "notion_database_property_relation" "decision_author" {
  database         = notion_database.decision.id
  name             = "Author"
  related_database = notion_database.person.id
}

resource "notion_database_property_relation" "decision_evidence" {
  database         = notion_database.decision.id
  name             = "Evidence"
  related_database = notion_database.experiment.id
}

resource "notion_database_property_relation" "decision_source" {
  database         = notion_database.decision.id
  name             = "Source"
  related_database = notion_database.source.id
}

resource "notion_database_property_relation" "decision_supersedes" {
  database         = notion_database.decision.id
  name             = "Supersedes"
  related_database = notion_database.decision.id
}

resource "notion_database_property_relation" "decision_conflicts_with" {
  database         = notion_database.decision.id
  name             = "Conflicts With"
  related_database = notion_database.decision.id
}

# --- source ---

resource "notion_database_property_relation" "source_topics" {
  database         = notion_database.source.id
  name             = "Topics"
  related_database = notion_database.topic.id
}
