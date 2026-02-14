defmodule Glossia.Waitlist do
  alias Glossia.Repo
  alias Glossia.Waitlist.Submission

  def create_submission(attrs) do
    %Submission{}
    |> Submission.changeset(attrs)
    |> Repo.insert()
  end

  def get_submission_by_user(user_id) do
    Repo.get_by(Submission, user_id: user_id)
  end
end
