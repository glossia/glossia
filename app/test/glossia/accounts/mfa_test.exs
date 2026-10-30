defmodule Glossia.Accounts.MFATest do
  use Glossia.DataCase, async: true
  alias Glossia.Accounts.{BrowserSession, MFA}
  alias Glossia.TestHelpers

  setup do
    user = TestHelpers.create_user("mfa@example.test", "mfa")
    {"session", token} = MFA.sign_in(user, "organization-proof")
    %{user: user, token: token}
  end

  test "enrollment is browser-bound, preserves retries, and revokes old sessions", %{
    user: user,
    token: token
  } do
    {"session", peer} = MFA.sign_in(user)
    assert {:error, :reauthenticate} = MFA.begin_enrollment(user, nil)
    assert {:ok, factor} = MFA.begin_enrollment(user, token)
    assert {:error, :reauthenticate} = MFA.confirm(user, peer, "123456")
    assert {:error, :invalid_code} = MFA.confirm(user, token, "bad")
    assert {:ok, retry} = MFA.begin_enrollment(user, token)
    assert retry.secret == factor.secret

    assert {:ok, codes, verified} =
             MFA.confirm(user, token, NimbleTOTP.verification_code(factor.secret))

    assert length(Enum.uniq(codes)) == 10
    assert MFA.enabled?(user)
    assert MFA.authorized?(user, verified)
    refute MFA.authorized?(user, token)
    refute MFA.authorized?(user, peer)
    refute MFA.authorized?(user, nil)
    assert MFA.organization_proof(verified) == "organization-proof"
    assert {:error, :already_enabled} = MFA.begin_enrollment(user, verified)
    MFA.cancel(user, verified)
    assert MFA.enabled?(user)
  end

  test "login consumes recovery and challenges once and preserves SSO proof", %{
    user: user,
    token: token
  } do
    {:ok, factor} = MFA.begin_enrollment(user, token)
    code = NimbleTOTP.verification_code(factor.secret)
    {:ok, [recovery | _], _} = MFA.confirm(user, token, code)
    {"challenge", challenge} = MFA.sign_in(user, "issuer-bound-proof")
    refute MFA.authorized?(user, challenge)
    assert {:error, :invalid_code} = MFA.complete(challenge, code)
    assert {:ok, signed_in, verified} = MFA.complete(challenge, recovery, true)
    assert signed_in.id == user.id
    assert MFA.authorized?(user, verified)
    assert MFA.organization_proof(verified) == "issuer-bound-proof"
    assert {:error, :expired} = MFA.complete(challenge, recovery, true)
    {"challenge", another} = MFA.sign_in(user)
    assert {:error, :invalid_code} = MFA.complete(another, recovery, true)
    MFA.revoke(verified)
    refute MFA.authorized?(user, verified)
  end

  test "the attempt budget spans new challenges and recovers only after its window", %{
    user: user,
    token: token
  } do
    {:ok, factor} = MFA.begin_enrollment(user, token)

    {:ok, [recovery | _], _} =
      MFA.confirm(user, token, NimbleTOTP.verification_code(factor.secret))

    for _ <- 1..5 do
      {"challenge", challenge} = MFA.sign_in(user)
      assert {:error, :invalid_code} = MFA.complete(challenge, "wrong", true)
    end

    {"challenge", challenge} = MFA.sign_in(user)
    assert {:error, :rate_limited} = MFA.complete(challenge, recovery, true)

    Repo.get!(MFA, user.id)
    |> Ecto.Changeset.change(attempt_window_started_at: DateTime.add(DateTime.utc_now(), -301))
    |> Repo.update!()

    assert {:ok, _, _} = MFA.complete(challenge, recovery, true)
  end

  test "management requires recent login and regeneration replaces recovery and sessions", %{
    user: user,
    token: token
  } do
    {:ok, factor} = MFA.begin_enrollment(user, token)

    {:ok, [first, second | _], verified} =
      MFA.confirm(user, token, NimbleTOTP.verification_code(factor.secret))

    hash = :crypto.hash(:sha256, verified)
    session = Repo.get!(BrowserSession, hash)

    session
    |> Ecto.Changeset.change(authenticated_at: DateTime.add(DateTime.utc_now(), -301))
    |> Repo.update!()

    assert {:error, :reauthenticate} = MFA.manage(user, verified, first, true, :disable)
    {"challenge", challenge} = MFA.sign_in(user)
    {:ok, _, fresh} = MFA.complete(challenge, first, true)
    assert {:ok, [new_code | _], rotated} = MFA.manage(user, fresh, second, true, :regenerate)
    refute MFA.authorized?(user, fresh)
    assert MFA.authorized?(user, rotated)
    assert {:error, :invalid_code} = MFA.manage(user, rotated, second, true, :disable)
    assert {:ok, [], after_disable} = MFA.manage(user, rotated, new_code, true, :disable)
    refute MFA.enabled?(user)
    assert MFA.authorized?(user, after_disable)
    refute MFA.authorized?(user, nil)
    refute MFA.authorized?(user, rotated)
  end

  test "expired enrollment and challenges do not issue credentials", %{user: user, token: token} do
    {:ok, factor} = MFA.begin_enrollment(user, token)

    factor
    |> Ecto.Changeset.change(enrollment_expires_at: DateTime.add(DateTime.utc_now(), -1))
    |> Repo.update!()

    assert {:error, :reauthenticate} =
             MFA.confirm(user, token, NimbleTOTP.verification_code(factor.secret))

    {:ok, fresh} = MFA.begin_enrollment(user, token)
    refute fresh.secret == factor.secret

    {:ok, [recovery | _], _} =
      MFA.confirm(user, token, NimbleTOTP.verification_code(fresh.secret))

    {"challenge", challenge} = MFA.sign_in(user)

    Repo.get!(BrowserSession, :crypto.hash(:sha256, challenge))
    |> Ecto.Changeset.change(expires_at: DateTime.add(DateTime.utc_now(), -1))
    |> Repo.update!()

    assert {:error, :expired} = MFA.complete(challenge, recovery, true)
  end
end
