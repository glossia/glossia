import { createAppsignalClient } from "https://deno.land/x/appsignal@v1.0.1/mod.ts";

const appSignalApiKey = Deno.env.get("GLOSSIA_APP_SIGNAL_API_KEY");
const apiKey = Deno.env.get("GLOSSIA_API_KEY");

let sendErrorReport: any = () => {};
if (appSignalApiKey) {
  sendErrorReport = createAppsignalClient(appSignalApiKey, "deno");
}

try {
  const glossiaTranslationId = Deno.env.get("GLOSSIA_TRANSLATION_ID");
  console.log(`Translating ${glossiaTranslationId}`);
} catch (err) {
  await sendErrorReport(err, {});
}
