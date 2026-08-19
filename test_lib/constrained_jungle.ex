defmodule ConstrainedJungle do
  use JungleSpec

  open_api_object "ConstrainedJungle", deprecated: true do
    property :page, :integer, minimum: 1, maximum: 100
    property :slug, :string, minLength: 3, maxLength: 30
    property :tags, {:array, :string}, minItems: 1, example: ["red", "blue"]
    property :ids, {:array, :string}, format: :uuid, minItems: 2
    property :codes, {:map, :string}, minLength: 2, minProperties: 1, example: %{"a" => "bb"}
    property :either, [:integer, :string], description: "a number or a word", example: 5
  end
end
