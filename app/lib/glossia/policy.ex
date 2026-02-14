defmodule Glossia.Policy do
  use LetMe.Policy

  object :user do
    action :read do
      allow(:self)
      allow(:org_member)
    end

    action :write do
      allow(:self)
    end
  end

  object :org do
    action :read do
      allow(:org_admin)
      allow(:org_member)
    end

    action :write do
      allow(:org_admin)
    end

    action :admin do
      allow(:org_admin)
    end
  end

  object :project do
    action :read do
      allow(:account_owner)
      allow(:org_admin)
      allow(:org_member)
    end

    action :write do
      allow(:account_owner)
      allow(:org_admin)
      allow(:org_member)
    end

    action :admin do
      allow(:account_owner)
      allow(:org_admin)
    end

    action :delete do
      allow(:account_owner)
      allow(:org_admin)
    end
  end

  object :translations do
    action :read do
      allow(:account_owner)
      allow(:org_admin)
      allow(:org_member)
    end

    action :write do
      allow(:account_owner)
      allow(:org_admin)
      allow(:org_member)
    end

    action :admin do
      allow(:account_owner)
      allow(:org_admin)
    end
  end

  object :glossary do
    action :read do
      allow(:account_owner)
      allow(:org_admin)
      allow(:org_member)
    end

    action :write do
      allow(:account_owner)
      allow(:org_admin)
    end

    action :admin do
      allow(:account_owner)
    end
  end
end
