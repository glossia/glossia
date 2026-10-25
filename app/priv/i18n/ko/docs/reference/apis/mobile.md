%{
  title: "모바일 및 동반 API",
  summary: "네이티브 UI, 프로필, 번역 내역, 분석 및 개인 Toki 대화.",
  category: "참조",
  subcategory: "API",
  order: 4
}
---

공공 네이티브 외관 카탈로그를 제외한 모든 엔드포인트는 Bearer 토큰이 필요합니다. 전체 스키마를 기술하는 [OpenAPI 사양](/api/openapi.json) 을 확인합니다. 기존 [OAuth PKCE 흐름](/docs/reference/apis/authentication) 를 통해 토큰을 소 모하십시오. 클라이언트에 추론 제공업체 키를 내장하지 마십시오.

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

토큰 범위는 한계일 뿐, 권한 부여가 아닙니다. 각 프로젝트 엔드포인트는 또한 사용자의 프로젝트 읽기 권한을 확인합니다. 두 번째 `project:read` **토큰** 범위는 필요하지 않지만, 명시적 권한을 갖춘 조직 멤버십은 프로젝트 읽기와 요청된 기능을 모두 허용해야 합니다. 새로운 멤버십에는 이러한 모바일 기능이 포함되며, 기존 명시적 멤버십은 자동으로 확장되지 않습니다.

개별 프로젝트는 기존 개인 - 조직 멤버십 규칙을 따릅니다. 계정 가시성은 공개 프로젝트 읽기를 제어합니다. 필요한 범위를 가진 인증된 외부 사용자는 공개 프로젝트의 번역 활동 및 분석을 읽을 수 있습니다. Toki 작성을 위해서는 계정 멤버십이 필요하므로, 공개 가시성만으로는 계정의 추론 크레딧을 소모하지 않습니다. 토키 대화는 공개 계정이라도 프로젝트 내에서 생성 사용자에게만 기록됩니다. 조직 및 플랫폼 관리자는 다른 사용자의 대화를 읽을 수 없습니다. 대화 UUID 를 알기만 해도 접근 권한은 아닙니다.

## 네이티브 외관

`GET /api/native/themes` 는 인증 또는 사용자/프로젝트 데이터를 동반하지 않고 선택된 Glossia 서버의 인스턴스 전역 외관 메타데이터를 반환합니다. 응답에는 `Cache-Control: public, max-age=300` 가 포함됩니다. 이는 모든 프로젝트 엔드포인트의 권한 부여 방식에는 영향을 미치지 않습니다.

응답에는 네 개의 필수 필드가 있습니다:

| 필드 | 값 |
|---|---|
| `schema_version` | 정수 `1` |
| `revision` | 공백이 없는 콘텐츠 대수본으로, 최대 128 자를 갖습니다 |
| `default_theme_id` | `"glossia"` |
| `themes` | 기본 Glossia 테마를 포함한 배열 |

기본 테마에는 `id: "glossia"` 와 `name: "Glossia"` , 공백이 없는 `description` 와 `typography: "standard"` 와 `button_radius: 8` 와 `card_radius: 12` 및 `light` 와 `dark` 팔레트가 있습니다. 반경은 숫자 논리 픽셀입니다. 각 팔레트는 아래 열거된 아홉 모든 필드를 불투명 `#RRGGBB` 색상으로 포함합니다:

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

카탈로그는 `app/priv/static/assets/styles.css` 의 `:root` 색상 및 반경 토큰에서 컴파일됩니다. 다크 팔레트는 네이티브 전용 철학 토큰만을 사용하여 웹 렌더링을 변경하지 않습니다. 토큰 변경 후 재구성을 통해 카탈로그와 그 결정론적 수정본이 업데이트됩니다. 수정본은 카탈로그 콘텐츠를 포함하며, 관련 없는 스타일시트 편집을 포함하지 않습니다. 개별 사용자 선호도나 런타임 테마 설정은 포함되지 않습니다.

## 프로파일

`GET /api/me` 는 인증된 사용자의 프로파일 만 반환하며:

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

`name` 는 `null` 가 될 수 있습니다. 핸들은 선택된 조직이 아닌 사용자의 개인 계정에 속합니다. `server_version` 는 실행 중인 애플리케이션의 버전입니다.

## 페이징

