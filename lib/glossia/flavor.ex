defmodule Glossia.Flavor do
  @flavor Application.compile_env!(:glossia, :flavor) |> String.to_atom()

  defmacro only_for_flavors(flavors, do: block) do
    quote do
      if Enum.member?(unquote(flavors), Glossia.Flavor.current()) do
        unquote(block)
      end
    end
  end

  defmacro excluding_from_flavors(flavors, do: block) do
    quote do
      unless Enum.member?(unquote(flavors), Glossia.Flavor.current()) do
        unquote(block)
      end
    end
  end

  def current() do
    @flavor
  end
end
