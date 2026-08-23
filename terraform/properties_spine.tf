# Entity-specific fields for the structural spine.
# Kind/Type/Status selects follow the same "small enum" shape throughout —
# see properties_knowledge.tf for the common-metadata fields shared by the
# five knowledge entities.

resource "notion_database_property_select" "workplace_kind" {
  database = notion_database.workplace.id
  name     = "Kind"
  options = {
    "Personal" = "blue"
    "Employer" = "orange"
    "Client"   = "purple"
  }
}

resource "notion_database_property_select" "project_status" {
  database = notion_database.project.id
  name     = "Status"
  options = {
    "Active"    = "green"
    "Paused"    = "yellow"
    "Completed" = "blue"
    "Archived"  = "gray"
  }
}

resource "notion_database_property_url" "repo_url" {
  database = notion_database.repo.id
  name     = "URL"
}

resource "notion_database_property_select" "repo_kind" {
  database = notion_database.repo.id
  name     = "Kind"
  options = {
    "Project-specific" = "blue"
    "General"           = "purple"
  }
}

resource "notion_database_property_select" "work_item_type" {
  database = notion_database.work_item.id
  name     = "Type"
  options = {
    "Ticket"     = "blue"
    "Session"    = "yellow"
    "Plan step"  = "purple"
  }
}

resource "notion_database_property_select" "work_item_status" {
  database = notion_database.work_item.id
  name     = "Status"
  options = {
    "Open"   = "yellow"
    "Closed" = "green"
  }
}
