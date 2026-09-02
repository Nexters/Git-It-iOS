# 계약: 화면 흐름 — Router 전환 규칙과 App 내비게이션

**기능 브랜치**: `feature/quiz-solving-flow` · **날짜**: 2026-09-03

Reducer 계약은 [feature-reducers.md](./feature-reducers.md), `ActiveScreen` 정의는
[data-model.md](../data-model.md) §6. 이 문서는 "어떤 사건이 어떤 전환을 만드는가"만 고정한다.

## 1. 진입 경로 (FR-001 · FR-002 · FR-006a)

| 출발 | 사건 | App이 만드는 State | Router 첫 화면 |
| --- | --- | --- | --- |
| 홈 이어 풀기 | `mainShell.delegate(.learningRequested(projectID:nextSetID:nextQuestionID:))` | `.quiz(QuizRouterFeature.State(projectID:, setID: nextSetID, entry: .direct(startingQuestionID: nextQuestionID)))` | `sessionLoading` → 지정 문제 |
| S1 세트 행 | `projectDetail.delegate(.setSelected(projectID:set:))` | `.quiz(…, entry: .setIntro(label: set.label, title: set.title))` | `setIntro` |
| S1 바로 시작 | `projectDetail.delegate(.quickStartRequested(projectID:setID:))` | `.quiz(…, entry: .direct(startingQuestionID: nil))` | `sessionLoading` → 첫 미답변 문제 |
| 홈·프로젝트 목록 | `mainShell.delegate(.projectDetailRequested(projectID:))` | `.projectDetail(ProjectDetailFeature.State(projectID:))` | S1 |

`mainShell.delegate(.questionSelected)`(저장 탭)는 범위 밖이라 계속 `.none`이다.

## 2. Router `Reduce` 해석표

`before = state.activeScreen`을 기록하고 아래를 적용한 뒤 값이 바뀌었으면
`transitionLog.append(from: before, to: activeScreen, trigger: String(describing: action))`.

| 수신 Action | State 변화 | 반환 Effect |
| --- | --- | --- |
| `view(.task)` | — | `.send(.session(.input(.loadRequested)))` (최초 1회) |
| `session(.delegate(.setLoaded(set)))` | `entry == .setIntro`: — | `.setIntro`: `.send(.setIntro(.input(.descriptionLoadChanged(.loaded(set.description)))))` · `.direct`: `.send(.session(.input(.startRequested)))` |
| `session(.delegate(.setLoadFailed(e)))` | `.setIntro`: — · `.direct`: `activeScreen = .sessionFailed` | `.setIntro`: `.send(.setIntro(.input(.descriptionLoadChanged(.failed(e)))))` |
| `session(.delegate(.setEmpty))` | `activeScreen = .setEmpty` | `.none` |
| `session(.delegate(.questionPresented(p)))` | `p.question.format`이 `.multipleChoice`: `choiceQuestion = .init(projectID:presentation: p)`, `essayQuestion = nil`, `activeScreen = .choiceQuestion(.answering)` · `.essay`: 대칭 | `.none` |
| `session(.delegate(.setCompleted(summary)))` | `completion = .init(summary:)`, `choiceQuestion = essayQuestion = nil`, `activeScreen = .completion` | `.none` |
| `setIntro(.delegate(.startRequested))` | — | `.send(.session(.input(.startRequested)))` |
| `setIntro(.delegate(.retryRequested))` | — | `.send(.setIntro(.input(.descriptionLoadChanged(.loading))))` 후 `.send(.session(.input(.retryRequested)))` |
| `setIntro(.delegate(.backRequested))` · `view(.backTapped)` | — | `.send(.exit(.input(.backRequestedAtEntry)))` |
| `view(.retryTapped)` | `activeScreen = .sessionLoading` | `.send(.session(.input(.retryRequested)))` |
| `choiceQuestion(.delegate(.answerSubmitted(id, outcome)))` · `essayQuestion(…)` | — | `.send(.session(.input(.answerRecorded(questionID: id, outcome:))))` |
| `…(.delegate(.nextRequested))` | — | `.send(.session(.input(.advanceRequested)))` |
| `…(.delegate(.sourceRequested))` | `source = QuestionSourceFeature.State(questionNumber: number, sources: question.sources)` | `.none` |
| `…(.delegate(.bookmarkChanged(id, flag)))` | — | `.send(.session(.input(.bookmarkRecorded(…))))` |
| `…(.delegate(.backRequested))` | `entry == .setIntro`: `choiceQuestion = essayQuestion = nil`, `activeScreen = .setIntro` · `.direct`: — | `.direct`: `.send(.exit(.input(.backRequestedAtEntry)))` |
| `source(.presented(.delegate(.closeRequested)))` · `source(.dismiss)` | `source = nil` | `.none` |
| `completion(.delegate(.finished))` | — | `.send(.exit(.input(.completionFinished)))` |
| `exit(.delegate(.shouldExit(reason)))` | — | `.send(.delegate(.exited(projectID:reason:)))` |
| `choiceQuestion(그 밖의 액션)` | `activeScreen == .choiceQuestion`이면 `.choiceQuestion(choiceQuestion.phase)`로 동기화 | `.none` |
| `essayQuestion(그 밖의 액션)` | 대칭 | `.none` |
| 그 밖 | — | `.none` |

