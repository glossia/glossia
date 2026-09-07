defmodule Glossia.RateLimiter do
  use Hammer, backend: :ets
end