번역 및 대화 목록은 `page` (기본 `1`, 범위 `1–10000`) 와 `page_size` (기본 `20`, 범위 `1–50`) 를 허용합니다. 잘못된 값은 `400` 를 반환하며, 묵식적으로 제한하지 않습니다. 메타데이터는 다른 Glossia API 목록과 동일한 형식을 사용합니다:

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

목록은 동결된 스냅샷이 아닌 현재 상태를 보여줍니다. 대화 순서는 가장 최근에 업데이트된 것을 먼저 표시하며, UUID 가 결정론적 동점 해결 기준이 됩니다.

## 번역 활동

`GET /api/:handle/projects/:project/translations?page=1` 이 반환합니다:

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

상태는 `pending` , `running` , `completed` , `failed` 또는 `cancelled` 입니다. 작업이 대온 중이거나 사용할 수 없는 경우, 커밋 메시지, 소스 언어, 요약은 `null` 가 될 수 있습니다. 결과는 최신순으로 제한되며, 전용 프로젝트에만 적용됩니다.

`GET /api/:handle/projects/:project/translations/:id` 는 `{session: {...}}` 를 반환하며, 정확히 목록 세션 필드를 포함하고 Nullable `commit_sha` 이 추가됩니다. 이는 페이지네이션 또는 세션의 나이와 무관하게 응_received 프로젝트 및 계정 내에서 직접 정확한 UUID 조회입니다. 잘못된, 누락된, 그리고 외부 프로젝트 ID 는 `404` 와 `error: "not_found"` 를 반환하며; 인증 및 프로젝트 권한 부여가 먼저 실행됩니다 (`401`/`403`). 이 리소스를 열면 대화 생성, 메시지 전송, 추론 시작은 절대 발생하지 않습니다.이는 **세션 요약 수준의 출처** 을 제공하며, 번역된 섹먼트 텍스트 또는 번역된 결과 검토가 아닙니다.

## 분석

`GET /api/:handle/projects/:project/analytics?days=30` 를 반환합니다:

```json
{
  "summary": {
    "pageviews": 1350,
    "unique_visitors": 900,
    "locale_gap_visits": 180,
    "top_country": "DE",
    "top_browser_language": "de"
  },
  "top_pages": [{"pathname": "/docs", "pageviews": 420}],
  "days": 30
}
```

`days` 의 기본값은 `30` 이며, `1` 부터 `365` 까지 정수여야 합니다. 이동하는 UTC 보고 창은 요청 시간에 마감됩니다. 이는 대시보드와 동일한 프로젝트 범위 ClickHouse 속성액이며, 일중 회전 방문자 식별표를 포함합니다. Forte 페이지 목록은 최대 십 개 항목을 포함합니다. 빈 데이터셋은 영 수, 빈 토포스 문자열, 빈 페이지 목록을 반환합니다. 저장소 오류는 `503` 와 `error: "analytics_unavailable"` 를 반환하며, 인조 영 지표를 없습니다.

## Toki 대화

### 생성 및 목록

`POST /api/:handle/projects/:project/toki/conversations` 는 클라이언트 생성 UUID 를 받습니다:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

이는 `201` 를 `{conversation, messages: []}` 와 함께 반환합니다. 빈 대화는 제목 `New conversation` 와 상태 `completed` (비활동, 생성 미완료) 를 가집니다. 동일한 행위자, 프로젝트, 출처에 대한 동일 UUID 를 재생하면 다른 대화 없이 기존 세부 사항을 반환합니다. 다른 행위자, 프로젝트, 또는 출처에 대해 재사용하면 `409` 와 `error: "id_conflict"` 를 반환합니다.

`GET /api/:handle/projects/:project/toki/conversations` 는 `{conversations: [...], meta: {...}}` 를 반환합니다. 대화에는 `id`, `title`, `status`, `updated_at`, Nullable `error`, Nullable `translation_session_id` 이 포함됩니다. 제목은 두 번째 모델 호출이 아닌 첫 번째 사용자 메시지에서 파생됩니다.

### 번역 유래

생성은 동일한 프로젝트에서 번역 세션 UUID 를 선택적으로 받습니다:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

출처는 불변이며; 생략과 `null` 모두 출처가 없음을 의미합니다. 재시도는 메시지 보낸 후에도 동일한 출처를 제공해야 합니다. 나중에 출처를 연결하거나 재시도로 제거할 수 없습니다. 형식이 잘못된 출처는 `422` 를 반환하며; 누락되거나 외부 프로젝트 소스는 `404` 를 반환합니다. `translation:read` 토큰 범위 및 현재 정책 권한, `toki:write` 와 프로젝트 읽기 권한과 함께 추가적인 소스 연결 생성이 필요합니다. 클라이언트가 제공하는 소스 요약, 메타데이터, 역할 및 소유권은 무시됩니다. UUID 만 영구 저장되며, 서버는 응답 시간에 권한 부여 컨텍스트를 해석합니다.

