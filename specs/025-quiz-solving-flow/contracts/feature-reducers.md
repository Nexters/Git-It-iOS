# 계약: Feature Reducer와 주입 UseCase

**기능 브랜치**: `feature/quiz-solving-flow`

**작성일**: 2026-09-03

이 문서는 FR-046·FR-047이 요구하는 **Reducer별 주입 UseCase 목록과 사용 지점**, 각 Reducer의
공개 Action 계약을 고정한다. 모든 의존성은 생성자 주입이며 `@Dependency`, Service Locator,
전역 컨테이너를 쓰지 않는다.

## 1. 주입 UseCase 요약 (SC-013 대조표)

| Reducer | 주입 UseCase | 사용 지점 |
| --- | --- | --- |
| `ProjectDetailRouterFeature` | 없음 (자식 생성용으로 7종을 받아 전달만 한다) | `Scope`에서 자식 Reducer 생성 |
| `ProjectDetailFeature` | `FetchLearningProjectDetailUseCase`, `DeleteLearningProjectUseCase` | `view(.task)`, `view(.retryTapped)`, `input(.refreshRequested)` / `view(.deletionConfirmed)` |
| `SavedFeature` (기존) | `FetchBookmarkedQuestionsUseCase` | `view(.task)`, `view(.retryTapped)` |
| `SingleQuestionEntryFeature` | `FetchLearningSetUseCase` | `input(.questionRequested)` |
| `QuizRouterFeature` | 없음 (자식 생성용으로 5종을 받아 전달만 한다) | `Scope`에서 자식 Reducer 생성 |
| `LearningSetIntroFeature` | `FetchLearningSetUseCase`, `FetchBookmarkedQuestionsUseCase` | `view(.task)`, `view(.retryTapped)` |
| `QuestionSolvingFeature` | `SubmitChoiceAnswerUseCase`, `SubmitEssayAnswerUseCase`, `SetQuestionBookmarkUseCase` | `view(.submitAnswerTapped)`, `view(.bookmarkToggleTapped)` |
| `LearningCompletionFeature` | 없음 | — |

`ProjectDetailRouterFeature`가 받는 7종은 자식별로 `ProjectDetailFeature` 2종, `SavedFeature`
1종, `SingleQuestionEntryFeature` 1종, `QuestionSolvingFeature` 3종이다.
`QuizRouterFeature`가 받는 5종은 `LearningSetIntroFeature` 2종과 `QuestionSolvingFeature` 3종
이며 `fetchLearningSet`·`fetchBookmarkedQuestions`는 두 Router가 같은 인스턴스를 공유한다.

두 Router는 UseCase를 직접 호출하지 않는다. 자식 생성 시 전달만 하며, 이는 Navigation 컨벤션
§2.3의 "Router는 화면 Feature들의 조합과 전환만 책임진다"를 지키기 위한 것이다
(`ProjectRegistrationRouterFeature`와 같은 형태).

## 2. `ProjectDetailRouterFeature` (신규 · D-001)

```swift
public enum ActiveScreen: Equatable, Sendable {
    case projectDetail
    case savedQuestions
    case singleQuestion
}

public struct ScreenTransition: Equatable, Sendable {
    public let from: ActiveScreen
    public let to: ActiveScreen
    public let cause: Cause

    public enum Cause: Equatable, Sendable {
        case savedQuestionsRequested
        case singleQuestionPrepared(questionID: String)
        case singleQuestionFinished
        case backRequested
    }
}

@ObservableState
public struct State: Equatable, Sendable {
    public init(projectID: String)

    public var activeScreen = ActiveScreen.projectDetail
    public var screenTransitions: [ScreenTransition] = []

    public var projectDetail: ProjectDetailFeature.State
    public var savedQuestions: SavedFeature.State
    public var singleQuestion: QuestionSolvingFeature.State?
    public var singleQuestionEntry: SingleQuestionEntryFeature.State
}

public enum Action: Sendable, Equatable {
    case projectDetail(ProjectDetailFeature.Action)
    case savedQuestions(SavedFeature.Action)
    case singleQuestion(QuestionSolvingFeature.Action)
    case singleQuestionEntry(SingleQuestionEntryFeature.Action)
    case delegate(Delegate)

    public enum Delegate: Sendable, Equatable {
        case learningSetRequested(projectID: String, setID: String, label: String)
        case externalURLRequested(URL)
        case projectDeleted(projectID: String)
        case dismissRequested
    }
}
```

