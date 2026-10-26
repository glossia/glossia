defmodule Glossia.Push.Message do
  @moduledoc "Generic lock-screen text and the version 1 native navigation contract."

  @title "Glossia"
  @body "You have an update in Glossia."

  def data(destination, registration_id) do
    with {:ok, server} <- server_origin() do
      # This is a native URI, not an HTTP router path. Source resolves the same
      # project/conversation/session that the authorized REST reads expose.
      url =
        %URI{
          scheme: "glossia",
          host: "navigate",
          path:
            Enum.map_join(
              ["", destination.account, destination.project, destination.screen, destination.id],
              "/",
              fn segment -> URI.encode(segment, &URI.char_unreserved?/1) end
            ),
          query: URI.encode_query(%{"server" => server})
        }
        |> URI.to_string()

      {:ok, %{"v" => "1", "url" => url, "registration_id" => registration_id}}
    end
  end

  def apns(data),
    do:
      Map.put(data, "aps", %{
        "alert" => %{"title" => @title, "body" => @body},
        "sound" => "default"
      })

  def fcm(data), do: Map.merge(data, %{"title" => @title, "body" => @body})

  defp server_origin do
    case URI.parse(GlossiaWeb.Endpoint.url()) do
      %URI{scheme: "https", host: host, userinfo: nil} = uri when is_binary(host) ->
        {:ok, URI.to_string(%{uri | path: nil, query: nil, fragment: nil})}

      _ ->
        {:error, :https_endpoint_required}
    end
  end
end
