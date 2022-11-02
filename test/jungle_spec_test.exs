defmodule JungleSpecTest do
  use ExUnit.Case

  test "Old and new object schemas are the same" do
    university_new = UniversityNew.schema()
    university_old = UniversityOld.schema()

    assert university_new == %{university_old | title: "UniversityNew"}

    student_new = StudentNew.schema()
    student_old = StudentOld.schema()

    updated_properties = %{student_old.properties | id: %OpenApiSpex.Reference{"$ref": "#/components/schemas/IDNew"}}

    assert student_new == %{student_old | title: "StudentNew", properties: updated_properties, "x-struct": StudentNew}
  end

  test "Old and new Type schemas are the same" do
    id_new = IDNew.schema()
    id_old = IDOld.schema()

    assert id_new == %{id_old | title: "IDNew"}
  end
end
