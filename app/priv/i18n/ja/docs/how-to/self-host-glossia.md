%{
  title: "Glossia のセルフホスティング",
  summary:
    "バンドルされた Helm チャートを使って、ご自身の Kubernetes クラスターに Glossia をインストールすることで、チームが独自のインフラストラクチャ上で言語 OS を運用できます。",
  category: "how-to",
  order: 2
}
---
Glossia は O'Saasy ライセンスの下でオープンソースです。 [O'Saasy ライセンス](https://github.com/glossia/glossia/blob/main/LICENSE.md). あなたはセルフホストし、変更し、組織の内部使用のために実行できます。ライセンスが許可していない唯一のことは、glossia.ai のホストサービスと競合するホストされたまたは SaaS プロダクトとして第三者に提供することです。

このガイドでは、空の Kubernetes クラスターから動作する Glossia インスタンスまで案内します。

## 開始前に

以下のものが必要です：

- Helm チャートをインストールできる Kubernetes クラスター（v1.28 以降）
- `helm` および `kubectl` ローカル
- クラスターの ingress を指すドメイン
- 認証用の OpenID Connect プロバイダーまたは SMTP リレー (Glossia は両方サポート)

Helm チャートは Postgres を同梱しています (via [CloudNativePG](https://cloudnative-pg.io/)）およびClickHouse（による [公式オペレーター](https://github.com/ClickHouse/clickhouse-operator)）外部データベースは不要です。ご自身で管理されたい場合は、設定内で両方を無効にできます `values.yaml`.

## オペレーターをインストール

有効化予定のコンポーネントに対応するオペレーターをインストールしてください。最低限：

- [CloudNativePG オペレーター](https://cloudnative-pg.io/documentation/current/installation_upgrade/) アプリデータベース用
- [ClickHouse Kubernetes オペレーター](https://github.com/ClickHouse/clickhouse-operator) 分析データベース用
- Ingress コントローラー（例えば [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 自動 TLS を有効化したい場合は

## Glossia チャートをインストール

リポジトリをクローンし、チャートをインストール：

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

指定された名前で Kubernetes Secret を作成 `glossia-app-env` 少なくとも以下のキー：

| キー | 目的 |
| --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix セッション署名鍵 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer トークン保護 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 基本認証の `/ops` ダッシュボード |
| `RELEASE_COOKIE` | 各 Pod で共有される Erlang クッキー |
| `GLOSSIA_SMTP_*` | 送信メール設定 |

これらを直接プロビジョニングして利用できます [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)、または図をシークレットマネージャーを介して接続する の [External Secrets Operator](https://external-secrets.io/) 図の README に記述されている統合

## 図に含まれるもの

- Glossia ウェブアプリケーション
- アプリケーションデータ向けの Postgres（オプション、デフォルトで有効）
- 分析向けの ClickHouse（オプション、デフォルトで有効）
- 翻訳ジョブのバックグラウンドワーカーです。Kubernetes Job として実行されるため、ローリング展開でも継続して稼働します。

## 次のステップへ

- この [Helm chart の README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) にはすべての値に対する完全な参照と、バックアップ、オブジェクトストレージ、観測可能性に関するメモが含まれます。
- [モデルプロバイダーを設定](/docs/how-to/configure-a-model-provider) インスタンスが実行された後に行います。これにより翻訳ジョブが LLM を呼び出せるようになります。
- 問題ご報告や改善ご提案は以下 [GitHub リポジトリ](https://github.com/glossia/glossia).