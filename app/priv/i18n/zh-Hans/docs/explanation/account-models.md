%{title: "账户模型", summary: "为何模型提供商只需在每个账户中配置一次并通过句柄引用。", category: "说明", order: 2}
---
Glossia 将仓库指令与模型提供商凭证分开。仓库描述应翻译的内容，而账户决定使用哪个 [大型语言模型](https://en.wikipedia.org/wiki/Large_language_model) 执行工作。

## 为什么模型归属于账户

团队通常翻译多个具有相同提供商关系的仓库。账户级模型允许管理员在不修改每个仓库的情况下，轮换提供商密钥或一次性切换底层模型。

这一界限也能将凭证排除在版本控制之外。仓库包含可读的句柄，例如 `translation-default`，而是而非提供商密钥。

## 句柄提供稳定的意图

The `model` field in `L10N.md` refers to an account model handle:

```yaml
model: translation-default
```

这个句柄表达了仓库的意图。管理员可以在稍后更新该句柄选择的提供者模型，同时保持仓库配置稳定。

## How several models are used

Glossia uses one configured model for each document translation. Adding several models does not create an ensemble, a fallback chain, or an automatic quality tier. The repository author chooses their purpose through stable handles such as `translation-default`, `long-form`, or `japanese-specialist`.

选择遵循文档和目标语言的上下文层级：

1. 最近的 `L10N/<locale>.md` 声明语言的文件 `model` 对该语言生效。
2. 否则，最近的 `L10N.md` 声明语言的文件 `model` 对该目录生效。
3. 父级 `L10N.md` 当更近的文件未声明模型时，设置将被继承。
4. 当没有适用的上下文文件声明句柄时，Glossia 使用账户默认项。

必须配置明确的句柄。Glossia 会对未知句柄报告错误，而不是静默切换到账户默认项。

## 默认选择

项目设置需要在仓库拥有自己的之前 `L10N.md`。因此，Glossia 会使用账户默认项。向账户添加的第一个模型将成为默认模型，管理员可以从其设置页面将另一个模型设为默认模型。

一旦仓库拥有 `L10N.md`, 使用显式句柄可以让审查者清楚其选择。省略 `model` 保持仓库处于账户默认状态。

## 人工审查边界

模型输出为提议内容，而非自动合并。设置和翻译活动保留在 Glossia 中可见，而仓库变更通过拉取请求发布供团队审查。这保留了团队在代码中已使用的相同质量与所有权边界。