# 구현 계획: Task3 학습 세트 풀이 흐름

**Git-flow 유형**: `feature`

**브랜치**: `feature/quiz-solving-flow` (재사용)

**날짜**: 2026-09-03 | **명세**: [spec.md](./spec.md)

**입력**: `specs/025-quiz-solving-flow/spec.md`의 기능 명세 (FR 98 · SC 22)

## 요약

프로젝트 상세에서 학습 세트를 선택해 문제를 풀고 완료 화면까지 도달하는 흐름과, 프로젝트
상세의 메뉴에서 저장한 문제를 다시 푸는 경로를 구현한다. 현재 저장소에는 `QuizFeature`
하나가 세트 조회·풀이·북마크를 모두 소유하고 화면이 없으며, `ProjectDetailFeature`와
`SavedFeature`에도 화면이 없어 앱에서 이 흐름에 도달할 경로가 없다.

기술 접근은 여섯 가지다. 첫째, **순차 Router 두 개**(`QuizRouterFeature`,
`ProjectDetailRouterFeature`)로 화면당 독립 Reducer를 구성한다(D-001). 둘째, 두 흐름의 상하
관계는 Router 중첩이 아니라 App의 표시로 해결한다(D-002). 셋째, `QuestionSolvingFeature`를
`Quiz` 흐름이 소유하고 상세 흐름이 조합해 단일 문제 풀이에 재사용한다(D-003·D-004). 넷째,
단일 문제 진입 조회는 화면 없는 조건부 Feature가 맡는다(D-005). 다섯째, 렌더(`s01`)를 정본으로
`LearningSetRow`의 공개 계약을 바꾸고 역할을 재판정한다(D-009). 여섯째, Data DTO에 이미
있으나 Domain이 버리는 값을 Domain 모델과 Composition 매핑에서 복원한다. 자세한 근거는
[research.md](./research.md)에 있다.

## 기술 맥락

**언어/버전**: Swift 6, iOS 26.0 이상

**주요 의존성**: SwiftUI, The Composable Architecture, Tuist

**저장소**: N/A (서버 API. 이 기능은 로컬 저장소를 추가하지 않는다)

**테스트**: Swift Testing + TCA `TestStore`, Preview

**대상 플랫폼**: iOS 26.0+ (기본 테스트 destination `iPhone 17 Pro`)

**프로젝트 유형**: 모바일 앱 (Tuist 멀티 패키지)

**성능 목표**: 명세에 정량 목표가 없다. 기존 화면과 같은 상호작용 수준을 유지하고 풀이 흐름
진입 시 네트워크 조회를 2회(세트 상세·북마크 목록)로 고정하며(FR-002a), 저장한 문제 목록
표시에 세트 조회를 0회로 유지한다(FR-044a-6, SC-020).

**제약 조건**: Data 패키지 파일 변경 금지(FR-049, SC-009), 서버 계약 변경 금지,
`NavigationStack`·`StackState` 사용 금지(FR-033), 생성자 주입만 사용(FR-046), DesignSystem 토큰
외 색·치수·타이포 직접 선언 금지(FR-048), 서브뷰의 TCA·Domain import 금지(D-008), 외부 URL
열기는 App의 단일 경로(FR-010c·SC-021)

