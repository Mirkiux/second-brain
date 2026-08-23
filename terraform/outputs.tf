output "database_ids" {
  description = "Notion database IDs, for the step 4 API/CLI/MCP layer to consume."
  value = {
    workplace          = notion_database.workplace.id
    project            = notion_database.project.id
    repo               = notion_database.repo.id
    work_item          = notion_database.work_item.id
    research_question  = notion_database.research_question.id
    experiment         = notion_database.experiment.id
    note               = notion_database.note.id
    decision           = notion_database.decision.id
    source             = notion_database.source.id
    person             = notion_database.person.id
    topic              = notion_database.topic.id
  }
}
