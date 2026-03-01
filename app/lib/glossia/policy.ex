defmodule Glossia.Policy do
  use LetMe.Policy

  object :admin do
    action :read do
      allow(:super_admin)
    end

    action :write do
      allow(:super_admin)
    end
  end

  object :user do
    action :read do
      allow(:super_admin)
      allow(:self)
      allow(:organization_member)
    end

    action :write do
      allow(:self)
    end
  end

  object :account do
    action :read do
      allow(:super_admin)
      allow([:authenticated, :collection])
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
      allow(:public_account)
    end
  end

  object :organization do
    action :read do
      allow(:super_admin)
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
      allow(:super_admin)
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
      allow(:public_account)
    end

    action :write do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
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
      allow(:super_admin)
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
      allow(:public_account)
    end

    action :write do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
    end

    action :admin do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
    end
  end

  object :members do
    action :read do
      allow(:super_admin)
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
      allow(:super_admin)
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

  object :discussion do
    action :read do
      allow(:super_admin)
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
      allow(:public_account)
    end

    action :write do
      allow(:super_admin)
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
      allow([:authenticated, :public_account])
    end

    action :admin do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
    end
  end

  object :ticket do
    action :read do
      allow(:super_admin)
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
      allow(:public_account)
    end

    action :write do
      allow(:super_admin)
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
      allow([:authenticated, :public_account])
    end

    action :admin do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
      allow(:organization_member)
    end
  end

  object :api_credentials do
    action :read do
      allow(:super_admin)
      allow(:account_owner)
      allow(:organization_admin)
    end

    action :write do
      deny(:no_access)
      allow(:account_owner)
      allow(:organization_admin)
    end
  end
end
