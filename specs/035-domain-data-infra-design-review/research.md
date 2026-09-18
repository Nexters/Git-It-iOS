# 조사: Domain·Data·Infrastructure 설계 점검과 문서·네이밍 교정

기준 커밋 `b424b27`(branch `feature/domain-data-infra-design-review` 생성 시점). 수치는
`git ls-files`와 `grep`으로 실측했다.

## 1. 점검 결과 산출물의 형식과 위치

- **결정**: `docs/review/domain-data-infra-design-review.md` 한 파일에 발견 항목 표를 둔다.
  명세 031·032·033·034가 각각 `docs/review/<slug>-requirements.md`에 점검 근거를 남긴 관행을
  따르되, 이 문서는 요구사항이 아니라 점검 결과이므로 `-requirements` 접미어를 붙이지 않는다.
  항목 구조는 [data-model.md](./data-model.md)의 "발견 항목"을 따르고, 열 순서와 처리 구분
  값은 [contracts/review-record.md](./contracts/review-record.md)가 고정한다.
- **근거**: `specs/` 산출물은 당시 결정의 기록이라 후속 명세가 참조하기 어렵고(명세 가정),
  `docs/review/`는 이미 `README.md`가 색인하는 점검 문서 위치다. 후속 설계 변경 명세가 이
  문서의 항목 ID를 입력으로 삼는다.
- **검토한 대안**: (a) `specs/035-…/audit.md` — `speckit-implement`가 `specs/` 아래 새
  파일을 만들 근거가 없고 후속 명세의 참조 대상으로 부적합. (b) 각 패키지 README에 분산 —
  세 패키지를 한곳에서 대조하는 시나리오 1을 만족하지 못한다.

## 2. FR-017 패키지 관심사 원칙의 정본 위치

- **결정**: 정본은 [아키텍처 문서](../../docs/architecture.md) 2장 패키지 책임의 Domain·Data·
  Infrastructure 설명이다. 3.3 "Data ↔ Infrastructure"의 `UserRemote`/`HTTPUserRemote` 예시를
  기술 이름이 없는 예시로 바꾸고, 9장에 결정 기록 `D-ARCH-004`를 추가해 명세 035가 확정한
  원칙과 판정 기준(FR-017·FR-020, 명확화 5·6)을 남긴다. 패키지 규칙 3개와
  [네이밍 컨벤션 4장 패키지 문맥 표](../../docs/conventions/naming.md)는 정본을 참조만 하고
  판정 기준을 재서술하지 않는다(FR-018). 3.3의 새 예시는 `HTTPClient`를 `private let`으로만
  보여 주고 공개 initializer 시그니처를 싣지 않는다. 현행 Data 공개 initializer가 Infrastructure
  타입을 받는 사실은 DS-06으로 기록하고 D-ARCH-004에 이관 중임을 한 문장으로 적어, 예시가
  FR-017과 모순되지 않으면서(SC-010) 현재 코드를 부정하지도 않게(FR-005) 한다.
- **근거**: Constitution 원칙 1이 모듈 설계의 기준을 아키텍처 문서로 지정하고, D-ARCH-003이
  같은 방식으로 명세 013의 결정을 기록했다. 네이밍 컨벤션은 "패키지 책임이 바뀌면 이 문서보다
  Constitution과 아키텍처를 먼저 갱신"한다고 스스로 정한다.
- **검토한 대안**: (a) 네이밍 컨벤션 4장을 정본으로 — 원칙은 이름이 아니라 책임 경계에 관한
  것이라 소유 범위가 맞지 않는다. (b) Constitution 개정 — 원칙 10이 이미 "공급자 중립 경계에
  저장 기술·실행 환경 용어를 노출하지 않는다"고 정하므로 개정 없이 하위 문서에서 구체화할 수
  있다.

## 3. 규칙 문서와 코드의 불일치 실측

### 3.1 문서 쪽 불일치(문서 교정 대상)

