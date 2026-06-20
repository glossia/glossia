import markdownIt from "markdown-it";
import markdownItAttrs from "markdown-it-attrs";
import nunjucks from "nunjucks";

export default function (eleventyConfig) {
  const md = markdownIt({
    html: true,
    linkify: false,
    typographer: false,
  }).use(markdownItAttrs, { leftDelimiter: "{:", rightDelimiter: ":}" });

  eleventyConfig.setLibrary("md", md);

  const njkEnv = new nunjucks.Environment(null, { autoescape: false });

  eleventyConfig.addFilter("specBody", function (value) {
    const rendered = njkEnv.renderString(value || "", this.ctx || {});
    return md.render(rendered);
  });
  eleventyConfig.addFilter("renderNunjucks", function (value) {
    return njkEnv.renderString(value || "", this.ctx || {});
  });

  eleventyConfig.addPassthroughCopy({ "site/assets": "assets" });
  eleventyConfig.addPassthroughCopy({ "site/assets/favicon.ico": "favicon.ico" });
  eleventyConfig.addPassthroughCopy({ "site/assets/apple-touch-icon.png": "apple-touch-icon.png" });
  eleventyConfig.addPassthroughCopy({ schemas: "schemas" });
  eleventyConfig.addPassthroughCopy({ examples: "examples" });
  eleventyConfig.addPassthroughCopy({ "L10N.md": "L10N.md" });

  eleventyConfig.addFilter("prettyJson", (value) => JSON.stringify(value, null, 2));
  eleventyConfig.addFilter("markdownify", (value) => md.render(value || ""));

  return {
    dir: {
      input: "site",
      includes: "_includes",
      data: "_data",
      output: "_site",
    },
    htmlTemplateEngine: "njk",
    markdownTemplateEngine: "njk",
    templateFormats: ["njk", "md", "html"],
  };
}
