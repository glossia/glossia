defmodule GlossiaWeb.Api.AccountApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts

  def index(conn, params) do
    user = conn.assigns[:current_user]

    case Accounts.list_user_accounts(user, params) do
      {:ok, {accounts, meta}} ->
        json(conn, %{
          accounts:
            Enum.map(accounts, fn account ->
              %{
                handle: account.handle,
                type: account.type,
                visibility: account.visibility
              }
            end),
          meta: serialize_meta(meta)
        })

      {:error, meta} ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: meta.errors})
    end
  end

  defp serialize_meta(%Flop.Meta{} = meta) do
    %{
      total_count: meta.total_count,
      total_pages: meta.total_pages,
      current_page: meta.current_page,
      page_size: meta.page_size,
      has_next_page?: meta.has_next_page?,
      has_previous_page?: meta.has_previous_page?
    }
  end
end
