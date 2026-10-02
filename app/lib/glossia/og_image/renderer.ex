defmodule Glossia.OgImage.Renderer do
  @moduledoc """
  Captures social images with the viewport and screenshot in one Chrome session.
  Chrome resets emulated dimensions when the session disconnects, so setting
  the viewport through a separate Browse call would crop the fixed-size layout.
  """

  def render(pool, html, opts) do
    BrowseChrome.checkout(pool, fn browser ->
      {BrowseChrome.Chrome.capture(browser, html, opts), :ok}
    end)
  end
end
