defmodule BabelWeb.OperationsLiveTest do
  use BabelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Babel.Organizations.Interaction
  alias Babel.Organizations.Organization
  alias Babel.Repo

  test "renders the overview at the home path", %{conn: conn} do
    organization = insert_organization!()

    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Overview"
    assert has_element?(view, "#babel-sidebar")
    assert has_element?(view, "#babel-sidebar-toggle[aria-controls='babel-navigation']")
    assert has_element?(view, "#babel-navigation")
    assert has_element?(view, "#overview-go-to-market-card")
    assert has_element?(view, "#babel-overview-navigation")
    refute has_element?(view, "#organizations-directory", organization.name)
    refute html =~ "Customers"
    refute html =~ "Finance"
  end

  test "renders the Growth summary", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/growth")

    assert html =~ "Growth pipeline"
    assert has_element?(view, "#growth-summary-card")
    assert has_element?(view, "#babel-growth-navigation")
  end

  test "renders reconciled Glossia organizations and Babel-only leads on the Organizations page",
       %{
         conn: conn
       } do
    glossia_organization_id = Ecto.UUID.generate()

    insert_organization!(%{
      name: "Connected organization",
      glossia_organization_id: glossia_organization_id
    })

    insert_organization!(%{name: "Lead organization"})

    {:ok, view, html} = live(conn, ~p"/organizations")

    assert html =~ "Connected organization"
    assert html =~ "Lead organization"
    assert has_element?(view, "#organizations-directory", "Glossia")
    assert has_element?(view, "#organizations-directory", "Lead")
    assert has_element?(view, "#organizations-directory tr[phx-click]", "Connected organization")
    refute has_element?(view, "#organizations-directory button", "Open")
    assert has_element?(view, "#babel-organizations-navigation[href='/organizations']")
    refute has_element?(view, "#babel-organizations-navigation[data-part='collapsible-group']")
  end

  test "adds an organization from the Organizations page", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/organizations")

    assert has_element?(view, "#add-organization-modal", "Add organization")

    view
    |> form("#organization-form",
      account: %{
        name: "Dashboard organization",
        website_url: "https://dashboard-account.example.com",
        origin_url: "https://example.com/customer-story",
        state: "qualified",
        translation_tool: "Phrase",
        notes: "Created from the Organizations page."
      }
    )
    |> render_submit()

    organization = Repo.get_by!(Organization, name: "Dashboard organization")
    assert_redirect(view, ~p"/organizations/#{organization}")
    assert is_nil(organization.glossia_organization_id)
    assert organization.origin_url == "https://example.com/customer-story"
  end

  test "filters, searches, and sorts organizations through the table controls", %{conn: conn} do
    researching = insert_organization!(%{name: "Aster Labs", state: "researching"})

    beta =
      insert_organization!(%{
        name: "Beta Labs",
        state: "qualified",
        glossia_organization_id: Ecto.UUID.generate()
      })

    zenith =
      insert_organization!(%{
        name: "Zenith Labs",
        state: "qualified",
        glossia_organization_id: Ecto.UUID.generate()
      })

    filter_params = %{
      "filter_source_op" => "==",
      "filter_source_val" => "glossia",
      "sort_by" => "name",
      "sort_order" => "desc"
    }

    {:ok, control_view, _html} = live(conn, ~p"/organizations")

    assert has_element?(control_view, "#search-organizations")
    assert has_element?(control_view, "#organizations-filter")

    assert has_element?(
             control_view,
             "#organizations-directory a[data-part='sort-link']",
             "Organization"
           )

    {:ok, filtered_view, html} = live(conn, ~p"/organizations?#{filter_params}")

    assert html =~ beta.name
    assert html =~ zenith.name
    refute has_element?(filtered_view, "#organizations-directory", researching.name)
    assert account_position(html, zenith.name) < account_position(html, beta.name)

    {:ok, search_view, search_html} = live(conn, ~p"/organizations?#{%{"search" => "Beta"}}")

    assert search_html =~ beta.name
    refute has_element?(search_view, "#organizations-directory", researching.name)
    refute has_element?(search_view, "#organizations-directory", zenith.name)
  end

  test "renders an organization interaction timeline", %{conn: conn} do
    organization = insert_organization!(%{origin_url: "https://example.com/customer-story"})

    %Interaction{}
    |> Interaction.changeset(%{
      organization_id: organization.id,
      kind: "research",
      summary: "Reviewed the public customer story.",
      occurred_at: DateTime.utc_now(:second)
    })
    |> Repo.insert!()

    {:ok, view, html} = live(conn, ~p"/organizations/#{organization}")

    assert html =~ organization.name
    assert has_element?(view, "#organization-list-button", "Organizations")
    assert has_element?(view, "#organization-summary-card", "Summary")
    assert has_element?(view, "#edit-organization-modal", "Edit organization")
    assert has_element?(view, "#organization-summary-card", "Open origin")

    assert has_element?(view, "#organization-page-avatar img[src$='/favicon.ico']")

    assert has_element?(
             view,
             "#organization-timeline-card",
             "Reviewed the public customer story."
           )

    assert has_element?(view, "#organization [data-part='timeline']")
  end

  test "renders Glossia project and translation usage as widgets" do
    organization =
      insert_organization!(%{glossia_organization_id: Ecto.UUID.generate()})
      |> Map.put(:interactions, [])

    html =
      render_component(&BabelWeb.OperationsLive.organization/1, %{
        account: organization,
        account_usage: {:ok, %{projects: 3, translations: 24}},
        organization_edit_form:
          organization
          |> Organization.changeset(%{})
          |> Phoenix.Component.to_form(as: :organization),
        interaction_form:
          %Interaction{}
          |> Interaction.changeset(%{kind: "note"})
          |> Phoenix.Component.to_form(as: :interaction)
      })

    assert html =~ "Projects"
    assert html =~ "Translations"
    refute html =~ "Members"
  end

  test "adds a manual interaction to an organization timeline", %{conn: conn} do
    organization = insert_organization!()

    {:ok, view, _html} = live(conn, ~p"/organizations/#{organization}")

    assert has_element?(view, "#organization-interaction-form", "Add event")

    view
    |> form("#organization-interaction-form",
      interaction: %{
        summary: "Confirmed the product team contact."
      }
    )
    |> render_submit()

    assert has_element?(
             view,
             "#organization-timeline-card",
             "Confirmed the product team contact."
           )
  end

  test "edits organization details from its summary", %{conn: conn} do
    organization = insert_organization!(%{state: "researching"})

    {:ok, view, _html} = live(conn, ~p"/organizations/#{organization}")

    view
    |> form("#edit-organization-form",
      organization: %{
        name: organization.name,
        website_url: organization.website_url,
        origin_url: "https://example.com/updated-source",
        state: "customer",
        translation_tool: "Updated translation tool",
        notes: "Updated organization description."
      }
    )
    |> render_submit()

    updated_organization = Repo.get!(Organization, organization.id)
    assert updated_organization.state == "customer"
    assert updated_organization.origin_url == "https://example.com/updated-source"
    assert updated_organization.notes == "Updated organization description."
    assert has_element?(view, "#organization-summary-card", "Updated organization description.")
    assert has_element?(view, "#organization-timeline-card", "from researching to customer")
  end

  defp insert_organization!(overrides \\ %{}) do
    suffix = System.unique_integer([:positive])

    %Organization{}
    |> Organization.changeset(
      Map.merge(
        %{
          name: "Example organization #{suffix}",
          website_url: "https://example-#{suffix}.com",
          state: "qualified",
          translation_tool: "Example translation tool"
        },
        overrides
      )
    )
    |> Repo.insert!()
  end

  defp account_position(html, account_name) do
    html
    |> String.split(~s(id="organizations-directory"), parts: 2)
    |> List.last()
    |> :binary.match(account_name)
    |> elem(0)
  end
end
