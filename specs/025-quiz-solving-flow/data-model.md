# 데이터 모델: Task 3 문제 풀이 흐름 구현

**기능 브랜치**: `feature/quiz-solving-flow`

**날짜**: 2026-09-03

**명세**: [spec.md](./spec.md) · **조사**: [research.md](./research.md)

이 기능의 데이터는 두 층이다. **Domain 모델**은 서버 응답을 잃지 않고 보존하는 업무 값이고(FR-017~
FR-022), **Feature 값 모델·State**는 Reducer가 소유하는 Presentation 정본이다. 영속 저장소는 없다
(FR-005a — 미제출 답안을 기기에 저장하지 않는다). Reducer별 Action·UseCase 계약은
[contracts/feature-reducers.md](./contracts/feature-reducers.md)가, 어댑터 매핑은
[contracts/domain-model-changes.md](./contracts/domain-model-changes.md)가 소유한다.

## 1. Domain 모델 (`DomainLearningProject`)

### 1.1 `LearningSet` — 변경

| 필드 | 형태 | 변경 | 근거 |
| --- | --- | --- | --- |
| `setID` | `String` | 유지 | |
| `title` | `String` | 유지 | |
| `description` | `String` | **추가** | FR-019. DTO `LearningSetResponseDTO.description`(non-optional) |
| `questions` | `[Question]` | 유지, 서버 순서 보존 | FR-022 |

메서드 추가 — `resumeQuestionIndex(additionallyAnswered: Set<String> = []) -> Int`:
`previousAnswer == nil`이고 `questionID`가 `additionallyAnswered`에 없는 첫 문제의 index, 없으면 `0`.
`questions`가 비어 있으면 호출하지 않는다(호출자가 빈 세트를 먼저 판정). FR-002a·R-07.

### 1.2 `Question` — 변경

| 필드 | 형태 | 변경 | 근거 |
| --- | --- | --- | --- |
| `questionID` | `String` | 유지 | |
| `prompt` | `String` | 유지 | |
| `format` | `QuestionFormat` | 유지 | |
| `choices` | `[String]?` | 유지, 순서 보존 | FR-022 |
| `sources` | `[QuestionSource]` | **`source: QuestionSource` → 배열** | FR-021, 명세 엔터티 "한 문제가 여러 출처" |
| `previousAnswer` | `PreviousAnswer?` | **`myAnswer: String?` → 구조화** | FR-020 |

computed: `isAnswered: Bool` = `previousAnswer != nil`, `hasSources: Bool` = `!sources.isEmpty`.

### 1.3 `PreviousAnswer` — 신설

사용자가 이전에 제출한 답. `MyAnswerResponseDTO`를 평탄화하지 않고 보존한다.

| 필드 | 형태 | 설명 |
| --- | --- | --- |
| `selectedIndex` | `Int?` | 객관식 선택 index. 서술형은 `nil` |
| `text` | `String?` | 서술형 작성 텍스트. 객관식은 `nil` |
| `correct` | `Bool?` | 서버 정답 판정. 서술형은 `nil`(서버가 채점하지 않음) |

`answeredAt`은 화면 요구가 없어 옮기지 않는다(FR-030 최소 범위). 정답 index·해설은 서버가 세트 조회에
포함하지 않으므로 이 모델로 결과 화면을 복원하지 않는다(R-06).

### 1.4 `QuestionSource` — 변경

| 필드 | 형태 | 변경 | 근거 |
| --- | --- | --- | --- |
| `filePath` | `String` | `String?` → non-optional | DTO `file` non-optional |
| `startLine` | `Int` | **추가** | FR-021. 링크 라벨 `file:L{startLine}` |
| `endLine` | `Int` | **추가** | DTO 보존 |
| `symbol` | `String` | **추가** | FR-021 "대상 심볼" |
| `summary` | `String?` | **추가** | FR-021 "설명", DTO `summary` optional |
| `referenceURL` | `String` | `String?` → non-optional | DTO `url` non-optional. `URL` 파싱 실패는 Feature가 처리(R-05) |

computed: `locationLabel: String` = `"\(filePath):L\(startLine)"`.

### 1.5 `LearningProjectDetail` · `LearningProjectSetProgress` — computed 추가

생성자와 저장 필드는 바꾸지 않는다. `LearningProjectDetail.firstIncompleteSet: LearningProjectSetProgress?`
= `sets.first { $0.completedCount < $0.problemCount }`. 기존 `nextSet`은 유지한다(R-07).
`LearningProjectSetProgress.problemCount`·`completedCount`는 어댑터가 DTO 값으로 채운다(FR-018).