- `projectDetail`·`savedQuestions`의 child State는 항상 보유한다(FR-032). `singleQuestion`만
  진입 전에는 값이 없으므로 optional로 두며, 이는 활성 화면 선택이 아니라 **child 수명**을
  나타낸다(State 컨벤션 §3).
- `singleQuestionEntry`는 화면이 없는 조건부 Feature다(D-005).
- 활성 화면 값에 상위 이탈 case를 두지 않는다(FR-032).

**전환 규칙**

| 수신 Action | 처리 |
| --- | --- |
| `projectDetail(.delegate(.setStartRequested(projectID:setID:label:)))` | `.delegate(.learningSetRequested(...))` — 흐름 이탈이므로 활성 화면을 바꾸지 않는다(D-002) |
| `projectDetail(.delegate(.savedQuestionsRequested(projectID:)))` | `savedQuestions`에 프로젝트 필터를 고정하고 활성 화면을 `.savedQuestions`로 전환, 이동 이벤트 기록 |
| `projectDetail(.delegate(.externalURLRequested(url)))` | `.delegate(.externalURLRequested(url))` |
| `projectDetail(.delegate(.projectDeleted(projectID:)))` | `.delegate(.projectDeleted(projectID:))` |
| `projectDetail(.delegate(.dismissRequested))` | `.delegate(.dismissRequested)` — 되돌아갈 이전 화면이 없다(FR-035b) |
| `savedQuestions(.delegate(.questionSelected(question)))` | `.singleQuestionEntry(.input(.questionRequested(setID:questionID:)))` 전달. 활성 화면은 아직 바꾸지 않는다 |
| `savedQuestions(.delegate(.backRequested))` | 활성 화면을 `.projectDetail`로 되돌린다(FR-035a), 이동 이벤트 기록 |
| `singleQuestionEntry(.delegate(.questionPrepared(question:projectID:)))` | `singleQuestion` State를 구성(`advanceActionTitle`은 완료 의미)하고 `.singleQuestion`으로 전환, 이동 이벤트 기록 |
| `singleQuestionEntry(.delegate(.preparationFailed(error)))` | Router View의 흐름 공용 alert로 표시한다. 활성 화면을 바꾸지 않는다 |
| `singleQuestion(.delegate(.advanceRequested))` | 활성 화면을 `.savedQuestions`로 되돌리고 `singleQuestion`을 해제한다(FR-044a-4), 이동 이벤트 기록 |
| `singleQuestion(.delegate(.backRequested))` | 같은 처리 |
| `singleQuestion(.delegate(.answerSubmitted(...)))` | 처리하지 않는다. 단일 문제는 세트 진행에 카운터를 만들지 않는다 |
| `singleQuestion(.delegate(.externalURLRequested(url)))` | `.delegate(.externalURLRequested(url))` |

## 3. `ProjectDetailFeature` (변경)

```swift
public enum Deletion: Sendable, Equatable {
    case idle
    case confirming
    case committing
    case failed(LearningProjectError)
}

public enum Action: ViewAction, Sendable, Equatable {
    case view(View)
    case input(Input)
    case effect(EffectEvent)
    case delegate(Delegate)

    public enum View: Sendable, Equatable {
        case task
        case retryTapped
        case setStartTapped(setID: String)
        case resumeTapped
        case menuTapped
        case menuDismissed
        case savedQuestionsTapped
        case repositoryLinkTapped
        case deleteTapped
        case deletionCancelled
        case deletionConfirmed
        case backTapped
    }

    public enum Input: Sendable, Equatable {
        case refreshRequested
    }

    public enum EffectEvent: Sendable, Equatable {
        case detailLoadFinished(requestID: Int, result: Result<LearningProjectDetail, LearningProjectError>)
        case deletionFinished(projectID: String, error: LearningProjectError?)
    }

    public enum Delegate: Sendable, Equatable {
        case setStartRequested(projectID: String, setID: String, label: String)
        case savedQuestionsRequested(projectID: String)
        case externalURLRequested(URL)
        case projectDeleted(projectID: String)
        case dismissRequested
    }
}
```

