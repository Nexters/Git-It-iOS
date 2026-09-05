# 데이터 모델: 공유 시트에서 GitHub 저장소를 등록하는 Share Extension

**대상 명세**: [spec.md](./spec.md) · **조사**: [research.md](./research.md) · **날짜**: 2026-09-05

이 기능이 새로 도입하거나 경계를 넘겨 전달하는 값만 기록한다. 기존 Domain 모델
(`ExternalRepository`, `QuizLevel`, `ProjectRegistrationReceipt`, `SessionRecord`)은 그대로
사용하며 필드를 바꾸지 않는다.

## 1. SharedRepositoryLink

호스트 앱이 전달한 공유 항목을 로컬 판정한 결과다. 네트워크 조회 전에 확정된다.

| 필드 | 타입 | 설명 |
|---|---|---|
| `originalURL` | `URL` | 호스트 앱이 전달한 원본 URL |
| `owner` | `String` | 저장소 소유자 식별자 |
| `name` | `String` | 저장소 이름 |

**검증 규칙**

- 호스트가 GitHub이어야 한다(FR-003). 자체 호스팅 인스턴스는 대상이 아니다.
- 경로의 첫 두 구성요소가 소유자와 저장소여야 하며, 그 뒤의 하위 경로·쿼리·프래그먼트는
  판정에 영향을 주지 않고 버린다(예외·경계 사례).
- 소유자 또는 저장소 위치에 GitHub의 예약 경로(`search`, `settings`, `topics` 등 저장소가 될 수
  없는 경로)가 오면 판정에 실패한다.
- 판정은 네트워크 호출 없이 수행한다(FR-003). 판정 실패는 URL 오류 상태로 이어진다(FR-004).

**소유**: Domain 계약과 파서는 기존 `GitHubRepositoryURLParser`
(`ExternalRepositoryAssembly`가 조립)를 재사용한다. 새 파서를 만들지 않는다.

## 2. ShareRegistrationState

Extension 단일 화면의 상태다. 화면 간 이동 없이 이 값만 바뀐다(FR-019).

| 상태 | 보유 값 | 허용 동작 |
|---|---|---|
| `validating` | 없음 | 닫기 |
| `registrable` | `ExternalRepository`, 선택된 `QuizLevel` | 난이도 변경, 등록, 닫기 |
| `invalidURL` | 사유 문구 | 닫기 |
| `signInRequired` | 안내 문구 | 닫기 |
| `appLaunchRequired` | 안내 문구 | 닫기 |
| `submitting` | `ExternalRepository`, `QuizLevel` | 없음(동작 차단) |
| `succeeded` | 없음 | 닫기 |
| `failed` | 사유 문구, 재시도 대상 단계 | 재시도, 닫기 |

**상태 전이**

```text
validating ─ 로컬 판정 실패 ─────────────→ invalidURL
validating ─ 마커 없음 ──────────────────→ appLaunchRequired
validating ─ 로그아웃 · 토큰 없음 · 만료 ─→ signInRequired
validating ─ 조회 인증 오류 ─────────────→ signInRequired
validating ─ 조회 기타 실패 ─────────────→ failed(재시도 대상: 조회)
validating ─ 조회 성공 ──────────────────→ registrable
registrable ─ 등록 실행 ─────────────────→ submitting
submitting ─ 성공 ───────────────────────→ succeeded
submitting ─ 인증 오류 ──────────────────→ signInRequired
submitting ─ 기타 실패 ──────────────────→ failed(재시도 대상: 등록)
failed ─ 재시도 ─────────────────────────→ validating 또는 submitting
```

- `submitting`에서는 추가 등록 실행을 받지 않는다(FR-015).
- 사용자가 화면을 닫으면 진행 중인 작업을 취소하고 어떤 상태도 보관하지 않는다(FR-018).
- 기본 선택 난이도는 본 앱과 동일한 `QuizLevel.l1`이다
  (`QuizLevelSelectionFeature.State.init` 기본값, FR-014a).

## 3. SessionAvailability

Extension이 세션 확인 결과로 판정하는 값이다. 화면 상태 결정에만 쓰이며 토큰 자체를 화면으로
전달하지 않는다.

| 값 | 판정 조건 |
|---|---|
| `available(accessToken)` | 마커의 로그인 상태가 true이고 공유 Keychain의 접근 토큰이 유효하다 |
| `signInRequired` | 마커의 로그인 상태가 false이거나, 토큰이 없거나 만료되었다 |
| `appLaunchRequired` | 공유 저장소에 세션 상태 마커가 없다 |

- 만료 판정은 저장된 `accessTokenExpiresAt`을 기준으로 하며, 값이 없으면 유효한 것으로 보고
  서버 인증 오류 응답에 위임한다(FR-009).
- Extension은 어떤 경우에도 갱신 경로를 호출하지 않는다(FR-007, R9).

## 4. SharedSessionStateMarker

본 앱이 쓰고 Extension이 읽는 App Group 값이다. 토큰을 포함하지 않는다.

| 필드 | 타입 | 설명 |
|---|---|---|
| `schemaVersion` | `Int` | 마커 형식 버전. 알 수 없는 값이면 Extension은 `appLaunchRequired`로 판정한다 |
| `isSignedIn` | `Bool` | 본 앱이 마지막으로 관찰한 로그인 여부 |
| `updatedAt` | `Date` | 마지막 기록 시각(진단용) |

**쓰기 시점(본 앱)**: 최초 실행의 세션 복원 직후, 로그인 성공 직후, 로그아웃 직후, 공유
Keychain 이전 완료 직후. **쓰기 주체는 본 앱뿐이며 Extension은 읽기만 한다.**

## 5. PendingGenerationReminder

Extension이 남기고 본 앱의 리마인더 조정자가 흡수하는 대기 항목이다(R5).

| 필드 | 타입 | 설명 |
|---|---|---|
| `projectID` | `String` | 등록 성공 응답의 프로젝트 식별자 |
| `requestedAt` | `Date` | 기록 시각 |

- Extension은 알림 권한이 이미 허용된 경우에만 기록한다(FR-016b).
- 본 앱 조정자는 시작 시 목록 전체를 읽어 등록 대상에 반영하고 읽은 항목을 제거한다.
- 기록 또는 흡수 실패는 등록 성공 표시와 사용자 흐름에 영향을 주지 않는다(FR-016c).
- 이 값은 미완료 등록 요청의 큐가 아니다. 등록은 이미 성공한 상태이며 자동 재실행 대상이
  아니다(FR-018, 범위 밖).

## 6. 저장 위치 요약

| 값 | 저장소 | 쓰기 | 읽기 |
|---|---|---|---|
| `SessionRecord`(토큰) | 공유 Keychain access group | 본 앱 | 본 앱, Extension |
| `SharedSessionStateMarker` | App Group UserDefaults | 본 앱 | Extension |
| `PendingGenerationReminder` | App Group UserDefaults | Extension | 본 앱 |
| `ShareRegistrationState` | Extension 프로세스 메모리 | Extension | Extension |
