%{
  title: "권한",
  summary: "권한 범위, 조직 역할, 및 리소스 수준의 접근 권한 확인.",
  category: "참조",
  subcategory: "API",
  order: 2
}
---

인증은 신원을 설정하며, 권한 부여는 해당 신원이 수행할 수 있는 작업을 결정합니다. 로그인 및 토큰 흐름에 대해서는 [인증](/docs/reference/apis/authentication) 을 참조하세요.

## 범위

범위는 토큰이 수행할 수 있는 동작을 제어합니다. `object:action` 패턴을 따릅니다.

| 범위 | 설명 |
|-------|-------------|
| `admin:read` | 플랫폼 관리 데이터 읽기 (플랫폼 관리자 전용) |
| `admin:write` | 플랫폼 관리 데이터 수정 (플랫폼 관리자 전용) |
| `ops:read` | 플랫폼 운영 데이터 읽기 (플랫폼 관리자 전용) |
| `user:read` | 사용자 프로필 정보 읽기 |
| `user:write` | 사용자 프로필 수정 |
| `account:read` | 액세스 가능한 조직 계정 목록 |
| `organization:read` | 조직 상세 정보 읽기 (및 내 조직 목록) |
| `organization:write` | 조직 생성 또는 수정 |
| `organization:claim` | 조직 점유 |
| `organization:delete` | 조직 삭제 |
| `organization:admin` | 조직 관리자 작업 |
| `members:read` | 조직 구성원 및 초대 읽기 |
| `members:write` | 조직 구성원 및 초대 관리 |
| `project:read` | 프로젝트 읽기 |
| `project:write` | 프로젝트 생성 또는 수정 |
| `project:admin` | 프로젝트 관리자 작업 |
| `project:delete` | 프로젝트 삭제 |
| `voice:read` | 음성 설정 읽기 |
| `voice:write` | 음성 설정 생성 또는 수정 |
| `voice:admin` | 음성 관리자 작업 |
| `glossary:read` | 사전 항목 읽기 |
| `glossary:write` | 사전 항목 생성 또는 수정 |
| `glossary:admin` | 사전 설정 관리 |
| `discussion:read` | 토론 읽기 |
| `discussion:write` | 토론 생성 또는 수정 |
| `discussion:admin` | 토론 관리자 작업 |
| `ticket:read` | 티켓 읽기 |
| `ticket:write` | 티켓 생성 또는 수정 |
| `ticket:admin` | 티켓 관리자 작업 |
| `llm_model:read` | 계정 언어 모델 읽기 |
| `llm_model:write` | 계정 언어 모델 관리 |
| `translation:write` | 번역 데이터 작성 |
| `api_credentials:read` | 접근 자격 증명 읽기 |
| `api_credentials:write` | 접근 자격 증명 관리 |

인증 서버의 [검색 메타데이터](/docs/reference/apis/authentication#discovery-endpoints) 는 클라이언트에 사용할 수 있는 범위를 게시합니다. 범위가 사용 가능하다고 해서 접근 권한이 자동으로 부여되는 것은 아닙니다.

## 권한 부여 모델

Glossia 는 [표현 상태 전달](https://developer.mozilla.org/en-US/docs/Glossary/REST) 애플리케이션 프로그래밍 인터페이스와 [모델 컨텍스트 프로토콜](https://modelcontextprotocol.io) 서버에 대한 **두 가지 층위** 를 강제합니다:

1. **범위 확인**: 액세스 토큰에는 필수 `object:action` 범위를 포함해야 합니다.
2. **자원 레벨 정책**: 현재 사용자는 역할 기반 정책 또는 명시적 구성원 권한을 통해 특정 자원에 대해 권한 부여되어야 합니다.

범위는 토큰의 *최대* 기능을 나타냅니다. 자원 레벨 확인은 특정 자원의 *실제* 권한을 강제합니다.

### 역할

| 역할 | 설명 |
|------|-------------|
| `self` | 자신의 자원에 액세스하는 사용자 |
| `organization_member` | 자원을 소유하는 조직의 구성원 |
| `organization_admin` | 자원을 소유하는 조직의 관리자 |
| `public_account` | 资源化 (요소가) 는 공개 계정에 속합니다. |

### 구성원 권한

비관리자 조직 구성원 자격은 명시적 권한 범위를 보유할 수 있습니다. 새 구성원은 계정, 조직, 프로젝트, 음성, 사전, 토론 및 티켓에 대한 읽기 액세스에서 시작합니다. 조직 관리자는 [구성원 → 권한](/docs/how-to/member-permissions) 을 통해 해당 범위를 교체할 수 있습니다. 토큰을 사용할 때 요청된 작업은 구성원의 허용 범위 및 토큰의 범위에 모두 포함되어야 합니다.

조직 관리자는 관리자 역할을 유지합니다. 명시적 범위가 없는 기존 구성원 자격은 권한이 저장될 때까지 아래 역할 기반 정책을 계속 사용합니다.

### 역할 권한

아래 표는 명시적 범위가 없는 구성원 자격에 대한 일반적인 역할 기반 규칙을 보여줍니다. 이는 전체 정책이 아니며, 컬렉션 요청, 임시 액세스, 및 플랫폼 관리자는 추가 규칙을 갖습니다.

| 범위 | 자신 | 조직 구성원 | 조직 관리자 | 공개 계정 |
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
