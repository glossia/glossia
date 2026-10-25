%{
  title: "모바일 및 컴패니언 API",
  summary: "네이티브 외관, 프로필, 번역 활동, 분석, 및 개인 토키 대화.",
  category: "참조",
  subcategory: "API",
  order: 4
}
---

공개 네이티브 외관 목록을 제외한 모든 엔드포인트는 Bearer 토큰이 필요합니다. [OpenAPI 사양서](/api/openapi.json) 는 전체 스키마를 설명합니다. 기존 [OAuth PKCE 흐름](/docs/reference/apis/authentication) 을 통해 토큰을 획득하세요. 클라이언트에 추론 제공자 키를 직접 포함하지 마세요.

## 인증

| 엔드포인트 | 토큰 범위 |
|---|---|
| `GET /api/native/themes` | 없음 (공개 외관 메타데이터) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

토큰 범위의 최상위 조건이며, 부여가 아닙니다. 각 프로젝트 엔드포인트 또한 사용자의 프로젝트 읽기 권한을 확인합니다. 두 번째 `project:read` **토큰** 범위는 필요하지 않지만 명시적 권한이 있는 조직 구성원은 프로젝트 읽기와 요청된 기능을 모두 허용해야 합니다. 새로운 구성원은 이러한 모바일 기능이 포함되며, 기존 명시적 구성원은 자동으로 확장되지 않습니다.

개인 프로젝트는 기존 개인-조직 구성원 규칙을 따릅니다. 계정 가시성은 공개 프로젝트 읽기를 제어하며, 필요한 범위를 가진 인증된 외부 사용자는 공개 프로젝트의 번역 활동 및 분석을 읽을 수 있습니다. Toki 작성에는 계정 구성원이 필요하므로 공개 가시성 만으로 계정의 추론 크레딧이 소모되지 않습니다. Toki 대화는 공개 계정이라도 프로젝트 내에서 작성자에게만 비공개로 유지됩니다. 조직 및 플랫폼 관리자는 다른 사용자의 대화를 읽을 수 없습니다. 대화 UUID 를 알면 액세스 권한이 부여되지 않습니다.

## 네이티브 외관

`GET /api/native/themes` 는 인증 또는 사용자/프로젝트 데이터 없이 선택한 Glossia 서버에서 전체 인스턴스 외관 메타데이터를 반환합니다. 응답에는 `Cache-Control: public, max-age=300` 가 포함됩니다. 이는 어떤 프로젝트 엔드포인트의 인증도 변경하지 않습니다.

응답에는 네 개의 필수 필드가 있습니다:

| 필드 | 값 |
|---|---|
| `schema_version` | 정수 `1` |
| `revision` | 비穢백 콘텐츠 버전, 최대 128 자 |
| `default_theme_id` | `"glossia"` |
| `themes` | 기본 Glossia 테마를 포함하는 배열 |

기본 테마에는 `id: "glossia"`, `name: "Glossia"`, 비穰백 `description`, `typography: "standard"`, `button_radius: 8`, `card_radius: 12`, 그리고 `light`와 `dark` 팔레트가 있습니다. 반지름은 수치 논리 픽셀입니다. 각 팔레트는 아래에 명시된 `#RRGGBB` 색상으로 표현된 모든 nine 개의 필드를 포함합니다:

| 팔레트 필드 | 밝은 | 어두운 |
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

데이터 말뭉기는 `:root` 색상과 반지름 토큰에서 완성됩니다. `app/priv/static/assets/styles.css` 에 있습니다. 어두운 팔레트는 네이티브 전용 시맨틱 토큰을 사용하며 웹 렌더링을 변경하지 않습니다. 토큰 변경 후 재 빌드하면 데이터 말뭉기와 결정론적 버전을 업데이트합니다. 버전은 데이터 말뭉기 콘텐츠를 포함하지만 관련 없는 스타일시트 편집은 포함하지 않습니다. 사용별 기준이나 런타임 테마 구성은 포함되어 있지 않습니다.

