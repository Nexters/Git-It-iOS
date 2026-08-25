# 0단계 조사: 온보딩·로그인·튜토리얼 App 통합

## 1. 멤버 프로필 nullability와 오류 분류

- **결정**: `position`과 `careerLevel`을 Data DTO부터 Domain `MemberProfile`까지 각각 optional로
  보존한다. JSON null은 미설정, 지원하지 않는 non-null raw value는 계약 오류로 구분한다.
- **근거**: 한 필드만 null이어도 전체 curation을 다시 시작해야 하며 unknown 문자열을 nil로
  바꾸면 미설정으로 오분류된다. 현재 DTO와 Domain 모델은 nonoptional이라 변경이 필요하다.
- **검토한 대안**: `.unknown` 또는 기본값 치환, 전체 profile을 nil로 치환, unknown raw를 nil로
  치환. 모두 필드별 null 의미 또는 오류 분류를 잃는다.

## 2. 멤버 404와 세션 정리

- **결정**: `(404, MEMBER-001)`만 가입되지 않음으로 분기하고 명시적 로컬 인증 정리 성공 뒤에만
  tutorial 1페이지로 이동한다. 정리 실패를 표현할 수 있도록 Domain UseCase 결과 계약을 보완한다.
- **근거**: 기존 `SignOut`은 repository 오류를 삼키고 항상 `.unauthenticated`를 반환하므로
  FR-033의 실패 상태를 판정할 수 없다. transport·5xx·decoding은 재시도 오류로 유지해야 한다.
- **검토한 대안**: 모든 404를 미가입 처리, 기존 SignOut 결과를 무조건 성공으로 간주, Feature가
  repository를 직접 호출. 각각 오분류, 실패 은폐, 패키지 경계 위반을 만든다.

## 3. 정책 동의 저장과 manifest

- **결정**: 안정적 문서 ID, 표시 이름, 승인 URL, 현재 버전, 필수 여부는 App 번들 manifest로
  공급하고 Domain이 유효성 정책을 판정한다. 최초 manifest는 개인정보 처리방침을
  `privacy-policy`/`1`, 서비스 이용 약관을 `terms-of-service`/`1`로 고정한다. 문서별
  `{documentID, version, acceptedAt}`은 계정 식별자 없이 설치 단위 local store에 보존하며
  session record와 분리한다.
- **근거**: 기존 `LocalOnboardingState`의 `[String]`과 단일 `acceptedAt`은 문서별 기록을 표현하지
  못하고, session record는 로그아웃 시 삭제되어 FR-034~041의 수명과 충돌한다.
- **검토한 대안**: session blob 유지, Feature/App의 직접 UserDefaults 접근, 계정별 저장, 외부 문서
  수정 시각을 버전으로 추론. 각각 수명·경계·개인정보·명시 버전 요구를 위반한다.

### 3.1 저장 기술 검증과 결정 (`/speckit-analyze` 세션 2026-08-26 F2 보완)

- **검증 대상과 결과**: FR-041은 정책 동의 기록이 "로그아웃 또는 session invalidation 후에도
  유지"되고 "앱 데이터 삭제 시 무효화"되는 두 수명 요건을 동시에 만족해야 한다. 현재
  Infrastructure가 제공하는 범용 저장 API 두 종류를 직접 확인했다.
  - `KeychainStore`(`sources/Projects/Infrastructure/Authentication/Keychain/KeychainStore.swift`):
    Keychain 항목은 iOS 기본 동작상 앱 삭제 후에도 유지되는 경우가 있어(재설치 시 이전 값이
    남을 수 있음) "앱 데이터 삭제 시 무효화" 요건을 만족한다고 확정할 수 없다.
  - `InMemoryCache`(`sources/Projects/Infrastructure/Cache/InMemoryCache.swift`): 프로세스 메모리
    범위만 보관하며 앱 재실행마다 소실되므로 "로그아웃 후에도 유지" 요건을 만족하지 못한다.
  - 두 API 모두 두 요건을 동시에 만족하지 못해 FR-041을 위한 새 범용 기술 API가 필요하다.
