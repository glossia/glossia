import { getAccessToken, getURL } from "./environment.ts";

type FetchParameters = Parameters<typeof fetch>;

export async function glossiaFetch<T>(
  path: string,
  init?: FetchParameters[1],
): Promise<T> {
  const absoluteURL = new URL(path, getURL());
  console.info("Sending requests to Glossia", absoluteURL.toString());
  const response = await fetch(absoluteURL.toString(), {
    ...init,
    headers: {
      ...init?.headers,
      "content-type": "application/json",
      "authorization": `Bearer ${getAccessToken()}`,
    },
  });
  const text = await response.text();

  let jsonData;
  try {
    jsonData = JSON.parse(text);
  } catch (error) {
    console.error(
      "Error parsing JSON response from Glossia",
      text,
    );
    throw error;
  }
  console.info("Glossia responded", {
    status: response.status,
    body: jsonData,
  });
  return jsonData;
}
