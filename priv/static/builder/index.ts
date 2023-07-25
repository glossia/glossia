import { createAppsignalClient } from "https://deno.land/x/appsignal@v1.0.1/mod.ts";

const appSignalApiKey = Deno.env.get("GLOSSIA_APP_SIGNAL_API_KEY");
let sendErrorReport: any = () => {};
if (appSignalApiKey) {
  sendErrorReport = createAppsignalClient(
    "3c3e56f0-efca-42c6-adfa-82d1644557a0",
    "deno",
  );
}

try {
  const glossiaTranslationId = Deno.env.get("GLOSSIA_TRANSLATION_ID");
  console.log(`Translating ${glossiaTranslationId}`);
} catch (err) {
  await sendErrorReport(err, {});
}
