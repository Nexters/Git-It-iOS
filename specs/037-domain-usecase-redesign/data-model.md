# 데이터 모델: 관심사별 Domain UseCase

선언 모양은 [contracts/domain-api.md](./contracts/domain-api.md), 결정 근거는
[재설계 문서](../../docs/review/domain-usecase-redesign.md)와 [research.md](./research.md)입니다. 이 문서는 동작 규칙,
상태 전이, 현재 타입과의 대응만 정의합니다.

## 1. Account

### 로그인 상태

```
           restoreSignIn: signedIn          signOut / withdraw / 무효화
 unknown ──────────────────────────▶ signedIn ─────────────────────────▶ signedOut
    │         signIn 성공 ▲                                                  │
    │                     └──────────────────── signIn 성공 ──────────────────┘
    └── restoreSignIn: signedOut ──▶ signedOut
        restoreSignIn: temporarilyUnavailable ──▶ unknown 유지
```

- `signInStates()`는 구독 즉시 현재 상태를 보내고, 이후 변경마다 방출한다. 같은 상태로의 전이도 방출한다(로그아웃 정리 신호).
- `signInInvalidations` 관찰은 첫 공개 동작 호출 시 한 번 시작한다.

### 동작 규칙

| 동작 | 규칙 | 현재 구현 |
| --- | --- | --- |
| `signIn(with:)` | `authenticate` 취소 → `.cancelled`, 그 외 실패 → `.retryableFailure`. `start` 실패 → `clearAuthentication()`(오류 무시) 후 `.retryableFailure`. 성공 → 상태 `signedIn(id)` | `SignIn` |
| `signOut()` | `signInRepository.signOut()` 실패 → `.retryableFailure`. `clearAuthentication()` 실패 → `.retryableFailure`. 성공 → 상태 `signedOut` | `SignOut` |
| `restoreSignIn()` | `restore()`가 `nil` → `clearAuthentication()` 후 `signedOut`. `unauthorized` → 무효 정리 후 `signedOut`. 일시 실패 → `temporarilyUnavailable`. 계정 사용 불가(`isAccountAvailable == false`) → 무효 정리. `authorizationStatus()`가 `valid` → `signedIn`, `reauthenticationRequired` → 무효 정리, 일시 실패·오류 → `temporarilyUnavailable` | `RestoreSession` |
| `verifySignIn()` | `authorizationStatus()` 오류 → `.temporarilyUnavailable`. `reauthenticationRequired` → 무효 정리 후 반환 | `VerifyAuthorization` |
| `signInAvailability()` | `sharedSignInState()` `nil` → `appLaunchRequired`, `false` → `signInRequired`, `hasUsableCredential()` `false` → `signInRequired`, 그 외 `signedIn` | `ResolveSessionAvailability` |
| 무효 정리(내부) | `signInRepository.signOut()`·`clearAuthentication()`(오류 무시) → 상태 `signedOut` | 세 UseCase의 `clearInvalidSession` |
| 무효 신호 수신(내부) | 무효 정리와 동일 | 없음 (결정 20) |
| `policyConsentStatus()` | `documents = policyDocuments`, `consents = repository.consents()`, `isSatisfied` = 필수 문서마다 같은 `id`·`version` 동의 존재 | `PolicyConsent` + `PolicyConsentRecord.isConsentValid` |
| `consent(to:)` | 인자 ID와 일치하는 문서마다 `PolicyConsent(documentID, version, consentedAt: now())`를 만들어 `record(_:)` | `saveConsentRecords` 호출부(LegalAgreementFeature) |
| `withdraw()` | `withdrawalRepository.withdraw()` 실패 → 오류 전파. 성공 → `policyConsentRepository.removeAll()`(오류 무시) → 무효 정리 | `DeleteMemberAccount` + `clearConsentRecords` |

## 2. UserInfo

- `profile` 조회 결과를 캐시하지 않는다. 동시에 진행 중인 조회는 한 작업을 공유한다.
- `detail()` = `profile().detail`, `curation()` = `profile().curation`.
- `updateCuration`·`updatePosition`·`updateCareerLevel`은 하나의 직렬화 키로 순서대로 처리한다(현재 `MemberAccount`의 키별
  직렬화를 단일 키로 합침, 점검표 A-3).

