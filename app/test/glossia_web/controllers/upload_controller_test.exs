defmodule GlossiaWeb.UploadControllerTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic

  test "serves discussion uploads through the app", %{conn: conn} do
    expect(ExAws, :request, fn operation ->
      assert %ExAws.Operation.S3{
               http_method: :get,
               bucket: "glossia",
               path: "uploads/account-1/discussions/discussion-1/image.png"
             } = operation

      {:ok, %{body: "image-bytes", status_code: 200}}
    end)

    conn = get(conn, "/uploads/account-1/discussions/discussion-1/image.png")

    assert response(conn, 200) == "image-bytes"
    assert get_resp_header(conn, "content-type") == ["image/png; charset=utf-8"]
  end

  test "returns not found for unsupported upload shapes", %{conn: conn} do
    conn = get(conn, "/uploads/account-1/other/image.svg")

    assert response(conn, 404) == ""
  end
end
