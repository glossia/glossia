defmodule GlossiaWeb.SignupProtectionTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Glossia.Cloudflare.Turnstile
  alias GlossiaWeb.RateLimit.Registration
  alias GlossiaWeb.SignupProtection

  describe "verify/3 when Turnstile is off" do
    test "short-circuits to :ok without hitting rate limit or verify" do
      stub(Turnstile, :required?, fn -> false end)
      stub(Registration, :hit, fn _ -> flunk("Registration.hit should not be called") end)
      stub(Turnstile, :verify, fn _, _ -> flunk("Turnstile.verify should not be called") end)

      assert :ok = SignupProtection.verify("csrf", %{}, "signup")
    end
  end

  describe "verify/3 when Turnstile is on" do
    setup do
      stub(Turnstile, :required?, fn -> true end)
      :ok
    end

    test "returns :missing_session when csrf token is nil" do
      stub(Turnstile, :verify, fn _, _ -> flunk("Turnstile.verify should not be called") end)

      assert {:error, :missing_session} = SignupProtection.verify(nil, %{}, "signup")
    end

    test "rate limits before hitting Turnstile" do
      stub(Registration, :hit, fn _ -> {:deny, 5_000} end)
      stub(Turnstile, :verify, fn _, _ -> flunk("Turnstile.verify should not be called") end)

      assert {:error, :rate_limited} = SignupProtection.verify("csrf", %{}, "signup")
    end

    test "passes the expected_action option through to Turnstile.verify/2" do
      stub(Registration, :hit, fn "csrf" -> {:allow, 1} end)

      expect(Turnstile, :verify, fn "the-token", opts ->
        assert Keyword.get(opts, :expected_action) == "signup"
        :ok
      end)

      assert :ok =
               SignupProtection.verify(
                 "csrf",
                 %{"cf-turnstile-response" => "the-token"},
                 "signup"
               )
    end

    test "maps any Turnstile error to :turnstile_failed" do
      stub(Registration, :hit, fn _ -> {:allow, 1} end)
      stub(Turnstile, :verify, fn _, _ -> {:error, :rejected} end)

      assert {:error, :turnstile_failed} = SignupProtection.verify("csrf", %{}, "signup")
    end
  end
end
