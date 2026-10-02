%{
  title: "Social images",
  summary: "Dashboard link previews, project branding, image updates, and availability.",
  category: "reference",
  section: "analytics",
  order: 30
}
---

Glossia generates social images for dashboard links on its hosted service.

## Link previews

Dashboard pages advertise a 1200 × 630 image through [Open Graph](https://ogp.me/) and Twitter large-image metadata. Sharing a link in a service that reads this metadata can display the preview. The sharing service decides when to fetch or refresh it.

Public projects include their name, section, and uploaded logo. Public accounts receive a section-specific preview. Private accounts and personal settings use generic Glossia branding.

## Project branding

Upload or replace the project's logo in Glossia to change the branding used in its public preview. Logos are limited to five million bytes, matching project uploads.

Private project information is not included in a public social-image preview. A preview does not grant access to the linked dashboard page.

## Image updates

Image addresses change when the displayed content, project logo, daily image version, or Glossia rendering implementation changes. A successful image can be cached for one day. Sharing services may retain their own cached preview, so replacing a logo does not guarantee an immediate update everywhere.

Glossia manages image generation, storage, fonts, and caching.

## Availability

| Result | Response |
|---|---|
| Image available | 200 |
| Invalid or expired image address | 404 |
| Image temporarily unavailable | 503, with a retry delay of 60 seconds |
| Request limit exceeded | 429, with a retry delay in the response |

If a preview is missing, open the dashboard page and share its current link. For a temporary failure, retry after the indicated delay. If the problem persists, contact Glossia support.
