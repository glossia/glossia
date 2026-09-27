defmodule GlossiaWeb.RedirectController do
  use GlossiaWeb, :controller

  def project_activity(conn, %{"handle" => handle, "project" => project}) do
    redirect(conn, to: "/#{handle}/#{project}")
  end

  def project_overview(conn, %{"handle" => handle, "project" => project}) do
    redirect(conn, to: "/#{handle}/#{project}")
  end

  def account(conn, %{"handle" => handle}) do
    redirect(conn, to: "/#{handle}")
  end

  def terminology_to_glossary(conn, %{"handle" => handle} = params) do
    rest = params |> Map.get("rest", []) |> Enum.join("/")
    suffix = if rest == "", do: "", else: "/" <> rest
    redirect(conn, to: "/#{handle}/-/glossary" <> suffix)
  end
end
