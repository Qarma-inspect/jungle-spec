defmodule PersonOld do
  alias OpenApiSpex.Schema

  require OpenApiSpex

  OpenApiSpex.schema(
    %Schema{
      title: "PersonOld",
      type: :object,
      nullable: false,
      required: [
        :id,
        :name
      ],
      properties: %{
        id: %OpenApiSpex.Reference{"$ref": "#/components/schemas/IDOld"},
        name: %Schema{type: :string, nullable: false},
        age: %Schema{type: :integer, nullable: false},
        height: %Schema{type: :number, nullable: false}
      }
    },
    struct?: false
  )
end
