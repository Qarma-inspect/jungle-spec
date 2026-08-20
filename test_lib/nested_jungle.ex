defmodule NestedJungle do
  use JungleSpec

  open_api_object "NestedJungle", default: %{"grid" => []} do
    property :grid, {:array, {:array, :string}}, min_length: 2, min_items: 1
  end
end
