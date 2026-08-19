# Changelog

## 0.2.0

**Breaking.** Options given to `open_api_object/3`, `open_api_type/3`, `property/3` and
`additional_properties/2` are now validated while the schema is compiled. Keys that were
previously accepted and silently discarded now raise an `ArgumentError`.

* The set of accepted options is derived from `OpenApiSpex.Schema` instead of a hardcoded list, so
  the schema fields JungleSpec does not set itself now reach the generated schema. That includes
  the validation keywords (`minimum`, `maximum`, `minLength`, `minItems`, `uniqueItems` and the
  rest) and the documentation keywords (`deprecated`, `readOnly`, `writeOnly`, `externalDocs`).
  Module-typed properties are the exception: a bare `$ref` has nowhere to put them, so only
  `:nullable` and `:inline` take effect there.
* Unknown options raise, with a suggestion of the closest supported option.
* Options that JungleSpec sets itself (`type`, `items`, `oneOf`, `title` and friends) raise
  instead of being ignored.
* Options are rejected for types they do not apply to, for example `minimum` on a `:string`, or
  `format` on a union.
* Options describing a single value now apply to the items of a collection. `{:array, type}` and
  `{:map, type}` accept whatever `type` accepts and hand it to the item schema, so
  `property :ids, {:array, :string}, format: :uuid, minItems: 1` puts `minItems` on the array and
  `format` on its items. Every other option describes the schema it is given for: previously keys
  such as `example` ended up on the item schema instead of the container.
* Object level options are validated the same way property level ones are. An `enum` raises,
  since it needs a `:string` type, and a `default` has to be a map.

Unrelated to the above, and not breaking:

* `open_api_type/2`, `property/2` and `additional_properties/1` are now imported by `use
  JungleSpec`. `open_api_type "Title", :string` previously failed with `undefined function
  open_api_type/2` and needed an explicit empty option list; the other two were reachable only
  inside an `open_api_object` block, which imports the module unrestricted.

## 0.1.1

* Update `open_api_spex` dependency to `~> 3.21`.
* Object properties of type `:string` with `format` `:binary` are now treated as `Plug.Upload:t()` in their Elixir types.
