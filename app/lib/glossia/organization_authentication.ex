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
end
