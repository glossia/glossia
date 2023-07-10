import { Authenticator } from "remix-auth";
import { sessionStorage } from "./session-storage.server.js";
import { User } from "./user.js";

export let authenticator = new Authenticator<User>(sessionStorage);
