%{
  title: "인가",
  summary: "권한 범위, 조직 역할 및 리소스 수준의 접근 확인.",
  category: "참조",
  subcategory: "API",
  order: 2
}
---
인증은 신원을 확립하며, 권한 부여는 해당 신원이 수행할 수 있는 작업을 결정합니다. 보려면 [인증](/docs/reference/apis/authentication) 로그인 및 토큰 흐름에 대해 확인하세요.

## 범위

범위는 토큰이 수행할 수 있는 작업을 제어합니다. 이는 `object:action` 패턴을 따릅니다.

| 범위 | 설명 |
|-------|-------------|
| `admin:read` | 플랫폼 관리 데이터 읽기 (플랫폼 관리자 전용) |
| `admin:write` | 플랫폼 관리 데이터 업데이트 (플랫폼 관리자 전용) |
| `ops:read` | 플랫폼 운영 데이터 읽기 (플랫폼 관리자 전용) |
| `user:read` | 사용자 프로필 정보 읽기 |
| `user:write` | 사용자 프로필 업데이트 |
| `account:read` | 접근 가능한 조직 계정 목록 |
| `organization:read` | 조직 상세 정보 읽기 (내 조직 목록) |
| `organization:write` | 조직 생성 또는 수정 |
| `organization:claim` | 조직 소유 |
| `organization:delete` | 조직 삭제 |
| `organization:admin` | 조직 관리 작업 |
| `members:read` | 조직 구성원 및 초대 조회 |
| `members:write` | 조직원 및 초대 관리 |
| `project:read` | 프로젝트 읽기 |
| `project:write` | 프로젝트 생성 또는 업데이트 |
| `project:admin` | 프로젝트 관리 작업 |
| `project:delete` | 프로젝트 삭제 |
| `voice:read` | 음성 구성 읽기 |
| `voice:write` | 음성 구성 생성 또는 업데이트 |
| `voice:admin` | 관리자 음성 작업 |
| `glossary:read` | 용어집 항목 읽기 |
| `glossary:write` | 용어집 항목 생성 또는 수정 |
| `glossary:admin` | 용어집 설정 관리 |
| `discussion:read` | 토론 읽기 |
| `discussion:write` | 토론 생성 또는 수정 |
| `discussion:admin` | 토론 관리 작업 |
| `ticket:read` | 티켓 확인 |
| `ticket:write` | 티켓 생성 또는 수정 |
| `ticket:admin` | 관리\_ticket 작업 |
| `llm_model:read` | 계정 언어 모델 읽기 |
| `llm_model:write` | 계정 언어 모델 관리 |
| `translation:write` | 번역 데이터 쓰기 |
| `api_credentials:read` | 읽기 접근 자격 증명 |
| `api_credentials:write` | 접근 자격 증명 관리 |

인증 서버의 [발견 메타데이터](/docs/reference/apis/authentication#discovery-endpoints) 클라이언트에 사용할 수 있는 스코프를 게시합니다. 스코프 가 사용 가능하더라도 접근 권한이 자동으로 부여되는 것은 아닙니다.

## 권한 부여 모델

Glossia 는 강제합니다 **두 계층** 를 위한 [표현 상태 전이](https://developer.mozilla.org/en-US/docs/Glossary/REST) 애플리케이션 프로그래밍 인터페이스 및 [모델 컨텍스트 프로토콜](https://modelcontextprotocol.io) 서버:

1. **범위 확인**: 액세스 토큰에는 필요한 `object:action` 스코프.
2. **리소스 레벨 정책**: 현재 사용자는 명시적인 멤버 권한 또는 역할 기반 정책을 통해 특정 리소스에 대한 권한이 부여 되어야 합니다.

스코프는 *최대* 토큰의 능력입니다. 리소스 레벨 검증은 *실제* 특정 리소스에 대한 권한.

### 역할

| 역할 | 설명 |
|------|-------------|
| `self` | 자신의 리소스에 접근하는 사용자 |
| `organization_member` | 해당 리소스를 소유한 조직의 구성원 |
| `organization_admin` | 리소스를 소유한 조직의 관리자 |
| `public_account` | 리소스가 공공 계정에 속합니다 |

### 멤버 권한

관리자가 아닌 조직 멤버는 명시적인 권한 범위를 가질 수 있습니다. 새로운 멤버는 계정, 조직, 프로젝트, 음성, 사전, 토론, 및 티켓에 대한 읽기 접근 권한으로 시작합니다. 조직 관리자는 해당 범위를 교체 [멤버 → 권한](/docs/how-to/member-permissions). 요청된 작업은 멤버의 허용 범위와 토큰의 범위에 모두 포함되어야 합니다.

조직 관리자는 관리자 역할을 유지합니다. 명시적인 범위가 없는 기존 소속은 권한이 저장될 때까지 아래 역할 정책이 적용됩니다.

### 역할 권한

아래 표는 명시적인 범위가 없는 기존 소속에 대한 일반적인 역할 규칙을 보여줍니다. 이는 전체 정책이 아닙니다. 수집 요청, 임시 접근, 및 플랫폼 관리자에게는 추가 규칙이 적용됩니다.

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