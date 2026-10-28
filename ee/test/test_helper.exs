# Reuse the core test setup when Mix discovers the enterprise test directory.
# Code.require_file/2 is idempotent if app/test/test_helper.exs was loaded first.
Code.require_file("../../app/test/test_helper.exs", __DIR__)

Mimic.copy(GlossiaEnterprise.Kubernetes)
Mimic.copy(GlossiaEnterprise.TranslationSessions.EngineRelease)
