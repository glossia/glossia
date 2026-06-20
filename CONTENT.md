+++
[llm]
api_key = "{{env.GEMINI_API_KEY}}"

[[llm.agent]]
role = "coordinator"
model = "gemini-2.5-flash"

[[llm.agent]]
role = "translator"
model = "gemini-2.5-flash"

[[translate]]
source = "app/priv/docs/**/*.md"
targets = ["es", "de", "ko", "ja", "zh-Hans", "zh-Hant"]
output = "app/priv/i18n/{lang}/docs/{relpath}"

[[translate]]
source = "app/priv/blog/*.md"
targets = ["es", "de", "ko", "ja", "zh-Hans", "zh-Hant"]
output = "app/priv/i18n/{lang}/blog/{relpath}"

[[translate]]
source = "app/priv/features/*.md"
targets = ["es", "de", "ko", "ja", "zh-Hans", "zh-Hant"]
output = "app/priv/i18n/{lang}/features/{relpath}"

[[translate]]
source = "app/priv/changelog/*.md"
targets = ["es", "de", "ko", "ja", "zh-Hans", "zh-Hant"]
output = "app/priv/i18n/{lang}/changelog/{relpath}"
+++
You are translating the Glossia Phoenix app's public website content.
Keep the voice crisp, pragmatic, and developer-first.
Preserve product names, CLI commands, file paths, and code snippets.
Avoid marketing fluff; be specific and direct.