| ID | 위치 | 불일치 |
| --- | --- | --- |
| DOC-01 | `docs/package-rules/infrastructure.md` 11행, 19행 | "Composition의 Adapter가 해당 API를 Data의 기술 계약과 연결", "Composition Adapter가 안정적으로 사용" — D-ARCH-003 이후 Data 내부 구현이 담당 |
| DOC-02 | `docs/architecture.md` 3.3 Data↔Infrastructure(151~182행) | `HTTPUserRemote` 예시가 Data 공개 타입에 기술 이름을 쓰는 형태를 규범으로 제시. FR-017과 모순 |
| DOC-03 | `docs/package-rules/data.md` 설명 2문단, 정책 5항 | "네트워크, 저장소, Keychain, 파일 시스템 … 계약을 정의" — 기술 능력을 Data 계약의 어휘로 서술. FR-017 원칙으로 재서술 필요 |
| DOC-04 | `sources/Projects/Domain/Authentication/README.md` 공개 모델 | 존재하지 않는 `AuthenticationOutcome`을 설명. 코드는 `AuthenticatedUser`·`AuthorizationStatus`만 소유 |
| DOC-05 | `docs/package-rules/infrastructure.md` 정책 2항 | "모든 내부 target은 하나의 범용 기술 기능" — `InfrastructureAuthentication`이 Apple 인증·Keychain·난수 생성 세 능력을 담는 현행과 불일치. 문서에 능력 묶음 target의 허용 조건을 설명하거나 target 분리를 후속으로 기록 |
| DOC-06 | `docs/conventions/naming.md` 4장 표 Data 행 | "필요한 기술 계약"이 Data 이름의 주된 문맥으로 적혀 있어 FR-017과 충돌 |
| DOC-07 | `docs/conventions/abstraction/structure-baseline.md` 3.1 | rename 대상 프로토콜 이름(`PendingGenerationReminderStore` 등)을 표에 적음. rename 시 이름만 갱신(FR-012) |
| DOC-08 | `docs/conventions/file-vocabulary/shape-vocabulary.md` Data 행 | Data가 실제로 쓰는 `Codings/`, `Layouts/`, `Migrations/`가 표에 없다(Composition 행에만 `Codings/`·`Layouts/`). 코드 6개 폴더가 어휘 밖 |
| DOC-09 | `docs/conventions/abstraction/structure-baseline.md` 3.1 Domain Authentication 행 | 계약 3개(`AuthenticationRepository`, `LoginSessionRepository`, `PolicyConsentRepository`)만 적혀 있고 코드의 `StoredSessionRepository`·`SharedSessionMarkerRepository`(Composition Adapter 있음)가 빠져 있다. 합계 47은 코드와 일치하므로 행 누락만 교정. rename 뒤 새 이름으로 추가 |

### 3.2 코드 쪽 불일치 — rename 후보

네이밍 컨벤션 4장(패키지 접두어 금지), FR-017·FR-019·FR-020, 명확화 5·6을 적용했다.
최종 rename 이름은 구현 단위가 정하되 아래 표의 방향을 따른다.