연결된 대화는 닫히는 방식으로 실패하며**소스 연결 대화는 닫히는 방식으로 실패합니다**, 단순히 UUID 를 편집하는 것보다 현재 `translation:read` 범위 또는 정책 권한이 없는 경우, 세부 정보, 일치하는 출처 생성 재생, 메시지 전송 및 메시지 재생은 `403` 를 반환합니다. 간섭하지 않는 출처를 `409` 를 반환하며, 이력 또는 소스 메타데이터를 반환하지 않습니다. 목록은 제목 및 페이지네이션 카운트에 기여하는 전체 소스 연결 대화를 제외합니다. 이는 소스를 언급할 수 있는 초기 어시스턴트 메시지를 보호합니다. 누락된 범위는 일반 `WWW-Authenticate` 챌린지 를 포함합니다. 연결되지 않은 대화는 기존 토키만 권한 부여 동작을 유지합니다.

삭제되거나 이동된 소스도 실패 상태로 전환됩니다: 소스 연결 세부 정보, 전송 및 일치하는 생성 재시도는 `404` 를 반환하며, 목록에서 대화를 제외합니다. 소스 삭제 후 불변 UUID 가 유지되어 재시도가 조용히 연결되지 않을 수 없습니다. 참조는 연동된 foreign key 가 없습니다; 모든 사용자는 현재 소스 존재 여부 및 정확한 프로젝트/계정을 확인합니다. 소스 참조는 액세스 부여하거나 음성, 용어집 또는 공유 컨텍스트 변경을 하지 않습니다.

소스 연결 대화 생성 또는 열기는 **아니며** 메시지를 보내거나 추론을 큐에 추가하지 않습니다. 네이티브 탐색은 번역 세부 사항을 먼저 가져와야 하며, 명시적 사용자 액션 만이 대상을 생성하고 별도의 명시적 메시지 제출이 턴을 시작합니다. 제시문 발행, 공유 토론 검토 또는 에이전트 작성 도구는 제공되지 않습니다.

