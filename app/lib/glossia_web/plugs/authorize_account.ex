defmodule GlossiaWeb.Plugs.AuthorizeAccount do
  @moduledoc """
  Resolves the `:handle` path param to an account, authorizes the current API
  principal against it for a policy action, and assigns the account.

  Use it declaratively in an account-scoped API controller so action bodies can
  assume `conn.assigns.account` is present and authorized, instead of repeating
  the `get_account_by_handle` → nil-check → `ApiAuthorization.authorize` dance:

      plug GlossiaWeb.Plugs.AuthorizeAccount, :translation_write
      plug GlossiaWeb.Plugs.AuthorizeAccount, :llm_model_read when action in [:index, :show]

  On failure the conn is halted with the appropriate JSON error: 404 for an
  unknown account, 403 (with a `www-authenticate` header) for insufficient scope
  or an unauthorized principal.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias Glossia.Accounts
  alias GlossiaWeb.ApiAuthorization

  def init(action) when is_atom(action), do: action

  def call(%Plug.Conn{params: %{"handle" => handle}} = conn, action) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(error_response("account not found"))
        |> halt()

      account ->
        case ApiAuthorization.authorize(conn, action, account) do
          {:ok, conn} -> assign(conn, :account, account)
          {:error, conn} -> conn
        end
    end
  end

  def call(conn, _action) do
    conn
    |> put_status(:bad_request)
    |> json(error_response("missing account handle"))
    |> halt()
  end

  defp error_response(message) do
    %{error: %{message: message, type: "api_error", code: nil}}
  end
end
