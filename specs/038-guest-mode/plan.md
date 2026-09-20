# 구현 계획: 비로그인(게스트) 모드

**Git-flow 유형**: `feature`

**브랜치**: `feature/guest-mode`

**날짜**: 2026-09-19 | **명세**: [spec.md](spec.md)

**입력**: `/specs/038-guest-mode/spec.md`의 기능 명세

## 요약

로그인하지 않은 사용자가 튜토리얼 마지막 면의 `로그인 없이 둘러보기`로 메인 화면에 들어오게 한다. 메인 화면은
접근 수준 `MainShellAccess`(`member`/`guest`)를 상태로 가지며, 비로그인이면 계정 데이터를 요청하지 않고 홈의 계정
영역을 로그인 안내로 대체하고, 프로젝트·저장 탭을 비활성화하며, 마이 탭에 로그인 화면을 보여준다. 비로그인 상태의
로그인은 메인 화면 위에서 약관 동의(필요 시)와 Apple 로그인을 진행하는 새 `GuestSignInFeature`가 맡는다. 직군·연차
입력이 필요한 계정은 기존 온보딩 흐름을 재사용하되, 중단하면 튜토리얼이 아닌 비로그인 메인 화면으로 돌아온다.
비로그인 선택은 저장하지 않으며 Domain·Data·Infrastructure는 변경하지 않는다. 결정 근거는 [research.md](research.md).

## 기술 맥락

**언어/버전**: Swift(버전은 Tuist 프로젝트 설정 기준), SwiftUI

**주요 의존성**: The Composable Architecture, Tuist 멀티 패키지(`UI`, `Feature`, `App`)

**저장소**: 해당 없음 — 비로그인 선택을 저장하지 않는다(FR-003). 약관 동의 기록은 기존 `PolicyConsentRepository` 사용

**테스트**: Swift Testing(`@Test`, 한국어 동작 문장 이름), TCA `TestStore`(MainActor 격리)

**대상 플랫폼**: iOS 26.0 이상, 기본 검증 destination `iPhone 17 Pro` 시뮬레이터

**프로젝트 유형**: 모바일 앱(iOS)

**성능 목표**: 비로그인 진입 시 추가 네트워크 대기 없음(계정 요청 0건, SC-002)

**제약 조건**: 새 Figma 노드 근거 없음 → 같은 화면의 기존 배치·UIComponent·DesignSystem 토큰만 재사용(research R7).
생성자 주입만 사용하고 `@Dependency`를 쓰지 않음. 로그인 사용자 동작 무변경(FR-015)

**규모/범위**: 3개 패키지(UI, Feature, App), 새 Reducer 1개, 새 공개 enum 3개(`MainShellAccess`, `OnboardingRouterFeature.CurationExit`, `GuestSignInFeature.Phase`), 기존 Reducer 5개 변경

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 점검 | 결과 |
| --- | --- | --- |
| 1. 명시적인 경계 | Feature는 Domain 계약(`AccountUseCase` 클로저 subset)과 UI 공개 API만 사용. App이 route를 결정하고 Feature는 delegate로 출력. Domain·Data·Infrastructure 변경 없음 | 통과 |
| 2. 상태와 데이터 안전성 | 비로그인 선택 비저장, 비로그인 시 계정 요청 차단(R6), 로그인 결과는 `requestID`로 최신 응답만 반영 | 통과 |
| 3. 검증 가능한 변경 | FR-003·FR-010을 제외한 FR을 Reducer·ViewModel 단위 테스트로 검증하고, FR-003(저장 코드 없음)·FR-010(View 분기)은 수동 검증으로 확인([quickstart.md](quickstart.md)). 실행기 미실행 예외와 아래 복잡성 추적의 컨벤션 예외는 PR에 기록 | 예외 기록 조건부 통과 |
| 4. 스킬별 수정 경로 | 이 명령은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 작성 | 통과 |
| 5·6. Spec-Kit 범위·한국어 | 산출물 한국어, 식별자 원문 유지 | 통과 |
| 7. 위험 기반 실행 단위 | UI → Feature → App 위상 순서, 단일 패키지 단위 기본(아래 "실행 단위") | 통과 |
| 8. Git-flow 브랜치 | `feature/guest-mode`, `/speckit-specify`가 생성 | 통과 |
| 9. 세션 지식 기록 | 기록 조건 미충족(현재 없음) | 해당 없음 |
| 10. 책임 기반 네이밍 | `MainShellAccess`(메인 화면 접근 수준), `GuestSignInFeature`(비로그인 상태의 로그인), `CurationExit`(직군·연차 중단 목적지), `guestAccessRequested`, `memberAccessGranted`, `curationAbandoned` — 공급자 용어 없음, 일괄 접두어 없음 | 통과 |