**규모/범위**: 신규 화면 6개(프로젝트 상세, 저장한 문제 목록, 세트 시작, 문제 풀이, 학습 완료,
그리고 화면 없는 조건부 Feature 1개), Router 2개, Reducer 8개, Domain 모델 4종 변경·추가,
UI 컴포넌트 1종 계약 변경, Composition 매핑 1곳

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 게이트 | 판정 | 근거 |
| --- | --- | --- |
| **브랜치 네임스페이스** (원칙 8) | 통과 | `feature/quiz-solving-flow`는 `feature/` 네임스페이스와 kebab-case 접미사를 만족하며 재사용이 확인되었다 |
| **허용 수정 경로** (원칙 4·5) | 통과 | 이 실행은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 생성·수정했다. 구현 파일은 아래 §구조에 경로만 기록한다 |
| **명시적 경계와 의존 방향** (원칙 1) | 통과 | 변경 패키지는 Domain, Composition, UI, Feature, App이며 아키텍처 §3.1의 허용 방향과 §7.1의 금지 목록을 벗어나지 않는다. Domain은 다른 내부 패키지에 의존하지 않고 Feature는 Domain·UI만 참조한다 |
| **상태와 데이터 안전성** (원칙 2) | 통과 | 병행 operation을 상태로 분리하고(FR-032a), 실패는 오류 의미와 복구 경로를 보존하며(FR-032b), 대체 가능한 요청은 식별 값을 보존한다(FR-032c). 모든 Effect는 `cancellable`과 대상 ID 검증을 가진다(FR-025a) |
| **검증 가능한 변경** (원칙 3) | 통과 | SC-001~SC-022를 [quickstart.md](./quickstart.md) §3·§4·§5의 테스트·정적 검사·Preview 항목에 대응시켰다 |
| **한국어 산출물** (원칙 6) | 통과 | 이 계획과 하위 산출물을 한국어로 작성했고 코드 식별자·경로만 원문을 유지했다 |
| **위험 기반 실행 단위** (원칙 7) | 통과 | 아래 §실행 단위가 위상 순서와 불가분한 integration unit의 근거를 명시한다 |
| **책임 기반 네이밍** (원칙 10) | 통과 | `SubmittedAnswer`, `LearningSetResumption`, `QuestionSolvingFeature`, `SingleQuestionEntryFeature`, `QuestionSourceDisplay` 등 새 공개 이름의 근거를 research.md에 남겼다 |
| **세션 지식 기록** (원칙 9) | 해당 없음 | 이번 세션에 반복·재사용 가능한 사건이 없다. 조건을 충족하면 전용 스킬로 별도 기록한다 |
| **Git 실행 직렬화** (원칙 3) | 해당 없음 | 계획 단계는 Git index를 변경하지 않는다 |