| ID | 현재 이름 | 위치 | 위반 근거 | 방향 |
| --- | --- | --- | --- | --- |
| RN-01 | `DataAuthenticationError` | Data/Authentication/Errors | 패키지 접두어 | Domain에 `AuthenticationError`가 있고 Composition Adapter가 둘을 함께 import하므로 구분 문맥은 실제 근거가 있다. 다만 패키지 이름이 아니라 오류가 분류하는 대상(서버 응답 실패)을 드러내는 이름으로 |
| RN-02 | `DataMemberError` | Data/Member/Errors | 패키지 접두어 | 위와 같음(Domain `MemberError`와 공존) |
| RN-03 | `DataLearningProjectError` | Data/LearningProject/Errors | 패키지 접두어 | 위와 같음(Domain `LearningProjectError`와 공존) |
| RN-04 | `DataExternalRepositoryError` | Data/ExternalRepository/Errors | 패키지 접두어 | 위와 같음(Domain `ExternalRepositoryError`와 공존). `offline`/`other` 두 case뿐이라 조회 실패 분류 이름으로 |
| RN-05 | `HTTPAuthenticationRemote` | Data/Authentication/Remotes | FR-017 기술 용어 | 역할 이름(예: `AuthenticationRemote`). 파일·폴더 `Remotes/`는 어휘표에 있어 유지 |
| RN-06 | `HTTPExternalRepositoryRemote` | Data/ExternalRepository/Remotes | FR-017 기술 용어 | 위와 같음 |
| RN-07 | `HTTPAnswerRemote`, `HTTPBookmarkRemote`, `HTTPLearningSetRemote`, `HTTPProjectRemote` | Data/LearningProject/Remotes | FR-017 기술 용어 | 위와 같음(4개) |
| RN-08 | `HTTPMemberRemote` | Data/Member/Remotes | FR-017 기술 용어 | 위와 같음 |
| RN-09 | `LearningProjectHTTPExecutor` | Data/LearningProject/Remotes | FR-017 기술 용어(internal이지만 파일 이름이 기술 노출) | 역할 이름 |
| RN-10 | `SessionRecordKeychainCoding`, `SessionKeychainMigration`, `SessionKeychainLayout`, `AppleIdentityKeychainLayout`, `AppleIdentityKeychainStore` | Data/Authentication | FR-017 기술 용어(Keychain) | 저장 매체 대신 역할(`SessionRecordCoding`, `SessionStorageMigration` 등). `Layout`의 `Key` rawValue(저장 key)는 FR-010으로 불변 |
| RN-11 | `LocalDeviceIdentifierStore`, `LocalGenerationStateStore`, `LocalPolicyConsentStore` | Data/Member, LearningProject, LegalConsent | `Local`은 기술이 아니라 위치 문맥 — 위반 아님 후보. 점검에서 "위반 아님" 근거 기록 | 유지 |
| RN-12 | `PendingGenerationReminderStore` | Domain/LearningProject/Contracts | FR-020 `Store` 접미어 | 역할 계약 이름(예: `PendingGenerationReminderQueue`는 여전히 구조 용어 — `PendingGenerationReminders` 계열로 판단) |
| RN-13 | `GenerationReminderRegistry` | Domain/LearningProject/Contracts | FR-020 `Registry` 접미어 | 역할 이름 |
| RN-14 | `NotificationAuthorizationGateway` | Domain/LearningProject/Contracts | FR-020 `Gateway` 접미어 | 역할 이름 |
| RN-15 | `ExternalRepositoryURLParser` | Domain/LearningProject/Contracts | FR-020 `Parser` 접미어 | 역할 이름(예: `ExternalRepositoryLocator`); Data의 `GitHubRepositoryURLParser`는 GitHub이 역할 대상이므로 서비스명 허용, `Parser`는 Data 어휘표 폴더 `Parsers/`와 일치 — 위반 아님 |
| RN-16 | `GenerationStateRepository.load()/save(_:)` | Domain/LearningProject/Contracts | FR-020 저장소 연산 이름 | 시그니처 불변 rename(예: `currentState()`/`record(_:)`). Data `GenerationStateStore`의 `load/save`는 Data 소유 저장 계약이라 FR-017 위반 아님(기술 이름 없음) |
| RN-17 | `StoredSessionRepository` | Domain/Authentication/Contracts | `Stored`가 저장 방식을 드러냄(FR-020 취지) | `currentSession()`만 제공하므로 역할 이름으로 |
| RN-18 | `SharedSessionMarkerRepository` | Domain/Authentication/Contracts | `Marker`는 App Group 저장 구현 용어 | 역할 이름(로그인 상태 공유 조회) |
| RN-19 | Domain README(`Domain/Authentication/README.md`) 및 Infrastructure README | 문서 | rename에 따른 이름 갱신 | FR-008 |

Domain `…Repository` 13개, `ExternalRepositoryLookup`, `GenerationReminderScheduler`,
`GenerationOutcomeRepository`는 명확화 6에 따라 허용한다. Data의 `GitHubRepositoryResponseDTO`,
`GitHubRepositoryRequest`, `AppleLoginRequestDTO`는 서비스가 역할 대상이라 허용한다.
Infrastructure 공개 이름은 기술 명칭 보존 대상이라 rename하지 않는다.

