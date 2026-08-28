defmodule BabelWeb.Router do
  use BabelWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BabelWeb.Layouts, :root}
    plug :put_layout, html: {BabelWeb.Layouts, :app}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :operations do
    plug BabelWeb.Plugs.PomeriumAuth
  end

  get "/up", BabelWeb.HealthController, :index

  scope "/", BabelWeb do
    pipe_through [:browser, :operations]

    live "/", OperationsLive, :overview
    live "/customers", OperationsLive, :customers
    live "/work-items", OperationsLive, :work_items
    live "/finance", OperationsLive, :finance
  end

  if Application.compile_env(:babel, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BabelWeb.Telemetry
    end
  end
end