- **결정**: Infrastructure에 `UserDefaultsStore` API를 신설한다. `UserDefaults`(앱 sandbox의
  `Library/Preferences`)는 앱이 삭제되면 sandbox 전체와 함께 제거되어 "앱 데이터 삭제 시
  무효화"를 만족하고, 로그아웃이나 프로세스 재시작으로는 삭제되지 않아 "로그아웃 후에도
  유지"를 만족한다. 정책 동의 기록은 회원·Apple 계정 식별자를 포함하지 않는 비민감 데이터(문서
  ID·version·시각)이므로 Keychain 수준의 암호화 저장이 필요하지 않다. `Data/LegalConsent/
  Stores/LocalPolicyConsentStore.swift`는 `KeychainStore`와 같은 패턴으로 이 신규 Infrastructure
  API 위에서 concrete 구현을 소유한다([Data ↔ Infrastructure 경계](../../docs/architecture.md)).
- **근거**: `docs/architecture.md` 3.1은 `Data → Infrastructure`를 허용하고, Infrastructure
  패키지 규칙은 "네트워크, 저장소, 로깅, 분석과 같은 범용 기술 기능"을 명시적으로 포함한다.
  `InMemoryCache`가 이미 이 패턴(제네릭 key-value 범용 API)을 따르므로 같은 스타일의 영속
  버전을 추가하는 편이 새 외부 의존성 도입보다 일관적이다.
- **검토한 대안**:
  - `KeychainStore` 재사용(kSecAttrAccessibleAfterFirstUnlock 등 accessibility 조정으로
    우회): iOS가 앱 삭제 시 Keychain 항목 삭제를 보장하지 않으므로 FR-041의 "무효화" 요건을
    코드만으로 충족한다고 확정할 수 없어 기각.
  - `InMemoryCache` 재사용 또는 확장: 프로세스 재시작마다 소실되어 "로그아웃 후 유지" 요건을
    구조적으로 만족하지 못해 기각.
  - Data 또는 Composition에서 `UserDefaults`를 직접 호출: Infrastructure가 외부 기술을
    범용 API 뒤로 격리해야 한다는 패키지 규칙(제약조건 1문단)을 위반해 기각.
  - 외부 라이브러리(예: 서드파티 DB) 도입: 이미 표준 `UserDefaults`로 요건을 충족하므로
    새 외부 의존성을 정당화할 근거가 없어 기각.
- **영향**: 이 결정으로 Infrastructure가 적용 대상 패키지에 추가된다. `plan.md`의 규모/범위,
  프로젝트 구조와 패키지 구현 경계·승인 순서를 갱신했다.

## 4. 정책 링크 열기 경계

- **결정**: 승인 URL은 외부 브라우저로 열고 운영체제가 반환하는 열기 요청 성공·실패만 앱이
  관측한다. 실패는 문서별 상태와 재시도 action으로 제공하지만 동의 선택, continue, sign-in 조건을
  바꾸지 않는다. 브라우저가 열린 뒤의 HTTP·network load 결과는 앱 상태로 추적하지 않는다.
- **근거**: 정책 열람은 선택 사항이고 외부 브라우저의 navigation 수명은 앱이 소유하지 않는다.
  이 경계는 동의 게이트와 외부 문서 가용성을 분리하면서 검증 가능한 실패만 계약으로 남긴다.
- **검토한 대안**: 앱 내부 WebView로 load 결과 추적, 모든 실패를 인증 오류로 변환, 링크 성공을
  동의 조건으로 사용. 각각 범위 확대, 오류 의미 혼합, 명세의 선택적 열람 원칙과 충돌한다.

## 5. Onboarding 상태와 App root

- **결정**: Feature는 `splash`, `restoreError`, `tutorial(page)`, `legalAgreement`, `position`,
  `career`, `completing` 중 하나의 phase만 소유하고 request identity로 늦은 응답을 무시한다. App은
  `restoring`, `onboarding`, `mainShell`의 root와 Feature delegate 연결만 소유한다.
- **결정**: Apple sign-in 결과는 `success`, `cancelled`, `retryableFailure`로 구분하고 sign-in에도
  request identity를 적용해 사용자가 단계를 떠난 뒤 도착한 응답을 무시한다.
- **근거**: Feature 내부 presentation과 Feature 간 root navigation을 분리하면서 모순 화면과
  중복 요청을 상태 구조로 차단할 수 있다.
