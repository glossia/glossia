import { redirect } from "@remix-run/node";
import { authenticator } from "../accounts/auth/authenticator.server.js";

export async function loader() {
  return redirect("/login");
}

export async function action({ request }) {
  return authenticator.authenticate("github", request);
}
