/**
 * It returns an object that implements the `Deno.Env` interface to inject it from tests to mock the
 * environment.
 *
 * @param env {env} An object representing the environment where the keys are the names of the environment variables and the values the values.
 * @returns An environment that implements the `Deno.Env` interface.
 */
export function getMockedEnv(env: { [variable: string]: string }): Deno.Env {
  const map = new Map<string, string>();
  Object.entries(env).forEach((entry) => {
    map.set(entry[0], entry[1]);
  });
  return new MockEnv(map);
}

class MockEnv implements Deno.Env {
  private env: Map<string, string>;
  constructor(env: Map<string, string>) {
    this.env = env;
  }
  get(key: string): string | undefined {
    return this.env.get(key);
  }
  set(key: string, value: string): void {
    this.env.set(key, value);
  }
  delete(key: string): void {
    this.env.delete(key);
  }
  has(key: string): boolean {
    return this.env.has(key);
  }
  toObject(): { [index: string]: string } {
    return Object.fromEntries(this.env);
  }
}