- **검토한 대안**: 여러 bool로 화면 제어, App이 onboarding 세부 phase 소유, View가 UseCase 직접
  호출. 각각 상태 모순, Feature 책임 침범, FR-018/019 위반을 만든다.

## 6. Composition graph

- **결정**: `GitItApp` 수명에 저장된 단일 `AppComposition.live` 결과를 root store 생성에 주입한다.
  `CompleteCurationUseCase`는 profile과 같은 Member graph를 단일 정본으로 사용한다.
- **근거**: 현재 AuthenticationAssembly와 MemberAssembly가 curation을 중복 조립하며 App은 아직
  composition을 생성하지 않는다. 수명당 한 graph와 공유 session 정본이 필요하다.
- **검토한 대안**: View body마다 live 생성, 전역 locator, 이중 assembly 유지. 각각 중복 생성,
  주입 원칙 위반, 책임과 수명 불명확성을 남긴다.

## 7. UI 재사용과 접근성

- **결정**: 기존 UIComponent를 기본으로 쓰고 `SelectionCard/List`의 단일 선택 callback·selected
  trait 등 공용 표현 계약만 UI에서 보강한다. 화면의 업무 매핑과 TCA action은 Feature에 둔다.
- **근거**: ActionButton은 44pt hit area를 이미 보장하고 SelectionCard는 selected trait를 제공하지만
  SelectionCardList는 선택/callback을 받지 않는다. 화면-local 중복 컴포넌트는 금지된다.
- **검토한 대안**: Feature-local 카드·버튼 구현, UI API에 Domain enum 또는 Feature State 노출.
  각각 재사용 책임과 패키지 경계를 위반한다.

## 8. Figma 비교 근거

- **결정**: node `737:10358`(미선택)과 `737:10349`(선택)의 직접 메타데이터·360×800 렌더에서
  표시 순서를 다음과 같이 확정한다.

| 순서 | 표시 제목 | 설명 | Domain 매핑 |
|---:|---|---|---|
| 1 | 입문 | 프로젝트 코드를 처음 살펴봐요. | `CareerLevel.entry` |
| 2 | 주니어 | 작은 기능 단위로 코드를 이해할 수 있어요. | `CareerLevel.junior` |
| 3 | 미들 | 프로젝트 구조와 흐름을 함께 살펴봐요. | `CareerLevel.midLevel` |
| 4 | 시니어 | 설계 의도와 변경 영향을 분석할 수 있어요. | `CareerLevel.senior` |

- **근거**: 두 node 모두 같은 카드 순서를 사용하며 `737:10349`는 첫 카드 선택과 활성화된 다음
  버튼을 보여 준다. 화면 질문은 “실제 프로젝트 코드를 어느 정도 이해할 수 있나요?”다.
- **검토한 대안**: `beginner` 유지, `student`로 rename, enum 선언 순서 자동 사용, section 전체
  이미지 추정, `CareerLevel.unknown` 추가. 확정한 `entry` 공개 이름, 명시적 1:1 매핑과 개별 node
  근거를 충족하지 못한다.
- **제약**: Figma `get_design_context`는 두 차례 예기치 않은 오류를 반환했다. 구현 시 자산·token
  세부값은 node context가 정상화된 뒤 재확인하고, 현재 계획은 직접 metadata와 원본 렌더에서
  확인 가능한 문구·순서·상태만 확정한다.

- **결정**: 필수 시각 비교 7종은 tutorial `779:33450`·`779:33529`·`779:33564`, 약관 전체 선택
  `786:38332`, 분야 선택 `737:10367`, Career 미선택·선택 `737:10358`·`737:10349`로 고정한다.
- **근거**: section `4113:6393`의 metadata와 개별 node context에서 화면과 상태를 직접 식별했다.
  Figma의 Google 로그인 표현, 개인정보 관련 명칭, 분야 화면 닫기 표현과 360×800 frame은 각각
  명세의 Apple 로그인, `개인정보 처리방침`, sign-out 복귀 동작, `iPhone 17 Pro Max` 기준을
  대체하지 않으며 승인된 차이로 기록한다.
- **검토한 대안**: section 전체 비교, 구현 중 node 선택, Figma 문구·동작을 명세보다 우선.
  각각 상태별 추적성을 잃거나 승인된 기능 계약과 충돌한다.

