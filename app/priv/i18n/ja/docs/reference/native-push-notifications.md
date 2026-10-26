%{
  title: "ネイティブプッシュ通知",
  summary: "プロバイダー設定、オプトインデバイス登録、配信ポリシー、およびネイティブペイロード。",
  category: "リファレンス",
  section: "platform",
  order: 30
}
---

## ## 通信と認証情報

Glossia は iOS には直接 APNs へ、Android には FCM HTTP v1 へ直接送信します。PostgreSQL は登録情報を保存し、Oban は配信キューを使用します。.messagingサービスや Firebase iOS SDK は必要ありません。プロバイダの承認は、配信または Read Receipt ではありません。不明朗なネットワーク障害は重複アラートを発生させる可能性があります。

プロバイダ秘密鍵は、サーバーの既存の秘密管理システムにのみ格納してください。APNs 秘密鍵や Firebase サービスアカウント JSON を、モバイルビルド、リポジトリファイル、ログ、またはクライアント表示の構成に決して格納しないでください。Firebase の公開 Android アプリ識別子はサービスアカウント省内書ではない出力です。

| 環境変数 | 意味 |
| --- | --- |
| `GLOSSIA_APNS_TEAM_ID` | 10 文字の Apple チーム ID。 |
| `GLOSSIA_APNS_KEY_ID` | 10 文字の Apple 署名鍵 ID。 |
| `GLOSSIA_APNS_PRIVATE_KEY` | PEM 形式エンコードされた秘密 P-256 署名鍵、改行を保持します。 |
| `GLOSSIA_APNS_TOPIC` | 署名された iOS アプリケーションの正確なバンドル識別子。クライアントは選択できません。 |
| `GLOSSIA_APNS_ENVIRONMENT` | `production`（デフォルト）、`sandbox`、または `both` を明示して両方の環境をサポートするキー。 |
| `GLOSSIA_FCM_SERVICE_ACCOUNT_JSON` | `type`、`project_id`、`client_email` および RSA `private_key` を含む Android Firebase サービスアカウント JSON。 |

APNs 資格情報の欠如は iOS だけを無効にします。FCM 資格情報の欠如は Android だけを無効にします。部分的なまたは不正確な構成されたプロバイダは、認証情報を含まないエラーで構成解析に失敗します。APNs 環境は登録と配信時に確認され、ビルドモードの仮定から導出せず、署名されたプロビジョニングプロファイルから導出します。APNs は専用の HTTP/2 専用 Finch プールと ES256 認証を使用します。FCM は Google の固定 OAuth エンドポイントで RS256 サービスアカウントアサートメントを交換し、その後固定の HTTP v1 エンドポイントを使用します。リダイレクトと HTTP クライアントリトライは無効にされています。

## ## レジストレーション API

すべてのルートには、ネイティブアプリのインストールごとに動的に登録された公開 PKCE クライアントに発行された Bearer OAuth アクセストークンが必要です。唯一のリダイレクト URI は `glossia://oauth/callback` です。リフレッシュと取消は公開で行い、クライアントシークレット認証方法は使用しません。従来の共有 Expo クライアント、アカウントトークン、ブラウザセッション、および他の OAuth クライアントはインストールアイデンティティではなく、デバイスを登録できません。これはクライアント形状の確認であり、デバイス証明ではありません。

`PUT /api/me/push-devices/:installation_id` は正確に次のものを受理します:

```json
{"platform":"ios","token":"<OS device token>","environment":"production"}
```

- `installation_id`: クライアントが生成した UUID です。また、返され、配信された `registration_id` としても使われます。
- `platform`: `ios` または `android`。
- `environment`: iOS には `sandbox` または `production`。Android には `production` のみ。
- iOS トークン: 32–512 文字の 16 進数文字、偶数、小文字に変換します。
- Android トークン: 16–4096 ライン可能非空白 ASCII 文字。
- 正常な PUT: `{"registered":true,"registration_id":"<installation UUID>"}`。
- 不明なフィールド、所有者セレクター、トピック、ホスト、およびプロバイダ URL を含むものは拒否されます。

