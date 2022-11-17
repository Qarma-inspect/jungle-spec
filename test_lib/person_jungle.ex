defmodule PersonJungle do
  use JungleSpec

  open_api_object "PersonJungle", required: false, struct?: false do
    property :id, IDJungle, required: true
    property :additional_id, IDJungle, required: false, nullable: true
    property :name, :string, required: true
    property :age, :integer
    property :height, :number
  end
end