## 프로파일

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

`name` 가 `null` 일 수 있습니다. 핸들은 선택한 조직이 아닌 사용자의 개인 계정에게 속합니다. `server_version` 는 실행 중인 애플리케이션의 버전입니다.

## 페이징

번역 및 대화 목록은 `page` (기본값 `1`, 범위 `1–10000`) 와 `page_size` (기본값 `20`, 범위 `1–50`) 를 받아들입니다. 잘못된 값은 무음으로 클램핑하지 않고 `400` 를 반환합니다. 메타데이터는 다른 Glossia API 목록과 동일한 모양을 사용합니다:

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

목록은 현재 상태를 반영하며 정지된 스냅샷이 아닙니다. 대화 정렬은 최신 업데이트 시간 기준이며 UUID 를 결정론적 구분자로 사용합니다.

## 번역 활동

`GET /api/:handle/projects/:project/translations?page=1` 는 반환합니다:

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

상태는 `pending`, `running`, `completed`, `failed`, 또는 `cancelled` 입니다. 작업이 대기 중이거나 이용 불가능할 경우 커밋 메시지, 소스 언어 및 요약은 `null` 일 수 있습니다. 결과는 최신 순서이며 지정된 프로젝트로 제한됩니다.

`GET /api/:handle/projects/:project/translations/:id` 는 `{session: {...}, progress: {...}}` 를 반환합니다. `session` 는 목록 세션 필드와 무효 `commit_sha` 를 포함하는 것으로 정확하게 changes 변함없이 `progress` 는 웹 대시보드와 동일한 Elixir 진행 감소기를 사용하여 재생됩니다. 이는 지정된 프로젝트 및 계정 내에서 페이징 또는 세션의 나이와 관련 없이 직접적이고 정확한 UUID 검색입니다. 잘못된, 누락 또는 외부 프로젝트 ID 는 `404` 와 `error: "not_found"` 를 반환하며 인증 및 프로젝트 인증이 먼저 실행됩니다 (`401`/`403`). 이 리소스를 여는 것은 대화 생성, 메시지 발송 또는 추론 시작을 나타내지 않습니다. **세션 요약 수준 출처** 와 파일별 진행을 제공합니다. 번역된 섹먼트 텍스트 또는 번역 결과 검토는 아닙니다.

### 네이티브 실시간 진행

지속적인 Phoenix WebSocket 을 `/native/socket/websocket?vsn=2.0.0` 에서 엽니다 (`wss` HTTPS 서버). Longpoll 을 비활성화합니다. 액세스 토큰은 WebSocket 서브프로토콜 헤더를 통해서만 전송하며, 쿼리 매개변수를 사용하지 않습니다:

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

서버는 `phoenix` 의 협상을 진행합니다. `translation:<session UUID>` 주제에는 `{"organization":"account-handle","project":"project-handle"}` 디테일에서 사용됩니다. 조직값은 HTTP API 가 포함하는 개인 계정을 동일하게 사용합니다. Join 응답 및 모든 `snapshot` 이벤트 는 HTTP 디테일과 동일한 완전한 프로젝션을 담고 있습니다:

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

`seq` 는 지속 가능한 진행 순서이며 **아니다** 고유한 스냅샷 버전입니다. 세션 상태/발표 변경 사항과 실시간 모델 호출 횟수로 인해 동일한 순서의 새 스냅샷이 만들어질 수 있습니다; `seq` 가 변하지 않더라도 이전 프로젝션을 교체합니다. 파일별 상태는 `queued`, `running`, `done`, `failed`, 및 `cancelled` 입니다. 경로, 로케일 및 파일 참조는 알려지기 전까지 `null` 일 수 있습니다. 건드리지 않은 세션은 순서 0, 빈 항목, 및 0 카운트를 가집니다. 요약은 **전부** 파일을 포함하며 항목이 누락되어도 마찬가지입니다. 요약의 해당 식별자/카운트는 웹 감소기의 총합이며 제공자 메타데이터가 아닙니다.