`DELETE /api/me/push-devices/:installation_id` は `{"deleted":true}` をイデムポテントで返します。不明な ID は句印にされるため、遅延された PUT によるサインアウト後のインストールの復活はできません。他のユーザーの無関係なインストールは決して変更されません。同じネイティブ OAuth クライアントはオフラインサインアウト復旧時に前のユーザーのインストールを廃止できますが、所有権は決して移動しません。`409 installation_retired` に続いて新しいインストール UUID にローテイトします。

`GET /api/me/push-devices/capabilities` は `{"ios":true,"android":false}` 返すと構成プロバイダと何が照合されているかによる認証要件はなります。本物の iOS 機能は APNs 環境制限を超えません。

応答は `no-store` です。変異は API 制限に加えて、ユーザーあたり 1 時間ごとに最大 120 リクエストに制限されます。欠落または無効な Bearer 認証は 401 を返します；非ネイティブ認証は 403 を返します；無効なデバイスデータは 400 を返します；廃止された競合インストールは 409 を返します；利用不能なプロバイダは 503 を返ります。プロバイダが無効化された場合でもクリーンアップは利用可能です。

## ## 配信意図

内部呼び出し者は、ソーストランザクションコミット后に固定 API を使います:

```elixir
Glossia.Push.notify_user(user_id, "toki_completed", %{
  conversation_id: conversation.id,
  message_id: completed_user_message.id
})

Glossia.Push.notify_user(user_id, "linguistic_input_needed", %{
  translation_session_id: session.id,
  review_id: review.id
})
```

種類は対応するアトムでもあり得ます。返答は `{:ok, queued_count}` または `{:error, :invalid_notification}` です。任意の宛先公開送信 API、カスタム通知テキスト、推論リトライ、または明示的なオプトインは存在しません。

`toki_completed` は、厳密に完了した**ユーザー**メッセージとその完了したアシスタント返信を必要とします。プライベート会話では、受信者が履歴を所有している必要があります。共有ゴール会話では、引き続き資格のある招待された流暢な参加者で、かつゴールが開いている必要があります。また、現在の Toki/プロジェクトへのアクセスを確認し、ソースにリンクされた会話の場合は、現在の翻訳読み取り権限とソースの存在も確認します。別の完了メッセージまたはアシスタントメッセージ ID はいずれも代用にはなりません。

`linguistic_input_needed` は、指定された翻訳セッション上の特定されたオープンなゴールおよび資格のある招待された流暢な参加者を必要とします。セッション限定のソースは互換性のために引き続き受け入れられ、資格のあるオープンなゴールを解決します。別のセッションのレビューは対象外です。すべての一致する承認されたチームメイトは同じ Toki 会話に参加します。配信は独立して、現在の流暢さ、Toki/翻訳/プロジェクトへのアクセス、およびメンバーシップを再確認します。

ユーザーあたり最 10 件のライブ登録があります。トークンは既存の Cloak vault で暗号化され SHA-256 ダイジェストで索引付けされます。トークン移動は古い登録を Retire します。プロバイダ無効化はクリアする前に試行済みのダイジェスト/環境と比較します。APNs の最終無効時刻は、その時刻後にリフレッシュされた登録を Retire しません。

配信ジョブには ID、種類、ソースID、および期限のみがあります。すべての試行は登録、所有者、現在保持されるネイティブ OAuth リフレッシュ許可とスコープ、ソース、メンバーシップ、および期限を確認します。プロバイダ認証取得後、送信直前に確認を再行します。アクセストークンの期限切れのみは依然有効なリフレッシュセッションを終了しません。取消、リフレッシュ期限切れ、ソースアクセスの欠落、サインアウト、または解決済みのレビューは配信をキャンセルします。

両方の種類は 1 時間後に期限切れになります。プロバイダ試行は最多 5 回あり、プロバイダバックプレッシャーによるのスヌーズを含む。Retry-After は通知の生存期間内のみで尊重されます。プロバイダレスポンスボディまたはトークンはジョブエラーとして返されません。フォアグランドの登録のリフレッシュが必要です。60 日間リフレッシュされていない登録は Retire されます。毎時 Prune ワーカーは、1,000 行のバウンデッド・ローテーションバッチをスキャンし、期限切れまたは終了したセッションのトークンを削除します。墓標は、インストール/クライアント ID、プラットフォーム/環境、およびライフサイクルタイムスタンプのみを、遅延リクエストを封じるために無期限に保持します。Retire された行には、ユーザー、トークン、またはダイジェストがありません。アカウント削除はユーザー参照を切断し、すべての配信を即座に阻止します。Prune ワーカーは保持されたトークンを削除します。

