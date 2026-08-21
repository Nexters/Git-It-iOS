# 1단계 데이터 모델: Git-It Server API 전체 Data 패키지 구현

이 문서는 참조 문서 SPEC-DATA-API-001의 DTO·오류 정의를 Data 패키지 3개 target
(`DataAuthentication`, `DataLearningProject`, `DataMember`)의 타입으로 정리한다. HTTP
method/path 같은 URL 계약은 참조 문서의 operation ID로만 지칭한다(spec.md 명확화 참고).

## 공통 형태(세 target에 동일하게 선언, research.md 결정 4)

### `APIResponseDTO<Payload>`

| 필드 | 타입 | Nullable |
|---|---|---|
| `success` | `Bool` | 아니오 |
| `data` | `Payload?` | 예 |
| `code` | `String?` | 예 |
| `message` | `String?` | 예 |
| `errors` | `[FieldErrorDTO]?` | 예 |

`Payload == Unit`(빈 struct 또는 `Void` 대체 타입)인 경우에도 `data` key 부재 또는
`null`을 정상 decode해야 한다(FR-005).

### `FieldErrorDTO`

| 필드 | 타입 | Nullable |
|---|---|---|
| `field` | `String` | 아니오 |
| `message` | `String?` | 예 |

### `ServerAPIError`(변환 입력)

| 필드 | 타입 |
|---|---|
| `httpStatus` | `Int` |
| `code` | `String?` |
| `message` | `String?` |
| `fieldErrors` | `[FieldErrorDTO]?` |

## `DataAuthentication` target

### 계약: `AuthenticationRemote`

- `appleLogin(idToken:) async throws -> LoginResponseDTO` — 참조 문서 AUTH-01, 인증 헤더 없음
- `verifyAccessToken() async throws` — 참조 문서 AUTH-02, Bearer 필수, Unit 응답

`googleLogin`, `refreshSession`, `revokeRefreshToken` 등은 계약에 선언하지 않는다
(research.md 결정 1, FR-002/FR-012).

### DTO

- `AppleLoginRequestDTO { idToken: String }` — `description`/`debugDescription`에서
  `idToken`을 `<redacted>`로 치환(FR-014).
- `LoginResponseDTO { accessToken: String; refreshToken: String; needsCuration: Bool }` —
  `accessToken`/`refreshToken`을 `<redacted>`로 치환. `refreshToken`은 원문 보존 필드이지
  refresh API 존재의 근거가 아니다(spec.md FR-012).

### 오류: `DataAuthenticationError`

`invalidRequest`, `unauthorized`, `temporarilyUnavailable`, `transport`, `decoding`,
`unexpectedStatus` — Auth 영역에는 도메인 전용 케이스가 없다(참조 문서 6절 대표 매핑 중
Auth에 해당하는 항목만 포함).

## `DataLearningProject` target

### 계약: `LearningProjectRemote`

참조 문서 10절과 동일한 11개 메서드: `registerProject`, `fetchProjects`,
`fetchProjectDetail`, `deleteProject`, `fetchGenerationStatus`, `retryQuizGeneration`,
`fetchLearningSet`, `submitChoiceAnswer`, `submitEssayAnswer`, `setBookmark`,
`fetchBookmarks`.

### DTO (operation → 주요 타입)

