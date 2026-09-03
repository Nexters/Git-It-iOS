# 데이터 모델: Task3 학습 세트 풀이 흐름

**기능 브랜치**: `feature/quiz-solving-flow`

**작성일**: 2026-09-03

**근거**: [spec.md](./spec.md) 핵심 엔터티와 FR-039·FR-040·FR-032a~c, [research.md](./research.md)

Data 패키지 DTO는 변경하지 않는다(FR-049). 필요한 값은 이미 모두 존재한다.

## 1. Domain 모델 (`sources/Projects/Domain/LearningProject/Models/Quiz/`)

### 1.1 `LearningSet` (변경)

| 필드 | 타입 | 변경 | 설명 |
| --- | --- | --- | --- |
| `setID` | `String` | 유지 | 세트 식별자 |
| `title` | `String` | 유지 | 세트 제목. 세트 시작 화면 제목의 유일한 출처(FR-003) |
| `description` | `String` | **추가** | 세트 설명. `LearningSetResponseDTO.description` |
| `questions` | `[Question]` | 유지 | 서버 응답 순서 보존(FR-040) |

세트 라벨은 이 모델에 없다. 출처는 `LearningProjectSetProgress.label`이며 흐름 진입 의도가
라벨만 전달한다(FR-003).

### 1.2 `Question` (변경)

| 필드 | 타입 | 변경 | 설명 |
| --- | --- | --- | --- |
| `questionID` | `String` | 유지 | 문제 식별자 |
| `prompt` | `String` | 유지 | 질문 본문 |
| `format` | `QuestionFormat` | 유지 | `multipleChoice` / `essay` |
| `choices` | `[String]?` | 유지 | 개수를 고정하지 않는다 |
| `sources` | `[QuestionSource]` | **단수 → 배열** | 배열 전체를 순서대로 보존(FR-010b) |
| `myAnswer` | `SubmittedAnswer?` | **타입 변경** | 이전 제출 답변. 없으면 `nil` |

### 1.3 `QuestionSource` (변경)

| 필드 | 타입 | 변경 |
| --- | --- | --- |
| `filePath` | `String?` | 유지 |
| `startLine` | `Int?` | **추가** |
| `endLine` | `Int?` | **추가** |
| `symbol` | `String?` | **추가** |
| `summary` | `String?` | **추가** |
| `referenceURL` | `String?` | 유지 |

`SourceResponseDTO`의 `startLine`·`endLine`·`symbol`은 비-optional이지만 Domain은 값이 없는
출처를 표현할 수 있어야 하므로 optional로 받는다.

### 1.4 `SubmittedAnswer` (신규)

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `selectedIndex` | `Int?` | 객관식에서 고른 선택지 index |
| `text` | `String?` | 서술형 답안 원문 |
| `correct` | `Bool?` | 정답 여부. 서술형은 항상 `nil` |

- 값이 있으면 "이미 답변한 문제"이고 세트 시작 지점 판정에서 건너뛴다(FR-004).
- `correct == true`이고 형식이 `multipleChoice`일 때만 완료 카운터 분자에 더한다(FR-029b).
- 단일 문제 진입에서는 이 값을 복원하지 않는다(FR-044a-5).

### 1.5 매핑 규칙 (Composition · `LearningSetRepositoryAdapter`)

| Domain | Data DTO |
| --- | --- |
| `LearningSet.description` | `LearningSetResponseDTO.description` |
| `Question.sources` | `QuestionResponseDTO.sources` 전체를 순서대로 |
| `QuestionSource.filePath` | `SourceResponseDTO.file` |
| `QuestionSource.startLine` / `endLine` / `symbol` / `summary` | 같은 이름의 DTO 필드 |
| `QuestionSource.referenceURL` | `SourceResponseDTO.url` |
| `SubmittedAnswer` | `MyAnswerResponseDTO`의 `selectedIndex` / `text` / `correct` |

`MyAnswerResponseDTO.answeredAt`은 화면이 쓰지 않으므로 매핑하지 않는다. 배열은 재정렬하지
않는다(FR-040).

## 2. UI 컴포넌트 계약 변경 (`sources/Projects/UI/Component/`)

### 2.1 `LearningSetRow` (변경 · D-009)

| 인자 | 변경 | 설명 |
| --- | --- | --- |
| `label` | **추가** | 세트 라벨. 제목과 구별되는 표현으로 그린다(FR-042) |
| `title` | 유지 | 세트 제목 |
| `questionCount` | 유지 | 세그먼트 개수의 분모(FR-042b) |
| `completedCount` | **추가** | 채울 세그먼트 수 |
| `progress` | **제거** | 세그먼트 표현으로 대체 |
| `isCompleted` | **제거** | 렌더에 없음. 필요하면 세그먼트가 가득 찬 상태로 드러난다 |
| `onStart` | **이름 변경**(`onTap` → `onStart`) | 우측 시작 버튼의 콜백 |

- 카드 전체를 감싸던 `Button`을 제거하고 우측 시작 버튼만 조작 단위로 둔다(FR-042a).
- 진행 표시는 `ProgressSegments(completed:total:)`를 사용한다(FR-042b).
- 역할 폴더는 `CollectionItems/`를 유지한다(D-009).
- 접근성: 카드는 정보 요소로 합쳐 읽고, 시작 버튼은 별도 요소로 레이블과 44pt hit area를
  갖는다(FR-052~FR-056).

## 3. Feature 표시 모델 (`ViewModels/`)

서브뷰에 Domain 모델을 넘기지 않기 위한 변환 타입이다(D-008).

