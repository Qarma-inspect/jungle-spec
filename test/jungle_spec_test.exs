defmodule JungleSpecTest do
  use ExUnit.Case

  test "Old and new object schemas are the same" do
    university_new = UniversityJungle.schema()
    university_old = UniversitySpex.schema()

    assert university_new == %{university_old | title: "UniversityJungle"}

    student_new = StudentJungle.schema()
    student_old = StudentSpex.schema()

    assert student_new == %{student_old | title: "StudentJungle", properties: student_old.properties, "x-struct": StudentJungle}
  end

  test "Old and new Type schemas are the same" do
    id_new = IDJungle.schema()
    id_old = %{IDSpex.schema() | title: "IDJungle"}

    # Regex structs built in different modules do not compare equal on Elixir 1.20, so the
    # pattern is compared through its source.
    assert id_new.pattern.source == id_old.pattern.source
    assert %{id_new | pattern: nil} == %{id_old | pattern: nil}
  end

  test "String with :binary format becomes Plug.Upload.t()" do
    assert {:ok, types} = Code.Typespec.fetch_types(FileUpload)
    type_str = types |> hd() |> elem(1) |> Code.Typespec.type_to_quoted() |> Macro.to_string()
    assert type_str == "t() :: %FileUpload{file: Plug.Upload.t(), metadata: %{optional(String.t()) => String.t()}}"
  end

  describe "option contract" do
    test "validation keywords reach the generated schema" do
      properties = ConstrainedJungle.schema().properties

      assert properties.page.minimum == 1
      assert properties.page.maximum == 100
      assert properties.slug.minLength == 3
      assert properties.slug.maxLength == 30
      assert properties.tags.minItems == 1
    end

    test "object level options reach the generated schema" do
      assert ConstrainedJungle.schema().deprecated
    end

    test "options stay on the outer schema instead of leaking into the item schema" do
      tags = ConstrainedJungle.schema().properties.tags

      assert tags.example == ["red", "blue"]
      assert tags.items.example == nil
    end

    test "an unknown option raises and suggests the closest supported one" do
      assert_raise ArgumentError,
                   ~r/:desciption is not a supported option for name\. Did you mean :description\?/,
                   &define_misspelled_option_schema/0
    end

    test "an option JungleSpec sets itself raises" do
      assert_raise ArgumentError,
                   ~r/:type cannot be given as an option for name: JungleSpec sets it itself/,
                   &define_derived_option_schema/0
    end

    test "a validation keyword that does not apply to the type raises" do
      assert_raise ArgumentError,
                   ~r/:minimum cannot be given as an option for name: it does not apply to type :string/,
                   &define_mismatched_constraint_schema/0
    end

    test "item options describe the items of a collection, not the container" do
      properties = ConstrainedJungle.schema().properties

      assert properties.ids.items.format == :uuid
      assert properties.ids.format == nil
      assert properties.ids.minItems == 2
      assert properties.codes.additionalProperties.minLength == 2
      assert properties.codes.minProperties == 1
      assert properties.codes.minLength == nil
    end

    test "passthrough reaches map and union schemas" do
      properties = ConstrainedJungle.schema().properties

      assert properties.codes.example == %{"a" => "bb"}
      assert properties.codes.additionalProperties.example == nil
      assert properties.either.description == "a number or a word"
      assert properties.either.example == 5
    end

    test "an item option raises when the type has no single item to describe" do
      assert_raise ArgumentError,
                   ~r/:format cannot be given as an option for either: it does not apply to type/,
                   &define_union_item_option_schema/0
    end

    test "an object level enum is rejected" do
      assert_raise ArgumentError,
                   ~r/:enum cannot be given as an option for ObjectEnum: it does not apply to type :object/,
                   &define_object_enum_schema/0
    end

    test "an enum is accepted for every scalar type" do
      properties = ConstrainedJungle.schema().properties

      assert properties.rank.enum == [1, 2, 3]
      assert properties.score.enum == [1.5, 2.5]
      assert properties.kind.enum == ["first", "second"]
    end

    test "enum values have to match the type they are given for" do
      assert_raise ArgumentError,
                   ~r/the enum values of rank do not all match its type :integer/,
                   &define_mismatched_enum_schema/0
    end

    test "every camelCased schema field is rejected with a usable message" do
      camel_cased = Enum.filter(list_schema_fields(), &camel_cased?/1)
      unhelpful = Enum.reject(camel_cased, &helpful_rejection?/1)

      assert camel_cased != []
      assert unhelpful == []
    end

    test "a camelCased option name is rejected and points at the Elixir one" do
      assert_raise ArgumentError,
                   ~r/:minLength is not a supported option for slug\. Did you mean :min_length\?/,
                   &define_camel_case_option_schema/0
    end

    test "an item option reaches the innermost schema of nested collections" do
      assert NestedJungle.schema().properties.grid.items.items.minLength == 2
    end

    test "open_api_type can be given without an option list" do
      assert TwoArgJungle.schema().type == :string
      assert TwoArgJungle.schema().title == "TwoArgJungle"
    end

    test "an object level default reaches the schema" do
      assert NestedJungle.schema().default == %{"grid" => []}
    end

    test "a collection nested in a collection cannot be constrained from the outside" do
      assert_raise ArgumentError,
                   ~r/:min_properties cannot be given as an option for buckets: it does not apply to type/,
                   &define_nested_container_option_schema/0
    end

    test "an object level option that does not apply to objects raises" do
      assert_raise ArgumentError,
                   ~r/:min_length cannot be given as an option for ObjectConstraint: it does not apply to type :object/,
                   &define_object_constraint_schema/0
    end

    test "an object only option raises when given to open_api_type" do
      assert_raise ArgumentError,
                   ~r/:struct\? cannot be given as an option for OnlyObject: it is only supported by open_api_object/,
                   &define_object_only_option_schema/0
    end
  end

  defp list_schema_fields do
    %OpenApiSpex.Schema{}
    |> Map.from_struct()
    |> Map.keys()
  end

  # Decided from the spelling alone, so that a regression in the translation removes coverage from
  # nothing and instead makes the assertion below fail.
  defp camel_cased?(schema_field) do
    schema_field
    |> Atom.to_string()
    |> String.match?(~r/[A-Z-]/)
  end

  defp helpful_rejection?(schema_field) do
    message = describe_rejection(schema_field)
    option = JungleSpec.OptionName.to_option(schema_field)

    String.contains?(message, "Did you mean #{inspect(option)}?") or
      String.contains?(message, "sets it itself")
  end

  defp describe_rejection(schema_field) do
    code = """
    defmodule CamelCased#{System.unique_integer([:positive])} do
      use JungleSpec

      open_api_object "CamelCased" do
        property :slug, :string, #{to_keyword_key(schema_field)} 1
      end
    end
    """

    try do
      Code.compile_string(code)
      "the option was accepted"
    rescue
      error in ArgumentError -> Exception.message(error)
    end
  end

  # A name that is not a bare atom literal has to be quoted; quoting the others would warn.
  defp to_keyword_key(schema_field) do
    name = Atom.to_string(schema_field)

    if String.match?(name, ~r/^[a-zA-Z_][a-zA-Z0-9_]*$/) do
      "#{name}:"
    else
      ~s("#{name}":)
    end
  end

  defp define_misspelled_option_schema do
    defmodule MisspelledOption do
      use JungleSpec

      open_api_object "MisspelledOption" do
        property :name, :string, desciption: "typo"
      end
    end
  end

  defp define_derived_option_schema do
    defmodule DerivedOption do
      use JungleSpec

      open_api_object "DerivedOption" do
        property :name, :string, type: :uuid
      end
    end
  end

  defp define_mismatched_constraint_schema do
    defmodule MismatchedConstraint do
      use JungleSpec

      open_api_object "MismatchedConstraint" do
        property :name, :string, minimum: 1
      end
    end
  end

  defp define_nested_container_option_schema do
    defmodule NestedContainerOption do
      use JungleSpec

      open_api_object "NestedContainerOption" do
        property :buckets, {:array, {:map, :string}}, min_properties: 1
      end
    end
  end

  defp define_union_item_option_schema do
    defmodule UnionItemOption do
      use JungleSpec

      open_api_object "UnionItemOption" do
        property :either, [:string, :integer], format: :uuid
      end
    end
  end

  defp define_mismatched_enum_schema do
    defmodule MismatchedEnum do
      use JungleSpec

      open_api_object "MismatchedEnum" do
        property :rank, :integer, enum: [1, "two"]
      end
    end
  end

  defp define_camel_case_option_schema do
    defmodule CamelCaseOption do
      use JungleSpec

      open_api_object "CamelCaseOption" do
        property :slug, :string, minLength: 3
      end
    end
  end

  defp define_object_enum_schema do
    defmodule ObjectEnum do
      use JungleSpec

      open_api_object "ObjectEnum", enum: [1, 2]
    end
  end

  defp define_object_constraint_schema do
    defmodule ObjectConstraint do
      use JungleSpec

      open_api_object "ObjectConstraint", min_length: 3
    end
  end

  defp define_object_only_option_schema do
    defmodule ObjectOnlyOption do
      use JungleSpec

      open_api_type "OnlyObject", :string, struct?: false
    end
  end
end
