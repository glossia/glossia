defmodule Glossia.TestHelpers do
  use Boundary, top_level?: true

  def unique_integer(length \\ 3) do
    System.unique_integer([:positive, :monotonic]) + (:math.pow(10, length - 1) |> round())
  end
end