## 9. Preview와 검증 진입점

- **결정**: 기능 화면마다 파일 하단 deterministic `#Preview`를 두고 이름에 node/state ID를 넣는다.
  FeatureTests target과 shared scheme Test Action을 추가하며 전체 검증은 project build runner의
  `build → compile → test` 순서를 사용한다.
- **근거**: 명세는 screen-local Preview를 요구하지만 현재 Feature는 화면·test target이 없다.
  `docs/conventions/view.md`와의 제한적 예외는 계획 및 PR에 기록한다.
- **검토한 대안**: UI PreviewApp만 사용, 분리 Preview 파일만 사용, 검증하지 않은 checklist 기록.
  실제 Feature 상태 재현성과 수용 기준 추적을 충족하지 못한다.

## 10. LoginResponse.needsCuration 필드와 활용 범위

- **결정**: `POST /api/v1/auth/login/apple` 200 응답의 `LoginResponse`에는 `needsCuration: Boolean`
  필드가 포함된다. 로그인 직후 경로에서 `needsCuration: true`이면 curation으로 이동하고,
  `false`이면 별도 profile 조회 없이 MainShell로 이동한다. 세션 복구 경로(앱 재시작)에서는
  로그인 응답이 없으므로 `FetchMemberProfileUseCase`를 통한 `position`/`careerLevel` null 여부
  판정을 유지한다. `needsCuration` 활용 범위와 `SignInUseCase` 결과 타입 포함 여부는 Domain
  UseCase 계약 설계에서 결정한다.
- **근거**: API 문서 `LoginResponse` schema(`#/components/schemas/LoginResponse`)에 `needsCuration:
  { type: boolean }`이 명시되고, 설명도 "true면 큐레이션 정보를 받지 않은 회원이므로 온보딩 화면으로
  보내야 합니다"라고 안내한다. 로그인 직후 이 필드를 무시하고 별도 profile 조회를 항상 실행하면
  불필요한 추가 요청이 발생한다. `needsCuration: false`일 때 서버가 null profile을 반환하면 서버
  계약 위반이므로 앱은 서버 응답을 신뢰한다.
- **검토한 대안**: 로그인 후에도 항상 `FetchMemberProfileUseCase`를 호출해 null 여부로 판정.
  복구 경로 판정 규칙(FR-002)은 유지되지만 로그인 경로에서 `needsCuration` 활용이 더 효율적이다.

## 11. careerLevel API raw value — MIDDLE vs midLevel

- **결정**: 서버의 `careerLevel` raw value는 `ENTRY`, `JUNIOR`, `MIDDLE`, `SENIOR`이다.
  Domain의 `CareerLevel` 공개 이름(`entry`, `junior`, `midLevel`, `senior`)과 `MIDDLE`/`midLevel`이
  다르므로 Data DTO 레이어에서 `"MIDDLE"` → `CareerLevel.midLevel` 명시 변환을 구현한다.
  `CurationRequest` 직렬화에서도 `CareerLevel.midLevel` → `"MIDDLE"` 변환을 수행한다.
- **근거**: API 문서 `CurationRequest`, `CareerLevelRequest` schema 모두 enum에 `"MIDDLE"`을
  명시한다. Domain의 `midLevel`은 Swift 관례에 따른 내부 공개 이름이고 서버 raw value가
  고정 계약이므로 Data 레이어가 변환 책임을 소유한다.
- **검토한 대안**: Domain을 `MIDDLE`로 변경, 자동 `rawValue` 매핑 사용. Domain 네이밍이
  Swift 관례와 어긋나거나 명세의 `entry` 변경과 일관성을 잃는다.

## 12. position API raw value 확인

- **결정**: 서버의 `position` raw value는 `BACKEND`, `FRONTEND`, `IOS`, `ANDROID`이며 `WEB`은
  서버 API에 없다. Data DTO 레이어에서 각각 `MemberPosition.backend`, `.frontend`, `.ios`,
  `.android`로 변환한다. `PositionRequest`·`CurationRequest` 직렬화도 같은 역방향 변환을 사용한다.
  지원하지 않는 non-null raw value(예: 미래 추가 값)는 계약/decoding 오류로 처리한다.
