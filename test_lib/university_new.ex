defmodule UniversityNew do
  use JungleSpec

  open_api_object "UniversityNew", description: "A university", struct?: false do
    property :name, :string
    property :is_technical, :boolean, default: false
    property :programs, {:array, :string}, description: "A list of programs"
    additional_properties {:array, [IDNew, :integer]}, nullable: true
  end
end
