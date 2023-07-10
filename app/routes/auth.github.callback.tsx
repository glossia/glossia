import type { LoaderArgs } from "@remix-run/node";
import { authenticator } from "../accounts/auth/authenticator.server.js";

export async function loader({ request }: LoaderArgs) {
  return authenticator.authenticate("github", request, {
    successRedirect: "/",
    failureRedirect: "/login",
  });
}
