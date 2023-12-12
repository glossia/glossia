defmodule Glossia.Projects.ProjectToken do
  use Joken.Config, default_signer: :project

  def token_config do
    %{}

    # issued at time, 60 seconds in the past to allow for clock drift
    |> add_claim("iat", fn -> (DateTime.utc_now() |> DateTime.to_unix()) - 60 end)

    # JWT expiration time (10 minute maximum)
    |> add_claim("exp", fn -> (DateTime.utc_now() |> DateTime.to_unix()) + 3 * 60 end)

    # GitHub App's identifier
    |> add_claim("iss", fn -> "glossia" end)
  end

  @doc """
  Given a project it generates a token to authenticate requests to the API.
  """
  @spec generate_token_for_project_with_id(String.t()) ::
          {:ok, Joken.bearer_token(), Joken.claims()} | {:error, Joken.error_reason()}
  def generate_token_for_project_with_id(id) do
    __MODULE__.generate_and_sign(%{"project_id" => id})
  end

  @spec get_project_id_from_token(String.t()) ::
          {:ok, number()} | {:error, Joken.error_reason()}
  def get_project_id_from_token(token) do
    case __MODULE__.verify_and_validate(token) do
      {:ok, %{"project_id" => project_id}} ->
        {:ok, project_id}

      {:error, error} ->
        {:error, error}
    end
  end
end
