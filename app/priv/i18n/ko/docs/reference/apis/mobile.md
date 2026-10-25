%{
  title: "모바일 및 동반 API",
  summary: "네이티브 외관, 프로필, 번역 활동, 분석 및 비공개 Toki 대화.",
  category: "참조",
  subcategory: "API",
  order: 4
}
---

공공 네이티브 외관 카탈로그를 제외한 모든 엔드포인트는 Bearer 토큰을 필요로 합니다. [OpenAPI 사양](/api/openapi.json) 은 전체 스키마를 설명합니다. 기존 [OAuth PKCE 흐름](/docs/reference/apis/authentication)을 통해 토큰을 획득하십시오. 클라이언트에 추론 제공자 키를 임베드하지 마십시오.

## 권한 부여

| 엔드포인트 | 토큰 범위 |
|---|---|
| `GET /api/native/themes` | 없음 (공공 외관 메타데이터) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

토큰 범위는 허용이 아닌 최상위 제한입니다. 각 프로젝트 엔드포인트도 사용자의 프로젝트 읽기 권한을 확인합니다. 두 번째 `project:read` **토큰** 범위는 필요하지 않지만, 명시적 권한이 있는 조직 멤버십은 프로젝트 읽기와 요청된 기능 모두를 허용해야 합니다. 새로운 멤버십에는 이러한 모바일 기능이 포함되어 있지만, 기존 명시적 멤버십은 자동으로 확장되지 않습니다.

개인 프로젝트는 기존 개인 조직 멤버십 규칙을 따릅니다. 계정의 가시성은 공개 프로젝트 읽기를 제어합니다; 인증된 외부 사용자가 필요한 범위를 가지고 있으면 공개 프로젝트의 번역 활동 및 분석을 읽을 수 있습니다. 토키 쓰기는 계정 멤버십이 필요하므로 공개 가시성만으로는 계정당 추론 크레딧을 소모하지 않습니다. 토키 회화는 공개 계정이어도 프로젝트 내에서 생성 사용자에만 비공개로 유지됩니다. 조직 및 플랫폼 관리자는 다른 사용자의 회화를 읽을 수 없습니다. 회화 UUID 를 알더라도 액세스 권한이 부여되지 않습니다.

## 네이티브 외관

`GET /api/native/themes` 는 인증이나 사용자/프로젝트 데이터 없이 선택된 Glossia 서버에서 인스턴스 전역의 외관 메타데이터를 반환합니다. 응답에는 `Cache-Control: public, max-age=300` 가 포함됩니다. 이는 모든 프로젝트 엔드포인트의 권한 부여에 영향을 주지 않습니다.

응답에는 4 개의 필수 필드가 있습니다:

| 필드 | 값 |
|---|---|
| `schema_version` | 정수 `1` |
| `revision` | 비어있지 않은 콘텐츠 수정본으로, 최대 128 자입니다. |
| `default_theme_id` | `"glossia"` |
| `themes` | 기본 Glossia 테마를 포함하는 배열 |

기본 테마는 `id: "glossia"`, `name: "Glossia"`, 비어있지 않은 `description`, `typography: "standard"`, `button_radius: 8`, `card_radius: 12` 및 `light` 와 `dark` 팔레트를 포함합니다. 반경은 수치 논리적 픽셀입니다. 각 팔레트에는 밑에 나열된 9 개의 모든 필드가 있으며, 불투명한 `#RRGGBB` 색상으로 표시됩니다:

| 팔레트 필드 | 가-light | 어두운 |
|---|---|---|
| `background` | `#FAF8F5` | `#1C1917` |
| `surface` | `#FFFFFF` | `#2A2621` |
| `subtle` | `#F2EFE9` | `#2A2621` |
| `text` | `#1C1917` | `#FAF8F5` |
| `secondary_text` | `#5C564E` | `#D1CDC5` |
| `border` | `#E4E0D9` | `#3D3833` |
| `accent` | `#6D3CC4` | `#D0BCFF` |
| `on_accent` | `#FFFFFF` | `#381E72` |
| `tint` | `#6D3CC4` | `#D0BCFF` |

카탈로그는 `app/priv/static/assets/styles.css` 에 있는 표준 `:root` 색상 및 반경 토큰에서 컴파일됩니다. 어두운 팔레트는 네이티브 전용 시맨틱 토큰을 사용하며 웹 렌더링을 변경하지 않습니다. 토큰 변경 후 재 빌드는 카탈로그와 그 결정론적 수정본을 업데이트합니다. 수정본은 카탈로그 내용을 덮는 것으로, 무관한 스타일시트 편집은 포함하지 않습니다. 사용자별 선호도나 런타임 테마 구성은 포함되지 않습니다.