`HTTP…Remote` 8개의 rename은 초기화 인자 `client: HTTPClient`를 그대로 두는 이름 변경이다.
공개 initializer에서 `HTTPClient`·`KeychainStore`·`UserDefaultsStore`를 받는 사실 자체는
"Infrastructure 타입 노출"로 후속 설계 변경(DS-06)이다.

### 3.3 코드 쪽 불일치 — 후속 설계 변경 후보

| ID | 대상 | 근거 | 권장 방향 |
| --- | --- | --- | --- |
| DS-01 | `ExternalRepositoryLocation` (Domain·Data) | FR-014 조건 (3) 이름·필드(`owner`, `name`) 완전 동일. Adapter `ExternalRepositoryURLParserAdapter`가 필드 복사만 수행 | 관심사 중복 쌍. Domain 모델을 남기고 Data는 `GitHubRepositoryRequest` 인자로 흡수하거나, 위치 값의 소유자를 하나로 |
| DS-02 | `GenerationStateRepository` ↔ `GenerationStateStore` | FR-014 조건 (1) `load/save` 1:1. Adapter `GenerationStateRepositoryAdapter`가 DTO↔모델 변환 | 관심사 중복 쌍. 변환이 필드 복사인지 확인 후 Data DTO 제거 여부 판단 |
| DS-03 | `PendingGenerationReminderStore`(Domain) ↔ Data `PendingGenerationReminderCoding` | FR-014 조건 (1). 두 선언 모두 `drainProjectIDs() async -> [String]` 하나뿐이고 `PendingGenerationReminderStoreAdapter`가 인자·결과 변환 없이 위임 | 관심사 중복 쌍. Domain 계약 하나만 남기고 Data 타입이 직접 채택하거나 Composition이 클로저로 연결 |
| DS-04 | `APIResponseDTO`, `FieldErrorDTO`, `EmptyResponseData`, `ServerAPIError` 3중 반복 | Data Authentication·LearningProject·Member에 동일 선언. 명확화 4 | 공유 Data target 또는 서버 응답 봉투를 Infrastructure `HTTPClient` 응답으로 흡수 |
| DS-05 | `HTTPMethod` (Data LearningProject ↔ Infrastructure NetworkClient) | Data가 기술 타입을 재정의. 명확화 4 | Data 선언 제거, `LearningProjectRequest.method`가 Infrastructure 타입 사용 |
| DS-06 | Data 공개 initializer의 `HTTPClient`, `KeychainStore`, `UserDefaultsStore<…>` 인자 6곳 | FR-017 "기술을 Data 밖으로 노출하지 않는다" | Data가 소유하는 역할 계약 뒤로 숨기거나 Composition 조립에서만 보이게 |
| DS-07 | `InfrastructureAuthentication` target의 Keychain·RandomGenerator 하위 능력 | 패키지 규칙 "target 하나에 기술 기능 하나" | `InfrastructureKeychain`·`InfrastructureSecureRandom` 분리(target 분리는 FR-009b로 후속) |
| DS-08 | `InfrastructurePushMessaging/Remote/` 하위 능력 폴더 하나만 존재 | 어휘표는 `[<하위 능력>/]` 선택이라 위반 아님 후보 | 점검에서 판정 |
| DS-09 | Data `Codings/`, `Layouts/`, `Migrations/` 형태 폴더 | DOC-08과 짝. 폴더를 어휘표에 추가할지, `Stores/`·`Models/`로 재배치할지 | 이 기능은 어휘표 추가(문서 교정)로 해소하고 재배치는 후속 |

### 3.4 target 이름 점검

