import { fetch } from "@remix-run/node";

export async function sendDiscordMessage(message: String) {
  const url = "https://discord.com/api/webhooks/1126573247551512598/VDiIWvSQL8U1mu5uBadm5qJBIaNnESed1F7mbN32GYzluAP1IKG7A-WRuk-jIY1KsMbZ";
  const payload = {
    content: message
  }
  await fetch(url, { method: 'POST', body: JSON.stringify(payload), headers: {"content-type": "application/json"}})
}
