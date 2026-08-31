defmodule Glossia.PomeriumTest do
  use ExUnit.Case, async: true

  alias Glossia.Pomerium
  alias Glossia.Pomerium.JWKSCache

  @key_id "pomerium-test-key"

  setup do
    private_key = JOSE.JWK.generate_key({:ec, :secp256r1})
    {_, public_key} = private_key |> JOSE.JWK.to_public() |> JOSE.JWK.to_map()

    cache = :"pomerium_jwks_#{System.unique_integer([:positive])}"
    start_supervised!({JWKSCache, name: cache})

    {:ok,
     private_key: private_key,
     cache: cache,
     jwks: %{"keys" => [Map.put(public_key, "kid", @key_id)]}}
  end

  test "accepts a signed assertion for the temporary-access host", %{
    private_key: private_key,
    cache: cache,
    jwks: jwks
  } do
    assert {:ok, identity} =
             Pomerium.identity_from_assertion(
               assertion(private_key, %{
                 "email" => "operator@glossia.ai",
                 "name" => "Glossia operator",
                 "sub" => "google/operator"
               }),
               options(jwks, cache)
             )

    assert identity == %{
             email: "operator@glossia.ai",
             name: "Glossia operator",
             subject: "google/operator"
           }
  end

  test "rejects an assertion that is not signed by Pomerium", %{cache: cache, jwks: jwks} do
    forged_assertion =
      JOSE.JWK.generate_key({:ec, :secp256r1})
      |> assertion(%{"email" => "operator@glossia.ai", "sub" => "google/operator"})

    assert {:error, :invalid_assertion} =
             Pomerium.identity_from_assertion(forged_assertion, options(jwks, cache))
  end

  test "rejects an assertion for another host", %{
    private_key: private_key,
    cache: cache,
    jwks: jwks
  } do
    assert {:error, :invalid_assertion} =
             Pomerium.identity_from_assertion(
               assertion(private_key, %{
                 "aud" => "another.glossia.ai",
                 "email" => "operator@glossia.ai",
                 "sub" => "google/operator"
               }),
               options(jwks, cache)
             )
  end

  test "rejects an expired assertion", %{private_key: private_key, cache: cache, jwks: jwks} do
    assert {:error, :invalid_assertion} =
             Pomerium.identity_from_assertion(
               assertion(private_key, %{
                 "email" => "operator@glossia.ai",
                 "exp" => System.system_time(:second) - 60,
                 "sub" => "google/operator"
               }),
               options(jwks, cache)
             )
  end

  defp options(jwks, cache) do
    [
      enabled: true,
      email_domain: "glossia.ai",
      expected_issuer: "access.glossia.ai",
      expected_audience: "access.glossia.ai",
      jwks_cache: cache,
      jwks_fetcher: fn -> {:ok, jwks} end
    ]
  end

  defp assertion(private_key, overrides) do
    now = System.system_time(:second)

    claims =
      Map.merge(
        %{
          "aud" => "access.glossia.ai",
          "exp" => now + 300,
          "iat" => now,
          "iss" => "access.glossia.ai"
        },
        overrides
      )

    private_key
    |> JOSE.JWT.sign(%{"alg" => "ES256", "kid" => @key_id}, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end
end
