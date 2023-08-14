- Support passing context at the language level

# Example 1
files: "posts/*/{language}.md"
context: "Context that
files: [
    { wildcard: "posts/*/{language}.md", }
]


- SEO in marketing pages
- Add to Google Search console
- RSS
- Implement API to to translate


blog/
  glossia.jsonc
  glossia/
    lockfiles/
        posts/
        post-1/
            en.md.lockfile
            es.md.lockfile
  posts/
   post-1/
     en.md
     es.md

marketing/
  glossia.jsonc
  glossia/
    lockfiles/
      en.yml.lockfile
      es.yml.lockfile
  en.yml
  es.yml

[
    {
        format: "yaml",
        source: "en",
        files: {
          "es": "marketing/es.yml"
          "en": "marketing/en.yml"
        }
    }
]