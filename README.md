# JungleSpec

A library providing simplified and less verbose way of definining OpenApiSpex types.

Example definition:

```elixir
defmodule Employee do
  use JungleSpec

  open_api_object "Employee", extends: Person, struct?: false do
    property :level, :string, enum: ["L1", "L2", "L3"]
    property :experience, [:number, :string]
    property :is_manager, :boolean, default: false
    property :team_members, {:array, Employee}, nullable: true
    property :technologies_to_experience, {:map, :string}
    additional_properties :integer
  end
end
```

It creates an OpenApiSpex type with title `"Employee"` that has all properties from the schema
defined in `Person` module. It also won't create any struct corresponding to the Employee module.

Other properties in the `Employee` schema:
* `:level` - it has type `:string` and can be one of `["L1", "L2", "L3"]`
* `:experience` - its type is a union of `:number` and `:string`
* `:is_manager` - it has type `:boolean` and is `false` by default
* `:team_members` - its type is an array with employees or `nil`
* `:technologies_to_experience` - its type is an object with additional properties having type `:string`
* `additional_properties` - the schema can have more properties having type `:integer`

All properties are required and not nullable by default.

Also, the following typespec will be created:

```elixir
@type t :: %{
  # additional properties
  String.t() => integer(),
  # properties
  level: String.t(),
  experience: number() | String.t(),
  is_manager: boolean(),
  team_members: [t()] | nil,
  technologies_to_experience: %{optional(String.t()) => String.t()},
  ... # and all properties from Person
}
```

For more information refer to `JungleSpec` module docs.
