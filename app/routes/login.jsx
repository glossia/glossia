import { cn } from "../lib/utils.js";
import { Label } from "../components/ui/label.js";
import { Input } from "../components/ui/input.js";
import { Button } from "../components/ui/button.js";
import { Form } from "@remix-run/react";
import {Icons} from '../components/ui/icons.js'

export const meta = () => {
  return [
    { title: "Sign in - Glossia" },
    { name: "description", content: "Authenticate with Glossia to access the tools to localize your projects." },
  ];
};

export default function Login() {
  return (
    <div className={cn("w-full h-screen flex flex-col justify-center items-center")}>
      <div className={cn("grid gap-6 w-96 bg-white p-10")}>
        <h1 className="text-2xl font-semibold tracking-tight text-center">Sign in on Glossia</h1>
        <p className="text-sm text-muted-foreground">The authentication with email is not supported yet. Please use GitHub.</p>
        <Form>
          <div className="grid gap-2">
            <div className="grid gap-1">
              <Label className="sr-only" htmlFor="email">
                Email
              </Label>
              <Input id="email" placeholder="hello-world@glossia.io" type="email" autoCapitalize="none" autoComplete="email" autoCorrect="off" disabled={true} />
            </div>
            <Button>Sign In with Email</Button>
          </div>
        </Form>
        <Form action="/auth/github" method="post">
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-background px-2 text-muted-foreground">Or continue with</span>
            </div>
          </div>
          <Button variant="outline" className="w-full mt-5">
            <Icons.gitHub className="mr-2 h-4 w-4" />
            Github
          </Button>
        </Form>
      </div>
    </div>
  );
}
