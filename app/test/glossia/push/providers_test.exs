defmodule Glossia.Push.ProvidersTest do
  use ExUnit.Case, async: false
  use Mimic
  alias Glossia.Push
  alias Glossia.Push.{APNs, Config, Credentials, FCM}

  setup :set_mimic_global

  setup do
    previous = Application.get_env(:glossia, Push)

    on_exit(fn ->
      if previous,
        do: Application.put_env(:glossia, Push, previous),
        else: Application.delete_env(:glossia, Push)
    end)

    {_, ec} = JOSE.JWK.generate_key({:ec, "P-256"}) |> JOSE.JWK.to_pem()
    {_, rsa} = JOSE.JWK.generate_key({:rsa, 2048}) |> JOSE.JWK.to_pem()

    env = %{
      "GLOSSIA_APNS_TEAM_ID" => "ABCDEFGHIJ",
      "GLOSSIA_APNS_KEY_ID" => "1234567890",
      "GLOSSIA_APNS_PRIVATE_KEY" => ec,
      "GLOSSIA_APNS_TOPIC" => "ai.glossia.mobile",
      "GLOSSIA_FCM_SERVICE_ACCOUNT_JSON" =>
        JSON.encode!(%{
          "type" => "service_account",
          "project_id" => "glossia-test",
          "client_email" => "push@glossia-test.iam.gserviceaccount.com",
          "private_key" => rsa
        })
    }

    config = Config.parse!(env)
    cache = :"push_credentials_#{System.unique_integer([:positive])}"
    Application.put_env(:glossia, Push, Keyword.put(config, :credentials_cache, cache))
    start_supervised!({Credentials, name: cache})
    %{env: env, config: config, rsa: rsa, ec: ec, cache: cache}
  end

  test "configuration independently disables absent providers and production APNs rejects sandbox",
       c do
    assert Config.parse!(%{}) == [apns: nil, fcm: nil]
    assert Config.available?("ios", "production")
    refute Config.available?("ios", "sandbox")
    assert Config.available?("android", "production")
    refute Config.available?("android", "sandbox")
    Application.put_env(:glossia, Push, apns: nil, fcm: c.config[:fcm])
    assert Config.capabilities() == %{"ios" => false, "android" => true}
    assert_raise ArgumentError, fn -> Config.parse!(Map.delete(c.env, "GLOSSIA_APNS_KEY_ID")) end

    assert_raise ArgumentError, fn ->
      Config.parse!(%{c.env | "GLOSSIA_APNS_PRIVATE_KEY" => "PRIVATE-BROKEN-KEY"})
    end

    assert_raise ArgumentError, fn ->
      Config.parse!(%{c.env | "GLOSSIA_APNS_PRIVATE_KEY" => c.rsa})
    end

    assert_raise ArgumentError, fn ->
      Config.parse!(%{c.env | "GLOSSIA_FCM_SERVICE_ACCOUNT_JSON" => "PRIVATE-BROKEN-JSON"})
    end
  end

  test "APNs JWTs are ES256, reused, isolated by key identity, and expire", c do
    name = :"push_credentials_#{System.unique_integer([:positive])}"
    start_supervised!({Credentials, name: name})
    config = c.config[:apns]
    assert {:ok, first} = Credentials.apns(config, name)
    assert {:ok, ^first} = Credentials.apns(config, name)
    {true, jwt, jws} = JOSE.JWT.verify_strict(JOSE.JWK.from_pem(c.ec), ["ES256"], first)
    assert jwt.fields["iss"] == "ABCDEFGHIJ"
    assert jws.fields["kid"] == "1234567890"
    assert {:ok, [key]} = Cachex.keys(name)
    assert {:ok, ttl} = Cachex.ttl(name, key)
    assert ttl > 2_900_000 and ttl <= 3_000_000
    {_, pem} = JOSE.JWK.generate_key({:ec, "P-256"}) |> JOSE.JWK.to_pem()
    assert {:ok, rotated} = Credentials.apns(%{config | private_key: pem}, name)
    refute rotated == first
    assert {:ok, true} = Cachex.expire(name, key, 1)
    Process.sleep(10)
    assert {:ok, nil} = Cachex.get(name, key)
  end

  test "APNs classifies only definitive token errors as invalid, never credentials or malformed payloads",
       c do
    installation = %{environment: "production", token: String.duplicate("ab", 32)}

    for {status, body, expected} <- [
          {400, %{"reason" => "BadDeviceToken"}, {:invalid_token, []}},
          {400, %{"reason" => "BadTopic"}, {:error, :provider_rejected}},
          {403, %{"reason" => "InvalidProviderToken"}, {:error, :provider_rejected}},
          {413, %{}, {:error, :provider_rejected}},
          {503, %{}, {:retry, nil}}
        ] do
      stub(Req, :post, fn _, _ -> {:ok, %Req.Response{status: status, body: body}} end)
      assert APNs.deliver(installation, %{}, opts()) == expected
    end

    assert {:ok, _} = Credentials.apns(c.config[:apns], c.cache)

    stub(Req, :post, fn _, _ ->
      {:ok, %Req.Response{status: 410, body: %{"timestamp" => 1_700_000_000_000}}}
    end)

    assert {:invalid_token, [unregistered_at: at]} = APNs.deliver(installation, %{}, opts())
    assert DateTime.to_unix(at) == 1_700_000_000
  end

  test "FCM uses RS256 service account OAuth, data-only HTTPv1 and bounded credential reuse", c do
    expect(Req, :post, fn "https://oauth2.googleapis.com/token", options ->
      assert options[:retry] == false and options[:redirect] == false

      {true, jwt, _} =
        JOSE.JWT.verify_strict(JOSE.JWK.from_pem(c.rsa), ["RS256"], options[:form][:assertion])

      assert jwt.fields["aud"] == "https://oauth2.googleapis.com/token"
      assert jwt.fields["scope"] == "https://www.googleapis.com/auth/firebase.messaging"

      {:ok,
       %Req.Response{
         status: 200,
         body: %{"access_token" => "provider-token", "expires_in" => 3600}
       }}
    end)

    assert {:ok, "provider-token"} = Credentials.fcm(c.config[:fcm], c.cache)
    assert {:ok, "provider-token"} = Credentials.fcm(c.config[:fcm], c.cache)

    expect(Req, :post, fn "https://fcm.googleapis.com/v1/projects/glossia-test/messages:send",
                          options ->
      assert options[:auth] == {:bearer, "provider-token"}
      assert options[:finch] == Glossia.Finch
      message = options[:json]["message"]
      assert message["data"] == %{"v" => "1"}
      refute Map.has_key?(message, "notification")
      assert message["android"]["priority"] == "HIGH"
      assert message["android"]["ttl"] in ["598s", "599s", "600s"]
      {:ok, %Req.Response{status: 200}}
    end)

    assert :ok = FCM.deliver(%{token: "device-token"}, %{"v" => "1"}, opts())
  end

  test "FCM payload errors do not retire devices; token-specific errors do", c do
    stub(Req, :post, fn "https://oauth2.googleapis.com/token", _ ->
      {:ok,
       %Req.Response{
         status: 200,
         body: %{"access_token" => "provider-token", "expires_in" => 3600}
       }}
    end)

    Credentials.fcm(c.config[:fcm], c.cache)

    for {code, field, expected} <- [
          {"INVALID_ARGUMENT", "message.data", {:error, :provider_rejected}},
          {"INVALID_ARGUMENT", "message.token", {:invalid_token, []}},
          {"UNREGISTERED", nil, {:invalid_token, []}},
          {"SENDER_ID_MISMATCH", nil, {:invalid_token, []}}
        ] do
      details = [
        %{"@type" => "type.googleapis.com/google.firebase.fcm.v1.FcmError", "errorCode" => code},
        %{
          "@type" => "type.googleapis.com/google.rpc.BadRequest",
          "fieldViolations" => [%{"field" => field}]
        }
      ]

      stub(Req, :post, fn _, _ ->
        {:ok, %Req.Response{status: 400, body: %{"error" => %{"details" => details}}}}
      end)

      assert FCM.deliver(%{token: "device-token"}, %{}, opts()) == expected
    end
  end

  defp opts do
    [
      expires_at: DateTime.add(DateTime.utc_now(), 600),
      notification_id: Ecto.UUID.generate(),
      authorized?: fn -> true end
    ]
  end
end