계획된 인덱스 순서로 최대 500 개 항목이 포함되며, 결합된 인코딩 항목 예산은 512,000 바이트입니다. 맞지 않는 항목은 제외되며 `omitted_items` 는 두 제한 중 하나로 제외된 모든 행을 카운트합니다. 원본 번역 출력, 스트리밍 텍스트, 사고, 비공개 제공자 페이로드 및 원본 실패 세부 사항은 포함되지 않습니다. 라이브 공개 모델 호출 횟수는 재연결 또는 조정 후 재설정될 수 있으며 견고한 최종 카운트 및 파일 상태는 재구성됩니다. 전체 네이티브 스냅샷은 인코딩 JSON 바이트 1,000,000 개에 제한됩니다. 변경되지 않은 세션 메타데이터 또는 전체 요약만으로도 그 제한을 초과하면 계정이 `{"reason":"payload_too_large"}` 로 실패하거나, 기존 채널은 해당 이유로 `error` 를 받고 닫거나 oversized frame 을 보내거나Provenance 를 지우지는 않습니다.

서버는 기존 크로스노드 세션 PubSub **전에** 지속 가능한 접두어를 읽기 전에 구독하며, 라이브 꼬리를 순서 중복 제거로 접합하고 진행/상태/발표 알림을 약 100ms 간격으로 전체 스냅샷으로 병합합니다. 각 클라이언트별 HTTP 폴링이나 런너 로컬 상태는 불필요합니다. 매 5 초마다 인증을 갱신하고 지속 가능한 상태를 재구성하여 누락된 알림을 복구합니다. 전경화 또는 전송 중단 후 재연결 및 재가입을 수행하며, 감마 재생 없이 가입 프로젝션이 충분합니다. 연결된 동안은 일반적인 Phoenix 펄스 라이프사이클을 따르며, 더 이상 조회하지 않을 때 토픽을 나갑니다.

현재 지속된 토큰 허가, 만료/회수, 사용자, `translation:read` 토큰 범위, 정책 권한, 프로젝트 가시성, 및 정확한 계정/프로젝트/세션 연결은 가입 시 및 각 스냅샷 전에 검증됩니다. 누락된 범위 또는 정책 권한은 `{"reason":"forbidden"}`를 반환하며, 누락된 리소스는 `{"reason":"not_found"}`를 반환합니다; 만료/회수된 인증은 `{"reason":"sign_in_required"}`를 반환합니다. 성공적인 가입 후 거부는 해당 이유를 담아 `access_revoked`를 방출하고 즉시 추가 스냅샷 없이 채널을 닫습니다. 갱신 또한 비활동 채널에서 회수를 감지합니다. `sign_in_required` 시 재인증하고 새 연결을 생성하며; 다른 거부 시 보호된 세부 사항을 표시를 중단합니다. WebSockets 는 모바일 앱이 대용인 동안의 전달 보장이 아닌 전경 라이브 업데이트 메커니즘입니다.

## 분석

`GET /api/:handle/projects/:project/analytics?days=30` 는 요약 지표, 최대 10 개의 톱 페이지 및 트래픽 시간 시계열을 반환하며, 빈 프로젝트는 다음을 반환합니다:

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

`days` 는 `30` 로 기본이며 `1` 에서 `365` 사이의 정수여야 합니다. 롤링 UTC 보고 창은 요청 시간까지 종료됩니다. 여기에는 대시보드와 동일한 프로젝트 범위 ClickHouse 집계 (일일 회전 방문자 식별자 포함) 가 포함됩니다. 저장소 실패는 `503` 와 함께 `error: "analytics_unavailable"` 를 반환하며, 발명된 영속 지표를 반환하지 않습니다.

