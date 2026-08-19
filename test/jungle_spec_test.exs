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
end