## 프로필

`GET /api/me` 는 인증된 사용자의 프로필만 반환합니다:

```json
{
  "user": {
    "id": "30c92fe9-4477-4ba6-ae0a-0d874f9ff650",
    "name": "Alex Chen",
    "email": "alex@example.com",
    "handle": "alex"
  },
  "server_version": "0.1.0"
}
```

`name` 는 `null` 값이 될 수 있습니다. 핸들은 선택된 조직이 아닌 사용자의 개인 계정에 속합니다. `server_version` 는 실행 중인 애플리케이션의 버전입니다.

## 페이지네이션

번역 및 회화 목록은 `page`(`1`, 범위 `1–10000`) 와 `page_size`(`20`, 범위 `1–50`) 를 받습니다. 유효하지 않은 값은 `400` 을 반환하여 침묵히 클램핑하지 않습니다. 메타데이터는 다른 Glossia API 목록과 동일한 형식을 사용합니다:

```json
{
  "total_count": 23,
  "total_pages": 2,
  "current_page": 1,
  "page_size": 20,
  "has_next_page?": true,
  "has_previous_page?": false
}
```

목록은 현재 상태를 반영하며, 소스 스냅샷이 아닙니다. 회화 정렬은 가장 최근에 업데이트된 순서이며, UUID 가 결정론적인 우선순위입니다.

## 번역 활동

`GET /api/:handle/projects/:project/translations?page=1` 를 반환합니다:

```json
{
  "sessions": [{
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "completed",
    "commit_message": "Update installation guide",
    "source_language": "en",
    "target_languages": ["es", "ja"],
    "translated_content_count": 8,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": "Translated eight documents."
  }],
  "meta": {"total_count": 1, "total_pages": 1, "current_page": 1, "page_size": 20, "has_next_page?": false, "has_previous_page?": false}
}
```

상태는 `pending`, `running`, `completed`, `failed` 또는 `cancelled` 입니다. 작업이 대기 중이거나 특정하지 않을 경우 커밋 메시지, 소스 언어, 요약은 `null` 가 될 수 있습니다. 결과는 최신순이며 전송된 프로젝트에 국한됩니다.

`GET /api/:handle/projects/:project/translations/:id` 는 `{session: {...}, progress: {...}}` 를 반환합니다. `session` 는 목록 세션 필드와 영구 가능한 `commit_sha` 가 추가로 정확히 일치하며 변경되지 않습니다. `progress` 는 웹 대시보드와 동일한 Elixir 진행량 환급기를 사용하여 확립된 이벤트에서 재구성됩니다. 이는 전송된 프로젝트 및 계정 내에서 페이지네이션 또는 세션 연령에 관계없이 직접 정확한 UUID 조회입니다. 잘못된 형식, 누락, 외래 프로젝트 ID 는 `404` 와 함께 `error: "not_found"` 을 반환합니다. 인증 및 프로젝트 권한 부여는 여전히 먼저 실행 (`401`/`403`). 이 리소스를 열면永远不会 회화를 생성하거나 메시지를 전송하거나 추론을 시작합니다. **세션-요약 수준의 추적성** 과 파일별 진행 상황을 제공하며, 번역 섹션 텍스트 또는 번역 결과 검토는 하지 않습니다.

### 네이티브 실시간 진행

지속 가능한 Phoenix WebSocket 을 `/native/socket/websocket?vsn=2.0.0` (`wss`(HTTPS 서버에서)) 에서 엽니다. 롱폴링은 비활성화됩니다. 액세스 토큰은 쿼리 매개변수를 통해 절대로 노출하고, WebSocket 서브프로토콜 헤더를 통해서만 보내십시오:

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

서버는 `phoenix` 을 협의합니다. `translation:<session UUID>` 토픽에 `{"organization":"account-handle","project":"project-handle"}` 를 사용하여 합류하십시오. 조직 값은 개인 계정을 포함하여 HTTP API 와 동일한 계정 핸들을 사용합니다. 합류 응답 및 모든 `snapshot` 이벤트는 HTTP 디테일과 동일한 완전한 투영을 포함합니다:

