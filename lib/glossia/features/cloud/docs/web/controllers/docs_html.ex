defmodule Glossia.Features.Cloud.Docs.Web.Controllers.DocsHTML do
  use Glossia.Features.Cloud.Docs.Web.Helpers, :html

  embed_templates "docs_html/*"

  attr :item, :map, required: true
  attr :level, :integer, required: true
  attr :index, :integer, required: true

  def navigation_item(assigns) do
    ~H"""
    <.action_list_section_divider :if={@index != 0 && @level == 0} />
    <%= if Map.has_key?(@item, :children) do %>
      <%!-- <.action_list_section_divider>
        <:title><%= @item.name %></:title>
      </.action_list_section_divider> --%>
      <.action_list_item is_collapsible is_expanded>
        <%= @item.name %>

        <:sub_group>
          <.navigation_item
            :for={{child, sub_index} <- Enum.with_index(@item.children)}
            item={child}
            level={@level + 1}
            index={sub_index}
          />
        </:sub_group>
      </.action_list_item>
    <% else %>
      <.action_list_item is_sub_item={@level != 0}>
        <%= @item.name %>
      </.action_list_item>
    <% end %>
    """
  end
end
