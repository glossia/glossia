defmodule Glossia.Analytics.Identity do
  @moduledoc """
  Daily-rotated, non-reidentifiable visitor identifiers.

  `visitor_id/3` derives an unsigned 64-bit integer from an HMAC-SHA256 of the
  client IP, User-Agent, and project id, salted per calendar day. Because the
  salt rotates daily and is derived from a server-held secret, identifiers:

    * cannot be linked across days (a visitor on Monday and Tuesday gets two
      unrelated identifiers),
    * are scoped per project (the same browser on two projects is unrelated),
    * cannot be reversed to an IP address without the secret.

  Daily and weekly unique counts remain accurate; long-term "returning visitor"
  tracking is intentionally impossible. See the design notes in
  `Glossia.Analytics.Event` for the rationale.
  """

  alias Glossia.Analytics.Config

  @spec visitor_id(binary(), binary(), binary(), Date.t()) :: non_neg_integer()
  def visitor_id(ip, user_agent, project_id, date \\ Date.utc_today()) do
    secret = Config.fetch!(:identity_secret)
    salt = daily_salt(secret, date)

    payload =
      IO.iodata_to_binary([
        salt,
        ?|,
        to_string(ip),
        ?|,
        to_string(user_agent),
        ?|,
        to_string(project_id)
      ])

    <<value::unsigned-big-integer-size(64)>> =
      :crypto.mac(:hmac, :sha256, secret, payload) |> binary_part(0, 8)

    value
  end

  defp daily_salt(secret, %Date{} = date) do
    :crypto.mac(:hmac, :sha256, secret, "salt:" <> Date.to_iso8601(date))
    |> Base.encode16(case: :lower)
  end
end
