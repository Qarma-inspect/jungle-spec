defmodule JungleSpec.OptionName do
  @moduledoc """
  Translation between the option names JungleSpec accepts and the fields of `OpenApiSpex.Schema`.

  Schema fields are camelCased, because that is how they are serialised into an OpenAPI document.
  Options are written the way Elixir names things, so the `minLength` field is given as
  `min_length` and the `x-validate` field as `x_validate`.
  """

  @doc """
  Translates a name into the spelling JungleSpec uses for options.

  `minLength` becomes `min_length` and `x-validate` becomes `x_validate`; a name that is already
  written that way is returned unchanged. Whether the resulting option is accepted for a given
  macro and type is decided elsewhere.
  """
  @spec to_option(atom()) :: atom()
  def to_option(schema_field) do
    underscored = schema_field |> Atom.to_string() |> Macro.underscore()

    underscored |> String.replace("-", "_") |> String.to_atom()
  end
end
