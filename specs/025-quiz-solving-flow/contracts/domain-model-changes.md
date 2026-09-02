# 계약: Domain 모델 변경과 Composition 어댑터 매핑

**기능 브랜치**: `feature/quiz-solving-flow` · **날짜**: 2026-09-03

FR-017~FR-022·FR-029·FR-030의 정본. Data 패키지는 읽기만 하며 DTO는 이미 필요한 필드를 모두 갖는다
(명세 가정, 2026-09-03 확인). 필드 정의는 [data-model.md](../data-model.md) §1.

## 1. Domain 공개 API 변경 (`DomainLearningProject`)

| 파일 | 변경 |
| --- | --- |
| `sources/Projects/Domain/LearningProject/Models/Quiz/LearningSet.swift` | `init(setID:title:description:questions:)`, `description` 추가, `resumeQuestionIndex(additionallyAnswered:)` 추가 |
| `sources/Projects/Domain/LearningProject/Models/Quiz/Question.swift` | `init(questionID:prompt:format:choices:sources:previousAnswer:)`. `source`·`myAnswer` 제거, `isAnswered`·`hasSources` 추가 |
| `sources/Projects/Domain/LearningProject/Models/Quiz/PreviousAnswer.swift` | **신설** `PreviousAnswer(selectedIndex:text:correct:)` |
| `sources/Projects/Domain/LearningProject/Models/Quiz/QuestionSource.swift` | `init(filePath:startLine:endLine:symbol:summary:referenceURL:)`, `locationLabel` 추가 |
| `sources/Projects/Domain/LearningProject/Models/LearningProject/LearningProjectDetail.swift` | `firstIncompleteSet` computed 추가. 생성자·`nextSet` 유지 |

deprecated 별칭을 남기지 않는다. 호출부는 같은 실행 단위에서 고친다(R-18).

## 2. `LearningSetRepositoryAdapter` 매핑

파일: `sources/Projects/Composition/Adapter/Adapters/LearningSetRepositoryAdapter.swift`

| DTO | Domain | 규칙 |
| --- | --- | --- |
| `LearningSetResponseDTO.setID` | `LearningSet.setID` | 유지 |
| `.title` | `.title` | 유지 |
| `.description` | `.description` | **추가** |
| `.orientation`, `.level` | — | 화면 요구 없음, 매핑하지 않음 |
| `.questions` | `.questions` | 순서 유지(FR-022) |
| `QuestionResponseDTO.questionID` | `Question.questionID` | 유지 |
| `.text` | `.prompt` | 유지 |
| `.format` | `.format` | 기존 `"essay"` → `.essay`, 그 밖 `.multipleChoice` 유지 |
| `.choices` | `.choices` | 빈 배열 → `nil` 유지, 순서 유지 |
| `.sources` | `.sources` | **전부 매핑**(기존 `first`만 → 배열), 순서 유지 |
| `SourceResponseDTO.file` | `QuestionSource.filePath` | |
| `.startLine`, `.endLine`, `.symbol`, `.summary`, `.url` | `.startLine`, `.endLine`, `.symbol`, `.summary`, `.referenceURL` | **추가** |
| `.myAnswer` | `.previousAnswer` | `nil` → `nil`. 아니면 `PreviousAnswer(selectedIndex: dto.selectedIndex, text: dto.text, correct: dto.correct)`. 문자열 평탄화 제거 |

오류 매핑 `domainError(for:)`는 바꾸지 않는다.

## 3. `LearningProjectRepositoryAdapter` 매핑

파일: `sources/Projects/Composition/Adapter/Adapters/LearningProjectRepositoryAdapter.swift`
(`fetchProjectDetail`, 현재 62-68행)

| DTO | Domain | 규칙 |
| --- | --- | --- |
| `ProjectSetSummaryDTO.problemCount` | `LearningProjectSetProgress.problemCount` | 상수 `0` → DTO 값(FR-018, SC-004) |
| `.completedCount` | `.completedCount` | 상수 `0` → DTO 값 |

`sets` 순서 유지(FR-022). 그 밖의 필드 매핑은 바꾸지 않는다.

## 4. 영향 받는 테스트와 기대값

| 파일 | 변경 |
| --- | --- |
| `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningSetTests.swift` | 새 생성자 사용, `myAnswer == nil` 검증을 `previousAnswer == nil`로 |
| `sources/Projects/Domain/Tests/LearningProject/Models/Quiz/LearningSetTests.swift` | **신설** — `resumeQuestionIndex`: 미답변 첫 문제 · 전부 답변 → 0 · `additionallyAnswered` 반영 |
| `sources/Projects/Domain/Tests/LearningProject/Models/LearningProject/LearningProjectDetailTests.swift` | `firstIncompleteSet`: 미완료 있음 · 전부 완료 → `nil` · `nextSet` 기존 동작 유지 |
| `sources/Projects/Composition/Tests/Adapter/Adapters/LearningSetRepositoryAdapterTests.swift` | `description`, 복수 `sources` 필드 6개, `previousAnswer` 3필드(객관식·서술형·없음) 기대값 |
| `sources/Projects/Composition/Tests/Adapter/Adapters/LearningProjectRepositoryAdapterTests.swift` | `problemCount`·`completedCount`가 DTO 값 그대로인지 |

## 5. 변경하지 않는 것

- Data 패키지 전체(`sources/Projects/Data/**`) — FR-029, SC-005.
- `LearningSetRepository`·`LearningProjectRepository` Protocol 시그니처.
- UseCase Protocol 6종과 구현체, `AppComposition`·`LearningProjectAssembly`.
- `Rubric`·`EssayAnswerResult` — rubric은 범위 밖(R-15).
- `LearningProjectSetProgress`·`LearningProjectDetail` 생성자.
