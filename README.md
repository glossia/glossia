<p align="center">
    <a href="https://github.com/glossia/glossia">
        <img width="150" src="priv/static/images/logo-mit-shadow.svg" alt="Logo">
    </a>
    <h2 align="center">Glossia</h2>
    <p align="center">
    The AI-powered localization copilot.
    <br />
    <a href="https://glossia.ai"><strong>Learn more »</strong></a>
    <br />
    <br />
    <a href="https://discord.gg/zqZxSBXKf8">Discord</a>
    ·
    <a href="https://glossia.ai">Website</a>
    ·
    <a href="https://github.com/glossia/glossia/issues">Issues</a>
    ·
    <a href="https://github.com/glossia/glossia/milestones">Roadmap</a>
  </p>
</p>

<p align="center">
  <a href="https://github.com/glossia/glossia/actions/workflows/glossia.yml"><img src="https://github.com/glossia/glossia/actions/workflows/glossia.yml/badge.svg"/></a>
   <a href="https://discord.gg/zqZxSBXKf8"><img src="https://img.shields.io/badge/Discord-go.cal.com%2Fdiscord-%234A154B" alt="Join Cal.com Discord"></a>
</p>

## Why Glossia?

We believe **AI holds the transformative power to revolutionize the world of continuous localization**, stripping away the complexities of legacy systems. While sectors like software development thrive on the open-source collaborative spirit of platforms like [GitHub](https://github.com), the localization industry remains entangled in proprietary confines, stifling innovation. These silos often lead organizations down a maze of expensive, convoluted systems that challenge comprehension. But we envision a different path.

**Glossia is spearheading change.** We champion **openness**, crafting our innovations with the world watching and inviting all to contribute. This inclusive approach harnesses a tapestry of diverse thoughts and the electric energy of a passionate community eager to redefine the industry. We're delving deep, **reimagining the foundational translation memory, exploring its AI-driven evolution for more intuitive designs.** *Our goal?* A system that's both simplified and potent, seamlessly integrating with content-rich platforms across the web, from [Shopify](https://shopify.com) to [Canva](https://canva.com). At Glossia, we're all in on AI, championing a universally accessible future of localization. Join us on this journey.

## Flavors

This repository contains **multiple flavors of Glossia licensed under different licenses.** The following table shows the different flavors and their licenses:

- **Cloud:** This is the version of Glossia hosted at [glossia.ai](https://glossia.ai). This version includes the proprietary code under `lib/cloud` and can't be self-hosted. Doing so implies a violation of the license.
- **Community:** This is a community version of Glossia that can be self-hosted to continuously localize content from GitHub and GitLab repositories. This version is licensed under AGPLv3 and distributed through the [GitHub Packages Registry](https://github.com/glossia/glossia/pkgs/container/community) as a Docker image.
- **Enterprise:** This is a version of Glossia with enterprise features that can be self-hosted to continuously localize content from multiple sources and using adaptative context. It's also distributed through the [GitHub Packages Registry](https://github.com/glossia/glossia/pkgs/container/community), and hosting it requires having an enterprise license.

## Development

Glossia's tech stack is based on [Elixir](https://elixir-lang.org) and [Phoenix](https://phoenixframework.org) to ease scalability and eliminate layers of complexity that are common in other languages. All the components of Glossia are contained in this repository and are part of the Phoenix project (e.g., documentation, website, web app, API).

To contribute to the project locally:

1. Clone the repository: `git clone https://github.com/glossia/glossia.git`
2. Make sure you have [PostgreSQL](https://www.postgresql.org/) running in your system.
2. Install [Mise](https://mise.jdx.dev/) and run `mise install`.
3. Set up the project environment with `mix setup`.
4. Run `mix phx.server`

`mix phx.server` will start an HTTP server locally.