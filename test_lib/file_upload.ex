defmodule FileUpload do
  use JungleSpec

  open_api_object "FileUpload" do
    property :file, :string, format: :binary
    property :metadata, {:map, :string}
  end
end
