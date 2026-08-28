alias Babel.Accounts.Account
alias Babel.Operations.WorkItem
alias Babel.Repo

today = Date.utc_today()
now = DateTime.utc_now(:second)

accounts = [
  %{email: "marek@glossia.ai", name: "Marek", pomerium_id: "google/marek", last_seen_at: now},
  %{email: "paulina@glossia.ai", name: "Paulina", pomerium_id: "google/paulina", last_seen_at: now},
  %{email: "nina@glossia.ai", name: "Nina", pomerium_id: "google/nina", last_seen_at: now},
  %{email: "tomas@glossia.ai", name: "Tomas", pomerium_id: "google/tomas", last_seen_at: now}
]

for attributes <- accounts do
  case Repo.get_by(Account, email: attributes.email) do
    nil -> Repo.insert!(Account.registration_changeset(%Account{}, attributes))
    account -> Repo.update!(Account.identity_changeset(account, attributes))
  end
end

work_items = [
  %{
    area: "Customer success",
    assignee: "Marek",
    due_on: Date.add(today, 2),
    priority: "High",
    status: "In progress",
    summary: "Prepare the Glossia customer adoption review"
  },
  %{
    area: "Finance",
    assignee: "Paulina",
    due_on: Date.add(today, 4),
    priority: "Urgent",
    status: "Blocked",
    summary: "Confirm the renewal scenario for the annual infrastructure contract"
  },
  %{
    area: "Growth",
    assignee: "Nina",
    due_on: Date.add(today, 6),
    priority: "Normal",
    status: "Open",
    summary: "Publish the customer story approval checklist"
  },
  %{
    area: "Operations",
    assignee: "Tomas",
    due_on: Date.add(today, -1),
    priority: "Low",
    status: "Done",
    summary: "Archive the completed vendor due diligence packet"
  }
]

for attributes <- work_items do
  case Repo.get_by(WorkItem, summary: attributes.summary) do
    nil -> Repo.insert!(WorkItem.changeset(%WorkItem{}, attributes))
    work_item -> Repo.update!(WorkItem.changeset(work_item, attributes))
  end
end
