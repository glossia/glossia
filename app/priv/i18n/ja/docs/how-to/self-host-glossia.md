%{
  title: "Glossia を自己ホストする",
  summary:
    "同梱の Helm チャートを使用し、独自の Kubernetes クラスタに Glossia をインストールすることで、チームが自前のインフラ上で言語 OS を稼働させることができます。",
  category: "ハウツー",
  order: 2
}
---
Glossia は、 [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). 組織の内部利用のために自己ホスティングし、変更し、実行することができます。ライセンスが許可しない唯一のことは、glossia.ai のホスティングサービスと競合するホスティングされたサービスまたは SaaS 製品として第三者に提供することです。

本ガイドでは、空の Kubernetes クラスターから動作する Glossia インスタンスへ導きます。

## 開始前に

必要なもの:

- Helm チャートをインストールできる Kubernetes クラスター (v1.28 以降)
- `helm` および `kubectl` ローカルに
- クラスタの ingress に設定できるドメイン
- 認証用の OpenID Connect プロバイダーまたは SMTP リレー (Glossia は両方に対応しています)

Helm チャートは Postgres をバンドルしています (via [CloudNativePG](https://cloudnative-pg.io/)) and ClickHouse (via the [official operator](https://github.com/ClickHouse/clickhouse-operator)) so you don't need external databases. If you'd rather bring your own, both can be disabled in `values.yaml`.

## 「オペレータ」のインストール

有効化対象のコンポーネントに一致するオペレータをインストールしてください。少なくとも、

- [CloudNativePG オペレータ](https://cloudnative-pg.io/documentation/current/installation_upgrade/) アプリケーションデータベース向け
- [ClickHouse Kubernetes オペレータ](https://github.com/ClickHouse/clickhouse-operator) アナリティクスデータベース向け
- Ingress コントローラ（例えば [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 自動 TLS を使いたい場合は

## Glossia チャートをインストールする

リポジトリをクローンし、次にチャートをインストールします：

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## アプリのシークレットを入力

指定名前の Kubernetes シークレットを作成 `glossia-app-env` これらのキーを少なくとも：

| キー | 目的 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix セッション署名キー |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer トークン保護 | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic 認証用 `/ops` ダッシュボード |
| `RELEASE_COOKIE` | 全ての Pod で共有される Erlang 配布クッキー |
| `GLOSSIA_SMTP_*` | メール送信設定 |

これらを直接設定してご使用できます。 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), またはチャートを秘密管理システムに接続し、 [External Secrets Operator](https://external-secrets.io/) , チャート README に記述されている統合です。

## このチャートには何が含まれるか

- Glossia Web アプリケーション
- アプリケーションデータ用の Postgres（オプション、デフォルトでオン）
- 分析用の ClickHouse（オプション、デフォルトでオン）
- 翻訳ジョブのバックグラウンドワーカーは、Kubernetes Jobs として実行されるため、ロールアウトデプロイを超えて稼働します。

## 次に進む先

- 以下の [Helm チャート README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) すべての値に対する完全な参照を、バックアップ、オブジェクトストレージ、および可観測性に関する注記を含みます。
- [モデルプロバイダーを設定する](/docs/how-to/configure-a-model-provider) インスタンスが稼働しているため、翻訳が LLM を呼び出すことができます。
- 不具合報告や改善提案は以下の [GitHub リポジトリ](https://github.com/glossia/glossia).