```json
{
  "session": {
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "running",
    "commit_message": "Update installation guide",
    "commit_sha": "abc123",
    "source_language": "en",
    "target_languages": ["es"],
    "translated_content_count": 0,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": null
  },
  "progress": {
    "seq": 3,
    "summary": {
      "total": 2, "checked": 2, "needs_translation": 2, "assessed?": true,
      "skipped": 0, "done": 0, "failed": 0, "cancelled": 0, "running": 1, "queued": 1,
      "glossary": {"applied_ids": [], "shadowed_ids": [], "files_with_applied": 0, "files_with_shadowed": 0}
    },
    "items": [
      {"index": 0, "output_path": "es/guide.md", "locale": "es", "status": "running", "turns": 1, "file_ref": null},
      {"index": 1, "output_path": "es/faq.md", "locale": "es", "status": "queued", "turns": 0, "file_ref": null}
    ],
    "omitted_items": 0
  }
}
```

`seq` 는 확립된 진행량 순환이며, **아님** 고유한 스냅샷 버전이 아닙니다. 세션 상태/게시 변경 사항 및 실시간 모델 호출 카운트는 동일한 순환을 가진 새로운 스냅샷을 생성할 수 있으며, `seq` 가 변경되지 않아도 이전 투영을 교체합니다. 파일별 상태는 `queued`, `running`, `done`, `failed` 및 `cancelled` 입니다. 경로, 로케일, 및 파일 참조는 알려지기 전에 `null` 일 수 있습니다. 대부분의 세션은 순환 zero, 빈 항목, 및 zero 카운트를 가집니다. 요약은 **모든** 파일을 덮지만 항목이 제외된 경우에도 포함됩니다. 요약의 글러사리 식별자/카운트는 웹 환상기의 집계이며, 제공자 메타데이터가 아닙니다.

계획된ดัชนี 순서로 최대 500 개의 항목만 포함되며, 인코딩된 항목 예산 합계가 512,000 바이트입니다. 배치되지 않은 항목은 제외되며, `omitted_items` 는 제한을 통해 제외된 모든 행을 카운트합니다. 원본 번역 출력, 스트리밍 텍스트, 사고, 제공자 페이로드 및 원본 실패 세부사항은 절대 포함되지 않습니다. 실시간 공개 모델 호출 카운트는 재 연결 또는 조정 후 재설정될 수 있으며, 확립된 최종 카운트 및 파일 상태는 재구성됩니다. 전체 네이티브 스냅샷은 인코딩된 JSON 바이트 1,000,000 개로 제한됩니다. 변경되지 않은 세션 메타데이터 또는 전체 요약만 한계가 넘으면 연결은 `{"reason":"payload_too_large"}` 로 실패하거나, 기존 채널은 해당 이유로 `error` 를 수신하여 닫거나,와디마이 프레임이나 침묵 프로그래프로 পরিলাculu를 보내지 않습니다.

서버는 기존 크로스 노드 세션 PubSub 에 **이전에** 지속 가능한 접두사를 읽지 않고 실시간 꼬리를 중복 제거하여 합치고, 진행량/상태/게시 알림을 약 100 ms 에 완전한 스냅샷으로 다룹니다. 클라이언트별 HTTP 폴링이나 러너 로컬 상태는 필요 없습니다. 해당 문자열이 5 초마다 권한을 갱신하고 누락된 알림을 수정하기 위해 확립된 상태를 재구성합니다. 포그라운드로 전환하거나 전송 차단 후 재연결 및 재합류하십시오; 합류 투영만으로도 변경 사항 재생 없이 연결이 필요합니다. 연결된 상태에서는 일반적인 Phoenix 심박수 생명 주기를 따르십시오; 더 이상 보지 않을 때 토픽을 떠납니다.

현재 지속된 토큰 부여, 만료/취소, 사용자, `translation:read` 토큰 범위, 정책 권한, 프로젝트 가시성, 및 정확한 계정/프로젝트/세션 연관은 합류 및 모든 스냅샷 전에 확인됩니다. 누락된 범위 또는 정책 권한은 `{"reason":"forbidden"}` 를 반환하고, 누락된 리소스는 `{"reason":"not_found"}` 를 반환하며, 만료/취소된 인증은 `{"reason":"sign_in_required"}` 를 반환합니다. 성공적인 합류 후 거부는 해당 사유로 `access_revoked` 를 방출하고 다른 스냅샷 없이 채널을 즉시 종료합니다. 갱신은 또한 비활성 채널에서 취소 상태를 감지합니다. `sign_in_required` 에서는 새로 고침/재인증하고 새로운 연결을 만드십시오; 기타 거부 사항에서는 보호된 세부 사항을 더 이상 표시하지 마십시오. WebSockets 는 이동 전화 앱이 현재 거동 상태에서 전송을 보장하는 메커니즘이 아닌 포그라운드 실시간 업데이트 메커니즘입니다.

