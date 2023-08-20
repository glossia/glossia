export type Result<T, E> = { success: T } | { failure: E };

/**
 * `isSuccess` is a user-defined type guard to check whether a given result instance
 * represents a success.
 * @param result {Result<T, E>} The result instance.
 * @returns {result is { success: T }} Whether the result instance represents a success.
 */
export function isSuccess<T, E>(
  result: Result<T, E>,
): result is { success: T } {
  return (result as { success: T }).success !== undefined;
}

/**
 * `isFailure` is a user-defined type guard to check whether a given result instance
 * represents a failure.
 * @param result {Result<T, E>} The result instance.
 * @returns {result is { failure: E }} Whether the result instance represents a failure.
 */
export function isFailure<T, E>(
  result: Result<T, E>,
): result is { failure: E } {
  return (result as { failure: E }).failure !== undefined;
}
