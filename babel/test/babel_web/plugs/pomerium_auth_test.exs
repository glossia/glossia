defmodule BabelWeb.Plugs.PomeriumAuthTest do
  use BabelWeb.ConnCase, async: true

  alias Babel.Pomerium.JWKSCache
  alias BabelWeb.Plugs.PomeriumAuth

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

  test "provisions and assigns an account from a verified Pomerium assertion", %{
    conn: conn,
    private_key: private_key,
    cache: cache,
    jwks: jwks
  } do
    conn =
      conn
      |> init_test_session(%{})
      |> put_req_header(
        "x-pomerium-jwt-assertion",
        assertion(private_key, %{
          "email" => "operator@glossia.ai",
          "name" => "Glossia operator",
          "sub" => "google/operator"
        })
      )
      |> PomeriumAuth.call(authentication_options(jwks, cache))

    assert conn.assigns.current_account.email == "operator@glossia.ai"
    assert conn.assigns.current_account.pomerium_id == "google/operator"
    assert get_session(conn, :current_account_id) == conn.assigns.current_account.id
  end

  test "rejects requests without a Pomerium assertion", %{conn: conn, cache: cache, jwks: jwks} do
    conn = PomeriumAuth.call(conn, authentication_options(jwks, cache))

    assert conn.halted
    assert conn.status == 401
  end

  test "rejects an assertion that Pomerium did not sign", %{
    conn: conn,
    cache: cache,
    jwks: jwks
  } do
    forged_assertion =
      JOSE.JWK.generate_key({:ec, :secp256r1})
      |> assertion(%{"email" => "operator@glossia.ai", "sub" => "google/operator"})

    conn =
      conn
      |> put_req_header("x-pomerium-jwt-assertion", forged_assertion)
      |> PomeriumAuth.call(authentication_options(jwks, cache))

    assert conn.halted
    assert conn.status == 401
  end

  test "rejects a verified assertion for another route", %{
    conn: conn,
    private_key: private_key,
    cache: cache,
    jwks: jwks
  } do
    conn =
      conn
      |> put_req_header(
        "x-pomerium-jwt-assertion",
        assertion(private_key, %{
          "aud" => "another.glossia.ai",
          "email" => "operator@glossia.ai",
          "sub" => "google/operator"
        })
      )
      |> PomeriumAuth.call(authentication_options(jwks, cache))

    assert conn.halted
    assert conn.status == 401
  end

  test "rejects an expired assertion", %{
    conn: conn,
    private_key: private_key,
    cache: cache,
    jwks: jwks
  } do
    conn =
      conn
      |> put_req_header(
        "x-pomerium-jwt-assertion",
        assertion(private_key, %{
          "email" => "operator@glossia.ai",
          "exp" => System.system_time(:second) - 60,
          "sub" => "google/operator"
        })
      )
      |> PomeriumAuth.call(authentication_options(jwks, cache))

    assert conn.halted
    assert conn.status == 401
  end

  test "rejects an assertion from another email domain", %{
    conn: conn,
    private_key: private_key,
    cache: cache,
    jwks: jwks
  } do
    conn =
      conn
      |> put_req_header(
        "x-pomerium-jwt-assertion",
        assertion(private_key, %{"email" => "operator@example.com", "sub" => "google/operator"})
      )
      |> PomeriumAuth.call(authentication_options(jwks, cache))

    assert conn.halted
    assert conn.status == 401
  end

  defp authentication_options(jwks, cache) do
    [
      enabled: true,
      email_domain: "glossia.ai",
      expected_issuer: "babel.glossia.ai",
      expected_audience: "babel.glossia.ai",
      jwks_cache: cache,
      jwks_fetcher: fn -> {:ok, jwks} end
    ]
  end

  defp assertion(private_key, overrides) do
    now = System.system_time(:second)

    claims =
      Map.merge(
        %{
          "aud" => "babel.glossia.ai",
          "exp" => now + 300,
          "iat" => now,
          "iss" => "babel.glossia.ai"
        },
        overrides
      )

    private_key
    |> JOSE.JWT.sign(%{"alg" => "ES256", "kid" => @key_id}, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end
end
