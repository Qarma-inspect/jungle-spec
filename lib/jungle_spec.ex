defmodule JungleSpec do
  @moduledoc """
  A module providing simplified and less verbose way of definining OpenApiSpex types.

  Example definition:

      defmodule Employee do
        use JungleSpec

        open_api_object "Employee", extends: Person, struct?: false do
          property :level, :string, enum: ["L1", "L2", "L3"]
          property :experience, [:number, :string]
          property :is_manager, :boolean, default: false
          property :known_technologies, {:array, :string}
          additional_properties :string
        end
      end
  """

  alias OpenApiSpex.Schema

  defmacro __using__(_) do
    quote do
      import JungleSpec,
        only: [
          additional_properties: 1,
          open_api_object: 1,
          open_api_object: 2,
          open_api_object: 3,
          open_api_type: 2,
          open_api_type: 3,
          property: 3
        ]
    end
  end

  @doc """
  Defines OpenApiSpex schema with `:object` type and appropriate typespec.

  It has one required argument:

    * `title` - a binary being a title of the schema

  It is followed by an optional keyword list of options and an optional `do ... end` block
  containing object's properties.

  Possible options

    * `:description` - a binary describing the whole object

    * `:example` - a map being an example of the object defined by the schema

    * `:extends` - a module of the schema that this schema extends. All properties of the extended
      schema will be added to the current schema, preserving the information if the properties are
      required. It does not propagate nullability of the extended schema. Ensure that
      `open_api_object/3` macro was used to define the extended module

    * `:inline` - a boolean value specifying the default `inline` option for all properties. By
      default it is `false`

    * `:nullable` - a boolean value specifying whether the object can be nullable. `false` by
      default

    * `:required` - a boolean value specifying the default `required` option for all properties. By
      default it is `true`

    * `:struct?` - a boolean value telling OpenApiSpex if it should create a struct out of the
      object. It will also add the struct to the typespec if set to `true`
  """
  defmacro open_api_object(title, opts, do: block) do
    quote do
      Module.register_attribute(__MODULE__, :properties, accumulate: true)
      Module.register_attribute(__MODULE__, :additional_properties, accumulate: false)
      Module.register_attribute(__MODULE__, :references_to_modules, accumulate: true)

      import JungleSpec
      import JungleSpec.TypespecGenerator, only: [define_object_type: 4]

      require OpenApiSpex

      unquote(block)

      object_schema = prepare_object_schema(__MODULE__, unquote(title), @properties, @additional_properties, unquote(opts))

      maybe_define_struct(object_schema, unquote(opts))
      define_object_type(__MODULE__, object_schema, @references_to_modules, unquote(opts))

      OpenApiSpex.schema(object_schema, struct?: false, derive?: false)
    end
  end

  defmacro open_api_object(title, do: block) do
    quote do
      open_api_object(unquote(title), [], do: unquote(block))
    end
  end

  defmacro open_api_object(title, opts) do
    quote do
      open_api_object(unquote(title), unquote(opts), do: nil)
    end
  end

  defmacro open_api_object(title) do
    quote do
      open_api_object(unquote(title), [], do: nil)
    end
  end

  @doc """
  Defines OpenApiSpex schema with type different from `:object` and appropriate typespec.

  It has two required arguments:

    * `title` - a binary being a title of the schema

    * `type` - an atom proving the type of the schema. More information in `property` macro

  It is followed by an optional keyword list of options. Possible options are all options that
  `property` can have.
  """
  defmacro open_api_type(title, type, opts \\ []) do
    quote do
      Module.register_attribute(__MODULE__, :references_to_modules, accumulate: true)

      import JungleSpec
      import JungleSpec.TypespecGenerator, only: [define_type: 2]

      require OpenApiSpex

      type_schema = prepare_type_schema(__MODULE__, unquote(title), unquote(type), unquote(opts))
      define_type(type_schema, @references_to_modules)

      OpenApiSpex.schema(type_schema, struct?: false)
    end
  end

  @doc """
  Defines one property for the open_api_object.

  It has two required arguments:

    * `name` - an atom being a name of the property

    * `type` - an atom proving the type of the schema

  Allowed types:

    * `:integer` - maps to the type of the same name

    * `:number` - either integer or float. Maps to the type of the same name

    * `:string` - a binary. Maps to the type of the same name

    * `:boolean` - maps to the type of the same name

    * `{:array, type}` - a list of elements having provided type. `type` have to be one of the
      allowed types

    * `[type_1, type_2, ...]` - a union of the provided types. The types have to be allowed

    * `module` - a module name that has it's own schema

  Property also has an optional keyword list with the following possible options:

    * `:default` - default value for the property. It has to match its type

    * `:description` - a binary describing the property

    * `:enum` - a list of possible values which have to be binaries. Also, property has to have
      `:string` type

    * `:example` - an example of the property. It has to match its type

    * `:format` - a binary describing property's format

    * `:inline` - a boolean value that is used if the property's type is another module. Then,
      if `inline: true`, the module's schema is just inlined. Otherwise, only the reference is
      used. By default, the value is propagated from the object

    * `:nullable` - a boolean value specifying if the property can be `nil`. `false` by default

    * `:pattern` - a regular expression describing possible format of the property

    * `:required` - a boolean value specifying if the property should be added to the list of
      object's required properties. By default, it is propagated from the object
  """
  defmacro property(name, type, opts \\ []) do
    quote do
      JungleSpec.define_property(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
  end

  @doc """
  Macro for defining object's `additionalProperties`. It has one required argument:

    * `type` - type have to be one of the allowed types defined in the `property` macro

  It has also one option:

    * `:nullable` - a boolean value specifying if the additional properties can be nullable.
    `false` by default
  """
  defmacro additional_properties(type, opts \\ []) do
    quote do
      Module.put_attribute(__MODULE__, :additional_properties, {unquote(type), unquote(opts)})
    end
  end

  def prepare_object_schema(module, title, properties, additional_properties, opts) do
    properties = propagate_general_opts(properties, opts)

    validate_object_opts!(properties, additional_properties, opts)

    nullable = Keyword.get(opts, :nullable, false)

    properties_schemas =
      Map.new(properties, fn {name, type, property_opts} ->
        {name, prepare_property_schema(module, title, name, type, property_opts)}
      end)

    required = required_properties_names(properties)

    schema_map =
      %{
        nullable: nullable,
        properties: properties_schemas,
        required: required,
        title: title,
        type: :object
      }
      |> maybe_add_additional_properties(additional_properties)
      |> maybe_add_opts([:description, :example], opts)
      |> maybe_add_xstruct(module, opts)
      |> maybe_extend_object(opts)

    struct(Schema, schema_map)
  end

  def prepare_type_schema(module, title, type, opts) do
    %Schema{prepare_property_schema(module, title, title, type, opts) | title: title}
  end

  defp propagate_general_opts(properties, opts) do
    general_opts = [
      inline: Keyword.get(opts, :inline, false),
      required: Keyword.get(opts, :required, true)
    ]

    Enum.map(properties, fn {name, type, property_opts} ->
      {name, type, Keyword.merge(general_opts, property_opts)}
    end)
  end

  defp validate_object_opts!(properties, additional_properties, object_opts) do
    struct? = Keyword.get(object_opts, :struct?, true)

    if struct? and not is_nil(additional_properties) do
      raise ArgumentError, "Struct cannot be defined with additional_properties"
    end

    if struct? and
         Enum.any?(properties, fn {_name, _type, property_opts} ->
           required = Keyword.get(property_opts, :required)
           nullable = Keyword.get(property_opts, :nullable, false)
           has_default = not (property_opts |> Keyword.get(:default) |> is_nil())

           not required and not nullable and not has_default
         end) do
      raise ArgumentError, "Struct cannot have not required properties which are not nullable and do not have default values"
    end
  end

  defp prepare_property_schema(module, title, name, {:array, type}, opts) do
    validate_opts!(name, {:array, type}, opts)

    items_schema = prepare_property_schema(module, title, name, type, clear_opts_for_nested_types(opts))

    nullable = Keyword.get(opts, :nullable, false)

    schema_map =
      maybe_add_opts(
        %{type: :array, items: items_schema, nullable: nullable},
        [:description, :default],
        opts
      )

    struct(Schema, schema_map)
  end

  defp prepare_property_schema(module, title, name, union_types, opts) when is_list(union_types) do
    validate_opts!(name, union_types, opts)

    items_schema =
      union_types
      |> Enum.map(&prepare_property_schema(module, title, name, &1, clear_opts_for_nested_types(opts)))
      |> Enum.uniq()

    nullable = Keyword.get(opts, :nullable, false)

    schema_map =
      maybe_add_opts(
        %{oneOf: items_schema, nullable: nullable},
        [:description, :default],
        opts
      )

    struct(Schema, schema_map)
  end

  @primitive_types [:integer, :number, :string, :boolean]
  defp prepare_property_schema(_module, _title, name, type, opts) when type in @primitive_types do
    validate_opts!(name, type, opts)

    nullable = Keyword.get(opts, :nullable, false)

    schema_map =
      maybe_add_opts(
        %{type: type, nullable: nullable},
        [:description, :default, :format, :pattern, :example, :enum],
        opts
      )

    struct(Schema, schema_map)
  end

  defp prepare_property_schema(module, title, name, property_module, opts) do
    validate_opts!(name, property_module, opts)

    Code.ensure_compiled!(property_module)

    module_schema =
      if Keyword.get(opts, :inline, false) do
        property_module
      else
        reference =
          if module == property_module do
            "#/components/schemas/" <> title
          else
            "#/components/schemas/" <> property_module.schema().title
          end

        Module.put_attribute(module, :references_to_modules, {reference, property_module})
        %OpenApiSpex.Reference{"$ref": reference}
      end

    nullable = Keyword.get(opts, :nullable, false)

    cond do
      Keyword.has_key?(opts, :default) ->
        default = Keyword.get(opts, :default)
        %Schema{oneOf: [module_schema], default: default, nullable: nullable}

      nullable ->
        %Schema{oneOf: [module_schema], nullable: nullable}

      true ->
        module_schema
    end
  end

  defp validate_opts!(name, type, opts) do
    if Keyword.has_key?(opts, :enum) do
      if type != :string do
        raise ArgumentError,
              "#{name} has an enum option, but it can be provided only for string type"
      end

      if opts |> Keyword.get(:enum) |> Enum.any?(fn item -> not is_binary(item) end) do
        raise ArgumentError,
              "#{name} has values of invalid types in the enum option. They should be binaries"
      end
    end

    if Keyword.has_key?(opts, :default) do
      if not (opts |> Keyword.get(:default) |> has_valid_type?(type)) do
        raise ArgumentError, "default value of #{name} does not match its type"
      end
    end
  end

  defp has_valid_type?(default, types_union) when is_list(types_union) do
    Enum.any?(types_union, fn expected_type -> has_valid_type?(default, expected_type) end)
  end

  defp has_valid_type?(default, expected_type) when is_integer(default) do
    expected_type in [:integer, :number]
  end

  defp has_valid_type?(default, expected_type) when is_number(default) do
    expected_type == :number
  end

  defp has_valid_type?(default, expected_type) when is_binary(default) do
    expected_type == :string
  end

  defp has_valid_type?(default, expected_type) when is_boolean(default) do
    expected_type == :boolean
  end

  defp has_valid_type?(default, {:array, expected_type}) when is_list(default) do
    Enum.all?(default, fn default_item -> has_valid_type?(default_item, expected_type) end)
  end

  defp has_valid_type?(_default, _expected_type), do: false

  defp clear_opts_for_nested_types(opts) do
    Enum.reduce([:nullable, :default, :description, :enum], opts, fn key, opts ->
      Keyword.delete(opts, key)
    end)
  end

  defp required_properties_names(properties) do
    properties
    |> Enum.filter(fn {_name, _type, opts} -> Keyword.get(opts, :required, true) end)
    |> Enum.map(fn {name, _type, _opts} -> name end)
    |> Enum.reverse()
  end

  defp maybe_add_additional_properties(schema_map, {type, opts}) do
    Map.put(schema_map, :additionalProperties, %Schema{
      type: type,
      nullable: Keyword.get(opts, :nullable, false)
    })
  end

  defp maybe_add_additional_properties(schema_map, nil) do
    schema_map
  end

  defp maybe_add_opts(schema_map, keys, opts) do
    Enum.reduce(keys, schema_map, fn key, map ->
      if Keyword.has_key?(opts, key) do
        Map.put(map, key, Keyword.get(opts, key))
      else
        map
      end
    end)
  end

  defp maybe_add_xstruct(schema, module, opts) do
    if Keyword.get(opts, :struct?, true) do
      Map.put(schema, :"x-struct", module)
    else
      schema
    end
  end

  defp maybe_extend_object(schema_map, opts) do
    if Keyword.has_key?(opts, :extends) do
      module = Keyword.get(opts, :extends)
      Code.ensure_compiled!(module)

      properties_to_add = module.schema().properties
      required_to_add = module.schema().required

      schema_map
      |> Map.update(:properties, properties_to_add, fn properties -> Map.merge(properties_to_add, properties) end)
      |> Map.update(:required, required_to_add, fn required -> required_to_add ++ required end)
    else
      schema_map
    end
  end

  defmacro maybe_define_struct(schema, opts) do
    quote do
      struct? = Keyword.get(unquote(opts), :struct?, true)

      if struct? do
        @derive Enum.filter([Poison.Encoder, Jason.Encoder], &Code.ensure_loaded?/1)

        @enforce_keys enforced_properties(unquote(schema))
        defstruct struct_definition(unquote(schema))
      end

      unquote(schema)
    end
  end

  def enforced_properties(schema) do
    schema.properties
    |> Enum.filter(fn
      {_name, %Schema{nullable: nullable}} -> not nullable
      {_name, %Schema{default: _default}} -> false
      {_name, _module} -> true
    end)
    |> Enum.map(fn {name, _property_schema} -> name end)
  end

  def struct_definition(schema) do
    Enum.map(schema.properties, fn {name, property_schema} -> {name, default_value(property_schema)} end)
  end

  defp default_value(%Schema{default: default}), do: default
  defp default_value(_), do: nil

  def define_property(module, name, type, opts) do
    if module |> Module.get_attribute(:properties) |> Keyword.has_key?(name) do
      raise ArgumentError, "the property #{inspect(name)} is already set"
    end

    Module.put_attribute(module, :properties, {name, type, opts})
  end
end
