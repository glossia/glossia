import { createCookieSessionStorage } from "@remix-run/node";
import { getSessionCookieSalt, isProduction } from '../../lib/environment.js'

export let sessionStorage = createCookieSessionStorage({
  cookie: {
    name: "_session",
    sameSite: "lax",
    path: "/",
    httpOnly: true,
    secrets: [getSessionCookieSalt()],
    secure: isProduction(),
  },
});

export let { getSession, commitSession, destroySession } = sessionStorage;
