defmodule Glossia.CoreEditionTest do
  use ExUnit.Case, async: true

  test "core builds have no enterprise audit modules or children" do
    if System.get_env("GLOSSIA_EDITION", "core") == "core" do
      assert Application.get_env(:glossia, :audit_extension) == nil
      assert Glossia.Extensions.audit_children() == []
      assert Glossia.Extensions.audit_migrations(Glossia.Repo) == []
      assert Glossia.Extensions.organization_authentication_migrations(Glossia.Repo) == []
      assert Glossia.Extensions.organization_authentication() == nil
      assert Glossia.Extensions.navigation_extension() == nil
      assert Glossia.OrganizationAuthentication.for_email("person@example.test") == nil

      assert Glossia.OrganizationAuthentication.sign_in(nil, %{}) ==
               {:error, :enterprise_required}

      refute Code.ensure_loaded?(GlossiaEnterprise.Audit)
      refute Code.ensure_loaded?(GlossiaEnterprise.Audit.Event)

      for module <- [
            GlossiaEnterprise.Audit.Migration,
            GlossiaEnterprise.OrganizationAuthentication,
            GlossiaEnterprise.OrganizationDomainVerificationWorker,
            GlossiaEnterprise.SCIM,
            GlossiaEnterprise.SCIM.Token,
            GlossiaEnterprise.SCIM.ProvisionedUser,
            GlossiaEnterprise.SCIM.Protocol,
            GlossiaEnterprise.Identity.Migration,
            GlossiaEnterprise.Identity.SecuritySettings,
            GlossiaEnterprise.Identity.OAuth2HTTP,
            GlossiaEnterprise.Identity.OAuth2Migration,
            GlossiaEnterprise.SCIM.AttachmentNotifierWorker,
            GlossiaEnterprise.MCP.GetOrganizationAuthenticationTool,
            GlossiaEnterprise.MCP.UpdateOrganizationAuthenticationTool,
            GlossiaEnterprise.MCP.VerifyOrganizationAuthenticationTool,
            GlossiaEnterpriseWeb.OrganizationAuthenticationApiController,
            GlossiaEnterpriseWeb.IdentityOpenApiSpec,
            GlossiaEnterpriseWeb.SCIMController,
            GlossiaEnterpriseWeb.SCIMDiscoveryController,
            GlossiaEnterpriseWeb.Plugs.SCIMAuth,
            GlossiaEnterpriseWeb.OrganizationSession,
            GlossiaEnterpriseWeb.AuthenticationSettingsLive,
            GlossiaEnterpriseWeb.AuditLogsLive,
            GlossiaEnterpriseWeb.OrganizationAuthController,
            GlossiaEnterpriseWeb.Navigation,
            GlossiaEnterpriseWeb.Gettext,
            GlossiaEnterprise.TranslationSessions.Runtime,
            GlossiaEnterprise.TranslationSessions.Launcher,
            GlossiaEnterprise.TranslationSessions.Job,
            GlossiaEnterprise.TranslationSessions.EngineRelease,
            GlossiaEnterprise.Runners,
            GlossiaEnterprise.Flame,
            GlossiaEnterprise.Kubernetes,
            GlossiaEnterprise.Sandbox.KataAdapter,
            FLAME,
            FLAMEK8sBackend
          ] do
        refute Code.ensure_loaded?(module)
      end

      assert Glossia.Extensions.translation_runtime() == Glossia.TranslationSessions.LocalRuntime
      assert Glossia.Sandbox.adapter() == Glossia.Sandbox.LocalAdapter
      refute Process.whereis(Glossia.RunnerPool)
      assert :not_ready = Glossia.TranslationSessions.EngineRelease.ready_release()

      refute Enum.any?(Phoenix.Router.routes(GlossiaWeb.Router), fn route ->
               route.path in [
                 "/auth/organization",
                 "/auth/organization/callback",
                 "/scim/v2/Users",
                 "/scim/v2/Groups",
                 "/scim/v2/ServiceProviderConfig",
                 "/api/organizations/:handle/authentication",
                 "/api/organizations/:handle/authentication/verify",
                 "/:handle/-/settings/authentication",
                 "/:handle/-/audit-logs"
               ]
             end)

      refute Map.has_key?(
               GlossiaWeb.OpenApiSpec.spec()["paths"],
               "/api/organizations/{handle}/authentication"
             )
    end
  end

  test "the core retains a usable no-op domain-event handler" do
    assert :ok = Glossia.Events.NoopHandler.handle_event(nil)
  end
end
