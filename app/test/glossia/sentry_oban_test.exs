defmodule Glossia.SentryObanTest do
  use ExUnit.Case, async: true

  alias Glossia.SentryOban

  test "does not report retryable Oban job errors" do
    refute SentryOban.report_error?(nil, %{attempt: 1, max_attempts: 3})
  end

  test "reports exhausted Oban job errors" do
    assert SentryOban.report_error?(nil, %{attempt: 3, max_attempts: 3})
  end

  test "reports Oban job errors when retry metadata is unavailable" do
    assert SentryOban.report_error?(nil, %{})
  end
end