プロバイダ証明書は、有界かつ期限意識のある Cachexキャッシュを使用します。キーローテーションはキャッシュの同一性を新たなものとします。APNs の JWT は 50 分間再利用されます。FCM 証明書はプロバイダの期限切れの 5 分前に期限切れとなります（最長 50 分）。失敗はキャッシュされません。

## Payload バージョン 1

APNs には汎用通知 **Glossia / Glossia での更新があります。** が含まれます。FCM は同じ `title` と `body` を持つデーナメッセージのみを送信し、ローカルレンダリングに供します。どちらもプロンプト、レスポンス、質問、ソースの抜粋、またはプロジェクトタイトルを含みません。ルーティングフィールドは文字列です:

```json
{"v":"1","url":"glossia://navigate/org/project/toki/CONVERSATION_UUID?server=https%3A%2F%2Fglossia.ai","registration_id":"INSTALLATION_UUID"}
```

両方の通知タイプは `/org/project/toki/CONVERSATION_UUID` を開きます。言語支援リクエストは共有のゴールスレッドを開きます。`server` は構成された Phoenix エンドポイントの HTTPS 起源であり、リクエストヘッダーまたはクライアント入力のいずれでもありません。HTTP のみのエンドポイント構成は配信時に閉じて失敗します。ネイティブクライアントは、 unknown バージョン、不一致の起源/登録、および無認証のルートを受け入れなければなりません。タップはサーバーを変更しません。または変更を実行しません。フェッチされたデスティネーションは、通常 API 認証が適用されている必要があります。

## ランタイム統合

親アプリケーションは Oban の前に `Glossia.Push.Supervisor` を開始し、証明書キャッシュと専用 APNs Finch プールを提供します。ランタイム構成は `Glossia.Push.Config.parse!(System.get_env())` を呼び出します。Oban の `push` キューの並列度は 5 で `Glossia.Push.Prune` が毎時実行されます。3 つの登録ルーティングは、既存のベアラ認証済み API パイプラインで実行されます。

リクエストロギングはデバイストークンを削除します。エンドポイントは Sentry のデフォルトのボディスクラッパーを、Phoenix パラメーターフィルターで拡張し、既存の保護機能を維持します:

```elixir
config :phoenix, :filter_parameters, ["password", "passwd", "secret", "token"]

# Endpoint request-body scrubber
plug Sentry.PlugContext, body_scrubber: {__MODULE__, :scrub_request_body}
def scrub_request_body(conn) do
  conn
  |> Sentry.PlugContext.default_body_scrubber()
  |> Phoenix.Logger.filter_values()
end

# Defense in depth: no Phoenix parameter logging for enrollment
put "/me/push-devices/:installation_id", PushDeviceController, :update, log: false
```

カスタムテレメトリや例外レポートで、生のプッシュリクエストボディを保持しないでください。

プッシュスーパーバイザーとキューは親 Web ワーカープロセスのみが必要です。翻訳ランナーポッドは、証明書、APNs プール、または新しいメッセージングサービスなしで ID をキュー化する可能性があります。標準のリリースワークフローを通じてマイグレーションを適用してください。エクスポートされたアカウントデータからプロバイダトークンを排除してください。常設の墓標を削除しないでください。

物理装置のチェックは引き続き必要です：構成された署名付き iOS/Android ビルド、許可の有効/無効、フォアグランド/バックグラウンド/終了時の配信、コールドスタートのタップ、プロバイダトークンのローテーション、有効期限切れの証明書、オフラインサインアウトのクリーンアップ、およびアカウント切り替え。スタブされたプロバイダテストはリアルタイム配信を確立しません。ネイティブビルドは、通知ライフサイクルサポートと Android Firebase 依存関係を含みますが、このコードは証明書、共有インフラストラクチャ、署名されたプロビジョニングプロファイル、または Firebase アプリ識別子を準備しません。
