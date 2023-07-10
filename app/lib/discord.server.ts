import { fetch } from "@remix-run/node";
import crypto from "node:crypto"
import { isProduction } from "./environment";

type DiscordMessagePayloadEmbedField = {
  name: string
  value: string
  inline: boolean
}

type DiscordMessagePayloadEmbedThumbnail = {
  url: string
}

type DiscordMessagePayloadEmbed = {
  author?: {
    name?: string
    url?: string
    icon_url?: string
  },
  title?: string
  url?: string
  description?: string
  fields?: DiscordMessagePayloadEmbedField[]
  thumbnail?: DiscordMessagePayloadEmbedThumbnail
}

type DiscordMessagePayload = {
  content?: string
  embeds?: DiscordMessagePayloadEmbed[]
}

export async function sendDiscordMessage(payload: DiscordMessagePayload) {
  if (!isProduction()) { return }
  const url = "https://discord.com/api/webhooks/1126573247551512598/VDiIWvSQL8U1mu5uBadm5qJBIaNnESed1F7mbN32GYzluAP1IKG7A-WRuk-jIY1KsMbZ";
  const response = await fetch(url, { method: 'POST', body: JSON.stringify(payload), headers: {"content-type": "application/json"}})
  console.log(await response.json())
}

export async function sendDiscordAuthenticatedMessage(email: string) {
  await sendDiscordMessage({
    content: 'A new user authentiacted',
    embeds: [{
      fields: [
        {
          name: "Email",
          inline: true,
          value: email
        }
      ],
      thumbnail: {
        url: getGravatarUrl(email)
      }
    }]
  })
}

function getGravatarUrl(email: string) {
  let trimmedEmail = email.trim().toLowerCase();
  let hash = crypto.createHash('md5').update(trimmedEmail).digest('hex');
  return `https://www.gravatar.com/avatar/${hash}`;
}
