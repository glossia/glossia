defmodule Glossia.OgImage.RendererTest do
  use ExUnit.Case, async: true

  alias Glossia.OgImage.Renderer

  @moduletag :live

  test "captures the complete canvas on every checkout of a reused Chrome worker" do
    pool = :"social_image_browser_#{System.unique_integer([:positive])}"

    start_supervised!(Browse.child_spec(pool, implementation: BrowseChrome.Browser, pool_size: 1))

    html = """
    <!doctype html>
    <html><body style="margin: 0; width: 1200px; height: 630px">
      <h1>Translation is the easy part</h1>
    </body></html>
    """

    for _ <- 1..2 do
      assert {:ok, image} = Renderer.render(pool, html, width: 1200, height: 630, quality: 90)
      # BrowseChrome captures at twice the logical viewport size.
      assert jpeg_dimensions(image) == {2400, 1260}
    end
  end

  defp jpeg_dimensions(<<0xFF, 0xD8, rest::binary>>), do: jpeg_frame(rest)

  defp jpeg_frame(<<0xFF, 0xC0, _length::16, _precision, height::16, width::16, _::binary>>),
    do: {width, height}

  defp jpeg_frame(<<0xFF, _marker, length::16, rest::binary>>) do
    segment_size = length - 2
    <<_segment::binary-size(^segment_size), remaining::binary>> = rest
    jpeg_frame(remaining)
  end
end