## 애널리틱스

`GET /api/:handle/projects/:project/analytics?days=30` 은 요약 지수, 최대 10 개의 상위 페이지, 및 트래픽 시간 시계열을 반환합니다. 빈 프로젝트는 다음과 같이 반환합니다:

```json
{
  "summary": {
    "pageviews": 0,
    "unique_visitors": 0,
    "locale_gap_visits": 0,
    "top_country": "",
    "top_browser_language": ""
  },
  "top_pages": [],
  "traffic": {"granularity": "day", "points": []},
  "days": 30
}
```

`days` 은 기본값이 `30` 이며 `1` 에서 `365` 사이의 정수여야 합니다. 이동 중인 UTC 보고 창은 요청 시 종료됩니다. 이는 데시보드와 동일한 프로젝트 단 ClickHouse 집계이며, 일간 회전 방문자 식별자를 포함합니다. 저장소 오류는 `503` 의 `error: "analytics_unavailable"` 와 함께 반환하며, 제로 지수를 작성하지 않습니다.

`traffic.granularity` 는 2 일까지의 창장에서 `"hour"` 그리고 90 일까지의 창장에서 `"day"` 와 `"month"` 입니다. `traffic.points` 는 순차적입니다. 각 지점은 UTC 바켓 시작 타임스탬프 및 음수가 아닌 정수 카운트를 포함합니다:

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

카운트는 요청된 보고 창에 있는 이벤트만 포함하므로 첫 번째 및最后一个 바켓은 부분적일 수 있습니다. 이벤트가 존재하면 해당 창의 조용한 바켓은 제로 카운트로 포함됩니다. 이벤트가 존재하지 않으면 `points` 은 합성 평평한 추세 대신 비어 있습니다. `unique_visitors` 는 **각 바켓 내에서** 고유한 식별자를 카운트하며, 이 값들을 더하면 기간의 고유 방문자 카운트를 얻지 못합니다. 해당 전액을 위해 `summary.unique_visitors` 를 사용하십시오. 클라이언트는 요약 지수로 추세를 재구성하는 대신 반환된 바켓을 변경하지 않고 플롯해야 합니다.

## Toki 대화

### 생성 및 목록

`POST /api/:handle/projects/:project/toki/conversations` 는 클라이언트 생성 UUID 를 받습니다:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

그것은 `201` 의 `{conversation, messages: []}` 와 함께 반환합니다. 빈 대화는 제목 `New conversation` 와 상태 `completed` (비동기, 생성 안함) 를 가집니다. 동일한 연동자, 프로젝트, 및 기원과 같은 UUID 를 재생하면 새 대화를 생성하지 않고 기존 세부 사항을 반환합니다. 새 연동자, 프로젝트, 또는 기원에 재사용하면 `409` 의 `error: "id_conflict"` 를 반환합니다.

`GET /api/:handle/projects/:project/toki/conversations` 는 `{conversations: [...], meta: {...}}` 를 반환합니다. 대화는 `id`, `title`, `status`, `updated_at`, 선택적 `error`, 및 선택적 `translation_session_id` 에 포함됩니다. 제목은 두 번째 모델 호출이 아닌 첫 번째 사용자 메시지에서 유래됩니다.

### 번역 기원

생성은 같은 프로젝트의 번역 세션 UUID 를 선택적으로 받습니다:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

기원은 불변입니다; 생략 및 `null` 은 모두 기원이 없음을 의미합니다. 재시도는 메시지 보낸 후에도 동일한 기원을 제공해야 합니다. 기원을 나중에 연결하거나 재시도로 제거할 수 없습니다. 다형 기원은 `422` 를 반환하며, 누락된 또는 외계 프로젝트 소스는 `404` 를 반환합니다. 소스 연결 생성은 또한 `translation:read` 토큰 범위 및 현재 정책 권한과 함께 `toki:write` 와 프로젝트 읽기 권한을 요구합니다. 클라이언트 제공 소스 요약, 메타데이터, 역할, 및 소유권은 무시됩니다. UUID 만 지속됩니다; 서버는 응답 시 권한 컨텍스트를 해결합니다.

