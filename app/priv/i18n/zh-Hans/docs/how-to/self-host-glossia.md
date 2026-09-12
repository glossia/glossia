%{
  title: "自托管 Glossia",
  summary: "使用配套 Helm 图表在您的 Kubernetes 集群上安装 Glossia，使团队能够在自有基础设施上运行语言操作系统。",
  category: "操作指南",
  order: 2
}
---
Glossia 在以下开源协议下 [O'Saasy 许可证](https://github.com/glossia/glossia/blob/main/LICENSE.md). 您可以自行托管、修改它，并用于组织的内部使用。该许可唯一不允许的是将其作为托管或 SaaS 产品提供给第三方，以与 glossia.ai 上的托管服务竞争。

本指南将引导您从零 Kubernetes 集群到运行中的 Glossia 实例。

## 开始之前

您需要：

- 一个可以安装 Helm 图表的 Kubernetes 集群（v1.28 或更新版本）
- `helm` 和 `kubectl` 本地
- 一个您可以指向集群入口的域名
- 用于身份验证的 OpenID Connect 提供程序或 SMTP 中继（Glossia 同时支持两者）

Helm 图表包含 Postgres（通过 [CloudNativePG](https://cloudnative-pg.io/)) 以及 ClickHouse（经由 [官方操作器](https://github.com/ClickHouse/clickhouse-operator)) 因此您无需外部数据库。若您更愿意自带，两者可在中禁用。 `values.yaml`.

## 安装 Operators

安装与计划启用的组件匹配的 Operators。至少需要：

- [CloudNativePG Operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 用于应用数据库
- [ClickHouse Kubernetes Operator](https://github.com/ClickHouse/clickhouse-operator) 用于分析数据库
- 一个入口控制器（例如 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 若需自动 TLS

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

创建一个 Kubernetes 密钥名为 `glossia-app-env` 至少包含以下密钥：

| 密钥 | 用途 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 会话签名密钥 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 令牌保护 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 基本认证的 `/ops` 仪表盘 |
| `RELEASE_COOKIE` | 每个容器共享的 Erlang 分布 Cookie |
| `GLOSSIA_SMTP_*` | 出站邮件设置 |

您可以直接配置这些，使用 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 或将图表连接到您的密钥管理器，通过 [External Secrets Operator](https://external-secrets.io/) 图表 README 中描述的集成。

## 图表中包含的内容

- Glossia Web 应用
- Postgres（用于应用数据，可选，默认开启）
- ClickHouse（用于分析，可选，默认开启）
- 翻译任务的背景工作进程，它们作为 Kubernetes Jobs 运行，从而在滚动部署期间持续存活

## 接下来去哪里

- 该 [Helm 图表 README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 包含每个值的完整参考，以及有关备份、对象存储和可观测性的说明。
- [配置模型提供商](/docs/how-to/configure-a-model-provider) 实例运行后，翻译任务即可调用 LLM。
- 报告问题或提出改进建议于 [GitHub 仓库](https://github.com/glossia/glossia).