%{title: "命令", summary: "所有 Glossia 命令行命令及其参数的参考。", category: "参考", subcategory: "CLI", order: 1}
---
## `glossia init`

创建一个起家家 `GLOSSIA.md`配置文件于当前仓库。

```bash
glossia init
```

如果 `GLOSSIA.md`已存在，将失败。

## 译工作运行于服务端

译工作在 Glossia 服务器上执行，而非在命令行界面。
当提交被接受时，`GLOSSIA.md`Glossia 根据您的 
文件规划工作，使用您的账户配置的模型翻译每个文件，并创建拉取请求包含结果。您将
可以在翻译会话页面查看每个文件及模型的交互历史。

模型根据文档选择：`GLOSSIA.md` `model:`命名您的
账户模型之一；否则使用您账户的默认模型。

命令行界面 intentionally 不规划、翻译、验证、
检查或删除生成的翻译。它也不会读取服务器的
翻译锁文件。

## `glossia revisit`

保留用于未来的源语言修订流程。Rust 命令行
接口当前对此命令返回未实现错误。

```bash
glossia revisit
```

## 全局标志

| 标志 | 说明 |
|---|---|
| `--path <PATH>` | 覆盖项目根目录 |
| `--no-color` | 禁用彩色输出 |