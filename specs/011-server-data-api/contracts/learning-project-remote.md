# 계약: `LearningProjectRemote`

**Target**: `DataLearningProject` | **참조 문서 영역**: PROJECT-01 ~ PROJECT-11

## 연산

| 연산 | 참조 Operation ID | Request | Response |
|---|---|---|---|
| `registerProject(...)` | PROJECT-01 | `RegisterProjectRequestDTO` | `RegisterProjectResponseDTO` |
| `fetchProjects(...)` | PROJECT-02 | query(`page`, `size`) | `ProjectListResponseDTO` |
| `fetchProjectDetail(...)` | PROJECT-03 | path(`projectId`) | `ProjectDetailResponseDTO` |
| `deleteProject(...)` | PROJECT-04 | path(`projectId`) | Unit |
| `fetchGenerationStatus(...)` | PROJECT-05 | path(`projectId`) | `QuizGenerationStatusResponseDTO` |
| `retryQuizGeneration(...)` | PROJECT-06 | path(`projectId`) | Unit |
| `fetchLearningSet(...)` | PROJECT-07 | path(`projectId`, `setId`) | `LearningSetResponseDTO` |
| `submitChoiceAnswer(...)` | PROJECT-08 | path(`projectId`, `questionId`) + `SubmitChoiceAnswerRequestDTO` | `SubmitChoiceAnswerResponseDTO` |
| `submitEssayAnswer(...)` | PROJECT-09 | path(`projectId`, `questionId`) + `SubmitEssayAnswerRequestDTO` | `SubmitEssayAnswerResponseDTO` |
| `setBookmark(...)` | PROJECT-10 | path(`projectId`, `questionId`) + `BookmarkQuestionRequestDTO` | `BookmarkQuestionResponseDTO` |
| `fetchBookmarks(...)` | PROJECT-11 | query(`projectId?`) | `BookmarkedQuestionListResponseDTO` |

모든 연산은 Bearer 인증을 사용한다(참조 문서 4절, Apple 로그인 제외 18개 operation 중
11개가 이 target에 속한다).

## 계약 불변식

- FR-007: `repositoryImageUrl`, `nextSetId`, `nextQuestionId`, `myAnswer`, `summary`는
  optional을 유지한다.
- FR-008: `setBookmark`는 toggle이 아니라 `bookmarked: Bool` 최종 상태를 전달하는 command다.
- FR-009: `sets`, `questions`, `choices` 등 서버가 반환한 배열 순서를 재정렬하지 않는다.
- FR-010: `submitEssayAnswer`의 응답에는 `correct` 필드를 생성해 추가하지 않는다.
- FR-011: `fetchGenerationStatus`의 `status`가 알려지지 않은 raw value여도 decoding
  failure로 처리하지 않고 원문 문자열을 보존한다.

## 오류 매핑

`DataLearningProjectError`: 공통(`invalidRequest`, `unauthorized`,
`temporarilyUnavailable`, `transport`, `decoding`, `unexpectedStatus`) + 도메인 전용
(`projectUnavailable`, `questionUnavailable`, `learningSetUnavailable`,
`generationRetryUnavailable`). `retryQuizGeneration`의 409 응답은
`generationRetryUnavailable`로 변환하고 다른 오류와 혼동하지 않는다(spec.md 시나리오 2).
