defmodule Mix.Tasks.Glossia.GrantAccess do
  @shortdoc "Grants dashboard access to a user by email"
  @moduledoc """
  Grants dashboard access to a user by email.

      mix glossia.grant_access user@example.com

  To revoke access instead:

      mix glossia.grant_access --revoke user@example.com
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case parse_args(args) do
      {:grant, email} ->
        case Glossia.Accounts.grant_access(email) do
          {:ok, _user} -> Mix.shell().info("Access granted to #{email}")
          {:error, :not_found} -> Mix.shell().error("No user found with email #{email}")
          {:error, changeset} -> Mix.shell().error("Failed: #{inspect(changeset.errors)}")
        end

      {:revoke, email} ->
        case Glossia.Accounts.revoke_access(email) do
          {:ok, _user} -> Mix.shell().info("Access revoked for #{email}")
          {:error, :not_found} -> Mix.shell().error("No user found with email #{email}")
          {:error, changeset} -> Mix.shell().error("Failed: #{inspect(changeset.errors)}")
        end

      :error ->
        Mix.shell().error("Usage: mix glossia.grant_access [--revoke] <email>")
    end
  end

  defp parse_args(["--revoke", email]), do: {:revoke, email}
  defp parse_args([email]) when email != "--revoke", do: {:grant, email}
  defp parse_args(_), do: :error
end