**소스 연결 대화는 닫혀 실패합니다**, 대신 단순히 UUID 를 축소를 하지는 않습니다: 현재 `translation:read` 범위에 정책 권한, 세부 사항, 원본 생성 재생, 메시지 발송, 및 메시지 재생 없이 `403` 를 반환합니다. 불일치된 기원도 역사 또는 소스 메타데이터를 반환하지 않고 `409` 를 반환합니다. 목록은 소스 연결 대화 전체를 제외하며, 제목 및 페이네이션 카운트 기여를 포함합니다. 이는 소스를 언급할 수 있는 이전 도움 메시지를 보호합니다. 누락된 범위는 일반 `WWW-Authenticate` 도전을 포함합니다. 연결된 대화는 기존 Toki 만 인증 동작을 유지합니다.

삭제 또는 이동된 소스 نیز 닫혀 실패합니다: 소스 연결 세부 사항, 발송, 및 일치하는 생성 재생은 `404` 를 반환하며, 목록은 대화를 제외합니다. 불변 UUID 는 소스 삭제 후 저장되므로 재시도가 무작정 연결되지 않게 됩니다. 참조는 연차 외국 키를 가지지 않으며; 모든 사용은 현재 소스 존재 및 정확한 프로젝트/계정을 확인합니다. 소스 참조는 접근을 부여하거나 목소리, 글러사리, 또는 공유 컨텍스트를 변경하지 않습니다.

소스 연결 대화를 생성하거나 여는 것은 **않** 메시지를 보내거나 추론 큐를 넣습니다. 네이티브 탐색은 먼저 번역 세부 사항을 가져와야 하며; 대화만 명확한 사용자 액션만 만들 수 있고 별도의 명시적 메시지 제출로 턴을 시작합니다. 제안 발표, 공유 토론 검토, 또는 에이전트 작성 도구는 제공되지 않습니다.

