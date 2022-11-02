# OpenApiSpexGenerator

A library providing simplified and less verbose way of definining OpenApiSpex types.

Example definition:

```elixir
defmodule Employee do
  use JungleSpec

  open_api_object "Employee", extends: Person, struct?: false do
    property :level, :string, enum: ["L1", "L2", "L3"]
    property :experience, [:number, :string]
    property :is_manager, :boolean, default: false
    property :known_technologies, {:array, :string}
    additional_properties :string
  end
end
```

It creates an OpenApiSpex type with title `"Employee"` that has all properties from the schema
defined in `Person` module. It also won't create any struct corresponding to the Employee module.

Other properties in the `Employee` schema:
* `:level` - it has type `:string` and can be one of `["L1", "L2", "L3"]`
* `:experience` - its type is a union of `:number` and `:string`
* `:is_manager` - it has type `:boolean` and is `false` by default
* `:known_technologies` - its type is an array with strings
* `additional_properties` - it can have more properties having type `:string`

All properties are required and not nullable by default.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `open_api_spex_generator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:open_api_spex_generator, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/open_api_spex_generator>.

