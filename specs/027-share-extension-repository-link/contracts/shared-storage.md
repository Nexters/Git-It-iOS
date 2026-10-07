# 계약: 본 앱과 Extension이 공유하는 저장소

**대상 명세**: [spec.md](../spec.md) · **데이터 모델**: [data-model.md](../data-model.md)

두 프로세스가 함께 읽고 쓰는 경계다. 값의 형식이나 식별자가 바뀌면 두 target을 함께 바꿔야
하므로 불가분한 통합 단위로 다룬다.

## 1. Keychain access group

| 항목 | 값 |
|---|---|
| access group | `$(AppIdentifierPrefix)com.nexters.hytime.gitit.shared` |
| 접근성 | `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` |
| 항목 클래스 | `kSecClassGenericPassword` |
| service | `com.nexters.hytime.gitit.session` (`SessionKeychainLayout.namespace`) |
| account | `sessionRecord` (`SessionKeychainLayout.Key`) |

- 두 target의 entitlements에 같은 access group을 선언한다.
- 접근성은 기기 최초 잠금 해제 이후로 완화하되 `ThisDeviceOnly`를 유지해 백업·기기 이전으로
  토큰이 새어 나가지 않게 한다(FR-010).
- Extension은 읽기만 수행한다. 쓰기·삭제는 본 앱만 수행한다(FR-007).

**이전 절차(본 앱, 1회성)**

1. 공유 access group에서 항목을 읽는다. 있으면 이전이 끝난 것으로 보고 종료한다.
2. 없으면 access group 없는 기존 항목을 읽는다.
3. 읽었으면 공유 access group에 저장한 뒤 기존 항목을 삭제한다.
4. 어느 쪽에도 없으면 로그아웃 상태로 보고 아무것도 쓰지 않는다.
5. 어느 단계에서 실패해도 기존 항목을 삭제하지 않으며 사용자를 로그아웃시키지 않는다(FR-011).

## 2. App Group

| 항목 | 값 |
|---|---|
| App Group 식별자 | `group.com.nexters.hytime.gitit` |
| UserDefaults suite | 같은 식별자 |

### 2.1 세션 상태 마커

| 키 | `com.nexters.hytime.gitit.sharedSession.stateMarker` |
|---|---|
| 형식 | JSON 인코딩된 `{ "schemaVersion": Int, "isSignedIn": Bool, "updatedAt": Date }` |
| 쓰기 | 본 앱 전용 |
| 읽기 | Extension |

- `schemaVersion`은 `1`에서 시작한다. Extension이 모르는 버전을 만나면 값이 없는 것과 같이
  `appLaunchRequired`로 판정한다.
- 값에 토큰·계정 식별자·개인정보를 넣지 않는다.

### 2.2 리마인더 대기 목록

| 키 | `com.nexters.hytime.gitit.sharedSession.pendingGenerationReminders` |
|---|---|
| 형식 | JSON 인코딩된 `[{ "projectID": String, "requestedAt": Date }]` |
| 쓰기 | Extension이 추가, 본 앱이 흡수 후 제거 |
| 읽기 | 본 앱 |

- 같은 `projectID`가 이미 있으면 추가하지 않는다.
- 본 앱은 흡수한 항목을 제거하고, 흡수 실패 시 목록을 그대로 둔다.
- 목록 길이 상한은 32로 두고, 초과분은 오래된 항목부터 버린다. 초과는 사용자에게 보고하지
  않는다(FR-016c).

## 3. 계약 위반 시 동작

| 상황 | 동작 |
|---|---|
| Keychain 읽기 실패 | `signInRequired`로 판정하고 사유를 진단 로그에 남긴다 |
| 마커 디코딩 실패 | `appLaunchRequired`로 판정한다 |
| 대기 목록 디코딩 실패 | 본 앱이 목록을 비우고 진단 로그에 남긴다. 등록 결과에는 영향이 없다 |
