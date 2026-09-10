%{
  title: "Glossia を自前でホスト",
  summary:
    "同梱された Helm チャートを使用して、自らの Kubernetes クラスターに Glossia をインストールし、チームが独自のインフラ上で言語 OS を運用できるようにします。",
  category: "使い方",
  order: 2
}
---
Glossia はライセンスの下でオープンソース [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md)。自身でホストしたり、修正したり、組織の内部利用のために実行することはできます。ライセンスが許可しておらず、glossia.ai のホストサービスと競合するホストまたは SaaS プロダクトを第三者に提供することです。

このガイドでは、空の Kubernetes クラスターから実行中の Glossia インスタンスに案内します。

## 開始する前に

必要なもの:

- Helm charts をインストールできる Kubernetes クラスター（v1.28 またはそれ以降）
- `helm` および `kubectl` ローカルで
- クラスターの Ingress に設定できるドメインです
- 認証用の OpenID Connect プロバイダーまたは SMTP リレーです（Glossia は両方に対応しています）

Helm チートは Postgres をバンドル（以下経由 [CloudNativePG](https://cloudnative-pg.io/)）と ClickHouse（以下経由の [公式オペレーター](https://github.com/ClickHouse/clickhouse-operator)）外部データベースは不要です。自前を持ち込もうとするなら、両方を無効にできます `values.yaml`.

## オペレーターのインストール

有効化する予定のコンポーネントに一致するオペレーターをインストールしてください。最低限：

- [CloudNativePG オペレーター](https://cloudnative-pg.io/documentation/current/installation_upgrade/) アプリケーションデータベース用
- [ClickHouse Kubernetes オペレーター](https://github.com/ClickHouse/clickhouse-operator) 分析データベース用
- Ingress コントローラー（例えば [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 自動 TLS を使用する場合は

## Glossia チャートをインストールします

リポジトリをクローンし、その後チャートをインストールします：

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## アプリのシークレットを指定

指定名前の Kubernetes シークレットを作成 `glossia-app-env` 少なくともこれらのキー：

| キー | 目的 |
| --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix セッション署名キー |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer token 保護 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth の `/ops` ダッシュボード |
| `RELEASE_COOKIE` | 各ポッドで共有される Erlang ディストリビューション・クッキー |
| `GLOSSIA_SMTP_*` | 送信メール設定 |

これらを直接設定でき、使用する [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), または、チャートをシークレットマネージャーに を介した [External Secrets Operator](https://external-secrets.io/) チャート README に記載されているインテグレーション。

## チャートに含まれる内容

- Glossia の Web アプリケーション
- Postgres（オプション、デフォルトでは有効）
- ClickHouse（オプション、デフォルトでは有効）
- 翻訳ジョブ用のバックグラウンドワーカーです。Kubernetes の Job として稼働するため、ロールアウトデプロイを超えても存続します。

## 次のステップ

- （本書の） [Helm チャートの README ファイル](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) には、各値の完全なリファレンス、バックアップ、オブジェクトストレージ、観測性に関するメモが含まれています。
- [モデルプロバイダーを設定する](/docs/how-to/configure-a-model-provider) インスタンスが稼働している状態では、翻訳で LLM を呼び出せるようにします。
- 不具合の報告や改善提案は以下に。 [GitHub リポジトリ](https://github.com/glossia/glossia).