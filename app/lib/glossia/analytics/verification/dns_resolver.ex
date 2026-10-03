defmodule Glossia.Analytics.Verification.DNSResolver do
  @moduledoc """
  Thin wrapper around Erlang's native stub resolver used by analytics domain
  ownership verification. Exists so tests can stub DNS at the Elixir boundary
  instead of trying to copy the sticky `:inet_res` module through Mimic.
  """

  # Per-nameserver attempt timeout, kept small so a slow authoritative
  # does not eat the whole deadline on the first try.
  @per_attempt_timeout_ms 2_000
  # Overall deadline for the entire resolution, including retries and
  # nameserver fallbacks. `verify_analytics_domain` runs synchronously in
  # a LiveView handler, so this bound protects dashboard responsiveness.
  @overall_timeout_ms 5_000

  @doc """
  Returns `{:ok, records}` with each TXT record flattened into a single
  binary. Any resolver error becomes `:error` so a transient upstream
  failure never locks an operator out of their own project.
  """
  def lookup_txt(name) when is_binary(name) do
    records =
      :inet_res.lookup(
        String.to_charlist(name),
        :in,
        :txt,
        [timeout: @per_attempt_timeout_ms],
        @overall_timeout_ms
      )

    {:ok, Enum.map(records, &IO.iodata_to_binary/1)}
  rescue
    _ -> :error
  catch
    _, _ -> :error
  end
end
