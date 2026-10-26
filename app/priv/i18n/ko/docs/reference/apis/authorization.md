%{
  title: "권한",
  summary: "권한 범위, 조직 역할, 및 리소스 수준의 접근 권한 확인.",
  category: "참조",
  subcategory: "API",
  order: 2
}
---

인증은 신원을 확립하고; 권한 부여는 해당 신원이 수행할 수 있는 작업을 결정합니다. 로그인 및 토큰 흐름에 대해 [인증](/docs/reference/apis/authentication) 을 확인하세요.

## 범위

범위는 토큰이 수행할 수 있는 작업을 제어합니다. `object:action` 패턴을 따릅니다.

| 범위 | 설명 |
|-------|-------------|
| `admin:read` | 플랫폼 관리 데이터 읽기 (플랫폼 관리자 전용) |
| `admin:write` | 플랫폼 관리 데이터 업데이트 (플랫폼 관리자 전용) |
| `ops:read` | 플랫폼 운영 데이터 읽기 (플랫폼 관리자 전용) |
| `user:read` | 사용자 프로필 정보 읽기 |
| `user:write` | 사용자 프로필 업데이트 |
| `account:read` | 접근 가능한 조직 계정 목록 |
| `organization:read` | 조직 세부 정보 읽기 (및 내 조직 목록) |
| `organization:write` | 조직 생성 또는 업데이트 |
| `organization:claim` | 조직 소유권 주장 |
| `organization:delete` | 조직 삭제 |
| `organization:admin` | 조직 관리 작업 |
| `members:read` | 조직 구성원 및 초대 읽기 |
| `members:write` | 조직 구성원 및 초대 관리 |
| `project:read` | 프로젝트 읽기 |
| `project:write` | 프로젝트 생성 또는 업데이트 |
| `project:admin` | 프로젝트 관리 작업 |
| `project:delete` | 프로젝트 삭제 |
| `voice:read` | 음성 설정 읽기 |
| `voice:write` | 음성 설정 생성 또는 업데이트 |
| `voice:admin` | 음성 관리 작업 |
| `glossary:read` | 용어집 항목 읽기 |
| `glossary:write` | 용어집 항목 생성 또는 업데이트 |
| `glossary:admin` | 용어집 설정 관리 |
| `discussion:read` | 토론 읽기 |
| `discussion:write` | 토론 생성 또는 업데이트 |
| `discussion:admin` | 토론 관리 작업 |
| `ticket:read` | 티켓 읽기 |
| `ticket:write` | 티켓 생성 또는 업데이트 |
| `ticket:admin` | 티켓 관리 작업 |
| `llm_model:read` | 계정 언어 모델 읽기 |
| `llm_model:write` | 계정 언어 모델 관리 |
| `translation:read` | 프로젝트 번역 활동 읽기 |
| `translation:write` | 번역 데이터 작성 |
| `analytics:read` | 프로젝트 웹사이트 분석 지표 읽기 |
| `toki:read` | 내 개인 프로젝트 대화 읽기 |
| `toki:write` | 개인 대화를 생성하고 동반 응답을 대기열에 추가합니다 |
| `api_credentials:read` | 접근 자격 증명 읽기 |
| `api_credentials:write` | 접근 자격 증명 관리 |

인증 서버의 [발견 메타데이터](/docs/reference/apis/authentication#discovery-endpoints) 는 클라이언트에 사용할 수 있는 상태를 공표합니다. 범위가 사용 가능하다고 해서 접근 권한이 스스로 부여되는 것은 아닙니다.

## 권한 부여 모델

글로시아는 [표현 상태 전달](https://developer.mozilla.org/en-US/docs/Glossary/REST) 응용 프로그램 프로그래밍 인터페이스 와 [모델 컨텍스트 프로토콜](https://modelcontextprotocol.io) 서버에 대해 **두 계층** 을 적용합니다:

1. **범위 확인**: 액세스 토큰은 필수 `object:action` 범위를 포함해야 합니다.
2. **자원 수준의 정책**

스코프는 토큰의 *최대* 기능성을 나타냅니다. 자원 수준의 확인은 특정 리소스에 대한 *실제* 권한을 적용합니다.

### 역할

| 역할 | 설명 |
|------|-------------|
| `self` | 자신의 리소스에 접근하는 사용자 |
| `organization_member` | 리소스를 소유한 조직의 구성원 |
| `organization_admin` | 리소스를 소유한 조직의 관리자 |
| `public_account` | 리소스가 공개 계정에 속함 |

### 구성원 권한

비관리자 조직 자격은 명시적인 권한 스코프를 포함할 수 있습니다. 새 구성원은 계정, 조직, 프로젝트, 음성, 용어집, 토론, 티켓, 번역 활동, 분석 지표 등에 대한 읽기 접근 권한으로 시작되며, 자신의 개인 Toki 대화 접근도 포함됩니다. 조직 관리자는 [구성원 → 권한](/docs/how-to/member-permissions) 을 통해 이러한 스코프를 대체할 수 있습니다. 토큰을 사용할 때 요청된 작업은 구성원의 허용된 스코프에도 포함되어야 하며 토큰의 스코프에도 포함되어야 합니다.

Toki 의 개인 소유권은 조직 구성원 스코프 중첩을 확인하기 전에 확인됩니다. 구성원 자격이나 관리자 역할 모두 다른 사용자의 대화 접근을 허용하지 않습니다. 프로젝트 가시성은 별도로 확인됩니다. 엔드포인트 스코프 및 한도에 대해서는 [모바일 및 동반 API](/docs/reference/apis/mobile) 를 참조하세요.

조직 관리자는 자신의 관리자 역할을 유지합니다. 명시적 스코프가 없는 기존 자격은 권한이 저장될 때까지 아래의 역할 기반 정책을 계속 사용합니다.

### 역할 권한

아래 표는 명시적 스코프가 없는 자격에 대한 일반적인 역할 기반 규칙을 보여줍니다. 이는 전체 정책이 아닙니다: 컬렉션 요청, 임시 액세스, 플랫폼 관리자가 추가 규칙을 지정합니다.

| 범위 | 본인 | 조직 구성원 | 조직 관리자 | 공개 계정 |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | 예 | 예 | | |
| `user:write` | 예 | | | |
| `account:read` | | 예 | 예 | 예 |
| `organization:read` | | 예 | 예 | |
| `organization:write` | | | 예 | |
| `organization:delete` | | | 예 | |
| `organization:admin` | | | 예 | |
| `members:read` | | 예 | 예 | |
| `members:write` | | | 예 | |
| `project:read` | | 예 | 예 | 예 |
| `project:write` | | | 예 | |
| `project:admin` | | | 예 | |
| `project:delete` | | | 예 | |
| `voice:read` | | 예 | 예 | 예 |
| `voice:write` | | | 예 | |
| `voice:admin` | | | 예 | |
| `glossary:read` | | 예 | 예 | |
| `glossary:write` | | | 예 | |
| `glossary:admin` | | | 예 | |
