export const versionDirectoryPattern = /^v(\d+(?:\.\d+)*)$/;

export function directoryNameToVersion(name) {
  const match = versionDirectoryPattern.exec(name);
  return match ? match[1] : null;
}

export function compareVersionsDesc(left, right) {
  const leftParts = left.split(".").map(Number);
  const rightParts = right.split(".").map(Number);
  const length = Math.max(leftParts.length, rightParts.length);

  for (let index = 0; index < length; index += 1) {
    const leftPart = leftParts[index] ?? 0;
    const rightPart = rightParts[index] ?? 0;

    if (leftPart !== rightPart) {
      return rightPart - leftPart;
    }
  }

  return 0;
}
