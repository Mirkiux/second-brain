variable "root_page_id" {
  description = "ID of the Notion page under which all Second Brain databases are created. This page must be shared with the integration in the Notion UI before running terraform apply."
  type        = string
}