### 1.6 변경 없는 Domain 모델

`ChoiceAnswerResult(correct, answerIndex, explanation)`, `EssayAnswerResult(explanation, rubric)`,
`BookmarkState(bookmarked)`, `LearningProjectError`, `QuestionFormat`. 정답 판정은 오직
`ChoiceAnswerResult.correct`·`PreviousAnswer.correct`에서 온다(FR-017).

## 2. Feature 값 모델 (`Feature/Quiz/Models/`)

| 타입 | 형태 | 용도 |
| --- | --- | --- |
| `AnswerOutcome` | `enum { choice(ChoiceAnswerResult), essay(EssayAnswerResult) }` | 세션이 보존하는 이번 풀이의 제출 결과 |
| `QuestionPresentation` | `struct { question: Question, number: Int, total: Int, isBookmarked: Bool }` | 세션 → Router → 문제 Feature 생성 입력. `number`는 1-based |
| `LearningCompletionSummary` | `struct { choiceQuestionCount: Int, correctChoiceCount: Int }` · computed `hasCounter`(count > 0), `isAllCorrect` | S8 표시 입력(FR-014b~d) |
| `ChoiceJudgement` | `enum { correct, incorrect, neutral }` | S5 선택지별 판정. UI `ChoiceResultRow.Judgement`로 화면에서 변환 |
| `QuizEntry` | `enum { setIntro(label: String, title: String), direct(startingQuestionID: String?) }` | Router 진입 방식(FR-001·002·006a) |
| `QuizExitReason` | `enum { completed, abandoned }` | Router → App 이탈 이유 |

모두 `Equatable, Sendable`. Domain 값을 복제하지 않고 참조만 담는다(`state.md` §2).

## 3. Reducer State

### 3.1 `ProjectDetailFeature.State` (S1, 기존 확장)

| 필드 | 형태 | 비고 |
| --- | --- | --- |
| `projectID` | `String` | |
| `detail` | `LearningProjectDetail?` | |
| `loadStatus` | `LoadStatus { idle, loading, loaded, failed(LearningProjectError) }` | 기존 |
| `requestID` | `Int` | 교체 가능한 조회 식별(재조회) |

computed: `quickStartSet` = `detail?.firstIncompleteSet` — `nil`이면 바로 시작 미노출(FR-006a).
메뉴 버튼 상태 없음(FR-006b).

### 3.2 `LearningSetIntroFeature.State` (S2)

| 필드 | 형태 | 비고 |
| --- | --- | --- |
| `label` | `String` | `LearningProjectSetProgress.label`, 진입 시 확정 |
| `title` | `String` | 진입 시 확정 |
| `description` | `DescriptionLoad { loading, loaded(String), failed(LearningProjectError) }` | Router가 세션 결과로 갱신 |

computed: `isStartEnabled` = `description`이 `loaded`.

### 3.3 `QuizSessionFeature.State` (비화면)

| 필드 | 형태 | 비고 |
| --- | --- | --- |
| `projectID`, `setID` | `String` | |
| `startingQuestionID` | `String?` | 홈 이어 풀기의 지정 문제(FR-001) |
| `setLoad` | `SetLoad { idle, loading, loaded(LearningSet), failed(LearningProjectError) }` | |
| `bookmarkLoad` | `BookmarkLoad { idle, loading, loaded(Set<String>), failed(LearningProjectError) }` | 실패 시 빈 집합으로 간주 |
| `position` | `Position { beforeStart, question(index: Int), completed }` | |
| `sessionOutcomes` | `[String: AnswerOutcome]` | key = `questionID`. 이번 세션 제출 결과 |
| `loadRequestID` | `Int` | 재시도 시 증가, 늦은 응답 거부 |

computed: `learningSet`, `bookmarkedQuestionIDs`(loaded 값 또는 `[]`), `currentQuestion`,
`completionSummary`(R-08 산식), `presentation(at index:)`.

### 3.4 `ChoiceQuestionFeature.State` (S3·S5)

