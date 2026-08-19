defmodule NestedJungle do
  use JungleSpec

  open_api_object "NestedJungle", default: %{"grid" => []} do
    property :grid, {:array, {:array, :string}}, minLength: 2, minItems: 1
  end
end
