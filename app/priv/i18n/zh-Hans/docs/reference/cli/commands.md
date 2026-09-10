%{title: "命令", summary: "所有 Glossia 命令行命令及其参数的参考。", category: "参考", subcategory: "命令行", order: 1}
---
## `glossia init`

创建一个起始`L10N.md`配置文件在当前仓库中。

```bash
glossia init
```

如果`L10N.md`已存在。

## 翻译由服务器执行

翻译在 Glossia 服务器上运行，而非在命令行界面中。当提交抵达时，
Glossia 根据您的`L10N.md`files, translates each file with
account's configured model, and opens a pull request with the results. You
can watch each file and the model's turns live on the translation session page.

The model is chosen per document: a `L10N.md` `model:` naming one of your@the
 account model handles selects it; otherwise your account's default model is used.

The command-line interface intentionally does not plan, translate, validate,
inspect, or delete generated translations. It also does not read the server's
translation lockfiles.

## `glossia revisit`

Reserved for a future source-language revision pass. The Rust command-line
interface currently returns a not-implemented error for this command.

```bash
glossia revisit
```

## 全局标志

| 标志 | 描述 |
|---|---|
| `--path <PATH>` | 覆盖项目根目录 |
| `--no-color` | 禁用彩色输出 |