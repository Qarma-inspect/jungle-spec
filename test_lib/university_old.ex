defmodule UniversityOld do
  alias OpenApiSpex.Schema

  require OpenApiSpex

  OpenApiSpex.schema(
    %Schema{
      title: "UniversityOld",
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
        nullable: false,
        type: :string
      }
    },
    struct?: false
  )
end
