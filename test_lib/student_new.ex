defmodule StudentNew do
  use JungleSpec

  open_api_object "StudentNew", extends: PersonNew do
    property :degree_type, :string, enum: ["bachelor's", "master's"]
    property :university, UniversityNew, inline: true
    property :grades, {:array, [:number, :string]}, required: false, nullable: true
  end
end
