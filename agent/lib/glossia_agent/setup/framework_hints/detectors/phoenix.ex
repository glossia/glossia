defmodule GlossiaAgent.Setup.FrameworkHints.Detectors.Phoenix do
  @moduledoc false

  @required_gettext_source "priv/gettext/**/*.po"

  @spec detect([String.t()], %{optional(String.t()) => String.t()}) :: map() | nil
  def detect(tree, key_files) do
    if phoenix_project?(tree, key_files) do
      required_sources =
        if has_gettext_catalogs?(tree) do
          [@required_gettext_source]
        else
          []
        end

      %{
        framework: "phoenix",
        summary: "Phoenix project with gettext catalogs detected",
        required_sources: required_sources
      }
    else
      nil
    end
  end

  defp phoenix_project?(tree, key_files) do
    has_phoenix_dependency?(key_files) || has_phoenix_project_shape?(tree)
  end

  defp has_gettext_catalogs?(tree) do
    Enum.any?(tree, fn path ->
      String.starts_with?(path, "priv/gettext/") && String.ends_with?(path, ".po")
    end)
  end

  defp has_phoenix_dependency?(key_files) do
    key_files
    |> Enum.any?(fn {path, content} ->
      Path.basename(path) == "mix.exs" &&
        (String.contains?(content, "{:phoenix") ||
           String.contains?(content, "{:phoenix_live_view"))
    end)
  end

  defp has_phoenix_project_shape?(tree) do
    has_web_router =
      Enum.any?(tree, fn path ->
        String.ends_with?(path, "_web/router.ex")
      end)

    has_gettext_dir =
      Enum.any?(tree, fn path ->
        String.starts_with?(path, "priv/gettext/")
      end)

    has_web_router && has_gettext_dir
  end
end