현재 타입 대응: `MemberProfile(name, email, position?, careerLevel?, statistics)` → `UserProfile(detail: UserDetail(name, email,
statistics), curation: position과 careerLevel이 모두 있으면 Curation)`. `MemberError` → `UserInfoError`(같은 case).

## 3. AppSetting

| 동작 | 규칙 |
| --- | --- |
| `notificationAuthorization()` | `NotificationAuthorization.status()` 그대로 |
| `requestNotificationAuthorization()` | `NotificationAuthorization.requestAuthorization()` 그대로 |
| `registerDevice()` | `deviceToken()`을 호출해(실패 시 오류 전파, 현재 동작) `DeviceRegistration(deviceID: currentDeviceID(), platform: .ios, appVersion, osVersion, token)`을 `register` |
| `updateDeviceToken(_:)` | 인자 토큰으로 같은 등록 정보를 구성해 `register` |

현재 타입 대응: `MemberDeviceInfo` → `DeviceRegistration`, `MemberRepository.registerDevice` → `DeviceRegistrationRepository.register`,
`NotificationAuthorizationOutcome` → `NotificationAuthorizationStatus`(요청 결과 `declined`·`previouslyDenied` → `denied`).

## 4. ExternalRepository

`locator.location(from:)`이 `nil`이면 `ExternalRepositoryError.invalidURLFormat`, 아니면 `lookup.repository(owner:name:)`.
현재 `FetchExternalRepository`와 같다.

## 5. QuizDetail

| 동작 | 규칙 | 현재 구현 |
| --- | --- | --- |
| `quizSet(_:in:)` | 저장소 위임 | `LearningLibrary.learningSet` |
| `grade(_: ChoiceAnswer)` | `selectedIndex < 0` → 요청 없이 `invalidAnswer` | `SubmitChoiceAnswer` |
| `grade(_: EssayAnswer)` | 앞뒤 공백 제거 후 비었거나 2000자 초과 → 요청 없이 `invalidAnswer`. 제거한 텍스트로 제출 | `SubmitEssayAnswer` |
| `bookmark`·`unbookmark` | `quizID` 키로 직렬화 후 `setBookmark(isBookmarked: true/false)` | `SetQuestionBookmark` |
| `bookmarks(_:)` | 저장소 위임 | `LearningLibrary.bookmarkedQuestions` |

현재 타입 대응: `Question(format, choices?, myAnswer?)` → `Quiz(content:)` — `multipleChoice`면
`.choice(options: choices ?? [], submitted: myAnswer에 selectedIndex·correct가 모두 있으면 ChoiceSubmission)`, `essay`면
`.essay(submitted: myAnswer.text가 있으면 EssaySubmission)`. `LearningProjectError.invalidRequest` → `invalidAnswer`,
`learningSetUnavailable` → `quizSetUnavailable`, `questionUnavailable` → `quizUnavailable`.

## 6. Project

### 보관 상태

`loaded: [ProjectSummary]`(서버 순서), `nextPageIndex: Int`, `hasNextPage: Bool`, `isLoaded: Bool`,
`excludedIDs: Set<ProjectID>`, 진행 중 로드 작업, 구독자 목록.

방출 값 = `ProjectList(summaries: loaded.filter { !excludedIDs.contains($0.id) }, hasNextPage, isLoaded)`.

### 규칙

| 사건 | 처리 |
| --- | --- |
| `projects()` 구독 | 현재 값 방출. 첫 구독이고 로드된 적이 없으면 첫 페이지 로드 시작(오류는 삼킴, `isLoaded` 유지) |
| `refresh()` | 진행 중 첫 페이지 로드가 있으면 그 결과를 기다려 오류를 던진다. 아니면 `page(0, size)` → 성공 시 `loaded` 교체, `nextPageIndex = 1`, `isLoaded = true`, 방출. 실패 시 오류 전파, 상태 유지 |
| `requestNextPage()` | `hasNextPage == false`이면 아무것도 하지 않음. `page(nextPageIndex, size)` → 이어 붙이고(같은 ID 중복 제거) 인덱스 증가, 방출 |
| `detail(of:)` | 저장소 위임 |
| `delete(_:)` | 저장소 성공 후 `loaded`에서 제거, 방출 |
| 제외 집합 수신 | `excludedIDs` 교체, 방출. 이전 집합에만 있던 ID가 있고 `isLoaded`이면 `refresh()`(오류 무시) |
| 로그아웃 신호 | `loaded = []`, `nextPageIndex = 0`, `hasNextPage = false`, `isLoaded = false`, 방출 |

