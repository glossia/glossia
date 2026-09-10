%{
  title: "自托管 Glossia",
  summary: "使用随附的 Helm Chart，在您的 Kubernetes 集群上安装 Glossia，以便您的团队在自有基础设施上运行语言操作系统。",
  category: "教程",
  order: 2
}
---
Glossia 基于以下 [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md)。您可以自行托管它，修改它，并用于您组织的内部使用。该许可证不允许的唯一事项是将其作为托管或 SaaS 产品提供给第三方，从而与 glossia.ai 上的托管服务竞争。

本指南将您从空的 Kubernetes 集群引导至运行中的 Glossia 实例。

## 开始之前

您需要：

- 一个您可以在此安装 Helm charts 的 Kubernetes 集群（v1.28 或更新）
- `helm` 和 `kubectl` 本地
- 一个你可以指向集群入口的域名
- 用于身份验证的 OpenID Connect 提供商或 SMTP 中继（Glossia 同时支持两者）

Helm 图表打包了 Postgres（通过 [CloudNativePG](https://cloudnative-pg.io/)）和 ClickHouse（通过 [官方算子](https://github.com/ClickHouse/clickhouse-operator)）这样您就不需要外部数据库了。如果您更愿意自带，两者均可在 `values.yaml`.

## 安装 Operator

安装与您计划启用的组件相匹配的任何 Operator。至少需要：

- [CloudNativePG Operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 用于应用数据库
- [ClickHouse Kubernetes Operator](https://github.com/ClickHouse/clickhouse-operator) 用于分析数据库
- 一个 Ingress 控制器（例如 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 如果希望自动 TLS

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

创建 Kubernetes 密钥并命名 `glossia-app-env` 至少包含以下密钥：

| 密钥 | 用途 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 会话签名密钥 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | 授权令牌保护 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic 认证用于 `/ops` 仪表板 |
| `RELEASE_COOKIE` | 每个 Pod 共享的 Erlang 分布式 Cookie |
| `GLOSSIA_SMTP_*` | 出站邮件设置 |

您可以直接配置这些，使用 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 或将图表通过您的密钥管理器连接至 [External Secrets Operator](https://external-secrets.io/) 图表 README 中描述的集成。

## 图表中包含的内容

- Glossia 网页应用程序
- 用于应用数据的 Postgres（可选，默认启用）
- 用于分析的 ClickHouse（可选，默认启用）
- 翻译任务的背景工作进程，它们作为 Kubernetes Job 运行，因此其生命周期长于滚动部署

## 接下来去哪里

- 这个 [Helm 图表 README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 包含每个值的完整引用，以及关于备份、对象存储和可观测性的说明。
- [配置模型提供商](/docs/how-to/configure-a-model-provider) 一旦实例运行后即可调用 LLM 进行翻译
- 在以下处报告问题或提出改进建议 [GitHub 仓库](https://github.com/glossia/glossia).