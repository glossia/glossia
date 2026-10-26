defmodule Glossia.Push.Supervisor do
  @moduledoc "Push-local credential cache and a dedicated HTTP/2-only APNs pool."
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    Supervisor.init(
      [
        Glossia.Push.Credentials,
        {Finch,
         name: Glossia.Push.Finch,
         pools: %{
           "https://api.push.apple.com" => [protocols: [:http2], count: 1],
           "https://api.sandbox.push.apple.com" => [protocols: [:http2], count: 1]
         }}
      ],
      strategy: :one_for_one
    )
  end
end
