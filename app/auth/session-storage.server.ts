import { createCookieSessionStorage } from "@remix-run/node";
import { getSessionCookieSalt } from '../lib/environment.js'

export let sessionStorage = createCookieSessionStorage({
  cookie: {
    name: "_session",
    sameSite: "lax",
    path: "/",
    httpOnly: true,
    secrets: [getSessionCookieSalt()],
    secure: process.env.NODE_ENV === "production",
  },
});

export let { getSession, commitSession, destroySession } = sessionStorage;
