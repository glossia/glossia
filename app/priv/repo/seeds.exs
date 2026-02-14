# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Glossia.Repo.insert!(%Glossia.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Glossia.Repo
alias Glossia.Accounts.{Account, User, Identity}

# Dev user for local development login
unless Repo.get_by(User, email: "dev@glossia.ai") do
  account =
    Repo.insert!(%Account{
      handle: "dev"
    })

  user =
    Repo.insert!(%User{
      email: "dev@glossia.ai",
      name: "Dev User",
      account_id: account.id
    })

  Repo.insert!(%Identity{
    provider: "dev",
    provider_uid: "dev-001",
    user_id: user.id
  })
end
