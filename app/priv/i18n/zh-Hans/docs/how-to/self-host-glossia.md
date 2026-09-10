%{
  title: "自托管 Glossia",
  summary: "在您的 Kubernetes 集群上使用内置的 Helm chart 安装 Glossia，以便您的团队在自己的基础设施上运行语言操作系统。",
  category: "指南",
  order: 2
}
---
Glossia 在以下开源许可下是开源的， [O'Saasy 许可](https://github.com/glossia/glossia/blob/main/LICENSE.md)。您可以自托管它、修改它，并用于您组织的内部用途。许可不允许的唯一事项是将其以托管或与 glossia.ai 托管服务竞争的 SaaS 产品形式提供给第三方。

本指南可以帮助您从零开始 Kubernetes 集群到运行中的 Glossia 实例。

## Before you start

您需要：

- 一个可以安装 Helm 图表的 Kubernetes 集群 (v1.28 或更新版本)
- `helm` 和 `kubectl` 本地
- 一个指向集群入口的域名
- 用于认证的 OpenID Connect 提供商或 SMTP 中继（Glossia 同时支持两者）

该 Helm chart 包含 Postgres（通过 [CloudNativePG](https://cloudnative-pg.io/)) 和 ClickHouse (通过 [官方算子](https://github.com/ClickHouse/clickhouse-operator)) 因此您不需要外部数据库了。如果您更愿意自备，两者均可以在 `values.yaml`.

## 安装操作符

安装与计划启用的组件相匹配的操作符。至少需要：

- [CloudNativePG 操作符](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 用于应用数据库
- [ClickHouse Kubernetes 操作符](https://github.com/ClickHouse/clickhouse-operator) 用于分析数据库
- 一个 Ingress 控制器（例如 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 如果你想要自动 TLS

## 安装 Glossia 图表

克隆仓库，然后安装图表：

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## 提供应用密钥

创建一个名为的 Kubernetes Secret `glossia-app-env` 至少包含这些键：

| 键名 | 用途 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 会话签名密钥 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 令牌保护 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 基本认证用于 `/ops` 仪表板 |
| `RELEASE_COOKIE` | 每个 Pod 共享的 Erlang 分发 Cookie |
| `GLOSSIA_SMTP_*` | 出站邮件设置 |

您可以直接配置这些，使用 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 或通过将其与您的密钥管理器集成，经由 [External Secrets Operator](https://external-secrets.io/) 图表 README 中描述的集成。

## 图表中包含的内容

- Glossia Web 应用程序
- Postgres 用于应用数据（可选，默认启用）
- ClickHouse 用于分析（可选，默认启用）
- 翻译作业的背景工作者，它们作为 Kubernetes Jobs 运行，因此能在滚动部署期间持续运行。

## 下一步去哪里

- 这个 [Helm Chart 说明文档](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 拥有所有值的完整参考，以及关于备份、对象存储和可观察性的说明。
- [配置模型提供者](/docs/how-to/configure-a-model-provider) 一旦实例运行，翻译即可调用 LLM。
- 在...处报告问题或提出改进建议 [GitHub 仓库](https://github.com/glossia/glossia).