defmodule Glossia.OgImageTest do
  use ExUnit.Case, async: true

  alias Glossia.OgImage
  alias Glossia.OgImage.Cache

  test "content, logo version, and day all contribute to the image identity" do
    attrs = %{
      title: "Tuist",
      project_avatar: "avatars/dev/projects/tuist.png",
      project_avatar_version: 1
    }

    day = ~D[2026-09-08]

    assert OgImage.hash(attrs, day) ==
             OgImage.hash(Map.new(Enum.reverse(Map.to_list(attrs))), day)

    refute OgImage.hash(attrs, day) == OgImage.hash(attrs, Date.add(day, 1))
    refute OgImage.hash(attrs, day) == OgImage.hash(%{attrs | title: "Glossia"}, day)
    refute OgImage.hash(attrs, day) == OgImage.hash(%{attrs | project_avatar_version: 2}, day)
  end

  test "signed links are deterministic during the day and reject tampering" do
    attrs = %{title: "Glossia"}
    token = OgImage.sign_attrs(attrs)
    assert token == OgImage.sign_attrs(attrs)
    assert {:ok, %{attrs: ^attrs, day: day}} = OgImage.verify_attrs(token)
    assert day == Date.utc_today()
    assert {:error, _} = OgImage.verify_attrs(token <> "changed")
    assert {:error, _} = OgImage.verify_attrs(String.duplicate("a", 8193))
    assert {:error, _} = OgImage.verify_attrs(OgImage.sign_attrs(attrs, Date.add(day, -3)))
  end

  test "simultaneous cache misses share a resolver and subsequent hits skip it" do
    cache = start_cache()
    parent = self()

    tasks =
      for _ <- 1..10 do
        Task.async(fn ->
          Cache.fetch(
            "image",
            fn ->
              send(parent, {:resolve, self()})

              receive do
                :finish -> {:ok, "image bytes"}
              end
            end,
            cache
          )
        end)
      end

    assert_receive {:resolve, resolver}
    send(resolver, :finish)
    assert Enum.map(tasks, &Task.await/1) == List.duplicate({:ok, "image bytes"}, 10)
    refute_receive {:resolve, _}
    assert {:ok, "image bytes"} = Cache.fetch("image", fn -> flunk("cache miss") end, cache)
  end

  test "transient failures do not occupy the cache" do
    cache = start_cache()
    assert {:error, :unavailable} = Cache.fetch("image", fn -> {:error, :unavailable} end, cache)
    assert {:ok, "recovered"} = Cache.fetch("image", fn -> {:ok, "recovered"} end, cache)
  end

  defp start_cache do
    name = :"test_cache_#{:erlang.unique_integer([:positive])}"
    start_supervised!({Cache, name: name})
    name
  end
end
