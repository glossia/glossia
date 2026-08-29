defmodule Glossia.BabelWorkloadIdentityTest do
  use ExUnit.Case, async: true

  alias Glossia.BabelWorkloadIdentity

  setup do
    signer = JOSE.JWK.generate_key({:rsa, 2048})

    policy = %{
      audience: "glossia-internal",
      issuer: "https://kubernetes.default.svc.cluster.local",
      jwks: Jason.encode!(jwks(signer)),
      max_token_lifetime_seconds: 3_600,
      namespace: "babel",
      service_account_name: "babel"
    }

    %{policy: policy, signer: signer}
  end

  test "verifies Babel's projected service-account token", %{policy: policy, signer: signer} do
    assert {:ok, %{namespace: "babel", name: "babel", uid: "babel-uid"}} =
             BabelWorkloadIdentity.verify(token(%{}, signer), policy)
  end

  test "rejects a token for another audience", %{policy: policy, signer: signer} do
    token = token(%{"aud" => ["other"]}, signer)

    assert {:error, :bad_audience} = BabelWorkloadIdentity.verify(token, policy)
  end

  test "rejects a token for another service account", %{policy: policy, signer: signer} do
    token =
      token(
        %{
          "sub" => "system:serviceaccount:other:babel",
          "kubernetes.io" => %{
            "namespace" => "other",
            "serviceaccount" => %{"name" => "babel", "uid" => "babel-uid"}
          }
        },
        signer
      )

    assert {:error, :wrong_principal} = BabelWorkloadIdentity.verify(token, policy)
  end

  test "rejects a token signed by another key", %{policy: policy} do
    token = token(%{}, JOSE.JWK.generate_key({:rsa, 2048}))

    assert {:error, :invalid_signature} = BabelWorkloadIdentity.verify(token, policy)
  end

  test "fails closed when the JSON Web Key Set is unavailable", %{policy: policy} do
    assert {:error, :not_configured} =
             BabelWorkloadIdentity.verify("token", %{policy | jwks: nil})
  end

  defp token(claims, signer) do
    now = DateTime.to_unix(DateTime.utc_now())

    base_claims = %{
      "iss" => "https://kubernetes.default.svc.cluster.local",
      "aud" => ["glossia-internal"],
      "exp" => now + 3_600,
      "iat" => now,
      "nbf" => now - 60,
      "sub" => "system:serviceaccount:babel:babel",
      "kubernetes.io" => %{
        "namespace" => "babel",
        "serviceaccount" => %{"name" => "babel", "uid" => "babel-uid"}
      }
    }

    jwt = JOSE.JWT.from_map(Map.merge(base_claims, claims))

    {_, token} =
      signer
      |> JOSE.JWT.sign(%{"alg" => "RS256", "kid" => "babel-key"}, jwt)
      |> JOSE.JWS.compact()

    token
  end

  defp jwks(signer) do
    {_, public_jwk} = signer |> JOSE.JWK.to_public() |> JOSE.JWK.to_map()
    %{"keys" => [Map.put(public_jwk, "kid", "babel-key")]}
  end
end
