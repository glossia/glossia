%{
  title: "自托管 Glossia",
  summary: "使用随附的 Helm Chart，在您的 Kubernetes 集群上安装 Glossia，让您的团队在自己的基础设施上运行语言操作系统。",
  category: "教程",
  order: 2
}
---
Glossia 是开源的，采用 [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md).您可以自行托管、修改并运行它供组织内部使用。许可证唯一禁止的是将其作为与 glossia.ai 上的托管服务竞争的托管或 SaaS 产品提供给第三方。

本指南将帮助您从一个空的 Kubernetes 集群部署到一个运行中的 Glossia 实例。

## 开始之前

您需要：

- 一个可以部署 Helm Chart 的 Kubernetes 集群（v1.28 或更新版本）
- `helm` 以及 `kubectl` 本地
- 一个可以指向集群入口的域名
- 用于身份验证的 OpenID Connect 提供商或 SMTP 中继（Glossia 同时支持两者）

Helm Chart 打包了 Postgres（通过 [CloudNativePG](https://cloudnative-pg.io/))、ClickHouse（通过 [官方 operator](https://github.com/ClickHouse/clickhouse-operator)) 这样您就不需要外部数据库。如果您更喜欢自带，两者均可禁用 `values.yaml`.

## 安装控制器

安装与计划启用的组件相匹配的控制器。至少需要：

- [CloudNativePG 控制器](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 用于应用数据库
- [ClickHouse Kubernetes 控制器](https://github.com/ClickHouse/clickhouse-operator) 用于分析数据库
- 一个入口控制器（例如 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 如果希望自动启用 TLS

## 安装 Glossia 图表

克隆代码库，然后安装图表：

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

创建一个名为的 Kubernetes 密钥 `glossia-app-env` 至少需包含以下密钥：

| 密钥 | 用途 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 会话签名密钥 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | 凭证令牌防护 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 基本认证 用于 `/ops` 仪表板 |
| `RELEASE_COOKIE` | 每个 Pod 共享的 Erlang 分布式 Cookie |
| `GLOSSIA_SMTP_*` | 出站邮件设置 |

您可以直接配置这些，使用 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 或将图表连接到您的密钥管理工具，通过 [External Secrets Operator](https://external-secrets.io/) 图表 README 中描述的集成。

## 图表中包含的内容

- Glossia 网页应用
- 用于应用数据的 PostgreSQL (可选，默认开启)
- 用于分析的 ClickHouse (可选，默认开启)
- 处理翻译任务的后台作业，以 Kubernetes Jobs 形式运行，从而能跨越滚动部署周期

## 下一步去哪里

- 该 [Helm 图表 README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 包含每个值的完整参考，以及关于备份、对象存储和可观测性的说明。
- [配置模型提供商](/docs/how-to/configure-a-model-provider) 一旦实例开始运行，以便翻译作业可以调用 LLM。
- 在此处报告问题或提出改进建议 [GitHub 仓库](https://github.com/glossia/glossia).