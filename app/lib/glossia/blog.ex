defmodule Glossia.Blog do
  defmodule Source do
    @moduledoc false

    @callback all_posts() :: [map()]
    @callback recent_posts(pos_integer()) :: [map()]
    @callback get_post_by_slug!(String.t()) :: map()
  end

  def all_posts, do: Glossia.Extensions.blog().all_posts()

  def recent_posts(count \\ 2), do: Glossia.Extensions.blog().recent_posts(count)

  def get_post_by_slug!(slug), do: Glossia.Extensions.blog().get_post_by_slug!(slug)
end

defmodule Glossia.Blog.NotFoundError do
  defexception [:message, plug_status: 404]
end
