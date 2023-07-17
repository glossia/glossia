defmodule GlossiaWeb.SEO do
  @moduledoc """
  Component modules can use this module and return the SEO metadata
  to use fora particular route.
  """
  defmacro __before_compile__(_env) do
    quote do
      def get_seo_metadata(_, _), do: %{}
    end
  end

  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)

      def get_seo_metadata(%{
            private: %{phoenix_action: action, phoenix_view: %{"html" => html_view}},
            assigns: assigns
          }) do
        app_metadata = Application.get_env(:glossia, :seo_metadata)
        view_metadata = html_view.get_seo_metadata(action, assigns)

        view_metadata =
          view_metadata
          |> Map.update(:title, app_metadata.title, fn value ->
            app_metadata.title <> " | " <> value
          end)

        Map.merge(app_metadata, view_metadata)
      end
    end
  end
end
