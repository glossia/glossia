%{
  title: "권한",
  summary: "권한 범위, 조직 역할, 및 리소스 수준의 akses荣光.",
  category: "참조",
  subcategory: "API",
  order: 2
}
---

인증은 신원을 설정하며, 권한은 해당 신원이 수행할 수 있는 행위를 결정합니다. [인증](/docs/reference/apis/authentication) 에서 로그인 및 토큰 흐름을 확인하세요.

## 범위

`object:action` 패턴을 따릅니다.

| 범위 | 설명 |
|-------|-------------|
| `admin:read` | 플랫폼 관리 데이터 읽기 (플랫폼 관리자 전용) |
| `admin:write` | 플랫폼 관리 데이터 업데이트 (플랫폼 관리자 전용) |
| `ops:read` | 플랫폼 운영 데이터 읽기 (플랫폼 관리자 전용) |
| `user:read` | 사용자 프로필 정보 읽기 |
| `user:write` | 사용자 프로필 업데이트 |
| `account:read` | 접근 가능한 조직 계정 목록 |
| `organization:read` | 조직 세부 정보 읽기 (조직 목록 확인) |
| `organization:write` | 조직 생성 또는 업데이트 |
| `organization:claim` | 조직 소유권 요청 |
| `organization:delete` | 조직 삭제 |
| `organization:admin` | 조직 관리 작업 |
| `members:read` | 조직 회원 및 초대 읽기 |
| `members:write` | 조직 회원 및 초대 관리 |
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
| `analytics:read` | 프로젝트 웹사이트 분석 읽기 |
| `toki:read` | 제 자신의 사적인 프로젝트 대화 읽기 |
| `toki:write` | 제 자신의 사적인 프로젝트 대화 생성 및 동반자 답변 대기 |
| `api_credentials:read` | 접근 자격 증명 읽기 |
| `api_credentials:write` | 접근 자격 증명 관리 |

인증 서버의 [발견 메타데이터](/docs/reference/apis/authentication#discovery-endpoints) 는 클라이언트에게 제공 가능한 범위를 게시합니다. 특정한 범ويت 고 있는 것 만本身就 접근 권한을 부여하지 못합니다.

## 권한 모델

Glossia 는 **두 레이어** 를 [표현 상태 전달](https://developer.mozilla.org/en-US/docs/Glossary/REST) 응용 프로그램 인터페이스 및 [모델 컨텍스트 프로토콜](https://modelcontextprotocol.io) 서버에 적용합니다.

1. **범위 확인**: 접근 토큰은 필수 `object:action` 범위를 포함해야 합니다.
2. **리소스 레벨 정책**: 현재 사용자는 명시적 회원 권한 또는 역할 기반 정책을 통해 특정 리소스에 대해 권한을 부여받아야 합니다.

범위는 토큰의 *최대* 능력을 나타냅니다. 리소스 레벨 검사는 특정 리소스에 대한 *실제* 권한을 강제합니다.

### 역할

| 역할 | 설명 |
|------|-------------|
| `self` | 자신의 리소스에 접근하는 사용자 |
| `organization_member` | 리소스를 소유한 조직의 회원 |
| `organization_admin` | 리소스를 소유한 조직의 관리자 |
| `public_account` | 리소스는 공개 계정의 소유입니다. |

### 회원 권한

비관리자 조직 멤버십 은 명시적 범위 를 포함할 수 있습니다. 새 회원 은 계정, 조직, 프로젝트, 음성, 용어집, 토론, 티켓, 번역 활동, 분석 으로 읽기 접근권 및 제 자신의 사적인 프로젝트 대화 접근으로 시작합니다. 조직 관리자 는 [회원 → 권한](/docs/how-to/member-permissions) 을 통해 해당 범위를 대체할 수 있습니다. 토큰 사용 시 요청된 작업 은 회원의 허용 범위 및 토큰의 범위에 포함되어야 합니다.

사적인 프로젝트 대화 소유 는 조직 회원 범위 재정의 전에 확인됩니다. 멤버십 부여도 관리자 역할도 다른 사용자의 대화 접근을 허용하지 않습니다. 프로젝트 가시성 은 별도로 확인됩니다. 엔드포인트 범위 및 제한 사항을 확인하려면 [모바일 및 동반자 API](/docs/reference/apis/mobile) 를 참조하세요.

조직 관리자 는 관리자 역할을 유지합니다. 명시적 범위가 없는 기존 멤버십 은 권한이 저장될 때까지 아래和作用 기반 정책을 계속 사용합니다.

### 역할 권한

아래 표 는 명시적 범위가 없는 멤버십 에 대한 일반적인 역할 기반 규칙 을 보여줍니다. 이는 완전한 정책 이 아닙니다: 컬렉션 요청, 임시 접근 및 플랫폼 관리자 는 추가 규칙 이 있습니다.

| 범위 | 자기 자신 | 조직 회원 | 조직 관리자 | 공개 계정 |
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
