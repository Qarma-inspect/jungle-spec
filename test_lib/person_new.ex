defmodule PersonNew do
  use JungleSpec

  open_api_object "PersonNew", required: false, struct?: false do
    property :id, IDNew, required: true
    property :additional_id, IDNew, required: false, nullable: true
    property :name, :string, required: true
    property :age, :integer
    property :height, :number
  end
end
