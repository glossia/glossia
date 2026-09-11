%{
  title: "自托管 Glossia",
  summary: "使用内置的 Helm Chart 在您的 Kubernetes 集群上安装 Glossia，让您的团队能够在自有基础设施上运行语言操作系统。",
  category: "操作指南",
  order: 2
}
---
Glossia 在 [“O'Saasy License”](https://github.com/glossia/glossia/blob/main/LICENSE.md)。您可以自行托管它，修改它，并为组织的内部用途运行它。该许可不允许的唯一事项是将其作为托管或 SaaS 产品提供给第三方，与 gistia.ai 上的托管服务竞争。

本指南帮助您从零开始的 Kubernetes 集群部署至运行中的 Glossia 实例。

## 开始之前

您需要：

- 您可以安装 Helm 图表的 Kubernetes 集群（v1.28 或更新版本）
- `helm` 以及 `kubectl` 本地
- 一个您可以指向集群入口的域名
- 用于身份验证的 OpenID Connect 提供商或 SMTP 中继（Glossia 均支持）

Helm chart 包含 Postgres（通过 [CloudNativePG](https://cloudnative-pg.io/)) 和 ClickHouse (通过 [官方 operator](https://github.com/ClickHouse/clickhouse-operator)) 因此您无需外部数据库。如果您更愿意自带，两者均可在 `values.yaml`。”

## 安装控制器

安装与您计划启用的组件相匹配的控制器。至少：

- [CloudNativePG 控制器](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 用于应用数据库
- [ClickHouse Kubernetes 控制器](https://github.com/ClickHouse/clickhouse-operator) 用于分析数据库
- 一个 Ingress 控制器（例如 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 如希望自动 TLS

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

创建一个名为的 Kubernetes Secret `glossia-app-env` 至少包含以下键：

| 键 | 用途 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 会话签名密钥 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 令牌保护 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 基本认证的 `/ops` 仪表板 |
| `RELEASE_COOKIE` | 每个 Pod 共享的 Erlang 分布式 Cookie |
| `GLOSSIA_SMTP_*` | 外部邮件设置 |

您可以直接配置这些，使用 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)，或将图表连接至您的密钥管理器，通过 [External Secrets Operator](https://external-secrets.io/) ，图表 README 中描述的集成。

## 图表中运行的内容

- Glossia Web 应用程序
- 用于应用数据的 Postgres（可选，默认开启）
- 用于分析的 ClickHouse（可选，默认开启）
- 翻译任务的后台工作进程，以 Kubernetes Jobs 的方式运行，以便它们在滚动部署期间继续存活

## 下一步去哪里

- 该 [Helm 图表 README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 包含每个值的完整参考，以及关于备份、对象存储和可观测性的说明。
- [配置模型提供商](/docs/how-to/configure-a-model-provider) 以便实例运行后，翻译能够调用 LLM。
- 在此报告问题或提出改进建议 [GitHub 仓库](https://github.com/glossia/glossia).