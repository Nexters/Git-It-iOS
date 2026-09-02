# 계약: UI 컴포넌트 공개 API와 화면별 조립

**기능 브랜치**: `feature/quiz-solving-flow` · **날짜**: 2026-09-03

FR-007·FR-028·FR-030의 정본. Figma 노드는 `.agents/skills/implement-figma-ui/references/figma-index.md`
§4.4와 `private/task3-quiz-flow-spec.md` §3을 근거로 하며 노드 근거 없는 레이아웃 값을 추정하지
않는다.

## 1. 변경하는 UI 컴포넌트 (`UIComponent`)

### 1.1 `LearningSetRow` — 재구성 (FR-007)

파일: `sources/Projects/UI/Component/CollectionItems/LearningSetRow/LearningSetRow.swift`,
`LearningSetRow+Constant.swift`. Figma `학습세트 List-item` `997:18550`(320×130).

```swift
public init(
    label: String,            // "Set 1"
    title: String,
    questionCount: Int,       // 세그먼트 수 = problemCount
    completedCount: Int,      // 채운 세그먼트 수
    onTap: @escaping () -> Void = { },
)
```

- 내부: `label`(Blue100) · `title`(흰색) · 우측 재생 아이콘(`ResourceImage.Icon.playSmall`, 원형 `blue400`
  배경) · 하단 `ProgressSegments(completed: completedCount, total: questionCount)`.
- 제거: `progress: Double`, `isCompleted`, `완료` `TagBadge`, `문제 N개` 캡션, `ContinuousProgressBar`.
- 접근성 라벨: `"\(label) \(title), \(questionCount)문항 중 \(completedCount)문항 완료"`.
- press 상태: 기존 `PressOverlayStyle` 유지(Figma `Variant2`).
- 테스트: `sources/Projects/UI/Tests/Component/Unit/CollectionItems/LearningSetRowTests.swift`,
  `sources/Projects/UI/Tests/Component/Unit/Controls/AccessibilityContractTests.swift` 생성자 갱신.

### 1.2 `ChoiceResultRow.Judgement.neutral` — 추가 (FR-010a)

파일: `sources/Projects/UI/Component/CollectionItems/ChoiceResultRow/ChoiceResultRow.swift`.

| case | 배경 | 접근성 접미사 | 용도 |
| --- | --- | --- | --- |
| `.correct` | `.correct`(`#3E85FF`) | `정답` | 기존 |
| `.incorrect` | `.incorrect`(`#FF5656`) | `오답` | 기존 |
| `.neutral` | `.grey600` | 없음 | **추가** — 정답도 사용자의 오답도 아닌 선택지 |

접힌 상태 표현은 세 case 모두 기존과 같다(Grey600 배경, Blue200 문자). 테스트:
`sources/Projects/UI/Tests/Component/Unit/CollectionItems/ChoiceResultRowTests.swift`에 `.neutral` 행 추가.

### 1.3 `GradientToken` 세트 시작 배경 — 승인 후에만 (R-13)

파일: `sources/Projects/UI/DesignSystem/Tokens/GradientToken.swift`. 승인 시 `#141414 → #A5C4F0` 세로
그라데이션 항목 1개를 `all`에 추가하고 DesignSystem 토큰 카탈로그 테스트의 개수 기대값을 갱신한다.
미승인 시 이 항목은 없다.

## 2. 변경 없이 사용하는 컴포넌트

`ScreenContainer`, `ScreenHeader(title:leading:trailing:onLeadingTap:)`, `BottomActionBar`, `ScreenEdgeScrim`,
`SheetSurface`, `ModalOverlay`, `ActionButton.primary/.secondary`, `BookmarkButton(isSaved:accessibilityLabel:onTap:)`,
`ChoiceAnswerOption(text:state:onTap:)`, `ChoiceResultRow`, `ProgressSegments`, `LabeledProgressBar`,
`EmptyState`, `ResourceAnimation`, `TagBadge`, `StyledText`, `IconGlassButton`, `TextField`.

## 3. 화면별 조립

| 화면 | Figma | 컴포넌트 | Feature 로컬 View |
| --- | --- | --- | --- |
| S1 | `1617:18786` | `ScreenContainer`, `ScreenHeader(.back)`, `ScreenEdgeScrim.top`, `LabeledProgressBar(label: "전체 진행률")`, `LearningSetRow` ×n, `IconGlassButton`(바로 시작 `playSmall`, `quickStartSet != nil`일 때만) | `RepositorySummaryHeader`(썸네일·이름·스타 `k` 축약·기술 스택) |
| S2 | `813:15700` | `ScreenHeader(.back)`, `StyledText`, `BottomActionBar` + `ActionButton.primary("시작하기")`, `ResourceAnimation(.generalLoading)`(설명 로드 중) | 배경 그라데이션(승인 시 토큰) |
| S3 | `1342:18657`·`18711`·`18925`·`18946` | `ScreenHeader(.back)`, `TagBadge.accent("문제 N")`, `ScreenEdgeScrim.top(headerStyle:)`·`.bottom`, `ChoiceAnswerOption(state: .default/.selected)` ×n, `BottomActionBar` + `BookmarkButton` + `ActionButton.primary("정답 확인")` | `QuestionPrompt`(태그 + 16 Bold 본문, 재작성), `SourceTriggerButton` |
| S5 | `1374:17084`·`17109` | S3 + `ChoiceResultRow(judgement:isExpanded:)` ×n, `ActionButton.primary("다음")` | `AIExplanationCard`(`AI 해설`, `blue500`) |
| S4 | `1342:18678` › `1342:18699` | `ModalOverlay`, `SheetSurface`, `StyledText`(제목 `문제 N 출처`·설명), `ActionButton.secondary`(링크 라벨 + `link` 아이콘, `isEnabled: url != nil`) ×출처 수, `ActionButton.primary("닫기")` | — |
| S6 | `855:15476`·`15454` | S3 헤더·툴바, `ActionButton.primary("정답 확인")` | `AnswerEditor`(Figma 262 카드, `n / 400`, 재작성), `SourceTriggerButton` |
| S7 | `855:15415` | S6 헤더·툴바, `ActionButton.primary("다음")` | `SubmittedAnswerCard`(`나의 답안`, `grey500`), `AIExplanationCard`(`AI의 답안`) |
| S8 | `1374:17250` | `ScreenHeader(.close)`, `ResourceAnimation(asset: .complete, isLooping: false)`, `StyledText`, `BottomActionBar` + `ActionButton.secondary("다음")` | `CompletionCounter`(`7 / 7`, `hasCounter`일 때만) |
| 로딩·실패·빈 세트 | 프레임 없음 | `ResourceAnimation(.generalLoading)`, `EmptyState`, `ActionButton.secondary("다시 시도")` | `QuizSessionStatusView` |

Feature 로컬 View 경로: `sources/Projects/Feature/Quiz/Views/`, `sources/Projects/Feature/ProjectDetail/Views/`.
색·치수·타이포는 전부 `DesignSystem` 토큰으로 참조한다(FR-028). 텍스트 스타일 선택 근거는 PR 본문에
남긴다(R-14).

## 4. 문서

`docs/conventions/ui-component.md` §3.4 컴포넌트 목록은 추가·삭제가 없어 바꾸지 않는다.
`.agents/skills/implement-figma-ui/references/component-index.md`의 `LearningSetRow` 대응 등급(`추정`)을
`확정`으로 올리는 것은 선택 사항이며 이 기능의 필수 산출물이 아니다.