### 보내고 확인

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` 는 별도의 클라이언트 생성 **메시지** UUID 를 받습니다:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

요청은 사용자 메시지와 Oban 일감을 하나의 데이터베이스 트랜잭션에 지속됩니다. 모델 호출하지 않습니다. `202` 의 대화 상태 `queued` 와 현재 메시지로 반환합니다. 상태가 `queued` 또는 `running` 인 동안 `GET /api/:handle/projects/:project/toki/conversations/:id` 를 확인하십시오; 현재 `completed` 또는 `failed` 에서 중지합니다.

디테일 응답은 다음 형식을 가집니다:

```json
{
  "conversation": {
    "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
    "translation_session_id": null,
    "title": "Which translations have completed?",
    "status": "queued",
    "updated_at": "2026-10-25T10:00:00Z",
    "error": null
  },
  "messages": [{
    "id": "17c3b189-80f0-4382-b7bb-1305b1db70ad",
    "role": "user",
    "content": "Which translations have completed?",
    "inserted_at": "2026-10-25T10:00:00Z"
  }]
}
```

메시지는 역할 `user` 또는 `assistant` 를 가져 chronological 입니다. 대화는 최대 100 메시지를 보유하고 있으므로 디테일 엔드포인트는 추가 페이지 요청 없이 그 전체 제한된 이력을 반환합니다.

동일한 콘텐츠를 가진 메시지 UUID 를 재생하는 경우 추론이 다시 큐에 추가되지 않습니다. 이는 완료 후 실패한 경우에도 마찬가지입니다. 확정된 재생은 `200`을 반환하며; 대기 중인 재생은 `202` 을 반환합니다. 다른 콘텐츠가 있거나 다른 대화에서 UUID 를 재사용하면 `409`을 반환합니다. 턴이 활성화된 동안 제출된 다른 메시지는 `409` 와 `error: "conversation_busy"`를 반환합니다.

### 모델 동작 및 제한

- 각 사용자 메시지는 공백이 없는 텍스트여야 하며, 길이는 최대 8,000 자이고 32,000 UTF-8 바이트입니다. 유효하지 않은 UUID, 타입 또는 콘텐츠는 `422`을 반환합니다.
- 각 사용자는 프로젝트 당 최대 100 회의 대화를 보유할 수 있으며, 모든 프로젝트 합산으로 최대 5 개의 대기 중/진행 중인 대화를 보유할 수 있습니다. 5 개 이상의 대기 중인 턴은 `429`을 반환합니다. 대화/이력 제한은 `422`을 반환합니다.
- 새로운 메시지는 일반 API 제한 외에 서버당 사용자당 시간당 30 개로 제한됩니다. 재생은 추론 할당량을 소모하지 않습니다.
- 전용 Oban 큐는 서버당 최대 2 개의 일을 동시에 실행합니다. 각 턴은 최대 한 번의 제공업체 HTTP 요청을 만듭니다: ReqLLM 은 제공업체 요청을 준비한 다음, Oban 작업자가 제공업체 연결 후 HTTP 재시도 및 리디렉션이 비활성화된 상태로 동기적으로 실행합니다. Condukt 세션, 분리된 추론 작업, 도구, 서브 에이전트 또는 파일 시스템 명령 로딩은 포함되지 않습니다. 제공업체는 2,048 출력 토큰의 상한을 받습니다. 보조원 답변도 8,000 자 및 32,000 바이트로 제한됩니다.
- HTTP 연결 및 풀 대기 시간은 5 초로 제한되며, 소켓 수신 대기는 60 초로 제한됩니다. Oban 작업자는 90 초의 고정된 벽시계 마감시간을 가지며, 응답도 포함됩니다. 작업자 종단은 로컬 추론 실행도 종료합니다. 연결을 해제하는 것이 원격 제공업체가 이미 승인한 수행 취소 담보를 보장할 수 없으므로, 모호한 실패는 자동으로 다시 시도되지 않습니다.
- 모델은 토큰과 현재 구성원이 두 조건 모두 `translation:read`을 허용할 때 제한된 프로젝트 메타데이터 및 최신 3 개의 번역 요약을 받습니다. 지난 10 개의 대화 예시는 저장장치와 독립적으로 분리되어 제한됩니다. 작성 권한이나 일반적인 리포지토리 접근 권한이 없으며, 모델에는 분석이 제공되지 않습니다.
- 소스 연결 대화의 경우, 모델은 추가적으로 정확히 영속화된 소스를 받습니다. 최근(true) 이어도 아니면: UUID, 상태, 커밋 메타데이터, 언어, 수, 최대 1,000 요약 문자. 컨텍스트는 `provenance: "session_summary"`로 라벨링되며, 프롬프트는 이 요약 수준의 제한 사항 보고를 요구합니다. 섹션 텍스트, 리포지토리 파일 또는 클라이언트 제공 소스 컨텍스트는 로딩되지 않습니다.
- 자격 증명은 계정의 기존 생성 모델 및 서버 추론 구성을 통해 해결됩니다. 인터랙티브 CLI/OAuth 세션은 Toki 에서 사용되지 않습니다. 누락되거나 지원되지 않는 자격 증명은 상태 `failed` 및 `error: "provider_unavailable"`을 생성합니다.
- 제공업체 실패는 `inference_failed`을 발생시킵니다. 비어 있거나 과다한 출력은 `invalid_provider_response`을 발생시킵니다. 원시 제공업체 오류 및 비밀은 반환되지 않습니다. 실패 시 합성 보조원 응답이 삽입되지 않습니다.
- 계정/프로젝트 접근 및 소스 존재, 프로젝트/계정 연결, 및 번역 권한은 추론 전과 후에 다시 확인됩니다. 취소된 접근 또는 부족함 대기 범위 턴은 `not_authorized`으로 실패하며; 삭제되거나 이동된 소스는 `source_unavailable`으로 실패합니다. 어느 실패에서든 보조원 응답은 영구화되지 않습니다.
- 복구 작업은 분마다 실행되며, 2 분 이상 된 활성 작업 또는 15 분 이상 된 대기 중인 작업을 `failed`으로 표시하며 `inference_interrupted`과 함께 합니다. 이는 시간이 초과되거나 종료되거나 고아인 작업을 다시 시도하기 전에 정리합니다. 지연된 작업은 만료된 메시지를 주장하거나 더 새로운 턴을 덮어쓰지 않습니다. 사용자가 실패 후 의도적으로 **새로**한 메시지 UUID 를 보낼 수 있습니다.

## 오류

`401`은 인증이 실패함을 의미합니다. `403`은 범위 또는 리소스 정책이 접근을 거절함을 의미하며; 누락된 범위는 `WWW-Authenticate`도움请来 Menyug 이 포함됩니다. 알려지지 않은 프로젝트 및 외부/개인 대화 UUID 는 `404`을 반환합니다. 유효성 검사는 `422`을, 페이징은 `400`을, UUID/버진 충돌은 `409`을, 할당량 고갈은 `429`을 사용합니다.
