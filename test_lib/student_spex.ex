defmodule StudentSpex do
  alias OpenApiSpex.Schema

  require OpenApiSpex

  OpenApiSpex.schema(
    %Schema{
      title: "StudentSpex",
      type: :object,
      nullable: false,
      required:
        PersonSpex.schema().required ++
          [
            :degree_type,
            :university,
            :assignments
          ],
      properties:
        Map.merge(
          PersonSpex.schema().properties,
          %{
            degree_type: %Schema{
              type: :string,
              enum: ["bachelor's", "master's"],
              nullable: false
            },
            university: UniversityJungle,
            grades: %Schema{
              type: :array,
              nullable: true,
              items: %Schema{
                oneOf: [
                  %Schema{type: :number, nullable: false},
                  %Schema{type: :string, nullable: false}
                ],
                nullable: false
              }
            },
            assignments: %Schema{
              type: :object,
              nullable: true,
              properties: %{},
              additionalProperties: %Schema{type: :array, items: %Schema{type: :string, nullable: false}, nullable: false},
              description: "Assignemnts per subject"
            }
          }
        )
    },
    derive?: false
  )
end
