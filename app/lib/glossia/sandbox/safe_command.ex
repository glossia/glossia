defmodule Glossia.Sandbox.SafeCommand do
  @moduledoc false

  @shell_metacharacters [
    ";",
    "&",
    "|",
    "`",
    "$",
    "<",
    ">",
    "*",
    "?",
    "(",
    ")",
    "[",
    "]",
    "{",
    "}",
    "\\"
  ]

  def parse(command) when is_binary(command) do
    command = String.trim(command)

    cond do
      command == "" ->
        {:error, :empty_command}

      String.match?(command, ~r/[[:cntrl:]]/) ->
        {:error, :shell_syntax_not_supported}

      Enum.any?(@shell_metacharacters, &String.contains?(command, &1)) ->
        {:error, :shell_syntax_not_supported}

      true ->
        command
        |> String.split()
        |> validate_argv()
    end
  end

  def parse(_command), do: {:error, :invalid_command}

  def validate(command) do
    case parse(command) do
      {:ok, _argv} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_argv(["echo" | _args] = argv), do: {:ok, argv}
  defp validate_argv(["printf" | _args] = argv), do: {:ok, argv}
  defp validate_argv([command] = argv) when command in ~w(false pwd true), do: {:ok, argv}

  defp validate_argv([command | paths] = argv) when command in ~w(cat ls),
    do: validate_paths(argv, paths)

  defp validate_argv(["mkdir" | args] = argv), do: validate_paths(argv, path_args(args, ["-p"]))

  defp validate_argv(["rm" | args] = argv),
    do: validate_paths(argv, path_args(args, ["-r", "-f", "-rf", "-fr"]))

  defp validate_argv([name | _]), do: {:error, {:unsupported_command, name}}
  defp validate_argv([]), do: {:error, :empty_command}

  defp validate_paths(argv, []), do: {:ok, argv}

  defp validate_paths(argv, paths) do
    if Enum.all?(paths, &safe_relative_path?/1) do
      {:ok, argv}
    else
      {:error, :path_outside_sandbox}
    end
  end

  defp path_args(args, flags) do
    {_flags, paths} = Enum.split_while(args, &(&1 in flags))
    paths
  end

  defp safe_relative_path?(path) do
    Path.type(path) == :relative and not String.starts_with?(path, "-") and
      ".." not in Path.split(path)
  end
end