### 보내기 및 조회

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` 는 별도 클라이언트 생성 **메시지** UUID 를 받습니다:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

요청 데이터베이스 트랜잭션 내 사용자 메시지와 Oban 작업을 영구 저장합니다. 모델을 호출하지 않습니다. `202` 를 의도 상태 `queued` 와 현재 메시지와 함께 반환합니다. 상태가 `GET /api/:handle/projects/:project/toki/conversations/:id` 또는 `queued` 인 동안 `running` 를 조회하며; 상태가 `completed` 또는 `failed` 일 때 중지합니다.

세부 응답은 다음과 같은 형태를 가지며:

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

메시지는 역할 `user` 또는 `assistant` 를 가지며 시계순입니다. 대화는 최대 100 개의 메시지만 보유하므로 세부 엔드포인트는 별도의 페이지 요청 없이 전체 제한 이력을 반환합니다.

동일한 내용으로 메시지 UUID 를 재생하면, 완료 또는 실패 후에도 다른 추론을 큐에 추가하지 않습니다. 완료된 재생은 `200` 를 반환하며, 대기 중인 재생은 `202` 를 반환합니다. 다른 내용 또는 다른 대화에서 UUID 를 재사용하는 경우 `409` 를 반환합니다. 턴이 활성화하는 동안 다른 메시지를 제출하는 경우 `409` 와 `error: "conversation_busy"` 를 반환합니다.

### 모델 동작 및 제한

- 각 사용자 메시지는 최대 8,000 자 및 32,000 UTF-8 바이트의 공백 없는 텍스트이며, 무효 UUID, 타입 또는 콘텐츠는 `422` 를 반환합니다.
- 각 사용자는 프로젝트당 최대 100 개의 대화 및 프로젝트 간에 대기/실행 중인 대화 5 개 만 보유할 수 있습니다. 5 개 이상의 대기 중 턴은 `429` 를 반환하며, 대화/이력 제한은 `422` 를 반환합니다.
- 새 메시지는 정상 API 속도 제한 외에도 서버당 사용자당 시간당 30 개 제한됩니다. 재생은 추론 할당량을 소모하지 않습니다.
- 전용 Oban 큐는 서버당 2 가지 작업을 동시 실행합니다. 각 턴은 최대 1 개 제공자 HTTP 요청을 수행합니다: ReqLLM 은 제공자 요청을 준비하고, Oban 워커는 제공자 연결 후 HTTP 재시도 및 리디렉션 비활성화 상태로 동기적으로 이를 실행합니다. Condukt 세션, 분리된 추론 작업, 도구, 서브 에이전트 또는 파일 시스템 지침 로딩은 관여하지 않습니다. 제공자는 2,048 출력 토큰 상한선을 받으며, 어시스턴트 응답도 8,000 자 및 32,000 바이트로 제한됩니다.
- HTTP 연결 및 풀 대기 시간은 5 초, 소켓 수신 대기 시간은 60 초로 제한됩니다. Oban 워커는 90 초의 단단한 벽시계 데드라인을 가지며 (점적 응답 포함). 워커 종료가 로컬 추론 실행도 종료합니다. 원격 제공자가 이미 승인하여 연산은 취소될 수 없으므로 연결 중단은 보장할 수 없습니다. 따라서 모호한 실패는 자동으로 재시도되지 않습니다.
- 모델은 토큰 및 현재 멤버십이 `translation:read` 를 허용할 때 제한된 프로젝트 메타데이터 및 최신 3 개 번역 요약을 받습니다. 마지막 10 개의 대화 추출은 저장소와 독립적으로 제한되어 있습니다. 쓰기 기능 또는 일반 저장소 액세스가 없으며, 분석은 모델에 제공되지 않습니다.
- 소스 연결 대화의 경우, 모델은 최신에 상관없이 정확한 영구 저장된 소스를 추가로 받습니다 (UUID, 상태, 커밋 메타데이터, 언어, 카운트, 최대 1,000 자 요약). 컨텍스트는 `provenance: "session_summary"` 로 표시되며, 프롬프트는 이 요약 수준 제한을 보고하도록 요구합니다. 섹먼트 텍스트, 저장소 파일 또는 클라이언트 제공 소스 컨텍스트는 로드되지 않습니다.
- 자격 증명 은 계정(existing 생성 모델 및 서버 추론 설정을 통해 해결됩니다. 인터랙티브 CLI/OAuth 세션은 Toki 에 사용되지 않습니다. 누락 또는 지원되지 않는 자격 증명은 상태 `failed` 와 함께 `error: "provider_unavailable"` 를 생성합니다.
- 제공자 실패는 `inference_failed` 를 발생시키며; 빈 또는 넘친 출력은 `invalid_provider_response` 를 발생시킵니다. 원본 제공자 오류 및 비밀은 반환되지 않습니다. 실패 시 합성 어시스턴트 응답이 삽입되지 않습니다.
- 계정/프로젝트 액세스 및 소스 존재, 프로젝트/계정 관련 및 번역 권한은 추론 전과 후에 다시 확인됩니다. 해지된 액세스 또는 충분한 대기 중 범위가 턴을 `not_authorized` 로 실패하며; 삭제되거나 이동된 소스는 `source_unavailable` 로 실패합니다. 어느 실패에서도 어시스턴트 응답이 저장되지 않습니다.
- 회복 작업은 매 분마다 실행되며, 2 분 이상 경과한 실행 중인 작업 또는 15 분 이상 대기 중인 작업은 `failed` 로 표시하고 `inference_interrupted` 를 포함합니다. 이는 타임아웃, 종료 및 고아 작업에 대해 추론을 재시도하지 않고 결과를 확정합니다. 지연된 작업은 만료된 메시지를 주장하거나 더 새로운 턴을 덮어쓸 수 없습니다. 사용자는 오류 후 **새로운** 메시지 UUID 를 의도적으로 보낼 수 있습니다.

## 오류

`401` 는 인증이 실패했다고 이해합니다. `403` 는 스코프 또는 리소스 정책이 액세스를 거부했음을 의미하며, 누락된 스코프에는 `WWW-Authenticate` 챌린지가 포함됩니다. 알 수 없는 프로젝트와 외국/사密的 대화 UUID 는 `404` 를 반환합니다. 검증은 `422` 를, 페이징은 `400` 를, UUID/버스 충돌은 `409` 를, 할당량 고갈은 `429` 를 사용합니다.