**설계 후 재점검**: 1단계 설계([data-model.md](data-model.md), [contracts/](contracts/)) 이후 Constitution 위반 없음.
Figma 근거 부재는 AGENTS.md 규칙을 위반하지 않도록 새 레이아웃 값을 만들지 않는 방식으로 처리했다(R7).
하위 컨벤션 예외 2건은 아래 복잡성 추적에 기록한다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/038-guest-mode/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── feature-actions.md
│   └── ui-tab-shell.md
└── tasks.md             # /speckit-tasks 산출물
```

### 소스 코드(저장소 루트)

```text
sources/Projects/
├── UI/
│   ├── Component/Scaffolds/TabShell/TabShell.swift                           # 수정: isEnabled 입력
│   └── Tests/Component/Unit/Scaffolds/TabShellContractTests.swift          # 추가
├── Feature/
│   ├── Onboarding/
│   │   ├── Tutorial/TutorialFeature.swift                                    # 수정: guestAccessTapped
│   │   ├── Tutorial/TutorialScreen.swift                                     # 수정: 콜백 연결
│   │   ├── Tutorial/SubViews/TutorialScreen+SignInSection.swift              # 수정: 둘러보기 버튼
│   │   ├── Tutorial/Previews/TutorialScreenPreviews.swift                    # 수정: 마지막 면 프리뷰
│   │   ├── Router/OnboardingRouterFeature.swift                              # 수정: delegate 2종, curationExit
│   │   └── Router/OnboardingRouterFeature+CurationExit.swift                 # 추가
│   ├── Home/
│   │   ├── HomeFeature.swift                                                 # 수정: access, 알럿, signIn, allProjectsRequested
│   │   ├── HomeScreen.swift                                                  # 수정: 비로그인 분기·알럿
│   │   ├── SubViews/HomeScreen+SignInSectionView.swift                       # 추가: 로그인 섹션
│   │   ├── SubViews/HomeScreen+ProjectSection.swift                          # 수정: 안내 문구, 전체보기 비활성
│   │   ├── ViewModels/HomeProjectSectionState.swift                          # 수정: signInRequired
│   │   └── Previews/HomeScreenPreviews.swift                                 # 수정: 비로그인 프리뷰
│   └── MainShell/
│       ├── Router/MainShellAccess.swift                                      # 추가
│       ├── Router/MainShellRouterFeature.swift                               # 수정: access, guestSignIn
│       ├── Router/MainShellRouter.swift                                      # 수정: 탭 비활성, 로그인 화면, 약관·실패 표시
│       ├── Router/SubViews/MainShellRouter+SignInPromptView.swift            # 추가: 마이 탭 로그인 화면
│       ├── Router/GuestSignInFeature.swift                                   # 추가: 화면 없는 관심사 Feature
│       └── Router/GuestSignInFeature+Phase.swift                             # 추가: 진행 단계 enum
│   Feature/Tests/
│       ├── Onboarding/Tutorial/TutorialFeatureTests.swift                    # 수정
│       ├── Onboarding/Router/OnboardingRouterFeatureTests.swift              # 수정
│       ├── Home/Home/HomeFeatureGuestAccessTests.swift                       # 추가
│       ├── Home/Home/HomeFeatureNavigationTests.swift                        # 수정: 전체보기 delegate
│       ├── Home/Home/HomeFeatureGenerationProgressTests.swift                # 수정: 전체보기 delegate
│       ├── Home/Home/ViewModels/HomeProjectSectionStateTests.swift           # 수정: access 인자, signInRequired
│       ├── MainShell/Router/GuestSignInFeatureTests.swift                    # 추가
│       ├── MainShell/TestDoubles/MainShellAccountUseCaseStub.swift           # 추가: 기존 private 스텁 승격·확장
│       ├── MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift     # 추가
│       └── MainShell/Router/MainShellRouterFeatureTests.swift                # 수정: 전체보기 delegate, private 스텁 제거
└── App/
    ├── GitIt/Reducers/AppRootFeature.swift                                   # 수정: 비로그인 route·가드
    └── Tests/GitIt/Reducers/AppRootFeatureGuestAccessTests.swift             # 추가
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 그대로 사용한다. 새 파일은
[디렉터리·파일 컨벤션](../../docs/conventions/directory-file.md)(파일당 타입 1개, 중첩 타입은
`{상위타입}+{중첩타입}.swift`, 화면 전용 서브뷰는 `SubViews/`)을 따른다. `GuestSignInFeature`는 화면이 없는 관심사
Feature라 [Feature 흐름 배치](../../docs/conventions/directory-file/feature-layout.md)의 화면 폴더를 만들 수 없으므로,
`OnboardingExitFeature` 선례를 따라 조합하는 Router와 같은 `Feature/MainShell/Router/`에 둔다(research R3). 새 파일은 Tuist glob에 포함되므로 manifest 변경이 없다.

