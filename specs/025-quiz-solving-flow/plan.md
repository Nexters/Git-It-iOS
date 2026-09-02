# 구현 계획: Task 3 문제 풀이 흐름 구현

**Git-flow 유형**: `feature`

**브랜치**: `feature/quiz-solving-flow`

**날짜**: 2026-09-03 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/025-quiz-solving-flow/spec.md`의 기능 명세

## 요약

Figma Task 3(문제 풀이) 화면 8종(S1 프로젝트 상세 ~ S8 학습 완료)을 구현한다. 핵심은 세 가지다.

1. **화면을 책임 단위 Reducer로 분해한다.** 사용자 원문 요구대로 하나의 화면·상태 영역마다 독립
   Reducer를 두고, 순차 여정 전체는 `docs/conventions/tca/navigation.md` §2.3의 Router-Feature
   패턴으로 조합한다. S3↔S5, S6↔S7은 같은 문제의 상태 전이이므로 문제 형식별 Reducer 하나가
   `answering`/`result` 두 phase를 소유한다(R-01).
2. **Domain 모델의 유실 필드를 복원한다.** 서버 DTO에는 이미 세트 설명, 기존 답변의 정답 여부,
   출처의 줄 번호·심볼·복수 출처, 세트별 문제 수·완료 수가 있지만 Domain·Composition이 이를 버리고
   있다(FR-017~022). Data 패키지는 건드리지 않고 Domain 모델과 Composition 어댑터 매핑만 고친다.
3. **App이 새 내비게이션 스택을 소유한다.** 현재 `AppRootFeature`는 `projectDetailRequested`·
   `learningRequested` delegate를 그냥 버린다. `MainShellScreen` 위에 `NavigationStack`을 얹어 프로젝트
   상세→세트 시작→문제 풀이 흐름을 push/pop으로 연결하고, 이탈 이유(완료/포기)에 따라 상세 재조회
   또는 홈 재조회를 트리거한다(FR-023, FR-014a).

조사에서 확인한 제약: 결과 화면 재진입은 서버가 정답 index·해설을 세트 조회에 포함하지 않아 완전
복원이 불가능하므로, 기존 답변이 있는 문제는 풀이 화면에 선반영한 뒤 재제출을 요구한다(R-06). S2
배경 그라데이션 색상은 토큰 카탈로그에 없어 토큰 추가 여부가 구현 중 승인 지점이다(R-13). 기존
`QuizFeature`는 새 Reducer군으로 대체되므로 삭제가 승인 지점이다(R-17).

## 기술 맥락

**언어/버전**: Swift 6, iOS 26.0 이상

**주요 의존성**: SwiftUI, TCA(`swift-composable-architecture` 1.26.0+). 생성자 주입을 정본으로 하며
`@Dependency`를 쓰지 않는다(`docs/conventions/tca/README.md`).

**저장소**: N/A — 이 기능은 서버 API를 호출하는 화면 계층이며 로컬 영속화가 없다. 미제출 입력은
기기에 저장하지 않는다(FR-005a).

**테스트**: Swift Testing + TCA `TestStore`. 각 화면 Feature 테스트는 자신의 State와 Mock만 준비한다
(SC-006). 새 target은 없다 — `Feature`/`FeatureTests`, `GitIt`/`GitItTests`,
`DomainLearningProject`/`DomainLearningProjectTests`, `CompositionAdapter`/`CompositionAdapterTests`,
`UIComponent`/`UIComponentTests`가 이미 있고 test source root가 `Tests/`라 새 폴더가 자동 포함된다.

**대상 플랫폼**: iOS 26.0+, iPhone. 주력 기기 iPhone 17 Pro(`GIT_IT_TEST_DESTINATION` 기본값).

**프로젝트 유형**: 모바일 앱(iOS)의 사용자 기능. Tuist 기반 멀티 패키지 구조.

**성능 목표**: 해당 없음. 이 기능은 서버 조회·제출 왕복 시간에 종속되며 별도 성능 목표를 두지 않는다.

**제약 조건**: 서버 API 계약과 Data 패키지 DTO를 바꾸지 않는다(FR-029, 명세 범위 밖). 정답 판정은
클라이언트에서 계산하지 않고 서버 응답 값만 쓴다(FR-017, SC-003). 미제출 입력은 화면 이탈 시 버린다
(FR-005a).

**규모/범위**: 화면 8종, 신규 TCA Reducer 10개(§"실행 단위" 참조), Domain 모델 변경 4개 + 신설 1개,
Composition 어댑터 2개, UI 컴포넌트 변경 2개(+ 승인 시 토큰 1개), App `AppRootFeature` 확장 1개 +
`MainStackDestinationFeature` 신설 1개.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

### 0단계 전 점검 — 통과

| 원칙 | 점검 | 결과 |
| --- | --- | --- |
| 1. 명시적인 경계 | Domain·Data는 서로 및 App/Feature/UI에 의존하지 않는다. 이 계획은 Data를 전혀 건드리지 않고 그 방향을 지킨다 | 통과 |
| 2. 상태와 데이터 안전성 | Reducer마다 UseCase를 생성자로 명시 주입한다(FR-026, FR-027). Service Locator·전역 컨테이너 없음 | 통과 |
| 3. 검증 가능한 변경 | quickstart.md가 실행 단위별 빌드·테스트 명령과 SC별 확인 절차를 정의 | 통과 |
| 4. 스킬별 수정 경로 | 이 계획은 `plan.md`·`research.md`·`data-model.md`·`quickstart.md`·`contracts/**`만 작성했다 | 통과 |
| 5. Spec-Kit 범위 | 구현 파일 경로는 계약 문서에 정확히 기록만 하고 수정하지 않았다 | 통과 |
| 6. 한국어 산출물 | 모든 산출물을 한국어로 작성. 식별자·경로·컴포넌트명은 원문 유지 | 통과 |
| 7. 위험 기반 실행 단위 | 아래 실행 단위 표 참조. 삭제·토큰 추가 2곳에 승인 지점 명시 | 통과 |
| 8. Git-flow 네임스페이스 | `feature/quiz-solving-flow`. `/speckit-specify`가 생성·검증 | 통과 |
| 9. 세션 지식 기록 | 현재 기록 조건 미충족. 계획 산출물로 만들지 않음 | 해당 없음 |
| 10. 책임 기반 네이밍 | 신설 Reducer·모델 이름은 책임을 그대로 드러낸다(`ChoiceQuestionFeature`, `PreviousAnswer` 등). 공통 접두어를 강제하지 않는다 | 통과 |

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`,
`contracts/**`만 수정했다. 구현 파일은 계약 문서에 정확한 경로로 기록했다.

**커밋 단위 구현**: 아래 실행 단위 표가 순서와 경계를 정의한다. 각 단위는 하나의 목적과 되돌릴 수
있는 결과를 갖는다. 단위 1(Domain+Composition 데이터 정합)만 다중 패키지 integration unit이다.

**실행 단위 진행**: 적용 패키지는 Domain·UI·Composition·Feature·App이며 위상 순서는
Domain → UI → Composition → Feature → App이다(`docs/architecture.md` 의존성 표: Composition→Domain,
Feature→Domain·UI, App→Feature·Composition·Domain).

### 1단계 후 재점검 — 통과

설계 산출물(research·data-model·contracts·quickstart)을 작성한 뒤 다시 확인했다. 새 위반은 없다.
다음을 기록한다.

- **원칙 7(위험 기반 실행 단위)**: R-13(S2 그라데이션 토큰 추가)과 R-17(기존 `QuizFeature` 삭제) 두
  곳에 구현 중 승인이 필요하다. "승인이 필요한 지점"에 명시했다. 그 밖의 단위는 반복 승인 없이
  진행한다.
- **원칙 10(책임 기반 네이밍)**: Router가 화면 State를 optional로 보유하는 예외(R-03)는
  `docs/conventions/tca/navigation.md` §2.3의 "항상 함께 보유" 문구와 형식상 다르다. 이는 네이밍이
  아니라 State 형태 결정이며, 근거를 research.md R-03에 남기고 문서 자체는 이 기능에서 개정하지
  않는다(문서 개정은 범위 확장이므로 별도 결정).
- **원칙 3(검증 가능한 변경)**: SC-001(전체 흐름 완주)은 자동화 대상이 아니라 quickstart.md §3에
  시뮬레이터 수동 확인 절차로 남겼다. PR에 수행 여부를 정확히 기록한다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/025-quiz-solving-flow/
├── spec.md                       # 기능 명세(/speckit-specify, /speckit-clarify)
├── plan.md                       # 이 파일(/speckit-plan 산출물)
├── research.md                   # 0단계 산출물 — 조사 항목 20건 해소
├── data-model.md                 # 1단계 산출물 — Domain·Feature 값 모델과 상태 전이표
├── quickstart.md                 # 1단계 산출물 — 검증 실행 가이드
├── contracts/                    # 1단계 산출물
│   ├── feature-reducers.md       # Reducer별 주입 UseCase(FR-027)와 Action 계약
│   ├── screen-flow.md            # Router 전환 규칙과 App 내비게이션 정책
│   ├── domain-model-changes.md   # Domain 공개 API 변경과 어댑터 매핑
│   └── ui-component-api.md       # UI 컴포넌트 변경과 화면별 조립
├── checklists/requirements.md
└── tasks.md                      # 2단계 산출물(/speckit-tasks가 생성)
```

입력으로 참조한 `private/task3-quiz-flow-spec.md`(Figma 조사 문서)는 `.gitignore` 대상이라 저장소에
포함되지 않는다. 그 문서에 근거한 값은 이 계획과 contracts에 옮겨 적어, 원본이 없는 환경에서도
검증이 성립하게 한다.

### 소스 코드(저장소 루트)

```text
sources/Projects/Domain/LearningProject/
├── Models/Quiz/
│   ├── LearningSet.swift              # description 추가, resumeQuestionIndex(additionallyAnswered:)
│   ├── Question.swift                 # sources: [QuestionSource], previousAnswer: PreviousAnswer?
│   ├── PreviousAnswer.swift           # 신설
│   └── QuestionSource.swift           # startLine·endLine·symbol·summary 추가, locationLabel
└── Models/LearningProject/
    └── LearningProjectDetail.swift    # firstIncompleteSet computed 추가

sources/Projects/Composition/Adapter/Adapters/
├── LearningSetRepositoryAdapter.swift      # description·복수 sources·previousAnswer 매핑
└── LearningProjectRepositoryAdapter.swift  # problemCount·completedCount DTO 값 매핑

sources/Projects/UI/
├── Component/CollectionItems/
│   ├── LearningSetRow/LearningSetRow.swift        # label·questionCount·completedCount로 재구성
│   └── ChoiceResultRow/ChoiceResultRow.swift       # Judgement.neutral 추가
└── DesignSystem/Tokens/GradientToken.swift         # (승인 시) 세트 시작 배경 그라데이션 1종

sources/Projects/Feature/
├── ProjectDetail/
│   ├── Reducers/ProjectDetailFeature.swift         # quickStartTapped·reloadRequested 추가
│   ├── Screens/ProjectDetailScreen.swift           # 신설
│   └── Views/RepositorySummaryHeader.swift         # 신설
└── Quiz/
    ├── Reducers/
    │   ├── QuizRouterFeature.swift                 # 신설 — Router
    │   ├── QuizSessionFeature.swift                # 신설 — 세션(비화면)
    │   ├── QuizExitFeature.swift                   # 신설 — 조건부 이탈 판단
    │   ├── LearningSetIntroFeature.swift            # 신설 — S2
    │   ├── ChoiceQuestionFeature.swift              # 신설 — S3·S5
    │   ├── EssayQuestionFeature.swift               # 신설 — S6·S7
    │   ├── QuestionBookmarkFeature.swift            # 신설 — 북마크 Child
    │   ├── QuestionSourceFeature.swift              # 신설 — S4
    │   ├── LearningCompletionFeature.swift          # 신설 — S8
    │   └── QuizFeature.swift                        # 삭제(승인 후, R-17)
    ├── Screens/                                     # 신설 — QuizScreen 외 6개
    ├── Views/
    │   ├── QuestionPrompt.swift                     # 재작성(Figma 정합)
    │   ├── AnswerEditor.swift                       # 재작성(400자, 262 카드)
    │   ├── SourceTriggerButton.swift                # 신설
    │   ├── AIExplanationCard.swift                  # 신설
    │   ├── SubmittedAnswerCard.swift                # 신설
    │   └── QuizSessionStatusView.swift               # 신설 — 로딩·실패·빈 세트
    └── Models/                                      # 신설 — AnswerOutcome 등 §2 값 모델

sources/Projects/App/GitIt/
├── Reducers/
│   ├── AppRootFeature.swift                # mainStack: StackState<MainStackDestinationFeature.State> 추가
│   └── MainStackDestinationFeature.swift    # 신설
└── Screens/AppRootView.swift                # NavigationStack(path:) 추가
```

각 패키지의 `Tests/` 아래에는 위 소스와 대응하는 테스트를 신설·갱신한다. 정확한 목록은
[data-model.md §7](./data-model.md#7-상태-전이와-검증-테스트-sc-002--sc-006--sc-010),
[domain-model-changes.md §4](./contracts/domain-model-changes.md#4-영향-받는-테스트와-기대값),
[ui-component-api.md §1](./contracts/ui-component-api.md#1-변경하는-ui-컴포넌트-uicomponent)이 소유한다.

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 그대로 쓴다. Router-Feature 패턴(R-01~R-03)으로 화면
8종을 10개 Reducer로 분해하고, App이 `NavigationStack` 기반 스택 내비게이션을 신설해 Feature 바깥
화면 전환을 소유한다(R-09). Tuist manifest 변경은 없다.

## 실행 단위

| # | 단위 | 패키지 | 목적 | 주요 경로 | 검증 |
| --- | --- | --- | --- | --- | --- |
| 1 | 데이터 정합 ⚠ | Domain + Composition | 세트 설명·복수 출처·기존 답변 정오·세트 진행 수치 복원 | `Domain/LearningProject/Models/Quiz/**` · `Domain/LearningProject/Models/LearningProject/LearningProjectDetail.swift` · `Composition/Adapter/Adapters/LearningSetRepositoryAdapter.swift` · `LearningProjectRepositoryAdapter.swift` | compile·test |
| 2 | UI 컴포넌트 정합 | UI | `LearningSetRow` 재구성, `ChoiceResultRow.neutral` 추가 | `UI/Component/CollectionItems/LearningSetRow/**` · `.../ChoiceResultRow/**` | test |
| 2a | S2 배경 그라데이션 ⛔ | UI | 승인 시 `GradientToken`에 1종 추가 | `UI/DesignSystem/Tokens/GradientToken.swift` | test |
| 3 | 문제 풀이 Reducer군 | Feature | 세션·문제·북마크·출처·완료 Reducer 8개 신설 | `Feature/Quiz/Reducers/**`(`QuizFeature.swift` 제외) · `Feature/Quiz/Models/**` | test |
| 4 | 프로젝트 상세 Reducer 확장 | Feature | 바로 시작·재조회 액션 추가 | `Feature/ProjectDetail/Reducers/ProjectDetailFeature.swift` | test |
| 5 | 화면 조립 | Feature | 7개 화면 + 로컬 View 신설 | `Feature/Quiz/Screens/**` · `Feature/Quiz/Views/**` · `Feature/ProjectDetail/Screens/**` · `Feature/ProjectDetail/Views/**` | build·test |
| 6 | 기존 `QuizFeature` 삭제 ⛔ | Feature | 대체 완료된 구 Reducer 제거 | `Feature/Quiz/Reducers/QuizFeature.swift` | build·test |
| 7 | App 내비게이션 조립 | App | 스택 내비게이션, delegate 해석, 재조회 트리거 | `App/GitIt/Reducers/AppRootFeature.swift` · `MainStackDestinationFeature.swift` · `App/GitIt/Screens/AppRootView.swift` · `App/GitIt/GitItApp.swift` | build·compile·test |

그 뒤에 파일 변경이 없는 `[no-write]` 전체 완료 검증(quickstart.md §2·§3)을 둔다.

⚠ = 불가분한 다중 패키지 단위 · ⛔ = 진행 중 승인이 필요할 수 있는 단위

### 승인이 필요한 지점

Constitution 원칙 7에 따라 확정된 기능 범위의 후속 단위는 반복 승인 없이 진행한다. 이 계획에서
승인이 필요한 지점은 두 곳이다.

**단위 2a — S2 배경 그라데이션 토큰 추가(research.md R-13).** `#141414 → #A5C4F0` 종료색이 기존
`GradientToken` 카탈로그에 없다. 새 토큰을 추가할지, 아니면 장식 그라데이션을 생략하고 단색
배경으로 대체할지 구현 전 승인을 받는다. 미승인 시 단위 2a는 건너뛰고 PR에 미반영 항목으로 남긴다.

**단위 6 — 기존 `QuizFeature` 삭제(research.md R-17).** 단위 3~5가 완전히 대체한 뒤 삭제한다.
`QuizFeature`는 App·다른 Feature에서 참조되지 않아(자기 파일뿐) 삭제해도 컴파일이 깨지지 않지만,
삭제는 되돌리기 어려운 작업이라 실행 전 대상과 근거를 제시하고 승인을 받는다.

두 지점 모두 삭제 또는 새 시각 토큰 도입이 되돌리기 어렵거나 범위를 넓히는 결정이라 원칙 7의
명시적 승인 대상이다. 그 밖의 단위는 승인 게이트를 두지 않으며, 전체 읽기 전용 검증도 같은 실행에서
이어서 수행한다.

### 다중 패키지 단위의 분리 불가 근거

**단위 1 — 데이터 정합**: `Question.source: QuestionSource` → `sources: [QuestionSource]`,
`myAnswer: String?` → `previousAnswer: PreviousAnswer?`, `LearningSet`에 `description` 추가는 Domain
공개 API 변경이다. `LearningSetRepositoryAdapter.question(from:)`은 이 생성자를 직접 호출하므로
Domain만 먼저 바꾸면 Composition이 컴파일되지 않고, Composition만 먼저 바꾸면 참조할 새 필드가
없다. `LearningProjectRepositoryAdapter`의 `problemCount`·`completedCount` 상수 제거도 같은 파일
그룹의 데이터 정합 목적이라 분리하지 않는다. **통합 검증**: Domain·Composition 두 target의 test
scheme이 함께 통과하고, `LearningSetRepositoryAdapterTests`가 새 필드 매핑을 직접 검증한다.

**정확한 경로**:
`sources/Projects/Domain/LearningProject/Models/Quiz/LearningSet.swift`,
`sources/Projects/Domain/LearningProject/Models/Quiz/Question.swift`,
`sources/Projects/Domain/LearningProject/Models/Quiz/PreviousAnswer.swift`,
`sources/Projects/Domain/LearningProject/Models/Quiz/QuestionSource.swift`,
`sources/Projects/Domain/LearningProject/Models/LearningProject/LearningProjectDetail.swift`,
`sources/Projects/Composition/Adapter/Adapters/LearningSetRepositoryAdapter.swift`,
`sources/Projects/Composition/Adapter/Adapters/LearningProjectRepositoryAdapter.swift`,
`sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningSetTests.swift`,
`sources/Projects/Domain/Tests/LearningProject/Models/Quiz/LearningSetTests.swift`,
`sources/Projects/Domain/Tests/LearningProject/Models/LearningProject/LearningProjectDetailTests.swift`,
`sources/Projects/Composition/Tests/Adapter/Adapters/LearningSetRepositoryAdapterTests.swift`,
`sources/Projects/Composition/Tests/Adapter/Adapters/LearningProjectRepositoryAdapterTests.swift`.

단위 3(Feature)은 단위 1의 새 Domain API에 의존하지만, Feature 쪽 컴파일 단절 없이(단위 1 완료 후
단위 3 시작) 순차 실행으로 충분해 통합 단위로 묶지 않는다. 같은 이유로 단위 7(App)도 단위 3·4에
순차 의존할 뿐 별도 통합 단위가 아니다.

### 패키지에 속하지 않는 파일의 배정

이 기능은 Tuist manifest, 도구(`tools/`), 문서 컨벤션 파일을 바꾸지 않는다. 배정할 패키지 밖 파일이
없다.

### 순서 근거

- 1 → 2·3·4는 Domain 값 모델(특히 `PreviousAnswer`, `resumeQuestionIndex`, `firstIncompleteSet`)이
  Feature Reducer의 State·전이 규칙 정본이기 때문이다. UI(2)는 Domain에 의존하지 않아 1과 병행
  가능하지만 표 순서는 위상 순서(Domain → UI)를 그대로 반영한다.
- 3 → 4는 독립적이다(둘 다 Feature, 서로 다른 하위 폴더). 표에서는 문제 풀이 흐름이 상세 화면의
  바로 시작 목적지이므로 먼저 둔다.
- 5(화면 조립)를 3·4 다음에 두는 이유는 화면이 Reducer의 State·Action에 의존하기 때문이다
  (`navigation.md` §2.2, 화면은 Store를 단일 정본으로 관찰).
- 6(구 `QuizFeature` 삭제)을 5 다음에 두는 이유는 신설 Reducer군이 화면까지 조립되어 대체가 끝난
  뒤에만 안전하게 지울 수 있기 때문이다.
- 7(App)을 마지막에 두는 이유는 App이 Feature가 공개하는 delegate·Reducer·화면을 조립하는
  Coordination Layer이기 때문이다(`docs/package-rules/app.md`).

## 복잡성 추적

> 헌법 점검에서 정당화해야 하는 위반이 있을 때만 작성한다.

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| Router-Feature `State`가 화면 State를 optional로 보유(navigation.md §2.3의 "항상 함께 보유" 예외) | 문제 화면 State의 정본(`Question`)은 세트 조회 완료 후에만 존재하고, 세트 시작 화면 State는 홈 이어 풀기·바로 시작 경로에서 존재하지 않는 세트 라벨을 필요로 한다 | 자리표시자 값으로 항상 생성하면 `docs/conventions/tca/state.md` §2(정본만 소유)를 어기고, 모든 액션에 불필요한 guard가 생긴다 |
| `Question.previousAnswer`로 기존 답변을 복원하되 결과 화면이 아니라 풀이 화면에 선반영(R-06) | 서버가 세트 조회 응답에 정답 index·해설을 포함하지 않아 결과 화면을 완전히 복원할 데이터가 없다 | 결과 화면으로 복원하면 정답 표시·해설이 빈 상태로 남아 FR-010을 만족하지 못한다 |
