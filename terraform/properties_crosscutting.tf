# Person and Topic carry almost no fields of their own — nearly all of
# their value is in the relations that reach into every other database
# (see relations.tf).

resource "notion_database_property_rich_text" "person_role" {
  database = notion_database.person.id
  name     = "Role"
}

# Topic has no fields beyond its title column (Name) — it exists to be
# related to, not to carry data of its own.
