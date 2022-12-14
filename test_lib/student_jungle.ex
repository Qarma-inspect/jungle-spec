defmodule StudentJungle do
  use JungleSpec

  open_api_object "StudentJungle", extends: PersonJungle do
    property :degree_type, :string, enum: ["bachelor's", "master's"]
    property :university, UniversityJungle, inline: true
    property :grades, {:array, [:number, :string]}, required: false, nullable: true
    property :assignments, {:map, {:array, :string}}, description: "Assignemnts per subject", nullable: true
  end
end
