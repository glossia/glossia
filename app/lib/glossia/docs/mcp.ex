defmodule Glossia.Docs.MCP do
  @moduledoc false

  alias Glossia.Docs.Page

  def tools_page do
    tools = Glossia.MCP.Server.__components__(:tool)
    {body, toc} = generate_tools_html(tools)

    %Page{
      id: "reference/mcp/tools",
      title: "Tools",
      summary: "Available MCP tools and their parameters.",
      category: "reference",
      subcategory: "mcp",
      order: 2,
      slug: "tools",
      body: body,
      toc: toc
    }
  end

  def prompts_page do
    prompts = Glossia.MCP.Server.__components__(:prompt)

    {body, toc} =
      if prompts == [] do
        {"<p>No prompts are currently defined. This page will be populated as prompt templates are added to the MCP server.</p>",
         []}
      else
        generate_prompts_html(prompts)
      end

    %Page{
      id: "reference/mcp/prompts",
      title: "Prompts",
      summary: "Available MCP prompt templates.",
      category: "reference",
      subcategory: "mcp",
      order: 3,
      slug: "prompts",
      body: body,
      toc: toc
    }
  end

  defp generate_tools_html(tools) do
    intro =
      "<p>The Glossia MCP server provides the following tools that coding agents can use to interact with your projects.</p>\n\n"

    {sections, toc_entries} =
      tools
      |> Enum.sort_by(& &1.name)
      |> Enum.map_reduce([], fn tool, toc_acc ->
        tool_id = slugify(tool.name)

        heading =
          ~s(<h2 id="#{tool_id}"><a href="##{tool_id}" class="heading-anchor">#{tool.name}</a></h2>\n)

        description = "<p>#{escape_html(tool.description)}</p>\n"

        params_html = render_parameters(tool.input_schema)

        section = heading <> description <> params_html

        toc_entry = %{id: tool_id, text: tool.name, level: 2}
        {section, toc_acc ++ [toc_entry]}
      end)

    {intro <> Enum.join(sections, "\n"), toc_entries}
  end

  defp generate_prompts_html(prompts) do
    intro = "<p>The Glossia MCP server provides the following prompt templates.</p>\n\n"

    {sections, toc_entries} =
      prompts
      |> Enum.sort_by(& &1.name)
      |> Enum.map_reduce([], fn prompt, toc_acc ->
        prompt_id = slugify(prompt.name)

        heading =
          ~s(<h2 id="#{prompt_id}"><a href="##{prompt_id}" class="heading-anchor">#{prompt.name}</a></h2>\n)

        description = "<p>#{escape_html(prompt.description)}</p>\n"
        section = heading <> description

        toc_entry = %{id: prompt_id, text: prompt.name, level: 2}
        {section, toc_acc ++ [toc_entry]}
      end)

    {intro <> Enum.join(sections, "\n"), toc_entries}
  end

  defp render_parameters(%{"properties" => properties} = schema) when map_size(properties) > 0 do
    required_fields = Map.get(schema, "required", [])

    rows =
      properties
      |> Enum.sort_by(fn {name, _} ->
        {if(name in required_fields, do: 0, else: 1), name}
      end)
      |> Enum.map(fn {name, prop} ->
        type = Map.get(prop, "type", "any")
        required? = name in required_fields
        description = Map.get(prop, "description", "")
        required_text = if required?, do: "Yes", else: "No"

        ~s(<tr><td><code>#{escape_html(name)}</code></td><td><code>#{escape_html(type)}</code></td><td>#{required_text}</td><td>#{escape_html(description)}</td></tr>)
      end)

    """
    <table class="docs-param-table">
    <thead><tr><th>Parameter</th><th>Type</th><th>Required</th><th>Description</th></tr></thead>
    <tbody>
    #{Enum.join(rows, "\n")}
    </tbody>
    </table>
    """
  end

  defp render_parameters(_), do: ""

  defp escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp escape_html(nil), do: ""

  defp slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
