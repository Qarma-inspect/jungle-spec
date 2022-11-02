defmodule StudentOld do
  alias OpenApiSpex.Schema

  require OpenApiSpex

  OpenApiSpex.schema(
    %Schema{
      title: "StudentOld",
      type: :object,
      nullable: false,
      required:
        PersonOld.schema().required ++
          [
            :degree_type,
            :university
          ],
      properties:
        Map.merge(
          PersonOld.schema().properties,
          %{
            degree_type: %Schema{
              type: :string,
              enum: ["bachelor's", "master's"],
              nullable: false
            },
            university: UniversityNew,
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
            }
          }
        )
    },
    derive?: false
  )
end
