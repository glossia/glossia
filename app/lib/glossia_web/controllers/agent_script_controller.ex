defmodule GlossiaWeb.AgentScriptController do
  use GlossiaWeb, :controller

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "agent_scripts",
    scale: :timer.minutes(1),
    limit: 120,
    by: :ip,
    format: :text

  @agent_dir "priv/scripts/agent"

  def show(conn, %{"path" => path_segments}) do
    filename = Enum.join(path_segments, "/")

    if String.contains?(filename, "..") do
      conn |> send_resp(400, "Invalid path") |> halt()
    else
      file_path = Path.join(Application.app_dir(:glossia, @agent_dir), filename)

      if File.exists?(file_path) do
        content = File.read!(file_path)

        conn
        |> put_resp_content_type("text/typescript")
        |> send_resp(200, content)
      else
        conn |> send_resp(404, "Not found") |> halt()
      end
    end
  end
end