| Operation | Request | Response |
|---|---|---|
| PROJECT-01 | `RegisterProjectRequestDTO{ githubRepoUrl: String; quizLevel: QuizLevelDTO }` | `RegisterProjectResponseDTO{ projectId: String; status: String }` |
| PROJECT-02 | query `page: Int; size: Int` | `ProjectListResponseDTO{ items: [ProjectListItemDTO]; hasNext: Bool }` |
| PROJECT-03 | — | `ProjectDetailResponseDTO{ projectId, repositoryUrl, repositoryName, repositoryImageUrl?, starCount, techStack, overallProgressPercent, nextQuestionId?, sets: [ProjectSetSummaryDTO] }` |
| PROJECT-04 | — | Unit |
| PROJECT-05 | — | `QuizGenerationStatusResponseDTO{ status: String }`(알려지지 않은 raw value 보존, FR-011) |
| PROJECT-06 | — | Unit(409 `QUIZ-007`은 `DataLearningProjectError.generationRetryUnavailable`) |
| PROJECT-07 | — | `LearningSetResponseDTO{ setId, title, description, orientation, level, questions: [QuestionResponseDTO] }` |
| PROJECT-08 | `SubmitChoiceAnswerRequestDTO{ selectedIndex: Int }` | `SubmitChoiceAnswerResponseDTO{ questionId, correct, answerIndex, explanation }` |
| PROJECT-09 | `SubmitEssayAnswerRequestDTO{ text: String }` | `SubmitEssayAnswerResponseDTO{ questionId, explanation, rubric: RubricResponseDTO }`(`correct` 없음, FR-010) |
| PROJECT-10 | `BookmarkQuestionRequestDTO{ bookmarked: Bool }`(최종 상태, FR-008) | `BookmarkQuestionResponseDTO{ bookmarked: Bool }` |
| PROJECT-11 | query `projectId: String?` | `BookmarkedQuestionListResponseDTO{ totalCount, availableProjects: [AvailableProjectResponseDTO], bookmarks: [BookmarkedQuestionResponseDTO] }` |

### 보조 타입

- `QuizLevelDTO`: `L1`/`L2`/`L3`
- `ProjectListItemDTO{ projectId, repositoryName, repositoryImageUrl?, techStack: [String], currentSetLabel, currentSetTitle, nextSetId?, nextQuestionId?, overallProgressPercent }` —
  `nextSetId`/`nextQuestionId`는 반드시 optional(FR-007).
- `QuestionResponseDTO{ questionId, format, text, choices: [String], sources: [SourceResponseDTO], myAnswer: MyAnswerResponseDTO? }`
- `SourceResponseDTO{ file, startLine, endLine, symbol, summary?, url }`
- `MyAnswerResponseDTO{ selectedIndex: Int?; text: String?; correct: Bool?; answeredAt: Date }`(ISO-8601, research.md 결정 5)
- `BookmarkedQuestionResponseDTO`는 `projectId`/`setId`/`questionId`를 모두 보존한다(FR-007 계열).

### 오류: `DataLearningProjectError`

공통(`invalidRequest`, `unauthorized`, `temporarilyUnavailable`, `transport`, `decoding`,
`unexpectedStatus`) + 도메인 전용(`projectUnavailable`, `questionUnavailable`,
`learningSetUnavailable`, `generationRetryUnavailable`).

## `DataMember` target(신규)

### 계약: `MemberRemote`

`fetchProfile`, `registerDeviceInfo`, `curateMember`, `updatePosition`,
`updateCareerLevel`, `withdrawMember`.

### DTO (operation → 주요 타입)

| Operation | Request | Response |
|---|---|---|
| MEMBER-01 | — | `MemberProfileResponseDTO{ name, email, position, careerLevel, thisWeekSolvedCount, thisMonthSolvedCount, streakDays, weeklyChart: [WeeklyChartItemDTO] }`(순서 보존, FR-009) |
| MEMBER-02 | `DeviceInfoRequestDTO{ deviceId, deviceType, appVersion, osVersion, deviceToken?: String }` — iOS는 `deviceType = "ios"` 고정 | Unit |
| MEMBER-03 | `CurationRequestDTO{ position: PositionDTO; careerLevel: CareerLevelDTO }` | Unit |
| MEMBER-04 | `PositionRequestDTO{ position: PositionDTO }` | Unit |
| MEMBER-05 | `CareerLevelRequestDTO{ careerLevel: CareerLevelDTO }` | Unit |
| MEMBER-06 | — | Unit(hard delete 의미 보존) |

### 오류: `DataMemberError`

공통(`invalidRequest`, `unauthorized`, `temporarilyUnavailable`, `transport`, `decoding`,
`unexpectedStatus`) + 도메인 전용(`memberUnavailable`).

## 상태 전이

이 기능은 저장 상태를 소유하지 않는 순수 요청/응답 계약이므로 별도 상태 전이 다이어그램은
없다. `QuizGenerationStatusResponseDTO.status`는 서버가 소유한 raw String이며 Data
계층은 이를 상태 머신으로 모델링하지 않는다(참조 문서 8절 PROJECT-05, spec.md FR-011).
