defmodule Glossia.Events.Token do
  use Joken.Config, default_signer: :event

  # alias Glossia.Events.Event

  # def token_config do
  #   %{}

  #   # issued at time, 60 seconds in the past to allow for clock drift
  #   |> add_claim("iat", fn -> (DateTime.utc_now() |> DateTime.to_unix()) - 60 end)

  #   # JWT expiration time (10 minute maximum)
  #   |> add_claim("exp", fn -> (DateTime.utc_now() |> DateTime.to_unix()) + 10 * 60 end)

  #   # GitHub App's identifier
  #   |> add_claim("iss", fn -> "glossia_builder" end)
  # end

  # @doc """
  # Given a build it generates a token to authenticate requests to the API.
  # """
  # @spec generate_and_sign(Build.t()) ::
  #         {:ok, Joken.bearer_token(), Joken.claims()} | {:error, Joken.error_reason()}
  # def generate_token(%Build{id: id}) do
  #   Glossia.Builds.Token.generate_and_sign(%{"build_id" => id})
  # end

  # @spec get_build_id_from_token(String.t()) ::
  #         {:ok, number()} | {:error, Joken.error_reason()}
  # def get_build_id_from_token(token) do
  #   case Glossia.Builds.Token.verify_and_validate(token) do
  #     {:ok, %{"build_id" => build_id}} ->
  #       {:ok, build_id}

  #     {:error, error} ->
  #       {:error, error}
  #   end
  # end
end
