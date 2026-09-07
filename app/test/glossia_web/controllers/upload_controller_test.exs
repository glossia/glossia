defmodule GlossiaWeb.UploadControllerTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic

  alias Glossia.Accounts.Account
  alias Glossia.Discussions
  alias Glossia.Repo
  alias Glossia.TestHelpers

  setup do
    owner = TestHelpers.create_user("upload-owner@test.com", "upload-owner")

    {:ok, discussion} =
      Discussions.create_discussion(owner.account, owner, %{
        title: "Upload",
        body: "Upload body"
      })

    %{owner: owner, discussion: discussion}
  end

  test "serves private discussion uploads to an authorized user", %{
    conn: conn,
    owner: owner,
    discussion: discussion
  } do
    expected_path = "uploads/#{owner.account.id}/discussions/#{discussion.id}/image.png"

    expect(ExAws, :request, fn operation ->
      assert %ExAws.Operation.S3{
               http_method: :get,
               bucket: "glossia",
               path: ^expected_path
             } = operation

      {:ok, %{body: "image-bytes", status_code: 200}}
    end)

    conn =
      conn
      |> init_test_session(%{user_id: owner.id})
      |> get("/uploads/#{owner.account.id}/discussions/#{discussion.id}/image.png")

    assert response(conn, 200) == "image-bytes"
    assert get_resp_header(conn, "content-type") == ["image/png; charset=utf-8"]
  end

  test "does not serve private discussion uploads to anonymous users", %{
    conn: conn,
    owner: owner,
    discussion: discussion
  } do
    conn = get(conn, "/uploads/#{owner.account.id}/discussions/#{discussion.id}/image.png")

    assert response(conn, 404) == ""
  end

  test "serves public discussion uploads to anonymous users", %{
    conn: conn,
    owner: owner,
    discussion: discussion
  } do
    {:ok, account} = Account.changeset(owner.account, %{visibility: "public"}) |> Repo.update()
    expected_path = "uploads/#{account.id}/discussions/#{discussion.id}/image.webp"

    expect(ExAws, :request, fn operation ->
      assert %ExAws.Operation.S3{
               http_method: :get,
               bucket: "glossia",
               path: ^expected_path
             } = operation

      {:ok, %{body: "image-bytes", status_code: 200}}
    end)

    conn = get(conn, "/uploads/#{account.id}/discussions/#{discussion.id}/image.webp")

    assert response(conn, 200) == "image-bytes"
    assert get_resp_header(conn, "content-type") == ["image/webp; charset=utf-8"]
  end

  test "returns not found for unsupported upload shapes", %{conn: conn} do
    conn = get(conn, "/uploads/account-1/other/image.svg")

    assert response(conn, 404) == ""
  end
end
