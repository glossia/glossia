defmodule Glossia.Waitlist do
  require OpenTelemetry.Tracer, as: Tracer

  alias Glossia.Repo
  alias Glossia.Waitlist.Submission

  def create_submission(attrs) do
    Tracer.with_span "glossia.waitlist.create_submission" do
      Tracer.set_attributes([
        {"glossia.user.id", to_string(attrs["user_id"] || attrs[:user_id] || "")}
      ])

      %Submission{}
      |> Submission.changeset(attrs)
      |> Repo.insert()
    end
  end

  def get_submission_by_user(user_id) do
    Tracer.with_span "glossia.waitlist.get_submission_by_user" do
      Tracer.set_attributes([{"glossia.user.id", to_string(user_id)}])
      Repo.get_by(Submission, user_id: user_id)
    end
  end
end