- `setStartRequested`는 라벨만 전달한다. 제목·설명은 세트 상세 응답에서만 온다(FR-003).
- `resumeTapped`는 첫 미완료 세트를 골라 같은 `setStartRequested`를 보낸다(FR-041a). 미완료
  세트가 없으면 컨트롤을 비활성으로 두고 Action을 보내지 않는다.
- `repositoryLinkTapped`는 상태의 `LearningProjectDetail.repositoryURL`을 `URL`로 변환해
  `externalURLRequested`로 올린다. 문자열을 조립하지 않는다(FR-044b).
- 삭제는 `Deletion` 상태 기계를 따르고 `committing`에서 재입력을 무시한다(FR-044c, D-012).
  성공하면 `projectDeleted`를 올린다.
- 메뉴 펼침은 `isMenuPresented: Bool`로 둔다 — payload가 없고 두 경우만 있다(State 컨벤션 §3).
- `s01` 우측 상단 메뉴 외에 근거가 확정되지 않은 컨트롤은 노출하지 않는다(FR-044d).
- 세트 목록 진행 표시는 각 `LearningProjectSetProgress`의 `completedCount`·`problemCount`에서
  계산한다(FR-042).

## 4. `SavedFeature` (변경 · 두 Router가 조합하는 기존 Reducer)

FR-044a-1에 따라 새 Reducer를 만들지 않고 기존 책임을 재사용한다. 이 Feature는 `MainShell`
셸 흐름과 `ProjectDetail` 순차 흐름 양쪽이 조합하므로, **자신을 쓰는 흐름을 알지 않는다**
(FR-045b). 흐름마다 달라지는 것은 상태로 주입받는 표시 값뿐이다.

```swift
public struct State: Equatable, Sendable {
    // 기본값이 있으므로 MainShell의 기존 `SavedFeature.State()` 호출부가 그대로 compile된다
    public init(projectFilter: String? = nil, isBackControlPresented: Bool = false)

    public let projectFilter: String?
    public let isBackControlPresented: Bool
}

public enum View: Sendable, Equatable {
    case task
    case retryTapped          // 추가 — FR-044a-7
    case filterSelected(projectID: String?)
    case solveTapped(BookmarkedQuestion)   // 이름 변경: bookmarkRowTapped → solveTapped
    case backTapped           // 추가 — isBackControlPresented가 true일 때만 화면이 보낸다
}

public enum Delegate: Sendable, Equatable {
    case questionSelected(BookmarkedQuestion)
    case backRequested        // 추가
}
```

- `projectFilter`가 있으면 진입 시 그 프로젝트로 필터를 고정한다. 목록에 다른 프로젝트의
  문제가 포함되지 않는다(FR-044a). `nil`이면 기존 셸 흐름의 전체 목록 동작을 유지한다.
- `isBackControlPresented`는 뒤로가기 컨트롤의 표시 여부만 결정하는 표시 값이다. 셸 흐름은
  `false`, 순차 흐름은 `true`로 구성한다. 이 값이 흐름 종류를 뜻하지 않으므로 FR-045b를
  위반하지 않는다(D-004와 같은 방식).
- 항목 진입은 `solveTapped`에서만 시작한다. 행 본문은 탭 대상이 아니다(FR-044a-2).
- 세트 제목·라벨을 얻기 위한 추가 조회를 하지 않는다(FR-044a-6).
- `MainShellRouterFeature`는 이 delegate 중 `questionSelected`만 기존대로 다루고
  `backRequested`는 받지 않는다(뒤로가기 컨트롤을 표시하지 않으므로 발생하지 않는다).

## 5. `SingleQuestionEntryFeature` (신규 · D-005)

화면이 없는 조건부 Feature다.

