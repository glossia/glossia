defmodule Glossia.LinguisticReviews.Participant do
  @moduledoc false
  use Glossia.Schema

  @primary_key false
  schema "linguistic_review_participants" do
    belongs_to :linguistic_review, Glossia.LinguisticReviews.Review, primary_key: true
    belongs_to :user, Glossia.Accounts.User, primary_key: true
    timestamps()
  end
end
