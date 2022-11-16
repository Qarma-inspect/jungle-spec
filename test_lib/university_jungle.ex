defmodule UniversityJungle do
  use JungleSpec

  open_api_object "UniversityJungle", description: "A university", struct?: false do
    property :name, :string
    property :is_technical, :boolean, default: false
    property :programs, {:array, :string}, description: "A list of programs"
    additional_properties {:array, [IDJungle, :integer]}, nullable: true
  end
end
