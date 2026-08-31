defmodule GlossiaWeb.BabelInternalRouter do
  @moduledoc false

  use GlossiaWeb, :router

  pipeline :babel_internal_api do
    plug :accepts, ["json"]
    plug GlossiaWeb.Plugs.InternalBabelAuth
  end

  scope "/api/internal/babel", GlossiaWeb.Internal do
    pipe_through :babel_internal_api

    post "/db/query", BabelDatabaseController, :query
    post "/clickhouse/query", BabelClickHouseController, :query
    post "/temporary-access-grants", TemporaryAccessGrantController, :create
  end
end
