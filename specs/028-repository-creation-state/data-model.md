# 데이터 모델: 레포지토리 생성 상태관리 Repository

## RepositoryCreationState (신규, Domain 모델)

생성 요청이 진행 중인 GitHub 레포지토리 하나를 나타내는 값 타입.

| 필드 | 타입 | 설명 |
|---|---|---|
| `normalizedGithubRepoURL` | `String` | 트림·소문자 변환·끝 슬래시 제거로 정규화한 식별자. 생성 시작 시점부터 존재. |
| `projectID` | `String?` | 서버 등록 응답(`ProjectRegistrationReceipt.projectID`)을 받은 뒤 채워짐. 등록 완료 전에는 `nil`. |
| `recordedAt` | `Date` | 상태가 기록된 시각. 15분(900초) lazy expiry 판정 기준. |

**불변식**:
- `normalizedGithubRepoURL`은 컬렉션 내에서 유일하다(동일 정규화 URL로 두 번째 레코드를 만들지
  않는다 — FR-003이 이를 사전에 차단).
- `recordedAt`으로부터 900초가 지난 레코드는 다음 조회·기록 시점에 존재하지 않는 것으로
  취급한다(결정 4 참고).

**상태 전이**:

```text
(없음) --beginCreation(githubRepoURL)--> 생성 중(projectID=nil)
생성 중(projectID=nil) --register 성공, attachProjectID--> 생성 중(projectID=X)
생성 중(projectID=nil) --register 실패--> (없음, 즉시 해제)
생성 중(projectID=X) --GenerationOutcome(projectID=X, .completed|.failed)--> (없음)
생성 중(*) --900초 경과 후 다음 조회--> (없음, lazy expiry)
```

## LearningProjectError (기존 Domain 모델, 확장)

위치: `sources/Projects/Domain/LearningProject/Errors/LearningProjectError.swift`
(`Models/LearningProject/`가 아니라 별도 `Errors/` 형태 폴더에 있다).

새 case 추가:

| Case | 의미 |
|---|---|
| `duplicateCreationInProgress` | 동일 정규화 `githubRepoURL`에 대한 생성 요청이 이미 "생성 중" 상태일 때 `CreateLearningProject`가 던진다. |

기존 case(`invalidRequest`, `unauthorized`, `notFound`, `learningSetUnavailable`,
`questionUnavailable`, `temporarilyUnavailable`, `unexpected`)는 변경하지 않는다.
`CaseIterable` 준수이므로 이 enum을 `switch`하는 기존 호출부(예:
`LearningProjectRepositoryAdapter.domainError(for:)`가 아니라 이 오류를 직접 소비하는 Feature
계층 코드)는 새 case를 처리하도록 exhaustive switch가 컴파일 시점에 강제된다 — 회귀 방지
효과가 있다.

## 기존 모델과의 관계 (변경 없음, 참고용)

- `ProjectRegistrationReceipt.projectID` → `RepositoryCreationState.projectID`로 연결.
- `LearningProjectSummary.projectID` → `FetchLearningProjects`가 활성 `RepositoryCreationState`의
  `projectID` 집합과 대조해 필터링.
- `GenerationOutcome.projectID` + `.status` → 상태 해제 트리거.
