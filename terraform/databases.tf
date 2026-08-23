# The eleven databases from data-model.md, grouped by layer.
# Properties and relations are defined in the other .tf files so each
# database's shape stays next to the pattern it follows.

# --- structural spine ---

resource "notion_database" "workplace" {
  parent              = var.root_page_id
  title               = "Workplaces"
  title_column_title  = "Name"
}

resource "notion_database" "project" {
  parent              = var.root_page_id
  title               = "Projects"
  title_column_title  = "Name"
}

resource "notion_database" "repo" {
  parent              = var.root_page_id
  title               = "Repos"
  title_column_title  = "Name"
}

resource "notion_database" "work_item" {
  parent              = var.root_page_id
  title               = "Work Items"
  title_column_title  = "Name"
}

# --- knowledge entities ---

resource "notion_database" "research_question" {
  parent              = var.root_page_id
  title               = "Research Questions"
  title_column_title  = "Question"
}

resource "notion_database" "experiment" {
  parent              = var.root_page_id
  title               = "Experiments"
  title_column_title  = "Name"
}

resource "notion_database" "note" {
  parent              = var.root_page_id
  title               = "Notes"
  title_column_title  = "Name"
}

resource "notion_database" "decision" {
  parent              = var.root_page_id
  title               = "Decisions"
  title_column_title  = "Name"
}

resource "notion_database" "source" {
  parent              = var.root_page_id
  title               = "Sources"
  title_column_title  = "Title"
}

# --- cross-cutting ---

resource "notion_database" "person" {
  parent              = var.root_page_id
  title               = "People"
  title_column_title  = "Name"
}

resource "notion_database" "topic" {
  parent              = var.root_page_id
  title               = "Topics"
  title_column_title  = "Name"
}