| 타입 | 위치 | 파생 원본 | 담는 값 |
| --- | --- | --- | --- |
| `ChoiceOptionDisplay` | `Quiz/QuestionSolving/ViewModels/` | `Question.choices` + `ChoiceAnswerResult` | 표시 문자열, 선택 여부, 결과 역할(`default`/`selected`/`correct`/`incorrect`) |
| `QuestionSourceDisplay` | `Quiz/QuestionSolving/ViewModels/` | `[QuestionSource]` | 설명 문자열, 위치 문자열, 링크 표시 문자열, `URL?` |
| `ProjectDetailSetDisplay` | `ProjectDetail/ProjectDetail/ViewModels/` | `LearningProjectSetProgress` | 라벨, 제목, 문제 수, 완료 수, 시작 가능 여부 |
| `SavedQuestionDisplay` | `ProjectDetail/Saved/ViewModels/` | `BookmarkedQuestion` | 문제 본문, 진입 식별 값 |

결과 역할은 `ChoiceAnswerResult.correct`·`answerIndex`에서만 판정하며 배열 위치나 `A`~`D`
문자로 추론하지 않는다(FR-018, SC-007).

## 4. 흐름 모델 (`Shared/Models/`)

### 4.1 `LearningSetResumption` (`Feature/Quiz/Shared/Models/`)

`LearningSet` 하나에서 시작 지점과 카운터 기준선을 계산하는 값 타입이다.

| 멤버 | 타입 | 규칙 |
| --- | --- | --- |
| `startIndex` | `Int` | 첫 미응답 문제의 index. 모두 응답되었으면 `0`(FR-004b). 문제가 없으면 `0` |
| `choiceQuestionCount` | `Int` | 세트 전체의 객관식 수. 완료 카운터 분모(FR-029a) |
| `skippedCorrectChoiceCount` | `Int` | index가 `startIndex` 미만인 객관식 중 `myAnswer?.correct == true`인 수 |

- 재풀이(`startIndex == 0`)에서는 `skippedCorrectChoiceCount`가 항상 `0`이다.
- `choiceQuestionCount == 0`이면 완료 화면이 카운터를 표시하지 않는다(FR-038).

### 4.2 완료 점수 계산

```text
분자 = skippedCorrectChoiceCount + (이번 세션에서 정답으로 채점된 객관식 수)
분모 = choiceQuestionCount
```

세션 정답 수는 `QuizRouterFeature`가 `QuestionSolvingFeature`의 delegate에서 받은 객관식 채점
결과만 누적한다. 서술형은 분자·분모 어디에도 넣지 않는다(FR-037).

## 5. 상태 전이

### 5.1 `QuizRouterFeature.ActiveScreen`

```text
learningSetIntro ⇄ questionSolving ──(마지막 문제 결과에서 진행)──▶ learningCompletion
```

- 오른쪽 방향은 `시작하기`와 진행 입력, 왼쪽 방향은 문제 화면의 뒤로가기다(FR-035a).
- 문제 사이 이동은 활성 화면을 바꾸지 않는다(FR-034, 시나리오 4-2).
- 활성 화면에 "완료 후 이탈" case를 두지 않는다. 이탈은 Router의 `delegate`다(FR-032, FR-035b).
- 뒤로 돌아온 뒤 `시작하기`는 보유 중인 `questionSolving` child State를 그대로 다시 활성화
  한다(FR-035d).

### 5.2 `ProjectDetailRouterFeature.ActiveScreen`

```text
projectDetail ⇄ savedQuestions ⇄ singleQuestion
```

- `projectDetail`의 뒤로가기는 되돌아갈 화면이 없으므로 흐름 이탈이다(FR-035b).
- `singleQuestion`의 결과 진행은 `savedQuestions`로 되돌아간다(FR-044a-4).

### 5.3 `QuestionSolvingFeature.Submission`

```text
editing ──submitAnswerTapped──▶ submitting ──성공──▶ answered(결과)
                                    └──실패──▶ failed(오류) ──submitAnswerTapped──▶ submitting
```

- `editing`·`failed`에서 draft(선택 index, 서술형 텍스트)는 유지된다(FR-021, FR-023).
- `submitting`에서는 제출·진행·뒤로가기 입력을 무시한다(FR-015, FR-035c, SC-004).
- `answered`에서만 진행 입력을 처리한다(FR-026).
- 북마크 mutation 상태는 이 enum과 분리한다(FR-032a).

### 5.4 `LearningSetIntroFeature`의 두 조회 (FR-032a~c)

```text
SetLoad:      idle ──task/retry──▶ loading(requestID) ──▶ loaded(LearningSet) | failed(error)
BookmarkLoad: idle ──task───────▶ loading ─────────────▶ loaded(Set<String>) | failed(error)
```

- 두 상태는 서로 영향을 주지 않는다. `BookmarkLoad.failed`는 풀이를 막지 않는다(FR-025c).
- `SetLoad`는 재시도가 이전 요청을 대체할 수 있으므로 `requestID`를 보존하고 일치하는 결과만
  반영한다(FR-032c).
- 두 실패 모두 `LearningProjectError`를 보존한다(FR-032b).

### 5.5 `ProjectDetailFeature.Deletion` (D-012)

```text
idle ──deleteTapped──▶ confirming ──deletionConfirmed──▶ committing ──성공──▶ (흐름 이탈)
         │                  └──deletionCancelled──▶ idle          └──실패──▶ failed(error)
```

`committing`에서는 재입력을 무시한다(FR-044c).
