defmodule ConstrainedJungle do
  use JungleSpec

  open_api_object "ConstrainedJungle", deprecated: true do
    property :page, :integer, minimum: 1, maximum: 100
    property :slug, :string, min_length: 3, max_length: 30
    property :tags, {:array, :string}, min_items: 1, example: ["red", "blue"]
    property :ids, {:array, :string}, format: :uuid, min_items: 2
    property :codes, {:map, :string}, min_length: 2, min_properties: 1, example: %{"a" => "bb"}
    property :either, [:integer, :string], description: "a number or a word", example: 5
    property :rank, :integer, enum: [1, 2, 3]
  end
end