주입 클로저 관찰은 첫 공개 동작 호출 시 한 번 시작한다.

현재 타입 대응: `LearningProjectSummary(currentSetLabel, currentSetTitle, nextSetID?, nextQuestionID?, overallProgressPercent)` →
`ProjectSummary(currentSet: ProjectSetLabel, next: nextSetID가 있으면 ProjectNextQuiz(setID, quizID: nextQuestionID), progressPercent)`.
`LearningProjectPage(items, hasNext)` → `ProjectPage`. `LearningProjectDetail` → `ProjectDetail`, `problemCount` → `quizCount`.

## 7. ProjectGeneration

### 단계 계산

`readyAt = record.requestedAt + waitPolicy.minimumWait`

| 기록 상태 | 조건 | 단계 |
| --- | --- | --- |
| `inProgress` | — | `inProgress(readyAt)` |
| `completed` | `now < readyAt` | `preparing(readyAt)` |
| `completed` | `now >= readyAt` | `ready` |
| `failed` | — | `failed` |

`preparingProjectIDs` = 단계가 `inProgress`·`preparing`이고 `projectID`가 있는 기록의 ID 집합.

### 규칙

| 사건 | 처리 |
| --- | --- |
| `request(_:)` | `beginGeneration(repositoryURL, now)` 거부 → `duplicateRequest`. `repository.register` 실패 → `releaseGeneration(repositoryURL:)` 후 오류 전파. 성공 → `attachProjectID` → `enqueueReminder(projectID)` → 영수증 반환. 상태 관찰을 시작하지 않는다 |
| `states()` 구독 | 관찰 시작(한 번): 보관 기한이 지난 기록 제거 → 대기열 흡수 → 결과 수신 구독 → 로그아웃 신호 구독 → 기록 변경 구독. 현재 상태 방출 |
| 결과 수신 | `finishGeneration(projectID, status, now)` |
| 기록 변경 | 대기열 흡수 → 새로 `completed`가 된 등록 대상은 `readyAt`에 완료 알림, 새로 `failed`가 된 등록 대상은 즉시 실패 알림(각각 `isAuthorized()`일 때만, 대상에서 제거) → 상태 방출 → 준비 타이머 재설정 |
| 준비 타이머 | `preparing` 중 가장 이른 `readyAt`까지 `sleep` 후 상태 재방출 |
| 로그아웃 신호 | `releaseAll()`, 등록 대상 비움, 방출 |

알림 식별자: 완료 `generation-completed-<projectID>`(현재와 동일), 실패 `generation-failed-<projectID>`.

현재 타입 대응: `CreateLearningProject` + `TrackGeneration` + `ScheduleGenerationReminder` + `RequestGenerationReminder(projectID:)` +
`AppRootFeature.releaseGeneration` 타이머·만료 판정 + `AppComposition.clearLocalStateAfterAccountDeletion`.
`ProjectRegistrationReceipt(projectID, requestStatus, quizLevel)` → `ProjectGenerationReceipt(projectID, quizLevel)`.
`GenerationRecord.githubRepoURL` → `repositoryURL`. `LearningProjectError.duplicateCreationInProgress` → `duplicateRequest`.

## 8. 요청 인증 정보 (Data)

| 상태 | `credential()` | 부수효과 |
| --- | --- | --- |
| 저장 기록 없음 또는 읽기 실패 | `.signedOut` | 없음 |
| `accessTokenExpiresAt <= now` | `.signedOut` | 저장 기록 삭제, 무효 신호 1회 |
| 그 외 | `.available(accessToken)` | 없음 |

`credentialRejected()`: 저장 기록이 있으면 삭제하고 무효 신호 1회. 없으면 아무것도 하지 않음.
