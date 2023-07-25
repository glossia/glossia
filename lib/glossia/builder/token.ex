defmodule Glossia.Builder.Token do
  use Joken.Config, default_signer: :builder

  def token_config do
    %{}

    # issued at time, 60 seconds in the past to allow for clock drift
    |> add_claim("iat", fn -> (DateTime.utc_now() |> DateTime.to_unix()) - 60 end)

    # JWT expiration time (10 minute maximum)
    |> add_claim("exp", fn -> (DateTime.utc_now() |> DateTime.to_unix()) + 10 * 60 end)

    # GitHub App's identifier
    |> add_claim("iss", fn -> "glossia" end)
  end
end
