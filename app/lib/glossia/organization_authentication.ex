defmodule Glossia.OrganizationAuthentication do
  @moduledoc "Optional organization sign-in; ordinary OAuth sign-in remains available in Community."

  def for_email(email) do
    case Glossia.Extensions.organization_authentication() do
      nil -> nil
      authentication -> authentication.for_email(email)
    end
  end

  def sign_in(organization, response, opts \\ []) do
    case Glossia.Extensions.organization_authentication() do
      nil -> {:error, :enterprise_required}
      authentication -> authentication.sign_in(organization, response, opts)
    end
  end

  def session_proof(organization, user) do
    case Glossia.Extensions.organization_authentication() do
      nil -> nil
      authentication -> authentication.session_proof(organization, user)
    end
  end

  def session_authorized?(account, user, proof) do
    case Glossia.Extensions.organization_authentication() do
      nil -> true
      authentication -> authentication.session_authorized?(account, user, proof)
    end
  end

  def mfa_required?(account, user) do
    case Glossia.Extensions.organization_authentication() do
      nil -> false
      authentication -> authentication.mfa_required?(account, user)
    end
  end

  def check_session(conn) do
    case Glossia.Extensions.organization_authentication() do
      nil -> conn
      authentication -> authentication.check_session(conn)
    end
  end

  def check_session(conn, account) do
    case Glossia.Extensions.organization_authentication() do
      nil -> conn
      authentication -> authentication.check_session(conn, account)
    end
  end
end
