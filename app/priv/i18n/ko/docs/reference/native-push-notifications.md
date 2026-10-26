%{
  title: "네이티브 푸시 알림",
  summary: "제공자 설정, 기기 등록 동의, 전송 정책 및 네이티브 페이로드.",
  category: "참조",
  section: "platform",
  order: 30
}
---

## 전송 및 자격 증명

Glossia 는 iOS 를 위한 APNs 와 Android 를 위한 FCM HTTP v1 로 직접 전송합니다. PostgreSQL 은 등록을 저장하고, Oban 은 전송을 대기합니다. 메신저 서비스 또는 Firebase iOS SDK 는 필요하지 않습니다. 제공자의 수용은 전송이나 읽음 confirmado that 관이 아닙니다. 모호한 네트워크 오류는 중복 알림을 생성할 수 있습니다.

제공자 기밀은 서버의 기존 기밀 관리 시스템에만 존재해야 합니다. 모바일 빌드, 레포지토리 파일, 로그, 또는 클라이언트 가시성 설정에 APNs 개인 키 또는 Firebase 서비스 계정 JSON 을 절대 포함하지 마십시오. Firebase 의 공개 Android 앱 식별자는 서비스 계정 자격 증명이 아닙니다.

| 환경 변수 | 의미 |
| --- | --- |
| `GLOSSIA_APNS_TEAM_ID` | 10 자리 Apple 팀 ID. |
| `GLOSSIA_APNS_KEY_ID` | 10 자리 Apple 서명 키 ID. |
| `GLOSSIA_APNS_PRIVATE_KEY` | PEM 인코딩된 private P-256 서명 키, 줄바꿈 문자 유지. |
| `GLOSSIA_APNS_TOPIC` | 서명된 iOS 애플리케이션의 정확한 번들 식별자. 클라이언트는 이를 선택할 수 없습니다. |
| `GLOSSIA_APNS_ENVIRONMENT` | `production` (기본값), `sandbox`, 또는 명시적으로 `both`. |
| `GLOSSIA_FCM_SERVICE_ACCOUNT_JSON` | `type`, `project_id`, `client_email`, 및 RSA `private_key`. |

APNs 자격 증명이 누락되면 iOS 만 비활성화됩니다. FCM 자격 증명이 누락되면 Android 만 비활성화됩니다. 부적절하거나 잘못된 구성된 제공자는 비비밀 오류로 구성 파싱에 실패합니다. APNs 환경은 등록 및 전송 시 확인되며, 빌드 모드 가정이 아닌 서명된 프로비저닝 프로필에서 이를 유도해야 합니다. APNs 는 전용 HTTP/2 전용 Finch 풀과 ES256 인증을 사용합니다. FCM 은 Google 의 고정 OAuth 엔드포인트에서 RS256 서비스 계정 주장을 교환한 후, 고정 HTTP v1 엔드포인트를 사용합니다. 리디렉션 및 HTTP-클라이언트 재시도는 비활성화됩니다.

## 등록 API

모든 라우트는 네이티브 앱의 설치 단위마다 동적으로 등록한 공개 PKCE 클라이언트에 발급된 bearer OAuth 액세스 토큰을 요구합니다. 유일한 리디렉션 URI 는 `glossia://oauth/callback` 이어야 하며, 리프레시 및 회수는 공개적이어서 클라이언트 기밀 인증 수단이 있어야 합니다. 전래 공유 Expo 클라이언트, 계정 토큰, 브라우저 세션 및 기타 OAuth 클라이언트는 설치 신원이 아니며 장치를 등록할 수 없습니다. 이는 장치 인증이 아닌 클라이언트 형식을 확인합니다.

`PUT /api/me/push-devices/:installation_id` 는 정확히 다음을 받습니다:

```json
{"platform":"ios","token":"<OS device token>","environment":"production"}
```

- `installation_id`: 클라이언트에서 생성된 UUID. 또한 반환된 및 전송된 `registration_id`이기도 합니다.
- `platform`: `ios` 또는 `android`.
- `environment`: iOS 에서 `sandbox` 또는 `production`, Android 에서 `production` 만 허용됩니다.
- iOS 토큰: 32-512 개의 16 진수 캐릭터, 짝수 길이, 소문자로 정규화.
- Android 토큰: 16-4096 printable 비공백 ASCII 캐릭터.
- 성공적인 PUT: `{"registered":true,"registration_id":"<installation UUID>"}`.
- 소유자 선택기, 토픽, 호스트 및 제공자 URL 포함 미 Jardin 필드는 제외됩니다.