`traffic.granularity` 는 두일 창에서 `"hour"`\_, 90 일 창에서 `"day"`\_, 그 외 경우 `"month"` 입니다. `traffic.points` 는 순차적입니다. 각 점은 UTC Bucket 초기 타임스탬프 및 음이 아닌 정수 카운트를 포함합니다:

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

카운트는 요청된 보고 창 내 이벤트만 포함하므로 첫 번째 및 마지막 Bucket 이 부분적일 수 있습니다. 이벤트가 존재할 경우, 해당 창 내 침묵 Bucket 이 0 카운트로 포함됩니다. 이벤트가 존재하지 않는 경우 `points` 는 합성 평탄 트렌드가 아닌 빈 것으로 처리됩니다. `unique_visitors` 는 각_BUCKET 내부에서 **고유 식별자** 를 카운트하며, 이 값들을 합산하면 기간별 고유 방문자 카운트를 제공하지 않습니다. `summary.unique_visitors` 를 해당 총량에 사용하세요. 클라이언트는 요약 지표에서 트렌드를 재구성하는 대신 반환된 Bucket 을 그대로 그려야 합니다.

## Toki 대화

### 생성 및 목록

`POST /api/:handle/projects/:project/toki/conversations` 는 클라이언트 생성 UUID 를 받습니다:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

이는 `201` 를 반환하며 `{conversation, messages: []}` 를 포함합니다. 빈 대화는 제목 `New conversation` 와 상태 `completed` (대기 중, 생성 불가) 를 가집니다. 동일한 역할, 프로젝트, 및 소스에서의 동일한 UUID 재생은 새로운 대화를 생성하지 않고 기존 세부 사항을 반환합니다. 다른 역할, 프로젝트, 또는 소스에서 재사용할 경우 `409` 및 `error: "id_conflict"` 를 반환합니다.

`GET /api/:handle/projects/:project/toki/conversations` 는 `{conversations: [...], meta: {...}}` 를 반환합니다. 대화에는 `id`, `title`, `status`, `updated_at`,可为 null `error`, 및可为 null `translation_session_id` 이 포함됩니다. 제목은 첫 번째 사용자 메시지에서 파생되며 두 번째 모델 호출에서는 파생되지 않습니다.

### 번역 소스

생성은 동일 프로젝트에서 번역 세션 UUID 를 선택적으로 받아둘 수 있습니다:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

소스는 불변이며, 지양 및 `null` 는 모두 소스가 없음을 의미합니다. 재시도는 메시지 전송 시 동일한 소스를 제공해야 합니다. 나중에 소스를 연결하거나 재시도로 제거할 수 없습니다. 잘못된 소스는 `422` 를 반환하며, 누락되거나 외부 프로젝트 소스는 `404` 를 반환합니다. 소스 연동 생성에는 `translation:read` 토큰 범위 및 현재 정책 권한 (또한 `toki:write` 및 프로젝트 읽기 권한) 이 추가로 필요합니다. 클라이언트 제공 소스 요약, 메타데이터, 역할, 소유권은 무시됩니다. 오직 UUID 만 저장되며, 서버는 응답 시 권한화된 컨텍스트를 해결합니다.

**소스 연동 대화는 닫힘 처리가 실패합니다.** UUID 를 마스킹하는 것만으로는 충분하지 않으며: 현재 `translation:read` 범위 또는 정책 권한 없이, 세부 사항, 일치하는 소스 재생, 메시지 전송 및 메시지 재생은 `403` 를 반환합니다. 불일치하는 소스는 여전히 주기나 소스 메타데이터를 반환하지 않고 `409` 를 반환합니다. 목록은 제목 및 페이지네이션 카운트 기여를 포함하여 전체 소스 연동 대화를 숨킥니다. 이는 소스를 언급할 수 있는 이전 어시스턴트 메시지를 보호합니다. 누락된 범위는 일반적인 `WWW-Authenticate` 도전 과제를 포함합니다. 미연결 대화는 기존 Toki 전용 권한 동작을 유지합니다.

