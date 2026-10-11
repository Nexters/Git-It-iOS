# 데이터 모델: 등록 흐름·홈 화면 UX 결함 해소

**입력**: [spec.md](./spec.md), [research.md](./research.md) | **날짜**: 2026-09-01

명세의 핵심 엔터티를 패키지별 타입으로 옮긴 정의다. 필드와 규칙은 요구사항에서 직접
도출했으며, 소유 패키지는 [아키텍처 문서 3.1](../../docs/architecture.md)의 의존성 표를 따른다.

## 1. GenerationProgress (Domain)

**경로**: `sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationProgress.swift`

진행 중인 학습 세트 생성 1건을 나타내는 단일 슬롯 값이다(명세 「핵심 엔터티」).

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `projectID` | `String` | 생성 대상 프로젝트 식별자. 도착한 생성 결과와 대조하는 키 |
| `requestedAt` | `Date` | 생성 요청을 제출한 시각. 최소 대기 시간 계산의 기준 |

**규칙**

- 동시에 최대 1건만 존재한다(FR-007).
- `requestedAt`은 생성 요청 제출 시점에 확정되며 이후 변하지 않는다(FR-005).
- `Equatable`, `Sendable`, `Codable`을 채택해 상태 비교와 저장을 지원한다.

**상태 전이**

```text
없음 ──(요청 제출)──▶ 진행 중(projectID, requestedAt)
진행 중 ──(readyDate 도달 AND 결과 도착)──▶ 없음
진행 중 ──(복원된 projectID가 학습 프로젝트 목록에 존재)──▶ 없음
진행 중 ──(retentionLimit 초과)──▶ 없음
```

두 번째 전이는 복원 경로의 1차 해소 수단, 세 번째는 결과가 끝내 도착하지 않는 경우의
절대 상한이다(R-008).

## 2. GenerationWaitPolicy (Domain)

**경로**: `sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationWaitPolicy.swift`

최소 대기 시간 규칙을 한 곳에서 소유한다. Feature(진행 화면 전이)와 Composition(알림 예약)이
같은 값을 참조해 SC-009를 보장한다(R-005).

| 멤버 | 타입 | 값·설명 |
| --- | --- | --- |
| `minimumWait` | `TimeInterval` | `300`. 진행 화면 안내 문구와 같은 고정값(FR-011) |
| `retentionLimit` | `TimeInterval` | 보존된 진행 상태의 절대 상한. 이 시간을 넘긴 상태는 결과와 무관하게 해제 |
| `readyDate(for:)` | `(GenerationProgress) -> Date` | `requestedAt + minimumWait` |
| `isExpired(_:now:)` | `(GenerationProgress, Date) -> Bool` | `now - requestedAt > retentionLimit` |

**규칙**

- 진행 화면 전이·완료 알림 발송·홈 표시 해제는 모두 `max(readyDate, 결과 도착 시각)`을
  기준으로 한다(FR-008, FR-010, FR-013).
- `retentionLimit`의 구체 값은 `tasks.md` 작성 시 확정한다. 명세는 상태가 영구히 남지 않아야
  한다는 제약만 요구한다.

## 3. GenerationProgressRepository (Domain 계약)

**경로**: `sources/Projects/Domain/LearningProject/Contracts/GenerationProgressRepository.swift`

```text
load()  -> GenerationProgress?
save(_: GenerationProgress)
clear()
```

기존 `GenerationOutcomeRepository`, `GenerationReminderRegistry`와 같은 위치·형태를 따른다.

## 4. GenerationProgressDTO / GenerationProgressStore (Data)

**경로**

- `sources/Projects/Data/LearningProject/DTOs/GenerationProgressDTO.swift`
- `sources/Projects/Data/LearningProject/Contracts/GenerationProgressStore.swift`
- `sources/Projects/Data/LearningProject/Stores/LocalGenerationProgressStore.swift`

| 필드 | 타입 |
| --- | --- |
| `projectID` | `String` |
| `requestedAt` | `Date` |

**규칙**

- Data는 Domain에 의존할 수 없으므로 자체 계약과 DTO를 소유하고, Composition 어댑터가 Domain
  계약으로 잇는다(R-008). `LegalConsent`의
  `PolicyConsentStore` ↔ `LocalPolicyConsentStore` 구조와 동일하다.
- 저장은 `InfrastructureStorage.UserDefaultsStore<GenerationProgressDTO>`를 사용하며 단일 키에
  1건만 보관한다.

## 5. SharedRepositoryLink (App)

**경로**: `sources/Projects/App/GitIt/Models/SharedRepositoryLink.swift`

공유 시트로 전달받은 URL 1건이다.

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `url` | `String` | 공유된 원문 URL. 검증 전 값이며 그대로 링크 입력 초기값이 된다 |

**규칙**

- App Group 컨테이너에서 읽는 즉시 컨테이너에서 삭제하고, 이후 수명은 앱 실행 중 메모리로만
  유지한다(FR-026, R-011).
- 링크 입력 화면의 초기 입력값으로 1회 소비되며, 그 소비가 "다음" 1회 자동 실행을 함께
  유발한다(FR-025a). 소비되지 못하는 조건(생성 진행 중)에서는 보관하지 않고 버린다(FR-027).
- 검증 전 외부 입력이므로 기존 링크 검증 경로에 그대로 넘기고, 검증 전에는 어떤 요청에도
  사용하지 않는다(R-010).
- 공유 항목에 URL이 여러 개면 확장이 **형식과 무관하게** 첫 번째만 기록한다. 확장은 저장소
  링크 여부를 판정하지 않는다(FR-028, FR-029, R-014).

## 6. 기존 타입 확장

명세를 충족하기 위해 값이 추가되는 기존 타입이다. 새 타입이 아니므로 필드 변화만 기록한다.

| 타입 | 패키지 | 변화 |
| --- | --- | --- |
| `HomeFeature.State` | Feature | 진행 중 여부를 담는 값 추가. 홈 불러오기 패널 표시와 조작 가능 여부를 결정(FR-005~007) |
| `HomeFeature.Action.Input` | Feature | 진행 상태 변화 수신 case 추가. 기존 `learningProjectsReloadRequested`와 같은 외부 조정 경로 |
| `ProjectRegistrationFeature.Action.View` | Feature | 화면 lifecycle case `task` 추가. 자동 실행 표식을 소비하는 유일한 지점(FR-025a, R-013) |
| `ProjectRegistrationFeature.State` | Feature | 링크 입력 초기값 주입 지점, 초기값과 함께 세워지고 View lifecycle에서 1회 소비되는 자동 실행 표식, 도착했으나 아직 노출하지 않은 생성 결과 보관 값 추가(FR-013, FR-025, FR-025a) |
| `AppRootFeature.State` | App | 진행 상태와 공유 링크 보관. 등록 흐름이 닫힌 뒤에도 수명을 유지(R-009) |
| `LocalNotificationRequest` | Infrastructure | 변경 없음. 예약 발송은 별도 API 인자로 시각을 받는다(R-007) |
