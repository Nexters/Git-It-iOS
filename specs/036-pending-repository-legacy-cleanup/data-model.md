# 데이터 모델: 생성 대기 상태와 Data 기술 능력 계약

**기능**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

## 1. Domain 모델(변경 없음, 소유 계약만 변경)

### GenerationRecord

`sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationRecord.swift`

| 필드 | 타입 | 규칙 |
|------|------|------|
| `githubRepoURL` | `String` | 생성 시 정규화(공백 제거, 소문자, 끝 `/` 제거) |
| `projectID` | `String?` | 서버 등록 성공 후 연결 |
| `requestedAt` | `Date` | 생성 시작 시각 |
| `status` | `Status` (`inProgress`, `completed`, `failed`) | 기본 `inProgress` |
| `finishedAt` | `Date?` | 완료·실패 전환 시각 |

### GenerationState

| 규칙 | 근거 메서드 |
|------|-------------|
| 같은 정규화 URL의 진행 중 기록은 하나 | `beginning(githubRepoURL:requestedAt:)`가 진행 중이면 `nil` |
| 같은 프로젝트 식별자는 하나의 기록에만 연결 | `attachingProjectID(_:toGithubRepoURL:)` |
| 만료 기록은 조회·시작 전에 제거 | `purgingExpired(now:retentionLimit:)`, `GenerationWaitPolicy.standard.retentionLimit` = 3600초 |
| 생성 중 프로젝트 = 진행 중이며 식별자가 있는 기록 | `activeProjectIDs` |

### 상태 전이

```text
(없음) --beginGeneration--> inProgress(projectID: nil)
inProgress(nil) --attachProjectID--> inProgress(projectID)
inProgress(nil) --releaseGeneration(url) [등록 실패]--> (없음)
inProgress(projectID) --finishGeneration(completed|failed)--> completed|failed (finishedAt 기록)
completed|failed --releaseGeneration(url) [준비 완료 해제·계정 삭제]--> (없음)
모든 상태 --만료(finishedAt ?? requestedAt + 3600초 경과)--> (없음)
```

- 이미 끝난 기록에 대한 `finishGeneration`은 상태를 바꾸지 않는다(`GenerationRecord.finishing`).

### 완료 알림 대기 항목

| 필드 | 타입 | 규칙 |
|------|------|------|
| `projectID` | `String` | 목록 안에서 유일 |
| `requestedAt` | `Date` | 기록 시각 |

- 목록 상한 32. 초과 시 가장 오래 기록된 항목부터 제거한다.
- 흡수(`drainReminderProjectIDs`)는 식별자 목록을 돌려주고 목록을 비운다.
- Domain에는 모델 타입을 추가하지 않는다. 계약 연산이 `String` 식별자만 주고받는다.

## 2. Data 저장 형태

### GenerationStateDTO / GenerationRecordDTO(변경 없음)

| 필드 | JSON 타입 |
|------|-----------|
| `records` | 배열 |
| `records[].githubRepoURL` | string |
| `records[].projectID` | string 또는 null |
| `records[].requestedAt` | `JSONEncoder` 기본 `Date` 인코딩 |
| `records[].status` | `"inProgress"`, `"completed"`, `"failed"` |
| `records[].finishedAt` | `Date` 또는 null |

제거: `LegacyGenerationProgressDTO`, `LegacyRepositoryCreationStateDTO`.

### 완료 알림 대기 항목 DTO

`PendingGenerationReminderCoding`의 `private struct Entry { projectID, requestedAt }`를
`LocalPendingGenerationStore` 내부 타입으로 옮긴다. JSON 필드 이름은 바꾸지 않는다.

## 3. 저장 좌표(변경 금지)

| 값 | 저장 계약 | 위치 | namespace | key | 최종 키 |
|----|-----------|------|-----------|-----|---------|
| 생성 진행 기록 | `KeyValueStorage` | App Group | `com.nexters.hytime.gitit.sharedSession` | `generationState` | `com.nexters.hytime.gitit.sharedSession.generationState` |
| 완료 알림 대기 | `KeyValueStorage` | App Group | 같음 | `pendingGenerationReminders` | `com.nexters.hytime.gitit.sharedSession.pendingGenerationReminders` |
| 공유 로그인 상태 marker | `KeyValueStorage` | App Group | 같음 | `stateMarker` (schemaVersion 1) | `com.nexters.hytime.gitit.sharedSession.stateMarker` |
| 약관 동의 기록 | `KeyValueStorage` | 기기 | `com.nexters.hytime.gitit.legalConsent` | `records` | `com.nexters.hytime.gitit.legalConsent.records` |
| 세션 기록 | `SecureValueStorage` | App Group access group | `com.nexters.hytime.gitit.session` | `sessionRecord` | Keychain service/account 규칙은 Infrastructure `KeychainStore` 그대로 |
| Apple 사용자 식별자 | `SecureValueStorage` | 구현 시 현재 `AuthenticationAssembly` 조립과 대조 | `com.nexters.hytime.gitit.authentication` | `appleUserID` | 같음 |
| 기기 식별자 | `SecureValueStorage` | 구현 시 현재 `MemberAssembly` 조립과 대조 | `com.nexters.hytime.gitit.device` | `deviceID` | 같음 |

- 약관 동의 기록의 현재 위치는 `AuthenticationAssembly.swift:21` `UserDefaultsStore(namespace:)` 기본값(기기
  `.standard`)이다. 구현 시 namespace 값을 코드와 다시 대조한다.
- 세션 제거 이관(`SessionStorageMigration`)이 쓰던 옛 Keychain access group은 더 이상 읽지 않는다.

## 4. Data 기술 능력 계약 엔터티

| 엔터티 | 소유 target | 묶이는 값 | 실제 구현이 감싸는 Infrastructure |
|--------|-------------|-----------|-----------------------------------|
| `KeyValueStorage` | `DataShared` | namespace, 저장 위치 | `UserDefaultsStore`, `AppGroupUserDefaults` |
| `SecureValueStorage` | `DataShared` | namespace, 저장 위치 | `KeychainStore`, `AppGroupKeychainStore` |
| `RequestTransport` | `DataShared` | 없음 | `URLSessionTransport`, `HTTPClient` |
| `LocalReminderNotifier` | `DataNotification` | 없음 | `LocalNotificationAuthorizationClient` |
| `RemoteMessageReceiver` | `DataNotification` | 없음 | `PushMessagingClientFactory`, `PushMessagingClient` |
| `NotificationAppDelegate` | `DataNotification` | 콜백 | `PushMessagingAppDelegate` |

관계:

```text
Composition Assembly ──(주입: 계약 또는 nil)──> Data 생성 진입점 ──> Data 내부 실제 구현 ──> Infrastructure
Composition Adapter ──> Data concrete(Remote·Store·Coding) ──> Data 계약
Domain UseCase ──> Domain 계약(PendingGenerationRepository 등) <── Composition Adapter
```

상세 시그니처는 [contracts/data-capability-contracts.md](./contracts/data-capability-contracts.md)와
[contracts/pending-generation-repository.md](./contracts/pending-generation-repository.md)를 따른다.
