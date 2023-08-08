import { getAccessToken, getURL } from "./environment.ts";

type FetchParameters = Parameters<typeof fetch>;

export async function glossiaFetch<T>(
  path: string,
  init?: FetchParameters[1],
): Promise<T> {
  const absoluteURL = new URL(path, getURL());
  console.info("Sending requests to Glossia", absoluteURL.toString());
  const jsonResponse = await fetch(absoluteURL.toString(), {
    ...init,
    headers: {
      ...init?.headers,
      "content-type": "application/json",
      "authorization": `Bearer ${getAccessToken()}`,
    },
  });
  const jsonData = await jsonResponse.json();
  console.info("Glossia responded", {
    status: jsonResponse.status,
    body: jsonData,
  });
  return jsonData;
}