`body` 순서: `Scope(\.session)`, `Scope(\.exit)`, `ifLet(\.setIntro)`, `ifLet(\.choiceQuestion)`,
`ifLet(\.essayQuestion)`, `ifLet(\.completion)`, `Reduce { … }`, `.ifLet(\.$source, action: \.source)`.

## 3. 활성 화면 순서 (검증 기준)

| 경로 | `transitionLog`의 `to` 순서 |
| --- | --- |
| S1 → 세트 행(객관식 2·서술형 1) → 완료 | `setIntro` → `choiceQuestion(.answering)` → `choiceQuestion(.result)` → `choiceQuestion(.answering)` → `choiceQuestion(.result)` → `essayQuestion(.answering)` → `essayQuestion(.result)` → `completion` |
| 홈 이어 풀기(서술형 1문제 남음) | `sessionLoading` → `essayQuestion(.answering)` → `essayQuestion(.result)` → `completion` |
| 바로 시작, 조회 실패 → 재시도 성공 | `sessionLoading` → `sessionFailed` → `sessionLoading` → `choiceQuestion(.answering)` … |
| 세트 행 → 시작 → 1문제 제출 → 뒤로가기 → 시작 | `setIntro` → `choiceQuestion(.answering)` → `choiceQuestion(.result)` → `setIntro` → `choiceQuestion(.answering)`(2번 문제) |
| 빈 세트 | `setIntro` 또는 `sessionLoading` → `setEmpty` |

출처 시트는 `to`에 나타나지 않는다(활성 화면 값 불변).

## 4. App 내비게이션 정책 (`AppRootFeature`)

| 수신 | 처리 |
| --- | --- |
| `mainShell(.delegate(.projectDetailRequested(projectID)))` | `mainStack.append(.projectDetail(.init(projectID:)))` |
| `mainShell(.delegate(.learningRequested(…)))` | `mainStack.append(.quiz(.init(…, entry: .direct(startingQuestionID: nextQuestionID))))` |
| `mainStack(.element(id, .projectDetail(.delegate(.setSelected(projectID, set)))))` | `append(.quiz(…, entry: .setIntro(label:title:)))` |
| `mainStack(.element(id, .projectDetail(.delegate(.quickStartRequested(projectID, setID)))))` | `append(.quiz(…, entry: .direct(startingQuestionID: nil)))` |
| `mainStack(.element(id, .projectDetail(.delegate(.backRequested))))` | `mainStack.pop(from: id)` |
| `mainStack(.element(id, .quiz(.delegate(.exited(projectID, reason)))))` | `pop(from: id)` → §4.1 갱신 규칙 |
| `mainStack(.popFrom(id))` (시스템 pop) | 제거된 요소가 `.quiz`이면 §4.1 갱신 규칙, `.projectDetail`이면 홈 재조회 |
| `mainShell(.delegate(.loggedOut))` · 전체 초기화 | `mainStack.removeAll()` (기존 `state.mainShell = …` 재설정 지점) |

### 4.1 이탈 후 진행률 갱신 (FR-014a · FR-023)

```text
quiz pop 이후:
  같은 projectID의 .projectDetail이 스택에 있음  → 그 요소에 .projectDetail(.input(.reloadRequested)) 전송
  없고 reason == .completed                       → .projectDetail(.init(projectID:)) append  (S8 → 프로젝트 상세)
  없고 reason == .abandoned                       → .mainShell(.home(.input(.learningProjectsReloadRequested))) 전송
```

## 5. 화면 표시 규칙 요약

| 화면 | 헤더 | 하단 툴바 | 출처 트리거 |
| --- | --- | --- | --- |
| S1 | `ScreenHeader(leading: .back)`, trailing 없음(FR-006b) | 없음 | — |
| S2 | `.back` | Primary `시작하기`(`isEnabled: isStartEnabled`) | — |
| S3 | `.back` | `BookmarkButton` + Primary `정답 확인`(`isEnabled: canSubmit`) | `hasSources`일 때 선택지 목록 끝 |
| S5 | `.back` | `BookmarkButton` + Primary `다음` | `AI 해설` 카드 아래 |
| S4 | 시트 제목 `문제 N 출처` | Primary `닫기` | — |
| S6 | `.back` | `BookmarkButton` + Primary `정답 확인`(`isEnabled: canSubmit`) | `hasSources`일 때 입력 카드 아래 우측 |
| S7 | `.back` | `BookmarkButton` + Primary `다음` | `AI의 답안` 카드 아래 우측 |
| S8 | `ScreenHeader(leading: .close)` | Secondary `다음` | — |
| 로딩·실패·빈 세트 | `.back` | 실패만 Secondary `다시 시도` | — |