**1단계 설계 후 재점검**: 설계 산출물이 새 패키지, 새 외부 의존성, 새 공용 구성 파일을
도입하지 않았다. 이전 계획이 세웠던 "UI 패키지 무변경" 결정은 렌더 정본화(FR-042 계열)로
무효가 되었고, UI 변경은 FR-049가 허용하는 범위 안에 있으므로 복잡성 추적에 기록할 위반이
아니다. 그 밖에 정당화가 필요한 위반이 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/025-quiz-solving-flow/
├── plan.md              # 이 파일
├── research.md          # 0단계 산출물
├── data-model.md        # 1단계 산출물
├── quickstart.md        # 1단계 산출물
├── contracts/           # 1단계 산출물
│   ├── feature-reducers.md
│   ├── screen-flow.md
│   └── app-navigation.md
├── checklists/
│   └── requirements.md
└── tasks.md             # 2단계 산출물(/speckit-tasks가 생성)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/
├── Domain/LearningProject/Models/Quiz/
│   ├── LearningSet.swift                               # 변경: description 추가
│   ├── Question.swift                                  # 변경: sources 배열, myAnswer 타입
│   ├── QuestionSource.swift                            # 변경: startLine·endLine·symbol·summary
│   └── SubmittedAnswer.swift                           # 신규
├── Domain/Tests/LearningProject/
│   ├── Models/Quiz/SubmittedAnswerTests.swift          # 신규
│   └── UseCases/FetchLearningSetTests.swift            # 변경: 새 이니셜라이저
├── Composition/Adapter/Adapters/
│   └── LearningSetRepositoryAdapter.swift              # 변경: 유실 값 복원 매핑
├── Composition/Tests/Adapter/Adapters/
│   └── LearningSetRepositoryAdapterTests.swift         # 변경: 매핑 검증 추가
├── UI/Component/CollectionItems/LearningSetRow/
│   └── LearningSetRow.swift                            # 변경: D-009 계약 개편
├── UI/Tests/Component/Unit/CollectionItems/
│   └── LearningSetRowTests.swift                       # 변경: 새 계약 검증
├── Feature/Quiz/
│   ├── Router/
│   │   ├── QuizRouter.swift                            # 신규 (View)
│   │   ├── QuizRouterFeature.swift                     # 신규 (ActiveScreen·ScreenTransition 포함)
│   │   └── Previews/QuizRouterPreviews.swift           # 신규
│   ├── LearningSetIntro/
│   │   ├── LearningSetIntroScreen.swift
│   │   ├── LearningSetIntroFeature.swift
│   │   ├── SubViews/LearningSetIntroScreen+ErrorView.swift
│   │   └── Previews/LearningSetIntroScreenPreviews.swift
│   ├── QuestionSolving/
│   │   ├── QuestionSolvingScreen.swift
│   │   ├── QuestionSolvingFeature.swift
│   │   ├── SubViews/
│   │   │   ├── QuestionSolvingScreen+QuestionPrompt.swift
│   │   │   ├── QuestionSolvingScreen+ChoiceSection.swift
│   │   │   ├── QuestionSolvingScreen+AnswerEditor.swift
│   │   │   ├── QuestionSolvingScreen+EssayResultSection.swift
│   │   │   └── QuestionSolvingScreen+SourceSheet.swift
│   │   ├── ViewModels/
│   │   │   ├── ChoiceOptionDisplay.swift
│   │   │   └── QuestionSourceDisplay.swift             # 신규 (D-008)
│   │   └── Previews/QuestionSolvingScreenPreviews.swift
│   ├── LearningCompletion/
│   │   ├── LearningCompletionScreen.swift
│   │   ├── LearningCompletionFeature.swift
│   │   └── Previews/LearningCompletionScreenPreviews.swift
│   ├── Shared/Models/LearningSetResumption.swift
│   └── Quiz/                                           # 삭제: QuizFeature·AnswerEditor·QuestionPrompt
├── Feature/ProjectDetail/
│   ├── Router/
│   │   ├── ProjectDetailRouter.swift                   # 신규 (View, 흐름 공용 overlay·alert)
│   │   ├── ProjectDetailRouterFeature.swift            # 신규
│   │   └── Previews/ProjectDetailRouterPreviews.swift  # 신규
│   ├── ProjectDetail/
│   │   ├── ProjectDetailScreen.swift                   # 신규
│   │   ├── ProjectDetailFeature.swift                  # 변경: 메뉴·삭제·재개·URL delegate
│   │   ├── SubViews/
│   │   │   ├── ProjectDetailScreen+RepositorySummaryView.swift
│   │   │   ├── ProjectDetailScreen+SetListSection.swift
│   │   │   ├── ProjectDetailScreen+MenuSheet.swift
│   │   │   └── ProjectDetailScreen+ErrorView.swift
│   │   ├── ViewModels/ProjectDetailSetDisplay.swift    # 신규
│   │   └── Previews/ProjectDetailScreenPreviews.swift  # 신규
│   └── SingleQuestionEntry/
│       └── SingleQuestionEntryFeature.swift            # 신규 (화면 없는 조건부 Feature, D-005)
├── Feature/Saved/Saved/                                # 기존 흐름. 두 Router가 조합한다
│   ├── SavedFeature.swift                              # 변경: 필터·뒤로가기 표시 값·retry
│   ├── SavedScreen.swift                               # 신규
│   ├── SubViews/
│   │   ├── SavedScreen+QuestionRow.swift               # 신규 (D-010)
│   │   └── SavedScreen+ErrorView.swift                 # 신규
│   ├── ViewModels/SavedQuestionDisplay.swift           # 신규
│   └── Previews/SavedScreenPreviews.swift              # 신규
├── Feature/Tests/
│   ├── Quiz/Router/QuizRouterFeatureTests.swift
│   ├── Quiz/LearningSetIntro/LearningSetIntroFeatureTests.swift
│   ├── Quiz/QuestionSolving/QuestionSolvingFeatureTests.swift
│   ├── Quiz/QuestionSolving/ViewModels/ChoiceOptionDisplayTests.swift
│   ├── Quiz/QuestionSolving/ViewModels/QuestionSourceDisplayTests.swift
│   ├── Quiz/LearningCompletion/LearningCompletionFeatureTests.swift
│   ├── Quiz/Shared/Models/LearningSetResumptionTests.swift
│   ├── Quiz/TestDoubles/                               # 둘 이상의 테스트가 쓰는 Double만
│   ├── ProjectDetail/Router/ProjectDetailRouterFeatureTests.swift
│   ├── ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift
│   ├── Saved/Saved/SavedFeatureTests.swift
│   ├── ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeatureTests.swift
│   └── ProjectDetail/TestDoubles/
└── App/
    ├── GitIt/Reducers/AppRootFeature.swift             # 변경: 흐름 2종 표시·delegate 해석·URL 열기
    ├── GitIt/Screens/AppRootView.swift                 # 변경: fullScreenCover 2단
    ├── GitIt/GitItApp.swift                            # 변경: UseCase 5종과 openExternalURL 전달
    └── Tests/GitIt/Reducers/AppRootFeatureTests.swift  # 변경: 진입·복귀·URL 경로 검증