`DomainAuthentication`, `DomainLearningProject`, `DomainMember`, `DataAuthentication`,
`DataExternalRepository`, `DataLearningProject`, `DataLegalConsent`, `DataMember`,
`InfrastructureAuthentication`, `InfrastructureCache`, `InfrastructureLocalNotification`,
`InfrastructureNetworkClient`, `InfrastructurePushMessaging`, `InfrastructureStorage`와 각
Tests target을 [target·소스 폴더 규칙](../../docs/conventions/naming/target-source-folder.md)에
대조했다.

- **결정**: target 이름은 모두 `<패키지><역할>` 형식을 지키고 소스 루트는 접두어를 제거한
  역할 폴더라 규칙 위반이 없다. `InfrastructureAuthentication`은 이름이 아니라 구성(DS-07)의
  문제이므로 FR-009b에 따라 rename하지 않는다. `DataLegalConsent`가 Domain의
  `Authentication/Models/Consent`와 관심사 축이 어긋나는 점은 점검 결과에 "위반 아님(관심사
  분할은 설계)"으로 근거를 남긴다. 따라서 FR-009a의 target rename 절차(manifest·import·
  `tools/package-dependencies/config/source-roots`·`AllTestsScheme.swift`·
  `tools/script-tests/tests/test-testable-schemes.sh` 갱신)는 이번 실측에서 실행 대상이 없다.
  점검 단계에서 새 target rename 항목이 발견되면 같은 절차로 처리한다.
- **근거**: FR-009a는 범위 허용이지 rename 강제가 아니다. 이름이 잘못된 target이 없는데
  이름을 바꾸면 rename의 근거(FR-007)가 없다.

## 4. rename 참조 갱신 범위

`Data…Error` 4개를 참조하는 파일은 Data 31, Composition 7, docs 10이다(`grep -rl`).
`HTTP…Remote`는 Composition Assembly 4개와 Adapter, Data 테스트가 참조한다. 옛 이름을
참조하는 `docs/**` 문서는 `abstraction/structure-baseline.md`, `abstraction/protocol-criteria.md`,
`abstraction/test-double-injection.md`, `release/guideline-5-1-1-appeal.md` 4개다(`docs/spec-kit`·
`docs/retrospective`·`docs/review` 제외). Domain 계약 rename은 Composition Adapter 파일
이름(`…Adapter.swift`)과 Feature의 주입 이름(3파일, App은 참조 없음)까지 바뀌므로
Domain→Composition→Feature 순 integration unit이 필요하다.

- **결정**: rename은 패키지별 단일 단위가 아니라 "선언 소유 패키지 + 참조 패키지"를 묶은
  integration unit으로 계획한다. 분리하면 중간 commit이 compile되지 않는다(Constitution 7).
  단위 순서는 의존 위상(Domain → Data → Composition → Feature/App)을 따르되, 한 단위 안에서
  소유 패키지와 모든 참조를 함께 바꾼다.
- **검토한 대안**: typealias로 옛 이름을 남겨 단계적 전환 — FR-008 "옛 이름이 남아서는 안
  된다" 위반.

## 5. 검증 명령

| 검증 | 명령 | 근거 |
| --- | --- | --- |
| 빌드·테스트 | `"$project_build_runner" build`, `compile`, `test` | README·AGENTS.md. 사용자가 직접 실행 |
| 패키지 의존성 검사(SC-006) | `tools/package-dependencies/bin/run.sh` | 명세 034 |
| 옛 이름 잔존(SC-003) | `git grep -nE '<옛 이름 목록>' -- sources docs ':!docs/spec-kit' ':!docs/retrospective' ':!docs/review'` | `docs/spec-kit`·`retrospective`·`review`는 당시 기록 |
| 프로토콜 수 불변(FR-012) | structure-baseline.md 2절의 세는 명령 | 기준선 47개 |
| target·의존 간선 불변(SC-005) | `git diff --stat sources/Tuist/ProjectDescriptionHelpers/Projects/` 가 비어 있음 | 3.4 결정 |
| 문서 링크 | `tools/script-verification/bin/run.sh`는 셸만 검사 — 마크다운 링크는 `grep -o '](\.\./[^)]*)'`로 대상 존재 확인 | 기존 도구 없음 |