삭제되거나 이동된 소스도 닫힘 처리가 실패합니다: 소스 연동 세부 사항, 전송 및 일치하는 생성 재시도는 `404` 를 반환하며, 목록은 대화를 생킥습니다. 불변 UUID 는 소스 삭제 후에도 저장되어 있어 재시도가 침묵되어 연결을 끊는 것을 방지합니다. 참조에는 연쇄 foreign key 가 없으며, 모든 사용은 현재 소스 존재 및 정확한 프로젝트/계정을 확인합니다. 소스 참조는 접근 권한 부여 또는 음성, 사전을 변경하지 않습니다.

소스 연동 대화의 생성 또는 열기는 **안** 메시지 전송 또는 추론 대기열enqueue 를 수행하지 않습니다. 네이티브 네비게이션은 번역 세부 사항을 먼저 가져와야 하며, 명시적인 사용자 동작만 대화 생성을 시작하고, 별도의 명시적인 메시지 전송이 턴을 시작합니다. 제안 게시, 공유 검토, 또는 에이전트 글쓰기 도구는 제공되지 않습니다.

### 전송 및 폴링

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` 는 별도 클라이언트 생성 **메시지** UUID 를 받습니다:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

요청은 사용자 메시지 및 Oban 작업을 한 데이터베이스 트랜잭션에 격납합니다. 모델 호출하지 않습니다. `202` 및 대화 상태 `queued` 와 현재 메시지를 반환합니다. 상태가 `GET /api/:handle/projects/:project/toki/conversations/:id` 또는 `queued` 인 동안 `running`, `completed` 또는 `failed` 에서 중단합니다.

세부 응답은 다음과 같은 모양을 가집니다:

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

메시지는 역할 `user` 또는 `assistant` 를 가지며 시간순입니다. 대화는 최대 100 개 메시지를 보유하므로, 세부 엔드포인트는 추가 페이지 요청 없이 전체 제한 역사를 반환합니다.

동일한 내용의 메시지 UUID 를 재실행하면 추론 추가 대기열이 해당되지 않으며 완료나 실패 후에도 해당되지 않습니다. 완료된 재생은 `200` 를 반환하며, 대기 중인 재생은 `202` 를 반환합니다. 다른 내용을 가진 UUID 를 재사용하거나 다른 대화에서 사용하는 경우 `409` 를 반환합니다. 활성 턴 동안 제출되는 다른 메시지는 `409` 를 반환하며 `error: "conversation_busy"` 를 포함합니다.

### 모델 동작 및 제한

- 각 사용자 메시지는 공백이 아닌 텍스트여야 하며, 최대 8,000 자 및 32,000 개의 UTF-8 바이트까지 허용됩니다. 유효하지 않은 UUID, 유형, 또는 내용은 `422` 를 반환합니다.
- 각 사용자는 프로젝트당 최대 100 개의 대화를 보유할 수 있으며, 프로젝트 간 총 5 개의 대기/진행 중인 대화를 보유할 수 있습니다. 5 개 이상의 대기 중 턴은 `429` 를 반환하며, 대화/역사 제한은 `422` 를 반환합니다.
- 신규 메시지는 서버당 사용자당 시간당 30 개까지 제한되며, 이는 일반 API 속도 제한과 별도로 적용됩니다. 재생은 추론 쿼터를 소모하지 않습니다.
- 전용 Oban 대기는 서버당 동시 두 개 작업을 실행합니다. 각 턴은 최대 하나의 제공자 HTTP 요청을 생성하며, ReqLLM 이 제공자 요청을 준비한 후 Oban 작업자는 제공자 연결 후 HTTP 재시도 및 리디렉션이 비활성화된 상태로 동기적으로 실행합니다. Condukt 세션, 분리된 추론 작업, 도구, 서브 에이전트, 또는 파일 시스템 명령 로딩에는 포함되지 않습니다. 제공자는 최대 2,048 개 출력 토큰을 받으며, 어시스턴트 응답도 8,000 자 및 32,000 바이트로 제한됩니다.
- HTTP 연결 및 풀 대기 시간은 5 초, 소켓 수신 대기 시간은 60 초로 제한됩니다. Oban 작업자는 응답 including trickling 을 포함한 90 초의 절대 시간 한계 시간을 갖습니다. 작업자 종료 또한 로컬 추론 실행을 종료합니다. 연결 분리는 원격 제공자에게 이미 승인된 연산의 무효화를 보장할 수 없으므로, 모호한 실패는 자동으로 재시도되지 않습니다.
- 모델은 토큰 및 현재 멤버십이 `translation:read` 를 허용할 때 제한된 프로젝트 메타데이터 및 최대 3 개 최근 번역 요약체를 받습니다. 마지막 10 개 대화 주제는 저장과 독립적으로 제한됩니다. 작성 기능이나 일반 저장소 접근 권한은 없으며, 모델은 분석 데이터를 제공받지 않습니다.
- 소스 연동 대화의 경우, 모델은 최신이 아닐지라도 정확한 영속화된 소스를 추가로 받습니다: UUID, 상태, 커밋 메타데이터, 언어, 수 및 최대 1,000 개의 요약 문자입니다. Context 는 `provenance: "session_summary"` 로 표시됩니다. 프롬프트는 이 요약 수준 제한을 보고해야 합니다. 섹먼트 텍스트, 저장소 파일, 또는 클라이언트가 제공한 소스 컨텍스트는 로드되지 않습니다.
- 자격 증명은 계정의 기존 생성 모델 및 서버 추론 Rüetthrough 를 통해 해결됩니다. 상호작용 CLI/OAuth 세션은 Toki 에는 사용되지 않습니다. 누락되거나 지원되지 않는 자격 증명은 상태 `failed` 를 가지며 `error: "provider_unavailable"` 를 포함합니다.
- 제공자 실패는 `inference_failed` 를 생성하며, 빈 또는 과도한 출력은 `invalid_provider_response` 를 생성합니다. 원시 제공자 오류 및 시크레트는 반환되지 않습니다. 실패 시 생성된 어시스턴트 응답은 삽입되지 않습니다.
- 계정/프로젝트 접근 및 소스 존재, 프로젝트/계정 연동, 번역 권한은 추론 전후에 다시 확인됩니다. 회수된 접근이나 충분한 대기 중 범위가 턴을 `not_authorized` 로 실패하며, 삭제되거나 이동된 소스는 `source_unavailable` 를 실패합니다. 어느 실패에도 어시스턴트 응답은 영속화되지 않습니다.
- 회복 작업은 분당 실행되며, 2 분 초과 실행 중인 작업 또는 15 분 초과 대기 중인 작업을 `failed` 로 `inference_interrupted` 를 포함하여 표시합니다. 이는 시간 침, 종료, 고아 작업을 처리하며 추론 재시도를 하지 않습니다. 지연된 작업은 만료된 메시지를 불가하거나 더 새로운 턴을 덮어쓸 수 없습니다. 사용자는 실패 후 의도적으로 **새** 메시지 UUID 를 전송할 수 있습니다.

## 오류

`401` 는 인증 실패입니다. `403` 는 범위 또는 리소스 정책이 접근 권한을 거부했습니다; 누락된 범위는 `WWW-Authenticate` 도 포함됩니다. 알 수 없는 프로젝트와 외국/개인 대화 UUID 는 `404` 를 반환합니다. 검증은 `422` 를, 페이징은 `400` 를, UUID/비상 충돌은 `409` 를, 쿼터 소진은 `429` 를 사용합니다.