```

**구조 결정**: Feature 패키지는 [디렉터리·파일 컨벤션 §4.3](../../docs/conventions/directory-file.md)의
흐름 배치를 따른다. 흐름 폴더는 `Quiz`와 `ProjectDetail`이고, 1뎁스는 `Router/`와 화면 폴더,
`Shared/`, 역할 폴더(`SubViews/`, `ViewModels/`, `Previews/`)만 사용한다. 활성 화면 값 타입과
`ScreenTransition`은 Router가 소유하는 상태이므로 `Router/`에 둔다.

**`Saved`를 독립 흐름으로 유지한다**: `SavedFeature`는 이미 `MainShellRouterFeature`가 탭으로
조합하고 있고, 이번에 `ProjectDetailRouterFeature`도 조합한다. 화면이 하나뿐인 흐름이므로
Router를 두지 않고(Navigation 컨벤션 §2.3) `Feature/Saved/Saved/`에 Screen·Feature 쌍을 완성
한다. 이 흐름으로 옮기지 않는 이유는 FR-045a가 "한 흐름만 소유하고 다른 흐름은 Router가
조합"하도록 요구하기 때문이며, `ProjectDetail/`로 옮기면 MainShell이 다른 흐름의 화면 폴더를
들여다보게 된다. `Feature` target의 `sourceDirectory`가 패키지 루트 하나이므로 폴더를
추가·삭제해도 Tuist 매니페스트는 바꾸지 않는다.

**기존 호출부 보호**: `MainShellRouterFeature.State`가 `SavedFeature.State()`를 무인자로 만들고
있으므로 새 이니셜라이저 인자에 기본값을 두어 셸 흐름의 동작과 compile을 유지한다.

## 실행 단위

아키텍처 §3.1의 허용 의존성이 순서를 정한다: Domain → Composition, UI → Feature → App
(D-015).

| 순서 | 단위 | 대상 패키지 | 목적 | 검증 |
| --- | --- | --- | --- | --- |
| 1 | **통합 단위**: 모델 확장과 매핑 복원 | Domain + Composition | FR-039의 유실 값을 Domain 모델과 Adapter 매핑에서 복원 | Domain·Composition 테스트 |
| 2 | 세트 항목 컴포넌트 개편 | UI | FR-042·042a·042b의 렌더 정본화와 D-009의 역할 재판정 | UI 컴포넌트 테스트 |
| 3 | 두 흐름의 Router와 화면 | Feature | Router 2종, 화면 Feature 6종, 표시 모델과 테스트 | Feature 테스트, Preview |
| 4 | 앱 진입 연결 | App | 흐름 2종 표시, delegate 해석, 외부 URL 단일 경로 | App 테스트 |
| 5 | 전체 읽기 전용 검증 | 없음 | 공유 scheme build / compile / test와 정적 검사 | SC-015, quickstart §4 |

**1단계를 다중 패키지 통합 단위로 두는 근거**: `Question`·`QuestionSource`·`LearningSet`의
이니셜라이저 시그니처가 바뀌면 유일한 호출부인 `LearningSetRepositoryAdapter`가 함께 바뀌지
않는 한 Composition이 compile되지 않는다. 두 변경은 하나의 목적(데이터 정합)을 가지며 독립적
으로 되돌릴 수 없다(Constitution 원칙 7). 포함 파일은 위 §구조의 Domain·Composition 경로
6개이고, 통합 검증은 Domain 테스트와 Composition Adapter 테스트다.

**2단계를 별도 단위로 두는 근거**: UI는 Domain에 의존하지 않으므로 1단계와 독립이지만,
`LearningSetRow`의 공개 계약이 바뀌므로 이를 사용하는 Feature(3단계)보다 먼저 와야 한다.
현재 사용처가 UI 테스트뿐이어서 이 단위만으로 compile·테스트가 완결된다.

**3단계와 4단계를 분리하는 근거**: Feature는 App에 의존하지 않으므로 Feature 단위만으로
compile·테스트가 성립한다. 3단계에서 삭제하는 `QuizFeature`는 App이 참조하지 않는다.

각 단위는 구현·검증·`tasks.md` 완료 표시·정확한 staging·커밋 확인을 마친 뒤 다음 단위로
진행하며, 같은 기능 범위의 후속 단위는 반복 승인 없이 이어서 수행한다. 마지막 단위는 전체
읽기 전용 검증과 필수 `after_implement` 훅(Swift 포맷)까지 실행한 뒤 커밋한다.

**예상되는 승인 지점**: 이번 범위에는 없다. 완료 화면 표현은 기존 `ResourceAnimation.Asset.complete`
재사용으로 확정했고(D-013), 그 밖에 새 자산·새 권한이 필요한 지점이 남아 있지 않다. 구현 중
새 자산이 필요하다고 판단되면 그 시점에 승인을 요청한다.

**패키지에 속하지 않는 파일**: 이번 범위에는 없다. Tuist 매니페스트, 공용 구성 파일,
`docs/**`를 수정하지 않는다.

## 복잡성 추적

> 헌법 점검에서 정당화해야 하는 위반이 없다. 작성하지 않는다.