## 실행 단위(의존성 위상 순서)

의존 방향: App → Feature → UI([아키텍처 문서](../../docs/architecture.md)). 모든 단위는 단일 패키지이며, 새 공개 API는
기본값을 두어 상위 패키지가 다음 단위 전까지 그대로 컴파일된다(다중 패키지 integration unit 불필요).

| 순서 | 단위 | 패키지 | 목적 | 검증 | 커밋 태그 |
| --- | --- | --- | --- | --- | --- |
| 1 | TabShell 비활성 탭 | UI | [ui-tab-shell 계약](contracts/ui-tab-shell.md) | UI 단위 테스트, 기존 호출 컴파일 | `[Feat]` |
| 2 | 튜토리얼 비로그인 진입·직군 중단 목적지 | Feature | FR-001, FR-002, FR-012 중단 | Tutorial·OnboardingRouter 테스트 | `[Feat]` |
| 3 | 홈 비로그인 표시 | Feature | FR-004~FR-008 | `HomeFeatureGuestAccessTests`, `HomeProjectSectionStateTests` + 기존 Home 테스트 | `[Feat]` |
| 4 | 비로그인 로그인 흐름과 탭 제한 | Feature | FR-009~FR-011, FR-013, 탭 유지 | `GuestSignInFeatureTests`, `MainShellRouterFeatureGuestAccessTests` | `[Feat]` |
| 5 | App 비로그인 route 연결 | App | FR-003, FR-012, FR-014, FR-015, 기기 등록 차단 | `AppRootFeatureGuestAccessTests` + 기존 `AppRootFeatureTests` 전체 통과 | `[Feat]` |

단위 2와 3은 서로 의존하지 않는다. 단위 2를 먼저 두는 이유는 변경 파일이 적고(기존 Reducer 2개와 새 enum 1개)
진입 경로라는 목적이 독립적이라, 먼저 커밋해 두면 이후 홈·메인 화면 단위의 리뷰·되돌리기 범위가 섞이지 않기 때문이다.
단위 3을 단위 4보다 먼저 두는 이유는 MainShellRouter가 Home의 새
`delegate(.signInRequested)`·`delegate(.allProjectsRequested)`와 `input(.accessChanged)`를 사용하기 때문이다. 마지막 단위 뒤에 전체 읽기 전용 검증
(`build`, `compile`, `test`)과 필수 `after_implement` 포맷 훅(`speckit.swift-format.run`)을 실행한다.
빌드·테스트 스크립트는 사용자가 직접 실행하는 운영 방침이 있으므로, 구현 단계에서 실행 주체를 사용자에게 확인한다.

각 단위의 구현·검증·보고는 확정된 범위 안에서 연속 진행한다. 새 권한이 필요한 경우는 없다. 다만 R7의 문구와
배치가 제품 결정이므로, Figma 시안이 따로 있으면 구현 전에 알려 주어야 한다.

## 복잡성 추적

| 예외 | 위반 규칙 | 이유 | 영향 | 기록 |
| --- | --- | --- | --- | --- |
| `GuestSignInFeature.State.legalAgreement`를 항상 보유 | [State 형태](../../docs/conventions/tca/state/shape.md) — 자식 수명은 optional·`@Presents`(순차 흐름 Router만 예외) | 판정(`checkingConsent`)과 표시(`agreeingToPolicies`)에 모두 쓰이고, 불러온 약관 문서를 다음 시도에서 재사용 | 표시 여부는 `phase`만으로 판단해야 함 | research R3, PR 본문 |
| MainShell 테스트가 `AccountUseCase`를 구현한 기존 스텁을 승격·확장 | [Feature 패키지 규칙 제약조건](../../docs/package-rules/feature.md) — 테스트에서도 Domain UseCase 프로토콜 구현 금지 | `MainShellRouterFeature.init(account: any AccountUseCase)`가 기존 계약이며, 클로저 subset 전환은 App·Settings까지 넓히는 범위 확대 | 새 프로토콜 구현은 추가하지 않지만 기존 부채가 유지됨. 해소는 별도 명세 | research R9, PR 본문 |
