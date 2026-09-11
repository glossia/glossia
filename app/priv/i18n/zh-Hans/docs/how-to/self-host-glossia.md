%{
  title: "自托管 Glossia",
  summary: "使用配套 Helm chart 在您自己的 Kubernetes 集群上部署 Glossia，让您的团队在自己的基础设施上运行语言操作系统。",
  category: "教程",
  order: 2
}
---
Glossia 遵循 [O'Saasy 许可证](https://github.com/glossia/glossia/blob/main/LICENSE.md)。

本指南帮助您从零 Kubernetes 集群起步，运行一个 Glossia 实例。

## 开始之前

您需要：

- 一个可以部署 Helm charts 的 Kubernetes 集群 (v1.28 或更高)
- `helm` 和 `kubectl` 本地
- 您可以指向集群入口的域名
- 用于身份验证的 OpenID Connect 提供商或 SMTP 中继（Glossia 同时支持两者）

Helm 图表捆绑了 Postgres（通过 [CloudNativePG](https://cloudnative-pg.io/)) 以及 ClickHouse（通过该 [官方操作符](https://github.com/ClickHouse/clickhouse-operator)) 因此您无需外部数据库。如果您更愿意自备，两者亦可在此禁用 `values.yaml`.

## 安装控制器

安装与您计划启用组件相匹配的控制器。至少需要：

- [CloudNativePG 控制器](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 用于应用数据库
- [ClickHouse Kubernetes 控制器](https://github.com/ClickHouse/clickhouse-operator) 用于分析数据库
- Ingress 控制器（例如 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 如果您希望自动 TLS

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

创建名为的 Kubernetes 密钥 `glossia-app-env` 至少包含以下密钥：

| 键 | 用途 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 会话签名密钥 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer Token 防护 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth 用于 `/ops` 仪表板 |
| `RELEASE_COOKIE` | Erlang 分发 cookie 由每个 pod 共享 |
| `GLOSSIA_SMTP_*` | 出站邮件设置 |

您可以直接配置这些，使用 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 或通过将图表与您的密钥管理器经由 [External Secrets Operator](https://external-secrets.io/) 在图表 README 中描述的集成。

## 图表包含了什么

- Glossia Web 应用程序
- 用于应用程序数据的 Postgres（可选，默认开启）
- 用于分析数据的 ClickHouse（可选，默认开启）
- 用于翻译任务的后台工作进程，它们以 Kubernetes Jobs 的形式运行，因此能在滚动部署后继续运行

## 接下来去哪里

- 该 [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 包含每个值的完整参考，以及有关备份、对象存储和可观测性的说明。
- [配置模型提供商](/docs/how-to/configure-a-model-provider) 在实例运行之后，以便翻译任务可以调用 LLM。
- 报告问题或提出改进建议在 [GitHub 仓库](https://github.com/glossia/glossia).