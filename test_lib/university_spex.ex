defmodule UniversitySpex do
  alias OpenApiSpex.Schema

  require OpenApiSpex

  OpenApiSpex.schema(
    %Schema{
      title: "UniversitySpex",
      description: "A university",
      type: :object,
      nullable: false,
      required: [
        :name,
        :is_technical,
        :programs
      ],
      properties: %{
        name: %Schema{type: :string, nullable: false},
        is_technical: %Schema{type: :boolean, default: false, nullable: false},
        programs: %Schema{
          type: :array,
          nullable: false,
          items: %Schema{type: :string, nullable: false},
          description: "A list of programs"
        }
      },
      additionalProperties: %Schema{
        type: :array,
        nullable: true,
        items: %Schema{
          oneOf: [%OpenApiSpex.Reference{"$ref": "#/components/schemas/IDJungle"}, %Schema{type: :integer, nullable: false}]
        }
      }
    },
    struct?: false
  )
end
