import { promises as fs } from "node:fs";
import path from "node:path";
import matter from "gray-matter";

const blogDir = path.join(process.cwd(), "site", "_content", "blog");

export default async function () {
  const entries = await fs.readdir(blogDir);
  const files = entries.filter((name) => name.endsWith(".md")).sort().reverse();
  const posts = [];
  for (const file of files) {
    const raw = await fs.readFile(path.join(blogDir, file), "utf8");
    const parsed = matter(raw);
    posts.push({
      slug: file.replace(/\.md$/, ""),
      ...parsed.data,
      body: parsed.content,
    });
  }
  return posts;
}
