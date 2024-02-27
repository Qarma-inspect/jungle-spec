defmodule IDJungle do
  use JungleSpec

  open_api_type "IDJungle", :string,
    nullable: true,
    format: :uuid,
    pattern: ~r/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/,
    example: "193202fc-ab55-4824-8ec8-5bef1201d9eb",
    struct?: false
end