| 필드 | 형태 | 비고 |
| --- | --- | --- |
| `projectID` | `String` | |
| `question`, `number`, `total` | `Question`, `Int`, `Int` | `QuestionPresentation`에서 복사 |
| `selectedIndex` | `Int?` | 초기값 `question.previousAnswer?.selectedIndex`(R-06). 항상 최대 1개(FR-009) |
| `submission` | `Submission { idle, committing, failed(LearningProjectError) }` | mutation, request ID 없음(State 전이로 중복 차단) |
| `result` | `ChoiceAnswerResult?` | 서버 응답 그대로 |
| `expandedChoiceIndices` | `Set<Int>` | S5 펼침. 문제 전환 시 새 State라 초기화 |
| `bookmark` | `QuestionBookmarkFeature.State` | Child |

computed: `phase: Phase { answering, result }`(`result == nil` ? answering : result),
`canSubmit`(`selectedIndex != nil && submission != .committing && result == nil`),
`judgement(at index) -> ChoiceJudgement`(`index == result.answerIndex` → correct; `index == selectedIndex && !result.correct` → incorrect; 그 외 neutral),
`hasSources`, `letter(at:)`(A…Z).

### 3.5 `EssayQuestionFeature.State` (S6·S7)

| 필드 | 형태 | 비고 |
| --- | --- | --- |
| `projectID`, `question`, `number`, `total` | 위와 동일 | |
| `draftText` | `String` | 초기값 `question.previousAnswer?.text ?? ""`. 400자 초과 저장 불가(FR-011a) |
| `submission` | `Submission` | |
| `result` | `EssayAnswerResult?` | |
| `submittedText` | `String?` | S7 `나의 답안` 정본(제출 시점 텍스트) |
| `bookmark` | `QuestionBookmarkFeature.State` | Child |

상수: `answerCharacterLimit = 400`. computed: `phase`, `characterCount`,
`canSubmit`(공백 제외 1자 이상 · `≤ 400` · idle/failed · `result == nil`), `hasSources`.

### 3.6 `QuestionBookmarkFeature.State`

| 필드 | 형태 | 비고 |
| --- | --- | --- |
| `projectID`, `questionID` | `String` | |
| `isBookmarked` | `Bool` | 서버 성공 응답으로만 변경(FR-015a) |
| `mutation` | `Mutation { idle, committing, failed(LearningProjectError) }` | committing 중 탭 무시 |

### 3.7 `QuestionSourceFeature.State` (S4)

| 필드 | 형태 | 비고 |
| --- | --- | --- |
| `questionNumber` | `Int` | 제목 `문제 N 출처` |
| `sources` | `[QuestionSource]` | 서버 순서 |

computed: `link(at index) -> URL?`(`URL(string: referenceURL)`; `nil`이면 버튼 비활성).

### 3.8 `LearningCompletionFeature.State` (S8)

| 필드 | 형태 | 비고 |
| --- | --- | --- |
| `summary` | `LearningCompletionSummary` | |

computed: `counter: (correct: Int, total: Int)?`(`hasCounter`일 때만), `message`(R-08).

### 3.9 `QuizExitFeature.State`

빈 State. 입력 사건을 이탈 이유로 판단만 한다.

### 3.10 `QuizRouterFeature.State`

| 필드 | 형태 | 비고 |
| --- | --- | --- |
| `projectID`, `setID` | `String` | |
| `entry` | `QuizEntry` | |
| `activeScreen` | `ActiveScreen` | §6 |
| `session` | `QuizSessionFeature.State` | 항상 보유 |
| `exit` | `QuizExitFeature.State` | 항상 보유 |
| `setIntro` | `LearningSetIntroFeature.State?` | `entry == .setIntro`일 때 생성 |
| `choiceQuestion` | `ChoiceQuestionFeature.State?` | 문제 제시 시 생성, 전환 시 제거 |
| `essayQuestion` | `EssayQuestionFeature.State?` | 위와 동일 |
| `completion` | `LearningCompletionFeature.State?` | 완료 시 생성 |
| `source` | `@Presents QuestionSourceFeature.State?` | 출처 시트 |
| `transitionLog` | `[ScreenTransitionEvent]` | `from`, `to`, `trigger` |

optional 화면 State의 근거는 R-03.

### 3.11 App — `AppRootFeature.State` 추가 필드

| 필드 | 형태 | 비고 |
| --- | --- | --- |
| `mainStack` | `StackState<MainStackDestinationFeature.State>` | `MainShellScreen` 위 push 목적지 |

`MainStackDestinationFeature.State`: `enum { projectDetail(ProjectDetailFeature.State), quiz(QuizRouterFeature.State) }`.

