defmodule Glossia.Admin do
  @behaviour Glossia.Authorization.Policy

  alias Glossia.Accounts.Models.User

  def authorize(:read, %User{ email: email}, _) do
    case Application.get_env(:glossia, :admin_emails) |> Enum.member?(email) do
      true -> :ok
      false -> :error
    end
  end

  def authorize(:read, nil, _), do: :error
end
