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
        id: %OpenApiSpex.Reference{"$ref": "#/components/schemas/IDNew"},
        additional_id: %Schema{oneOf: [%OpenApiSpex.Reference{"$ref": "#/components/schemas/IDNew"}], nullable: true},
        name: %Schema{type: :string, nullable: false},
        age: %Schema{type: :integer, nullable: false},
        height: %Schema{type: :number, nullable: false}
      }
    },
    struct?: false
  )
end
