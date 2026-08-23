# Entity-specific fields for the five knowledge entities, plus the common
# metadata block (Provenance / Confidence / Epistemic status / Last
# validated / Created) they all share per data-model.md. The common block
# is written once with for_each instead of five times — the loop is the
# literal Terraform form of "common metadata," the same pattern collapsed
# into one mechanism.

# --- entity-specific fields ---

resource "notion_database_property_select" "research_question_status" {
  database = notion_database.research_question.id
  name     = "Status"
  options = {
    "Open"      = "yellow"
    "Answered"  = "green"
    "Abandoned" = "gray"
  }
}

resource "notion_database_property_rich_text" "experiment_hypothesis" {
  database = notion_database.experiment.id
  name     = "Hypothesis"
}

resource "notion_database_property_rich_text" "experiment_method" {
  database = notion_database.experiment.id
  name     = "Method / Config"
}

resource "notion_database_property_rich_text" "experiment_reproducibility" {
  database = notion_database.experiment.id
  name     = "Reproducibility Notes"
}

resource "notion_database_property_rich_text" "experiment_result" {
  database = notion_database.experiment.id
  name     = "Result"
}

resource "notion_database_property_select" "experiment_conclusion" {
  database = notion_database.experiment.id
  name     = "Conclusion"
  options = {
    "Validated"    = "green"
    "Refuted"      = "red"
    "Inconclusive" = "yellow"
    "Abandoned"    = "gray"
  }
}

resource "notion_database_property_rich_text" "note_body" {
  database = notion_database.note.id
  name     = "Body"
}

resource "notion_database_property_select" "note_subtype" {
  database = notion_database.note.id
  name     = "Subtype"
  options = {
    "Fact"          = "blue"
    "Pattern"       = "purple"
    "Gotcha"        = "red"
    "Preference"    = "yellow"
    "Open question" = "gray"
  }
}

resource "notion_database_property_select" "note_reusability" {
  database = notion_database.note.id
  name     = "Reusability"
  options = {
    "Project-specific" = "blue"
    "Generalizable"    = "green"
  }
}

resource "notion_database_property_rich_text" "decision_context" {
  database = notion_database.decision.id
  name     = "Context"
}

resource "notion_database_property_rich_text" "decision_decision" {
  database = notion_database.decision.id
  name     = "Decision"
}

resource "notion_database_property_rich_text" "decision_consequences" {
  database = notion_database.decision.id
  name     = "Consequences"
}

resource "notion_database_property_select" "decision_status" {
  database = notion_database.decision.id
  name     = "Status"
  options = {
    "Active"     = "green"
    "Superseded" = "gray"
    "Disputed"   = "red"
    "Deprecated" = "orange"
  }
}

resource "notion_database_property_select" "source_type" {
  database = notion_database.source.id
  name     = "Type"
  options = {
    "External doc"       = "blue"
    "Meeting transcript" = "yellow"
    "Paper"              = "purple"
    "Chat export"        = "orange"
    "Other"              = "gray"
  }
}

resource "notion_database_property_url" "source_reference" {
  database = notion_database.source.id
  name     = "Reference"
}

# NOTE: Source's raw-content attachment (Files & Media property) has no
# corresponding resource in delize/notion — it isn't in this provider's
# supported property types yet. Add that one field manually in the Notion
# UI after the first apply; everything else is declarative.

# --- common metadata, shared by all five knowledge entities ---

locals {
  knowledge_databases = {
    research_question = notion_database.research_question.id
    experiment         = notion_database.experiment.id
    note               = notion_database.note.id
    decision           = notion_database.decision.id
    source             = notion_database.source.id
  }
}

resource "notion_database_property_select" "provenance" {
  for_each = local.knowledge_databases
  database = each.value
  name     = "Provenance"
  options = {
    "Human" = "blue"
    "Agent" = "purple"
  }
}

resource "notion_database_property_select" "confidence" {
  for_each = local.knowledge_databases
  database = each.value
  name     = "Confidence"
  options = {
    "Low"    = "red"
    "Medium" = "yellow"
    "High"   = "green"
  }
}

resource "notion_database_property_select" "epistemic_status" {
  for_each = local.knowledge_databases
  database = each.value
  name     = "Epistemic Status"
  options = {
    "Confirmed"   = "green"
    "Hypothesis"  = "yellow"
    "Speculation" = "gray"
  }
}

resource "notion_database_property_date" "last_validated" {
  for_each = local.knowledge_databases
  database = each.value
  name     = "Last Validated"
}

resource "notion_database_property_created_time" "created" {
  for_each = local.knowledge_databases
  database = each.value
  name     = "Created"
}