`DELETE /api/me/push-devices/:installation_id` 는 `{"deleted":true}` 만 idempotently 반환합니다. 미개의 ID 는 tombstones 으로 변환되므로, 지연된 PUT 은 로그아웃 후 설치를 부활시킬 수 없습니다. 다른 사용자의 관련 없는 설치물은 변경되지 않습니다. 동일한 네이티브 OAuth 클라이언트는 오프라인 로그아웃 복구 동안 이전 사용자의 설치물을 은퇴시킬 수 있지만 소유권은 절대 이동하지 않습니다. `409 installation_retired` 후 새로운 설치 UUID 로 회전하세요.

`GET /api/me/push-devices/capabilities` 는 구성된 제공자에 따라 `{"ios":true,"android":false}` 을 반환하며 동일한 인증 요구 사항이 있습니다. 진정한 iOS 기능은 APNs 환경 제한을 오버라이드하지 않습니다.

응답은 `no-store` 입니다. 변형은 사용자당 시당 120 요청으로 제한되며 API 한도 외입니다. 결측/유효하지 않은 bearer 인증은 401 을 반환하며, 비 네이티브 자격 증명은 403 을 반환합니다. 유효하지 않은 장치 데이터는 400 을 반환하며, 은퇴/충돌 설치물은 409 를 반환합니다. 이용はいけない 제공자는 503 을 반환합니다. 제공자가 비활성화될 때 클리너업은 계속 이용 가능합니다.

## 전송 의도

내부 호출자는 원본 트랜잭션 커밋 후 고정 API 를 사용합니다:

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

형은 또한 해당 원자일 수 있습니다. 반환은 `{:ok, queued_count}` 또는 `{:error, :invalid_notification}` 입니다. 임의 수신자용 공개 송신 API, 커стье화된 알림 텍스트, 추론 재시도 또는 암시적 옵트가 없습니다.

`toki_completed` 는 정렬된 완성된 **사용자** 메시지와 그 완성된 도우너 응답을 요구합니다. 사적 대화에서는 수신자가 포인트를 소유해야 하며, 공유 목표 대화에서는iong한 합리적인 dimensions 한 참여자여야 하고 목표는 열려 있어야 합니다. 현재 Toki/프로젝트 접근 권한과, 소스 연결된 대화의 경우 현재 전환 읽기 접근 권한 및 소스 존재를 확인합니다. 다른 완성된 메시지나 도우너 메시지 ID 는 수준의 교체가 아닙니다.

`linguistic_input_needed` 는 특정 전환 세션의 식별된 열린 목표와요 합리적인 invited 들투하여 파트너를 요구합니다. 세션-only 목수는 호환성을 위해 계속 승인되며 합리적인 열린 목표를 해결합니다. 다른 세션의 검토는 적격이 아닙니다. 모든 대응하는 승인된 동료는 동일한 Toki 대화에 합류하며, 전송은 독립적으로 현재 유창성, Toki/전환/프로젝트 접근 및 멤버십을 다시 확인합니다.

사용자당 실시간 등록은 최대 10 개입니다. 토큰은 기존 Cloak vault 로 암호화되며 SHA-256 디지스트로 색인됩니다. 토큰 이동은 이전 등록을 은퇴시키며,提供商 취소는 기존 디지스트/환경을 비교한 후 무언가를 지우기 전에 수행합니다. APNs 마지막 무효 타임스탬프는 그 타임스탬프 후에 새로 갱신된 등록을 은퇴시키지 않습니다.

전송 작업은 ID, 형, 소스 ID, 만료 만 포함합니다. 각 시도는 등록, 소유자, 현재 지속 네이티브 OAuth 리프레시 권한 및 범위를 다시 확인하며, 소스, 멤버십 및 만료도 합니다. 제공자 자격 획득 후, 즉시 전송 전에도 다시 확인합니다. 액세스 토큰 만료는 여전히 유효한 리프레션 세션을 종료하지 않습니다. 회수, 리프레 치 만료, 소스 접근 불가, 로그아웃, 또는 해결된 검토는 전송을 취소합니다.