## 4. 검증 규칙(불변식)

| ID | 규칙 | 소유 | 요구사항 |
| --- | --- | --- | --- |
| V-01 | 객관식 선택은 0개 또는 1개 | `ChoiceQuestionFeature` | FR-009 |
| V-02 | `result != nil`이면 선택 변경·재제출 불가, `다음`만 가능 | `ChoiceQuestionFeature`·`EssayQuestionFeature` | FR-002b |
| V-03 | `submission == .committing`이면 제출·선택·입력 변경 무시 | 두 문제 Feature | 경계 사례 "중복 제출" |
| V-04 | 제출 실패 시 `selectedIndex`·`draftText` 유지 | 두 문제 Feature | SC-009 |
| V-05 | `draftText.count ≤ 400` 항상 성립 | `EssayQuestionFeature` | FR-011a |
| V-06 | 공백만 있는 답안은 제출 불가 | `EssayQuestionFeature` | 기존 `QuizFeature` guard 계승 |
| V-07 | `isBookmarked`는 `mutationFinished(.success)`에서만 바뀜, committing 중 탭 무시 | `QuestionBookmarkFeature` | FR-015a |
| V-08 | `sessionOutcomes`는 `answerRecorded`로만 추가·갱신, 늦은 조회 응답은 `loadRequestID` 불일치로 거부 | `QuizSessionFeature` | `state.md` §4 |
| V-09 | 카운터 분모 = 객관식 문제 수, 분자 = 서버 `correct == true` 수(세션 결과 우선) | `QuizSessionFeature` | FR-014b·c, SC-003 |
| V-10 | `questions.isEmpty`이면 `questionPresented`를 내지 않고 `setEmpty` | `QuizSessionFeature` | 경계 사례 "문제 0개" |
| V-11 | `ActiveScreen`에 "완료·이탈" case 없음, 이탈은 `QuizExitFeature.delegate`로만 | `QuizRouterFeature` | navigation.md §2.3 |
| V-12 | 활성 화면 값이 바뀔 때만 `transitionLog`에 추가 | `QuizRouterFeature` | navigation.md §2.3 |
| V-13 | `firstIncompleteSet == nil`이면 `quickStartTapped` 무시 | `ProjectDetailFeature` | FR-006a |
| V-14 | `sources.isEmpty`이면 `sourceTapped` 무시(트리거 미노출) | 두 문제 Feature | 경계 사례 "출처 없음" |
| V-15 | Data 패키지 파일 변경 0건 | 전체 | FR-029, SC-005 |

## 5. 관계

```text
LearningProjectDetail ──┬── LearningProjectSetProgress (label·problemCount·completedCount)
                        └── firstIncompleteSet → QuizEntry.direct / .setIntro(label,title)

LearningSet ── Question ──┬── PreviousAnswer?
                          └── [QuestionSource]

QuizRouterFeature.State
├── session: QuizSessionFeature.State ── LearningSet · sessionOutcomes[questionID: AnswerOutcome]
├── setIntro?: LearningSetIntroFeature.State
├── choiceQuestion?: ChoiceQuestionFeature.State ── bookmark: QuestionBookmarkFeature.State
├── essayQuestion?: EssayQuestionFeature.State ── bookmark: QuestionBookmarkFeature.State
├── completion?: LearningCompletionFeature.State ── LearningCompletionSummary
├── source?: QuestionSourceFeature.State ── [QuestionSource]
└── exit: QuizExitFeature.State

AppRootFeature.State.mainStack: StackState<[.projectDetail | .quiz]>
```

세션 → 문제 Feature 방향은 `QuestionPresentation` 값 복사 한 번뿐이고, 문제 Feature → 세션 방향은
`delegate`(제출 결과·북마크 결과)뿐이다. 두 문제 Feature는 서로를 알지 못한다(SC-006).

## 6. `ActiveScreen`과 이동 이벤트

```swift
public enum ActiveScreen: Equatable, Sendable {
    case setIntro                                   // S2
    case sessionLoading                              // 직접 진입의 세트 조회 중
    case sessionFailed                               // 직접 진입의 세트 조회 실패
    case setEmpty                                    // 문제 0개
    case choiceQuestion(ChoiceQuestionFeature.Phase) // S3(answering) · S5(result)
    case essayQuestion(EssayQuestionFeature.Phase)   // S6(answering) · S7(result)
    case completion                                  // S8
}
```

