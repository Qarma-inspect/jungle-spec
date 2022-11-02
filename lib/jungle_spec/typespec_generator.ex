defmodule JungleSpec.TypespecGenerator do
  @moduledoc """
  Generator of typespecs for OpenApiSpex.Schema structs.
  """

  alias OpenApiSpex.Schema

  defmacro define_object_type(module, schema, references_to_modules, opts) do
    quote bind_quoted: [module: module, schema: schema, references_to_modules: references_to_modules, opts: opts] do
      import JungleSpec.TypespecGenerator

      @type_ast properties_types(schema, references_to_modules, opts)

      if Keyword.get(opts, :struct?, true) do
        @type t :: unquote(@type_ast |> create_map_type() |> module_struct(module) |> maybe_nullable(schema))
      else
        @type t :: unquote(@type_ast |> create_map_type() |> maybe_nullable(schema))
      end

      # if the module is extended, this helper function will make getting properties' types easier
      def __jungle_type__(), do: @type_ast
    end
  end

  defmacro define_type(schema, references_to_modules) do
    quote bind_quoted: [schema: schema, references_to_modules: references_to_modules] do
      import JungleSpec.TypespecGenerator

      @type t :: unquote(create_type(schema, references_to_modules))
    end
  end

  def properties_types(schema, references_to_modules, opts) do
    references_to_modules = Map.new(references_to_modules)

    # since extended object is not adding anything to `references_to_modules`, we need to use it's already created type
    {object_properties, extended_properties_asts} =
      if Keyword.has_key?(opts, :extends) do
        extended_module = Keyword.get(opts, :extends)

        object_properties = Map.drop(schema.properties, Map.keys(extended_module.schema().properties))
        extended_properties_asts = get_extended_properties_ast(extended_module)

        {object_properties, extended_properties_asts}
      else
        {schema.properties, []}
      end

    properties_asts =
      Enum.map(object_properties, fn {name, property} ->
        property
        |> maybe_extend_by_nil()
        |> to_type_ast(references_to_modules)
        |> then(&{name, &1})
      end)

    properties_asts ++ extended_properties_asts
  end

  def create_map_type(properties_types) do
    {:%{}, [], properties_types}
  end

  def module_struct(contents, module) do
    {:%, [], [{:__aliases__, [alias: false], module_to_list(module)}, contents]}
  end

  def maybe_nullable(contents, schema) do
    if schema.nullable do
      {:|, [], [contents, nil]}
    else
      contents
    end
  end

  def create_type(schema, references_to_modules) do
    references_to_modules = Map.new(references_to_modules)

    schema
    |> maybe_extend_by_nil()
    |> to_type_ast(references_to_modules)
  end

  defp get_extended_properties_ast(extended_module) do
    Code.ensure_compiled!(extended_module).__jungle_type__()
  end

  defp maybe_extend_by_nil(%Schema{oneOf: schemas, nullable: nullable} = schema) when not is_nil(schemas) do
    schemas =
      schemas
      |> Enum.map(&maybe_extend_by_nil/1)
      |> Enum.reduce([], fn schema, acc ->
        case schema do
          %Schema{oneOf: schemas} when not is_nil(schemas) -> acc ++ schemas
          schema -> acc ++ [schema]
        end
      end)
      |> Enum.reject(fn schema -> schema == nil end)

    inner_schema_nullable =
      Enum.any?(schemas, fn
        %Schema{nullable: nullable} -> nullable
        _schema -> false
      end)

    if nullable || inner_schema_nullable do
      %Schema{schema | oneOf: schemas ++ [nil]}
    else
      %Schema{schema | oneOf: schemas}
    end
  end

  defp maybe_extend_by_nil(%Schema{type: :array, items: items_schema, nullable: nullable} = schema) do
    items_schema = maybe_extend_by_nil(items_schema)

    if nullable do
      %Schema{oneOf: [%Schema{schema | items: items_schema}, nil]}
    else
      %Schema{schema | items: items_schema}
    end
  end

  @primitive_types [:integer, :number, :string, :boolean]
  defp maybe_extend_by_nil(%Schema{type: type, nullable: nullable} = schema) when type in @primitive_types do
    if nullable do
      %Schema{oneOf: [schema, nil]}
    else
      schema
    end
  end

  defp maybe_extend_by_nil(schema) do
    schema
  end

  defp to_type_ast(%Schema{type: :integer}, _references_to_modules) do
    {:integer, [], []}
  end

  defp to_type_ast(%Schema{type: :number}, _references_to_modules) do
    {:number, [], []}
  end

  defp to_type_ast(%Schema{type: :string}, _references_to_modules) do
    {{:., [], [{:__aliases__, [alias: false], [:String]}, :t]}, [], []}
  end

  defp to_type_ast(%Schema{type: :boolean}, _references_to_modules) do
    {:boolean, [], []}
  end

  defp to_type_ast(%Schema{oneOf: schemas}, references_to_modules) when not is_nil(schemas) do
    union_to_ast(schemas, references_to_modules)
  end

  defp to_type_ast(%Schema{type: :array, items: schema}, references_to_modules) do
    [to_type_ast(schema, references_to_modules)]
  end

  defp to_type_ast(%OpenApiSpex.Reference{"$ref": reference}, references_to_modules) do
    to_type_ast(references_to_modules[reference], references_to_modules)
  end

  defp to_type_ast(module, _references_to_modules) do
    Code.ensure_compiled!(module)

    {module_alias, module} =
      case Macro.Env.fetch_alias(__ENV__, module) do
        {:ok, module_alias} -> {module_alias, module}
        :error -> {false, module}
      end

    {{:., [], [{:__aliases__, [alias: module_alias], module_to_list(module)}, :t]}, [], []}
  end

  defp union_to_ast([nil], _references_to_modules) do
    nil
  end

  defp union_to_ast([schema], references_to_modules) do
    to_type_ast(schema, references_to_modules)
  end

  defp union_to_ast([schema | schemas], references_to_modules) do
    {:|, [], [to_type_ast(schema, references_to_modules), union_to_ast(schemas, references_to_modules)]}
  end

  defp module_to_list(module) do
    module
    |> Module.split()
    |> Enum.map(&String.to_atom/1)
  end
end
