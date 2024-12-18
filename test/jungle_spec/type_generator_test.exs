defmodule JungleSpec.TypespecGeneratorTest do
  use ExUnit.Case

  alias OpenApiSpex.Schema

  import JungleSpec.TypespecGenerator

  defmodule ExampleModule do
    use JungleSpec

    open_api_object "ExampleModule", struct?: false do
      property :name, :string
    end
  end

  describe "open_api_object" do
    test "primitive types" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          bool: %Schema{type: :boolean, nullable: false},
          int: %Schema{type: :integer, nullable: false},
          num: %Schema{type: :number, nullable: false},
          str: %Schema{type: :string, nullable: false}
        }
      }

      type =
        quote do
          %{bool: boolean(), int: integer(), num: number(), str: String.t()}
        end

      assert {:%{}, [], expected_type_fields} = type

      expected_types = Map.new(expected_type_fields)

      assert {:%{}, [], type_fields} =  generate_type(schema, [], [])
      types = Map.new(type_fields)

      assert expected_types == types
    end

    test "array type" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          arr: %Schema{type: :array, items: %Schema{type: :string, nullable: false}}
        }
      }

      type =
        quote do
          %{arr: [String.t()]}
        end

      assert generate_type(schema, [], []) == type
    end

    test "map type" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          map: %Schema{type: :object, additionalProperties: %Schema{type: :number, nullable: false}}
        }
      }

      type =
        quote do
          %{map: %{optional(String.t()) => number()}}
        end

      assert generate_type(schema, [], []) == type
    end

    test "union type" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          union: %Schema{oneOf: [%Schema{type: :string, nullable: false}, %Schema{type: :integer, nullable: false}]}
        }
      }

      type =
        quote do
          %{union: String.t() | integer()}
        end

      assert generate_type(schema, [], []) == type
    end

    test "inline module type" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          module: ExampleModule
        }
      }

      type =
        quote do
          %{module: JungleSpec.TypespecGeneratorTest.ExampleModule.t()}
        end

      assert generate_type(schema, [], []) == type
    end

    test "single inline module in a nullable union" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          union: %Schema{oneOf: [ExampleModule], nullable: true}
        }
      }

      type =
        quote do
          %{union: JungleSpec.TypespecGeneratorTest.ExampleModule.t() | nil}
        end

      assert generate_type(schema, [], []) == type
    end

    test "referenced module type" do
      reference = "#/components/schemas/" <> ExampleModule.schema().title

      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          module: %OpenApiSpex.Reference{"$ref": reference}
        }
      }

      type =
        quote do
          %{module: JungleSpec.TypespecGeneratorTest.ExampleModule.t()}
        end

      references_to_modules = [{reference, JungleSpec.TypespecGeneratorTest.ExampleModule}]
      assert generate_type(schema, references_to_modules, []) == type
    end

    test "nested type" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          nested: %Schema{
            type: :array,
            items: %Schema{
              oneOf: [
                %Schema{type: :string, nullable: false},
                %Schema{type: :array, items: %Schema{type: :integer, nullable: false}}
              ]
            }
          }
        }
      }

      type =
        quote do
          %{nested: [String.t() | [integer()]]}
        end

      assert generate_type(schema, [], []) == type
    end

    test "struct type" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          bool: %Schema{type: :boolean, nullable: false}
        }
      }

      type =
        quote do
          %Example{bool: boolean()}
        end

      assert generate_type(schema, [], [], Example) == type
    end

    test "nullable type" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          bool: %Schema{type: :boolean, nullable: true},
          union: %Schema{
            oneOf: [
              %Schema{type: :string, nullable: true},
              %Schema{type: :array, items: %Schema{type: :integer, nullable: true}, nullable: true}
            ]
          }
        }
      }

      type =
        quote do
          %{
            bool: boolean() | nil,
            union: String.t() | [integer() | nil] | nil
          }
        end

      assert generate_type(schema, [], []) == type
    end

    test "nullable object" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: true,
        properties: %{
          string: %Schema{type: :string, nullable: false}
        }
      }

      type =
        quote do
          %{string: String.t()} | nil
        end

      assert generate_type(schema, [], []) == type
    end

    test "extended schema" do
      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          int: %Schema{type: :integer, nullable: false}
        }
      }

      type =
        quote do
          %{
            int: integer(),
            name: String.t()
          }
        end

      opts = [{:extends, ExampleModule}]

      assert generate_type(schema, [], opts) == type
    end

    test "additional propeties present" do
      reference = "#/components/schemas/" <> ExampleModule.schema().title

      schema = %Schema{
        title: "Example",
        type: :object,
        nullable: false,
        properties: %{
          string: %Schema{type: :string, nullable: false}
        },
        additionalProperties: %Schema{
          nullable: true,
          type: :array,
          items: %Schema{
            nullable: false,
            oneOf: [%OpenApiSpex.Reference{"$ref": reference}, %Schema{type: :integer, nullable: false}]
          }
        }
      }

      type =
        quote do
          %{
            String.t() => [JungleSpec.TypespecGeneratorTest.ExampleModule.t() | integer()] | nil,
            string: String.t()
          }
        end

      references_to_modules = [{reference, JungleSpec.TypespecGeneratorTest.ExampleModule}]
      assert generate_type(schema, references_to_modules, []) == type
    end

    defp generate_type(schema, references_to_modules, opts, module \\ nil)

    defp generate_type(schema, references_to_modules, opts, nil) do
      schema
      |> properties_types(references_to_modules, opts)
      |> create_map_type()
      |> maybe_nullable(schema)
    end

    defp generate_type(schema, references_to_modules, opts, module) do
      schema
      |> properties_types(references_to_modules, opts)
      |> create_map_type()
      |> module_struct(module)
      |> maybe_nullable(schema)
    end
  end

  describe "open_api_type" do
    test "primitive type" do
      schema = %Schema{
        title: "Example",
        type: :string,
        nullable: false
      }

      type =
        quote do
          String.t()
        end

      assert create_type(schema, []) == type
    end

    test "nested and nullable type" do
      reference = "#/components/schemas/" <> ExampleModule.schema().title

      schema = %Schema{
        title: "Example",
        oneOf: [
          %Schema{type: :array, items: %Schema{type: :integer, nullable: true}, nullable: true},
          %Schema{type: :object, additionalProperties: %Schema{type: :boolean, nullable: false}},
          %OpenApiSpex.Reference{"$ref": reference}
        ],
        nullable: true
      }

      type =
        quote do
          [integer() | nil] | %{optional(String.t()) => boolean()} | JungleSpec.TypespecGeneratorTest.ExampleModule.t() | nil
        end

      references_to_modules = [{reference, JungleSpec.TypespecGeneratorTest.ExampleModule}]
      assert create_type(schema, references_to_modules) == type
    end
  end
end
