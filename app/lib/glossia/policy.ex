defmodule Glossia.Policy do
  use LetMe.Policy

  object :user do
    action :read do
      allow(:self)
      allow(:organization_member)
    end

    action :write do
      allow(:self)
    end
  end

  object :account do
    action :read do
      allow([:authenticated, :collection])
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
      allow(:public_account)
    end
  end

  object :organization do
    action :read do
      allow([:authenticated, :collection])
      allow(:organization_admin)
      allow(:organization_member)
    end

    action :write do
      deny(:no_access)
      allow([:authenticated, :collection])
      allow(:organization_admin)
    end

    action :delete do
      deny(:no_access)
      allow(:organization_admin)
    end

    action :admin do
      deny(:no_access)
      allow(:organization_admin)
    end
  end

  object :project do
    action :read do
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
      allow(:public_account)
    end

    action :write do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
    end

    action :admin do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
    end

    action :delete do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
    end
  end

  object :voice do
    action :read do
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
      allow(:public_account)
    end

    action :write do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
    end

    action :admin do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
    end
  end

  object :members do
    action :read do
      allow(:organization_admin)
      allow(:organization_member)
    end

    action :write do
      deny(:no_access)
      allow(:organization_admin)
    end
  end

  object :glossary do
    action :read do
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
    end

    action :write do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
    end

    action :admin do
      deny(:no_access)
      allow(:account_owner)
    end
  end
end