```swift
public enum Preparation: Equatable, Sendable {
    case idle
    case loading(questionID: String)
    case failed(LearningProjectError)
}

@ObservableState
public struct State: Equatable, Sendable {
    public let projectID: String
    public var preparation = Preparation.idle
}

public enum Action: Sendable, Equatable {
    case input(Input)
    case effect(EffectEvent)
    case delegate(Delegate)

    public enum Input: Sendable, Equatable {
        case questionRequested(setID: String, questionID: String)
        case failureDismissed
    }

    public enum EffectEvent: Sendable, Equatable {
        case setLoadFinished(questionID: String, result: Result<LearningSet, LearningProjectError>)
    }

    public enum Delegate: Sendable, Equatable {
        case questionPrepared(question: Question, projectID: String)
        case preparationFailed(LearningProjectError)
    }
}
```

- `loading` 중 같은 입력을 무시한다. 결과는 `questionID`가 일치할 때만 반영한다(FR-032c).
- 세트에서 `questionID`를 찾지 못하면 `preparationFailed`를 보낸다.
- 기존 답변을 복원하지 않는다 — 준비한 `Question`을 그대로 넘기고 화면은 편집 상태로 연다
  (FR-044a-5).

## 6. `QuizRouterFeature` (신규)

```swift
public enum ActiveScreen: Equatable, Sendable {
    case learningSetIntro
    case questionSolving
    case learningCompletion
}

public struct ScreenTransition: Equatable, Sendable {
    public let from: ActiveScreen
    public let to: ActiveScreen
    public let cause: Cause

    public enum Cause: Equatable, Sendable {
        case startRequested
        case advancedToCompletion
        case backRequested
    }
}

@ObservableState
public struct State: Equatable, Sendable {
    public init(projectID: String, setID: String, setLabel: String)

    public var activeScreen = ActiveScreen.learningSetIntro
    public var screenTransitions: [ScreenTransition] = []

    public var learningSetIntro: LearningSetIntroFeature.State
    public var questionSolving: QuestionSolvingFeature.State?
    public var learningCompletion: LearningCompletionFeature.State
}

public enum Action: Sendable, Equatable {
    case learningSetIntro(LearningSetIntroFeature.Action)
    case questionSolving(QuestionSolvingFeature.Action)
    case learningCompletion(LearningCompletionFeature.Action)
    case delegate(Delegate)

    public enum Delegate: Sendable, Equatable {
        case externalURLRequested(URL)
        case progressInvalidated(projectID: String)
        case dismissRequested(projectID: String)
    }
}
```

- Router가 소유하는 흐름 데이터: 세트, 현재 문제 index, 세션 채점 누적, `LearningSetResumption`.
  모두 `learningSetIntro`의 delegate payload로 받는다.
- `questionSolving`은 `시작하기` 전에는 값이 없으므로 optional이다. 한 번 만든 뒤에는
  뒤로가기로 돌아가도 **버리지 않는다**(FR-035d).
- `NavigationStack`·`StackState`를 쓰지 않는다(FR-033).

**전환 규칙**

| 수신 Action | 처리 |
| --- | --- |
| `learningSetIntro(.delegate(.startRequested(set:resumption:bookmarkedQuestionIDs:)))` | `questionSolving`이 이미 있으면 그대로 활성화(FR-035d). 없으면 `resumption.startIndex` 문제로 구성. 문제가 없으면 전환하지 않고 `.learningSetIntro(.input(.emptySetReported))`를 보낸다 |
| `learningSetIntro(.delegate(.backRequested))` | `.delegate(.dismissRequested(projectID:))` — 이전 화면이 없다(FR-035b) |
| `questionSolving(.delegate(.backRequested))` | 활성 화면을 `.learningSetIntro`로 되돌린다. child State는 유지한다(FR-035a) |
| `questionSolving(.delegate(.answerSubmitted(questionID:choiceCorrect:)))` | 세션 채점 누적 갱신, `.delegate(.progressInvalidated(projectID:))` |
| `questionSolving(.delegate(.advanceRequested))` | 다음 문제가 있으면 index를 올리고 child State를 새 문제로 교체(FR-027). 없으면 완료 화면 State를 채우고 `.learningCompletion`으로 전환 |
| `questionSolving(.delegate(.externalURLRequested(url)))` | `.delegate(.externalURLRequested(url))` |
| `learningCompletion(.delegate(.dismissRequested))` | `.delegate(.dismissRequested(projectID:))` — 닫기는 뒤로가기가 아니다(FR-035b) |

