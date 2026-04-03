defmodule GlossiaWeb.WaitlistController do
  use GlossiaWeb, :controller

  alias Glossia.Events
  alias Glossia.Waitlist
  alias Glossia.Waitlist.Submission

  plug GlossiaWeb.Plugs.RateLimit,
       [
         key_prefix: "waitlist_create",
         scale: :timer.hours(1),
         limit: 10,
         by: :user,
         format: :text
       ]
       when action in [:create]

  def new(%{assigns: %{current_user: %{account: %{has_access: true}}}} = conn, _params) do
    redirect(conn, to: ~p"/dashboard")
  end

  def new(conn, _params) do
    user = conn.assigns.current_user

    case Waitlist.get_submission_by_user(user.id) do
      %Submission{} = submission ->
        render(conn, :submitted, submission: submission, page_title: gettext("Waitlist"))

      nil ->
        changeset = Submission.changeset(%Submission{}, %{})

        render(conn, :form,
          changeset: changeset,
          current_user: user,
          page_title: gettext("Waitlist")
        )
    end
  end

  def create(%{assigns: %{current_user: %{account: %{has_access: true}}}} = conn, _params) do
    redirect(conn, to: ~p"/dashboard")
  end

  def create(conn, %{"submission" => submission_params}) do
    user = conn.assigns.current_user

    attrs =
      submission_params
      |> Map.put("user_id", user.id)
      |> Map.put("email", user.email)

    case Waitlist.create_submission(attrs) do
      {:ok, submission} ->
        Events.emit("waitlist.submitted", user.account, user,
          resource_type: "waitlist_submission",
          resource_id: to_string(submission.id),
          resource_path: ~p"/interest",
          summary: "Submitted waitlist interest."
        )

        render(conn, :submitted, submission: submission, page_title: gettext("Waitlist"))

      {:error, changeset} ->
        render(conn, :form,
          changeset: changeset,
          current_user: user,
          page_title: gettext("Waitlist")
        )
    end
  end
end