`ScreenTransitionEvent(from: ActiveScreen, to: ActiveScreen, trigger: String)`은
`OnboardingRouterFeature.ScreenTransitionEvent`와 같은 형태다. S3→S5처럼 같은 문제 Feature 안의
`phase` 변화도 활성 화면 값이 바뀌므로 이벤트로 남는다. 출처 시트 표시(`source` 존재)는 활성 화면
값을 바꾸지 않아 이벤트를 남기지 않는다.

## 7. 상태 전이와 검증 테스트 (SC-002 · SC-006 · SC-010)

| 화면 | 전이 | 검증 테스트 파일 |
| --- | --- | --- |
| S1 | `idle → loading → loaded/failed`, `retry`, `reloadRequested`(requestID 증가), `setRowTapped → setSelected(set)`, `quickStartTapped → quickStartRequested`(미완료 세트 없으면 무시), `backTapped → backRequested` | `sources/Projects/Feature/Tests/ProjectDetail/Reducers/ProjectDetailFeatureTests.swift` |
| S2 | `description loading → loaded/failed`, `startTapped`(loaded 아니면 무시) `→ startRequested`, `retry`, `back` | `sources/Projects/Feature/Tests/Quiz/Reducers/LearningSetIntroFeatureTests.swift` |
| S3 | `choiceTapped`(교체·1개 유지), `submitTapped`(선택 없음·committing 무시) `→ committing → result/failed`, 실패 시 선택 유지·재시도, 기존 답변 선반영 | `sources/Projects/Feature/Tests/Quiz/Reducers/ChoiceQuestionFeatureTests.swift` |
| S5 | 결과 후 선택 변경 무시, `resultRowTapped` 펼침·접힘 독립, `judgement` 정답·오답·중립, `nextTapped → nextRequested`, `sourceTapped`(출처 없음 무시) | 위와 동일 파일 |
| S4 | `linkTapped`(URL 파싱 실패 무시·성공 시 `openExternalLink` 1회), `closeTapped → closeRequested`; Router가 `sourceRequested`로 표시·`closeRequested`로 제거 | `sources/Projects/Feature/Tests/Quiz/Reducers/QuestionSourceFeatureTests.swift`, `QuizRouterFeatureTests.swift` |
| S6 | `essayTextChanged`(400자 절단), `submitTapped`(공백·초과·committing 무시) `→ committing → result/failed`, 실패 시 입력 유지 | `sources/Projects/Feature/Tests/Quiz/Reducers/EssayQuestionFeatureTests.swift` |
| S7 | `submittedText` 보존, `nextTapped → nextRequested` | 위와 동일 파일 |
| S8 | 카운터 유무(`hasCounter`), 메시지, `nextTapped`·`closeTapped → finished` | `sources/Projects/Feature/Tests/Quiz/Reducers/LearningCompletionFeatureTests.swift` |
| 세션 | 조회 성공·실패·재시도·늦은 응답 거부, 빈 세트, 시작 index(지정 문제·미답변·전부 답변·세션 결과 반영), 순차 진행, 완료 집계(혼합 세트·서술형만, SC-010), 북마크 실패 시 빈 집합 | `sources/Projects/Feature/Tests/Quiz/Reducers/QuizSessionFeatureTests.swift` |
| 북마크 | committing 중 재탭 무시, 성공 시만 반영, 실패 시 유지·재시도 | `sources/Projects/Feature/Tests/Quiz/Reducers/QuestionBookmarkFeatureTests.swift` |
| 이탈 판단 | `completionFinished → shouldExit(.completed)`, `backRequestedAtEntry → shouldExit(.abandoned)` | `sources/Projects/Feature/Tests/Quiz/Reducers/QuizExitFeatureTests.swift` |
| Router | 두 진입 경로의 활성 화면 순서와 `transitionLog`, S2 복귀 뒤로가기, 직접 진입 뒤로가기 이탈, 출처 시트 표시·제거, 완료 → `exited(.completed)` | `sources/Projects/Feature/Tests/Quiz/Reducers/QuizRouterFeatureTests.swift` |
| App | delegate → push/pop, 이탈 후 상세 재조회·홈 재조회, 시스템 pop | `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift` |

각 화면 Feature 테스트는 자기 State와 자기 Mock만 준비한다(SC-006). Router 테스트만 여러 State를
함께 다루며, 이는 조합 검증이 Router의 책임이기 때문이다(명세 시나리오 6 독립 테스트 항목).
