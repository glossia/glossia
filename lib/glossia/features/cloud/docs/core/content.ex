defmodule Glossia.Features.Cloud.Docs.Core.Content do
  use Modulex

  defimplementation do
    alias Glossia.Features.Cloud.Docs.Core.Models.Page
    alias Glossia.Features.Cloud.Docs.Core.Models.Navigation.Item

    @external_resource "priv/docs/navigation.json"
    @navigation File.read!("priv/docs/navigation.json")
                |> Jason.decode!(keys: :atoms)
                |> Enum.map(&Item.new!/1)

    def all_pages() do
      []
    end

    def navigation() do
      %{}
    end
  end

  defbehaviour do
    alias Glossia.Features.Cloud.Docs.Core.Models.Page

    @callback all_pages() :: [Page.t()]
    @callback navigation() :: Navigation.t()
  end
end