두 유형은 모두 1 시간 후 만료됩니다. 최대 5 회 제공자 시도가 있으며, provider-backpressure snoozes 를 포함합니다. Retry-After 는 알림 수명 내에서만 승인됩니다. 제공자 응답 본문 또는 토큰은 작업 오류로 반환되지 않습니다. 포어그라운드에서 등록을 새로고침합니다; 60 일 동안 새로고침되지 않은 등록은 은퇴됩니다. 시간당 리트라이 decals 작업자는 1,000 행의 유계 회전 배치 를 스캔하여 오래되거나 종료된 세션의 토큰을 제거합니다. tombstones 는 설치/클라이언트 ID, 플랫폼/환경, 및 생명주기 타임스탬프만 무한히 유지하여 지연된 요청을 차단하며; 은퇴된 행에는 사용자, 토큰, 또는 digest 가 없습니다. 계정 삭제는 사용자 참조를 끊고 모든 전송을 즉시 방지하며, 리졸 운 worker 는 유지된 토큰을 삭제합니다.

제공자 자격 증명은 유계 만료 지향 Cachex 캐시를 사용합니다. 키 회전은 캐시 신원을 변경합니다. APNs JWT 는 50 분 동안 재사용되며, FCM 자격 증명은 제공자 만료 5 분 전까지 만료됩니다 (최대 50 분). 실패는 캐시되지 않습니다.

## Payload 버전 1

APNs 는 일반 경고 **Glossia / Glossia 에 업데이트가 있습니다.** 를 포함합니다. FCM 은 동일한 `title` 와 `body` 를 가진 데이터 전용 메시지를 보내며, 로컬 렌더링에 사용합니다. 둘은 모두 사적인 프롬프트, 응답, 질문, 소스 발췌, 또는 프로젝트 제목을 포함하지 않습니다. 라우팅 필드는 문자열입니다:

```json
{"v":"1","url":"glossia://navigate/org/project/toki/CONVERSATION_UUID?server=https%3A%2F%2Fglossia.ai","registration_id":"INSTALLATION_UUID"}
```

두 알림 종류는 `/org/project/toki/CONVERSATION_UUID` 를 엽니다; 언어적 도움말 요청은 공유 목표 스레드를 엽니다. `server` 는 구성된 Phoenix 엔드포인트의 HTTPS 오리지널이며, 요청 헤더나 클라이언트 입력은 아닙니다. HTTP 전용 엔드포인트 구성은 배달 시 실패합니다 (fail closed). 네이티브 클라이언트는 미확인 버전, 불일치하는 오리지널/등록, 및 미확인 라우트를 거부해야 하며, 탭핑은 서버를 변경하거나 변형을 실행하지 않아야 합니다. 검색된 목적지는 여전히 정상 API 인증을 통과해야 합니다.

## 런타임 통합

상위 애플리케이션은 Oban 보다 앞서 `Glossia.Push.Supervisor` 를 시작하여 자격 증명 캐시 및 전용 APNs Finch 풀을 제공합니다. 런타임 구성은 `Glossia.Push.Config.parse!(System.get_env())` 를 호출합니다. Oban 의 `push` 큐는 동시성 5 를 가지며 시간당 `Glossia.Push.Prune` 를 실행합니다. 세 등록 라우트는 기존 비어 인증 API 파이프라인에서 실행됩니다.

요청 로깅은 장치 토큰을 숨깁니다. 엔드포인트는 Phoenix 의 파라미터 필터로 Sentry 의 기본 본문 정화기를 확장하여 기존 보호 기능을 유지합니다:

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

커스텀 텔레메트리나 예외 보고서에서 원본 푸시 요청 본문을 보관하지 마십시오.

상위 웹/워커 프로세스만 전송 관리자 (supervisor) 와 큐가 필요합니다. 번역 러너 포드는 자격 증명, APNs 풀, 또는 새 메신저 서비스에 의존하지 않고 ID 를 대기열에 등록할 수 있습니다. 마이그레이션을 정상 릴리스 워크플로우를 통해 적용하십시오. 동기화된 계정 데이터에서 제공자 토큰을 제거하십시오. 정기 유지보수를 위해 tombstones 를 삭제하지 마십시오.

유형 디바이스 검증이 여전히 필요합니다: 설정된 서명 iOS/Android 빌드, 허용/거부된 권한, 오中规/배경/종료 전송, 차 디인 타프, 제공자 토큰 회전, 만료된 자격 증명, 오프라인 로그아웃 정리, 및 계정 전환. Stubbed 제공자 테스트는 라이브 전송을 수립하지 않습니다. 네이티브 빌드에는 알림 수명 지원 및 Android Firebase 의존성이 포함되어 있으며, 이 코드는 자격 증명, 공유 인프라, 서명 프로비저닝 프로필, 또는 Firebase 앱 식별자를 제공하지 않습니다.
