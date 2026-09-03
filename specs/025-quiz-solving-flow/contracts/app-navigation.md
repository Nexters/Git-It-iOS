# 계약: App 진입과 표시

**기능 브랜치**: `feature/quiz-solving-flow`

**작성일**: 2026-09-03

App은 Feature의 delegate를 해석해 목적지와 표시 방식을 결정한다(아키텍처 §2, FR-035).

## 1. App 상태

```swift
@Presents var projectDetail: ProjectDetailRouterFeature.State?
@Presents var quiz: QuizRouterFeature.State?
```

`AppRootView`는 `mainShell` 위에 프로젝트 상세 흐름을 `fullScreenCover`로, 그 위에 풀이 흐름을
`fullScreenCover`로 표시한다. 상세 흐름이 아래 계층에 남으므로 풀이 흐름을 닫으면 그 세트가
속한 프로젝트 상세로 돌아온다(FR-043, D-002).

## 2. Action 해석

| 수신 | 처리 |
| --- | --- |
| `mainShell(.delegate(.projectDetailRequested(projectID:)))` | `projectDetail = .init(projectID:)` |
| `projectDetail(.presented(.delegate(.learningSetRequested(projectID:setID:label:))))` | `quiz = .init(projectID:setID:setLabel:)` |
| `projectDetail(.presented(.delegate(.externalURLRequested(url))))` | `openExternalURL(url)` 실행 |
| `projectDetail(.presented(.delegate(.projectDeleted(projectID:))))` | `projectDetail = nil`, MainShell에 목록 갱신 신호 전달 |
| `projectDetail(.presented(.delegate(.dismissRequested)))` | `projectDetail = nil` |
| `quiz(.presented(.delegate(.externalURLRequested(url))))` | `openExternalURL(url)` 실행 |
| `quiz(.presented(.delegate(.progressInvalidated(projectID:))))` | 표시 중인 상세가 같은 프로젝트면 `.projectDetail(.presented(.projectDetail(.input(.refreshRequested))))` |
| `quiz(.presented(.delegate(.dismissRequested(projectID:))))` | `quiz = nil`. 상세가 없거나 다른 프로젝트면 `projectDetail = .init(projectID:)`로 맞춘 뒤, 같은 프로젝트면 `refreshRequested` 전달 |
| `mainShell(.delegate(.learningRequested))` | 이번 범위에서는 처리하지 않는다(명세 §범위 밖). 기존 무처리 유지 |
| `mainShell(.delegate(.questionSelected))` | 기존 무처리 유지 |

## 3. 주입

### 3.1 UseCase

`AppRootFeature`가 이미 보유한 것과 이번에 추가할 것을 구분한다.

| 대상 | 전달 UseCase | 비고 |
| --- | --- | --- |
| `ProjectDetailFeature` | `fetchLearningProjectDetail`(신규 주입), `deleteLearningProject`(보유 중) | |
| `SavedFeature` | `fetchBookmarkedQuestions`(보유 중) | |
| `SingleQuestionEntryFeature` | `fetchLearningSet`(신규 주입) | |
| `LearningSetIntroFeature` | `fetchLearningSet`, `fetchBookmarkedQuestions` | 같은 인스턴스 재사용 |
| `QuestionSolvingFeature` | `submitChoiceAnswer`, `submitEssayAnswer`, `setQuestionBookmark`(모두 신규 주입) | |

`AppRootFeature`에 새로 추가되는 생성자 인자는 `fetchLearningProjectDetail`, `fetchLearningSet`,
`submitChoiceAnswer`, `submitEssayAnswer`, `setQuestionBookmark` 5종이다.
`fetchBookmarkedQuestions`와 `deleteLearningProject`는 이미 주입되어 있다. `AppComposition`은
이 7종을 모두 공개하고 있으므로 Composition에 새 공개 API를 추가하지 않는다.

### 3.2 외부 URL 열기 (D-011)

```swift
openExternalURL: @Sendable (URL) async -> Void
```

`GitItApp`이 `UIApplication.shared.open`을 감싼 클로저를 주입한다. 기존
`openNotificationSettings` 주입과 같은 형태이며, Feature가 Infrastructure 기술 API를 참조하지
못하게 하는 Feature 패키지 규칙을 지킨다. 열기 경로는 이 하나뿐이다(SC-021).

## 4. 검증

- `AppRootFeatureTests`에 프로젝트 상세 표시 → 세트 선택 → 풀이 흐름 표시 → 닫기 후 상세
  복귀·갱신 신호 전달을 확인하는 테스트를 추가한다(SC-002).
- 외부 URL delegate가 `openExternalURL`을 정확히 한 번 호출하는지 확인한다(SC-021).
- 삭제 완료 delegate가 상세 표시를 해제하는지 확인한다(FR-044c).
- 표시 방식(`fullScreenCover`)은 App이 결정하며 Router의 delegate에는 전환 방식을 지시하는
  값이 없다(FR-035).
