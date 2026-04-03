defmodule Glossia.TestHelpers do
  @moduledoc false

  import ExUnit.Assertions
  import Plug.Conn, only: [put_req_header: 3]

  alias Glossia.Accounts.{Account, User}
  alias Glossia.Repo

  def create_user(email, handle_prefix, opts \\ []) do
    has_access = Keyword.get(opts, :has_access, true)

    {:ok, account} =
      %Account{}
      |> Account.changeset(%{
        handle: "#{handle_prefix}-#{System.unique_integer([:positive])}",
        type: "user",
        has_access: has_access
      })
      |> Repo.insert()

    {:ok, user} =
      %User{account_id: account.id}
      |> User.changeset(%{email: email, has_access: has_access})
      |> Repo.insert()

    %{user | account: account}
  end

  def authenticate(conn, user, scopes) when is_list(scopes) do
    # Use Boruta's client changeset to properly create a client with required keys.
    {:ok, client} =
      Boruta.Ecto.Client.create_changeset(%Boruta.Ecto.Client{}, %{
        name: "test-client-#{System.unique_integer([:positive])}",
        redirect_uris: ["http://localhost"],
        access_token_ttl: 3600,
        authorization_code_ttl: 60
      })
      |> Repo.insert()

    # Use Boruta's token changeset to create a valid access token.
    {:ok, token} =
      Boruta.Ecto.Token.changeset(%Boruta.Ecto.Token{}, %{
        client_id: client.id,
        sub: to_string(user.id),
        scope: Enum.join(scopes, " "),
        access_token_ttl: 3600
      })
      |> Repo.insert()

    conn
    |> put_req_header("authorization", "Bearer #{token.value}")
    |> put_req_header("content-type", "application/json")
  end

  def expect_event(expected_name, fun, opts \\ []) when is_function(fun, 0) do
    expected = Map.new(opts)

    Mimic.stub(Glossia.Extensions, :event_handler, fn -> Glossia.TestEventHandler end)

    test_pid = self()

    Mimic.expect(Glossia.TestEventHandler, :handle_event, fn event ->
      send(test_pid, {:glossia_event, event})
      :ok
    end)

    result = fun.()

    assert_receive {:glossia_event, event}
    assert event.name == expected_name

    Enum.each(expected, fn {key, value} ->
      actual = event_field(event, key)

      case value do
        fun when is_function(fun, 1) -> assert fun.(actual)
        _ -> assert actual == value
      end
    end)

    result
  end

  defp event_field(event, :account_id), do: event.account.id
  defp event_field(event, :user_id), do: event.user && event.user.id
  defp event_field(event, {:opt, key}), do: event.opts[key]
  defp event_field(event, key), do: Map.fetch!(event, key)
end
