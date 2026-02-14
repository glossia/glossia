defmodule Glossia.StorageTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Glossia.Storage

  describe "upload/3" do
    test "puts an object in the configured bucket" do
      expect(ExAws, :request, fn operation ->
        assert %ExAws.Operation.S3{
                 http_method: :put,
                 bucket: "glossia",
                 path: "test/file.txt",
                 body: "hello"
               } = operation

        {:ok, %{status_code: 200}}
      end)

      assert {:ok, _} = Storage.upload("test/file.txt", "hello")
    end
  end

  describe "download/1" do
    test "gets an object from the configured bucket" do
      expect(ExAws, :request, fn operation ->
        assert %ExAws.Operation.S3{
                 http_method: :get,
                 bucket: "glossia",
                 path: "test/file.txt"
               } = operation

        {:ok, %{body: "hello", status_code: 200}}
      end)

      assert {:ok, %{body: "hello"}} = Storage.download("test/file.txt")
    end
  end

  describe "delete/1" do
    test "deletes an object from the configured bucket" do
      expect(ExAws, :request, fn operation ->
        assert %ExAws.Operation.S3{
                 http_method: :delete,
                 bucket: "glossia",
                 path: "test/file.txt"
               } = operation

        {:ok, %{status_code: 204}}
      end)

      assert {:ok, _} = Storage.delete("test/file.txt")
    end
  end

  describe "bucket/0" do
    test "returns the configured bucket name" do
      assert Storage.bucket() == "glossia"
    end
  end
end