## 7. `LearningSetIntroFeature` (신규)

```swift
public enum SetLoad: Equatable, Sendable {
    case idle
    case loading(requestID: Int)
    case loaded(LearningSet)
    case failed(LearningProjectError)
}

public enum BookmarkLoad: Equatable, Sendable {
    case idle
    case loading
    case loaded(Set<String>)
    case failed(LearningProjectError)
}

@ObservableState
public struct State: Equatable, Sendable {
    public let projectID: String
    public let setID: String
    public let label: String

    public var setLoad = SetLoad.idle
    public var bookmarkLoad = BookmarkLoad.idle
    public var isEmptySetReported = false
    public var loadRequestID = 0
}

public enum Action: ViewAction, Sendable, Equatable {
    case view(View)
    case input(Input)
    case effect(EffectEvent)
    case delegate(Delegate)

    public enum View: Sendable, Equatable {
        case task
        case retryTapped
        case startTapped
        case backTapped
    }

    public enum Input: Sendable, Equatable {
        case emptySetReported
    }

    public enum EffectEvent: Sendable, Equatable {
        case setLoadFinished(requestID: Int, result: Result<LearningSet, LearningProjectError>)
        case bookmarksLoadFinished(Result<BookmarkedQuestionCollection, LearningProjectError>)
    }

    public enum Delegate: Sendable, Equatable {
        case startRequested(set: LearningSet, resumption: LearningSetResumption, bookmarkedQuestionIDs: Set<String>)
        case backRequested
    }
}
```

- `view(.task)`에서 두 조회를 각각 1회 실행한다. 문제 이동에서 다시 조회하지 않는다
  (FR-002a, FR-025b).
- 두 조회 상태는 분리되어 서로 영향을 주지 않는다(FR-032a). `BookmarkLoad.failed`는 풀이를
  막지 않고 빈 집합으로 시작하되 오류 의미는 보존한다(FR-025c, FR-032b).
- `setLoadFinished`는 `requestID`가 현재 값과 같을 때만 반영한다(FR-032c).
- `startTapped`는 `setLoad == .loaded`에서만 `startRequested`를 보낸다(FR-002b).
- `input(.emptySetReported)`는 Router가 보낸다. 화면이 "문제 없음"을 표시하고 `startTapped`는
  아무 일도 하지 않는다.
- 표시 값: 라벨은 진입 값, 제목·설명은 `SetLoad.loaded`의 `LearningSet`이다(FR-003).

## 8. `QuestionSolvingFeature` (신규 · 두 흐름이 공유 · D-003)

```swift
public enum Submission: Equatable, Sendable {
    case editing
    case submitting
    case answered(AnswerOutcome)
    case failed(LearningProjectError)
}

public enum AnswerOutcome: Equatable, Sendable {
    case choice(ChoiceAnswerResult)
    case essay(EssayAnswerResult)
}

public enum BookmarkMutation: Equatable, Sendable {
    case idle
    case committing
    case failed(LearningProjectError)
}

@ObservableState
public struct State: Equatable, Sendable {
    public let projectID: String
    public var question: Question
    public var questionNumber: Int?     // nil이면 순번을 표시하지 않는다(단일 문제)
    public var questionCount: Int?
    public let advanceActionTitle: String   // 결과 상태 하단 컨트롤 문구 (D-004)

    public var submission = Submission.editing
    public var draftChoiceIndex: Int?
    public var draftEssayText = ""
    public var isBookmarked = false
    public var bookmarkMutation = BookmarkMutation.idle
    public var isSourceSheetPresented = false
}

public enum Action: ViewAction, Sendable, Equatable {
    case view(View)
    case effect(EffectEvent)
    case delegate(Delegate)

    public enum View: Sendable, Equatable {
        case choiceSelected(Int)
        case essayTextChanged(String)
        case submitAnswerTapped
        case advanceTapped
        case bookmarkToggleTapped
        case sourceTapped
        case sourceSheetDismissed
        case sourceLinkTapped(URL)
        case backTapped
    }

    public enum EffectEvent: Sendable, Equatable {
        case choiceAnswerFinished(questionID: String, result: Result<ChoiceAnswerResult, LearningProjectError>)
        case essayAnswerFinished(questionID: String, result: Result<EssayAnswerResult, LearningProjectError>)
        case bookmarkFinished(questionID: String, result: Result<BookmarkState, LearningProjectError>)
    }

    public enum Delegate: Sendable, Equatable {
        case answerSubmitted(questionID: String, choiceCorrect: Bool?)
        case advanceRequested
        case externalURLRequested(URL)
        case backRequested
    }
}
```

