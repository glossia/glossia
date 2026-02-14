defmodule GlossiaWeb.WaitlistController do
  use GlossiaWeb, :controller

  alias Glossia.Waitlist
  alias Glossia.Waitlist.Submission

  def new(conn, _params) do
    user = conn.assigns.current_user

    case Waitlist.get_submission_by_user(user.id) do
      %Submission{} = submission ->
        render(conn, :submitted, submission: submission)

      nil ->
        changeset = Submission.changeset(%Submission{}, %{})
        render(conn, :form, changeset: changeset, current_user: user)
    end
  end

  def create(conn, %{"submission" => submission_params}) do
    user = conn.assigns.current_user

    attrs =
      submission_params
      |> Map.put("user_id", user.id)
      |> Map.put("email", user.email)

    case Waitlist.create_submission(attrs) do
      {:ok, submission} ->
        render(conn, :submitted, submission: submission)

      {:error, changeset} ->
        render(conn, :form, changeset: changeset, current_user: user)
    end
  end
end
