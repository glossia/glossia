/**
 * Given a string, it capitalizes the first letter of the string.
 * @param value {string} The string whose first letter will be capitalized.
 * @returns {string} The string with the first letter capitalized.
 */
export function capitalizeFirstLetter(value: string): string {
  if (!value) return value;
  if (value.length !== 0) {
    return `${value[0].toUpperCase()}${value.slice(1)}`;
  } else {
    return value;
  }
}