**규칙**

| 요구사항 | 처리 |
| --- | --- |
| FR-045b | 이 Feature는 자신을 쓰는 흐름을 알지 않는다. 진행 입력은 언제나 `advanceRequested` 하나이고 문구는 `advanceActionTitle`이 결정한다(D-004) |
| FR-011 | `choiceSelected`는 `draftChoiceIndex`를 덮어쓴다 |
| FR-014, FR-014a | `submitAnswerTapped`만 제출을 시작한다. 객관식은 `draftChoiceIndex == nil`이면 무시 |
| FR-020, FR-020a | `essayTextChanged`는 400자로 자른 값만 저장 |
| FR-020b | 공백만 있는 서술형은 제출하지 않는다 |
| FR-015, FR-035c, SC-004 | `submission == .submitting`이면 `submitAnswerTapped`·`advanceTapped`·`backTapped`를 무시 |
| FR-016~FR-018 | 결과 표현은 `ChoiceAnswerResult.correct`·`answerIndex`만으로 판정. 배열 위치·`A`~`D` 문자로 추론하지 않는다 |
| FR-021, FR-023 | 성공 전에는 draft를 결과 표현으로 바꾸지 않고, 결과 상태에서도 제출 당시 텍스트를 보존 |
| FR-025, FR-025a, FR-032a | 북마크는 명시 Action → Effect. `committing` 중 재입력 무시, 결과는 `questionID` 일치 시에만 반영. 제출 상태와 분리 |
| FR-026 | `advanceTapped`는 `submission`이 `.answered`일 때만 `advanceRequested`를 보낸다 |
| FR-009, FR-010, FR-010a | Sheet 개폐는 다른 상태를 건드리지 않는다. `question.sources.isEmpty`면 `sourceTapped` 컨트롤을 노출하지 않는다. 표시 여부 외 상태가 없으므로 `Bool`로 둔다(State 컨벤션 §3) |
| FR-010c | `sourceLinkTapped`는 `delegate(.externalURLRequested(url))`로 올린다. Feature가 URL을 열지 않는다 |
| FR-044a-5 | 단일 문제로 열릴 때도 `myAnswer`를 복원하지 않고 `editing`으로 시작한다 |

`delegate(.answerSubmitted)`의 `choiceCorrect`는 객관식에서만 값을 갖고 서술형은 `nil`이다
(FR-037).

## 9. `LearningCompletionFeature` (신규)

```swift
@ObservableState
public struct State: Equatable, Sendable {
    public let projectID: String
    public var correctChoiceCount = 0
    public var choiceQuestionCount = 0

    public var isScorePresented: Bool { choiceQuestionCount > 0 }
}

public enum Action: ViewAction, Sendable, Equatable {
    case view(View)
    case delegate(Delegate)

    public enum View: Sendable, Equatable {
        case closeTapped
        case primaryActionTapped
    }

    public enum Delegate: Sendable, Equatable {
        case dismissRequested
    }
}
```

- 두 카운트는 Router가 채운다. 화면이 계산하거나 고정값을 쓰지 않는다(FR-029).
- `isScorePresented == false`면 카운터 없이 완료 메시지만 표시한다(FR-038).
- `closeTapped`와 `primaryActionTapped`는 같은 `dismissRequested`를 보낸다(FR-043).
- 접근성 레이블은 "객관식 N문제 중 M문제 정답" 형태의 한 문장이다(FR-055).
