%{
  title: "命令",
  summary: "Glossia 所有命令行命令及其标志的参考说明。",
  category: "reference",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

在当前仓库中创建一个初始 `GLOSSIA.md` 配置文件。

```bash
glossia init
```

如果 `GLOSSIA.md` 已存在，则操作失败。

## 翻译在服务器端执行

翻译在 Glossia 服务器上运行，而非在命令行界面中运行。提交合入后，Glossia 会根据您的 `GLOSSIA.md` 文件规划工作，使用您账户中配置的模型翻译每个文件，并创建包含翻译结果的拉取请求。您可以在翻译会话页面实时查看每个文件以及模型的各轮交互。

模型按文档选择：如果 `GLOSSIA.md` `model:` 指定了您账户中的某个模型句柄，则使用该模型；否则使用您账户的默认模型。

命令行界面有意不提供规划、翻译、验证、检查或删除已生成翻译的功能，也不会读取服务器的翻译锁定文件。

## `glossia revisit`

保留用于未来的源语言修订流程。Rust 命令行界面目前会对此命令返回“尚未实现”错误。

```bash
glossia revisit
```

## 全局标志

| 标志 | 描述 |
|---|---|
| `--path <PATH>` | 覆盖项目根目录 |
| `--no-color` | 禁用彩色输出 |