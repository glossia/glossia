export type Result<T, E> = { success: T } | { failure: E };

export function isSuccess<T, E>(result: Result<T, E>): boolean {
  // TODO: Add compile-time checks to be able to do if (isSuccess(result)) { .... }
  return true;
}

export function isFailure<T, E>(result: Result<T, E>): boolean {
  // TODO: Add comnpile-time checks here too.
  return true;
}