- **근거**: API 문서 `PositionRequest`, `CurationRequest` schema의 position enum은
  `["BACKEND", "FRONTEND", "IOS", "ANDROID"]`로 `WEB`이 없다. 명세(FR-011)의
  `MemberPosition.web` 미노출 규칙과 일치하며, `.web`은 UI에서도 노출하지 않는다.
- **검토한 대안**: `WEB`을 raw value로 보존하거나 nil로 치환. 서버 API에 없으므로 변환 대상에서
  제외하고, unknown raw value는 nil이 아닌 오류로 처리한다(research 섹션 1 결정과 일치).

## 13. GET /api/v1/members/me — position/careerLevel nullable 확인

- **결정**: `GET /api/v1/members/me` 200 응답 example에서 `position`, `careerLevel`은 non-null
  문자열로 표시된다. API 문서에 해당 응답의 공식 schema 선언이 없어 null 허용 여부가 schema로
  명시되지 않았다. 명세(FR-002, FR-030)의 null 보존 요구와 세션 2026-08-25의 "프로필 필드 null은
  미설정으로 판정" 답변을 우선 계약으로 유지한다. Data DTO의 `position`, `careerLevel`은
  `String?`으로 선언하고 null 수신 시 손실 없이 Domain까지 전달한다.
- **근거**: 서버 example에 null이 없더라도 명세 세션에서 null 도달 경로를 명시적으로 확인했고,
  `needsCuration: true`인 회원은 profile null 필드를 가질 수 있다는 서버 의도와 일치한다.
  schema에 nullable 선언이 없는 경우 명세 계약을 우선하고 DTO에서 방어적으로 처리한다.
- **검토한 대안**: non-null로 DTO를 선언하고 디코딩 오류를 retryableFailure로 처리. null을
  정상 도달로 처리하는 명세 계약(세션 2026-08-25 답변)과 충돌한다.

## 14. 인증 액션 결과 타입과 상태 조회 타입 분리

- **결정**: `AuthenticationOutcome`은 `ObserveAuthenticationOutcomesUseCase`가 노출하는 상태 조회
  전용 타입으로 유지하고 `authenticated(AuthenticatedUser)`/`unauthenticated`/`recoverableFailure`
  3케이스를 그대로 둔다. `SignInUseCase`는 신규 `SignInResult`(`success(AuthenticatedUser)`/
  `cancelled`/`retryableFailure`)를, `SignOutUseCase`는 신규 `SignOutResult`(`success`/
  `retryableFailure`)를, `RestoreSessionUseCase`는 신규 `RestoreSessionResult`
  (`authenticated(AuthenticatedUser)`/`unauthenticated`/`recoverableFailure`)를 각각 반환하도록
  Domain 계약을 상태 조회 타입과 분리한다.
- **근거**: `AuthenticationOutcome`은 상태 조회 목적으로는 정확히 3케이스가 맞지만, 기존
  `SignInUseCase`가 이를 재사용하면서 Apple 로그인 취소(`AuthenticationError.cancelled`)가
  `.unauthenticated`로 병합돼 FR-009·시나리오2-5·SC-003이 요구하는 `success`/`cancelled`/
  `retryableFailure` 3분류를 표현할 수 없었다(`/speckit-analyze` 세션 2026-08-26 발견,
  `sources/Projects/Domain/Authentication/UseCases/SignIn.swift`). 사용자는 상태 조회와 액션
  결과를 분리하는 원칙을 확정하고 `SignOutUseCase`·`RestoreSessionUseCase`에도 동일 원칙을
  적용하도록 답변했다.
- **검토한 대안**: `AuthenticationOutcome`에 `cancelled` 케이스를 직접 추가(상태 조회 스트림에
  존재할 수 없는 `cancelled` 상태가 관찰자에게 노출됨), `SignInUseCase`만 별도 타입을 갖고
  `SignOutUseCase`·`RestoreSessionUseCase`는 `AuthenticationOutcome`을 유지(사용자가 "다른
  케이스에도 동일합니다"로 명시적으로 기각), 액션 결과를 별도 타입 없이
  `Result<AuthenticatedUser, AuthenticationActionError>`로 표현(취소·재시도 가능 실패의 의미가
  enum 케이스가 아니라 Error 타입에 실려 Domain 계약 가독성이 떨어짐).
