defmodule BabelWeb.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint BabelWeb.Endpoint

      use BabelWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import BabelWeb.ConnCase
    end
  end

  setup tags do
    Babel.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
