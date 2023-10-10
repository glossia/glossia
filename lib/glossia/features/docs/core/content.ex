defmodule Glossia.Features.Docs.Core.Content do
  use Modulex

  defimplementation do
    alias Glossia.Features.Docs.Core.Models.Page
    alias Glossia.Features.Docs.Core.Models.Navigation.Item
    alias Glossia.Features.Docs.Core.Content.Validator

    @external_resource "priv/docs/navigation.json"
    @navigation File.read!("priv/docs/navigation.json")
                |> Jason.decode!(keys: :atoms)
                |> Enum.map(fn item ->
                  Nestru.decode_from_map!(item, Item)
                end)
    use NimblePublisher,
      build: Page,
      from: Application.app_dir(:glossia, "priv/docs/pages/**/*.md"),
      as: :pages,
      highlighters: [:makeup_elixir, :makeup_erlang]

    Validator.validate(@pages, @navigation)

    def pages() do
      @pages
    end

    def navigation() do
      @navigation
    end
  end

  defbehaviour do
    alias Glossia.Features.Docs.Core.Models.Page
    alias Glossia.Features.Docs.Core.Models.Navigation.Item

    @callback pages() :: [Page.t()]
    @callback navigation() :: [Item.t()]
  end
end
