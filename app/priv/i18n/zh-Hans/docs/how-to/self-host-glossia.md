%{
  title: "自托管 Glossia",
  summary: "使用配套 Helm 图表在您的 Kubernetes 集群中安装 Glossia，让您的团队在自身基础设施上运行语言操作系统。",
  category: "教程",
  order: 2
}
---
Glossia 以 [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). 您可以自行托管、修改它，并用于组织内部。许可证唯一不允许的是向第三方提供与 glossia.ai 上的托管服务竞争的托管或 SaaS 产品。

本指南将帮助您从空 Kubernetes 集群部署至运行中的 Glossia 实例。

## 开始之前

您需要：

- 一个可以安装 Helm 图表的 Kubernetes 集群 (v1.28 或更新)
- `helm` 和 `kubectl` 本地
- 指向集群 Ingress 的域名
- 用于身份验证的 OpenID Connect 提供商或 SMTP 中继（Glossia 同时支持两者）

Helm Chart 打包了 Postgres (通过 [CloudNativePG](https://cloudnative-pg.io/)) 和 ClickHouse (通过 [官方 Operator](https://github.com/ClickHouse/clickhouse-operator)) 这样您就不需要外部数据库了。如果您更愿意自备，两者均可在...中禁用 `values.yaml`.

## 安装操作符

安装与您计划启用的组件匹配的操作符。至少需要：

- [CloudNativePG 操作符](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 用于应用数据库
- [ClickHouse Kubernetes 操作符](https://github.com/ClickHouse/clickhouse-operator) 用于分析数据库
- 一个入口控制器（例如 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 如果希望启用自动 TLS

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

创建一个 Kubernetes 密钥名为 `glossia-app-env` 至少具有以下键：

| 键 | 用途 |
| --- | |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 会话签名密钥 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 令牌保护 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 基本认证用于 `/ops` 仪表盘 |
| `RELEASE_COOKIE` | 每个 Pod 共享的 Erlang 分布式 Cookie |
| `GLOSSIA_SMTP_*` | 出站邮件设置 |

您可以直接配置这些，使用 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 或通过您的密钥管理器连接图表 [External Secrets Operator](https://external-secrets.io/) 图表 README 中描述的集成。

## 图表中包含了什么

- Glossia Web 应用
- 用于应用数据的 Postgres（可选，默认启用）
- 用于分析数据的 ClickHouse（可选，默认启用）
- 翻译任务的后台工作进程，它们以 Kubernetes Jobs 运行，因此能在滚动更新后继续存活。

## 下一步去哪里

- 该 [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 包含每个值的完整参考，以及关于备份、对象存储和可观测性的说明。
- [配置模型提供商](/docs/how-to/configure-a-model-provider) 一旦实例运行，以便翻译可以调用 LLM。
- 报告问题或提出改进建议在 [GitHub 仓库](https://github.com/glossia/glossia).