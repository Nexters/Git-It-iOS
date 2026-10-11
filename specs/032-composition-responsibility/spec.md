# 기능 명세: Composition에 들어온 정책·저장·기동 책임을 소유 패키지로 되돌리기

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/composition-responsibility`

**브랜치 상태**: `생성`

**생성일**: 2026-09-16

**상태**: 초안

**입력**: 사용자 설명: "docs/review/composition-responsibility-requirements.md 의 요구사항을 기능 명세로 정의한다. 조립 경계인 Composition에 들어와 있는 비즈니스 정책·영속·런타임 제어 흐름을 원래 소유 패키지로 되돌린다. 전제: Domain↔Data 경계 구조는 현행 유지, Adapter 자체는 Composition에 남는다. 근거와 FR-1~FR-8, 수용 기준은 해당 문서를 따른다. 단 FR-2의 RepositoryCreationStateRepositoryAdapter는 명세 030에서 이미 GenerationStateRepositoryAdapter로 대체되어 사라졌으므로 현재 상태를 확인해 범위를 조정한다."

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - 저장 스키마와 직렬화를 Data가 소유한다 (우선순위: P1)

Keychain·UserDefaults의 네임스페이스·키·인코딩 형식을 Composition이 정의하고 있어, 저장
형식을 바꾸려면 조립 코드를 열어야 합니다. 이 정의를 각 도메인의 Data 모듈로 옮겨
Composition은 만들어진 저장 타입을 조립 인자로만 받게 합니다.

**주요 행위자**: 저장 형식을 바꾸는 개발자

**우선순위 이유**: [Composition 패키지 규칙](../../docs/package-rules/composition.md)이 금지한 세
가지 중 저장 정책 위반이 가장 넓게 퍼져 있고(`Codings/` 3개, `Layouts/` 3개, `Migrations/`
1개), 나머지 시나리오가 이 타입들을 참조하므로 먼저 정리해야 뒤가 풀립니다.

**독립 테스트**: `sources/Projects/Composition/Adapter/` 아래에서 `Codings/`, `Layouts/`,
`Migrations/` 폴더가 사라지고, 기존 키로 저장된 값을 이동 후 코드가 그대로 읽는지 확인하는
테스트가 Data 패키지에 존재하는지 본다.

**수용 시나리오**:

1. **전제** 이동 전 코드가 쓴 Keychain 세션 레코드와 UserDefaults 마커가 있다, **실행** 이동
   후 코드로 같은 값을 읽는다, **결과** 저장된 값을 그대로 읽어 로그인 세션이 유지된다.
2. **전제** `SessionKeychainMigration`이 다루던 레거시 저장소에 값이 있다, **실행** 이동 후의
   마이그레이션 경로를 실행한다, **결과** 이동 전과 같은 결과로 값이 옮겨진다.
3. **전제** Composition 프로덕션 코드를 검색한다, **실행** 저장 키·네임스페이스 문자열과
   인코딩 정의를 찾는다, **결과** 어느 것도 Composition에 남아 있지 않다.

---

### 시나리오 2 - 세션 유효성 판정과 기기 등록을 Domain이 소유한다 (우선순위: P2)

access token 만료 판정과 기기 등록 절차가 Composition에 있어 Domain 테스트가 덮지 못합니다.
판정 규칙과 등록 절차를 Domain으로 옮기고, Composition에는 Data 조회와 계약 연결만 남깁니다.

**주요 행위자**: 세션 만료 규칙 또는 기기 등록 항목을 바꾸는 개발자

**우선순위 이유**: 두 정책 모두 판정 결과가 사용자 흐름을 가릅니다(공유 확장에서 로그인 유도,
푸시 수신 가능 여부). 규칙이 Domain에 있어야 규칙 테스트만으로 검증할 수 있습니다.

**독립 테스트**: 만료 시각이 지난 access token과 지나지 않은 token 각각에 대해 Domain
테스트만으로 판정 결과를 검증할 수 있고, 기기 등록이 앱·OS 버전을 주입받아 동작하는지
Domain 테스트로 확인할 수 있다.

**수용 시나리오**:

1. **전제** access token 만료 시각이 현재보다 과거다, **실행** 세션 유효성을 판정한다,
   **결과** 재로그인이 필요하다는 결과가 나오며 그 판정이 Domain 테스트로 검증된다.
2. **전제** 앱 버전과 OS 버전을 주입한다, **실행** 기기 등록을 수행한다, **결과** 주입한 값이
   등록 정보에 담기고, Composition 코드가 `Bundle.main`이나 `ProcessInfo`를 읽지 않는다.

---

### 시나리오 3 - 리마인드 정책과 알림 문구를 소유 위치로 되돌린다 (우선순위: P2)

`GenerationCompletionReminderCoordinator`가 등록 대상 집합, 완료 판정, 예약 시각 계산, 알림
권한 확인과 한국어 알림 문구를 모두 갖고 있습니다. 판정과 계산은 Domain으로, 표시 문구는
사용자에게 보이는 문자열을 소유하는 위치로 옮깁니다.

**주요 행위자**: 리마인드 조건이나 알림 문구를 바꾸는 개발자

**우선순위 이유**: 조립 객체가 아니라 앱 수명 내내 사는 정책 객체이며, 알림 문구가 조립
계층에 하드코딩되어 있어 문구 변경이 조립 코드 변경으로 잡힙니다.

**독립 테스트**: 완료·미완료 생성 결과와 알림 권한 유무 조합에 대해 Domain 테스트만으로
예약 여부와 예약 시각을 검증할 수 있고, Composition 프로덕션 코드에 사용자에게 표시되는
문자열 리터럴이 없는지 검색으로 확인한다.

**수용 시나리오**:

1. **전제** 등록된 프로젝트의 생성이 완료되고 알림 권한이 있다, **실행** 결과를 처리한다,
   **결과** 대기 정책이 계산한 시각에 예약이 요청되며 그 판정이 Domain 테스트로 검증된다.
2. **전제** 알림 권한이 없다, **실행** 완료 결과를 처리한다, **결과** 예약을 요청하지 않는다.
3. **전제** Composition 프로덕션 코드를 검색한다, **실행** 사용자에게 표시되는 문자열
   리터럴을 찾는다, **결과** 하나도 없다. 개발자용 로그 메시지는 이 기준의 대상이 아니다.

---

### 시나리오 4 - 기동 순서와 외부 라이브러리 선택을 Composition 밖으로 옮긴다 (우선순위: P3)

`AppComposition.bootstrap`이 마커 저장 → 푸시 클라이언트 활성화 → AppDelegate 구성 → 관측
시작을 정해진 순서로 실행하고, `FirebaseMessagingPushClient`를 직접 생성합니다. 순서 있는
기동 절차는 App이, 구현 선택은 Infrastructure가 소유합니다.

**주요 행위자**: 앱 기동 절차를 바꾸거나 푸시 구현을 교체하는 개발자

**우선순위 이유**: 앞 시나리오에서 조각이 정리된 뒤 수행해야 옮길 대상이 확정됩니다. 단독
가치는 있으나 선행 정리에 의존하므로 뒤에 둡니다.

**독립 테스트**: `AppComposition`에 순서 의존적인 기동 절차를 실행하는 클로저가 없고,
Composition 프로덕션 코드에 외부 라이브러리 타입 이름이 없는지 검색으로 확인한다.

**수용 시나리오**:

1. **전제** 앱을 기동한다, **실행** 기동 절차를 수행한다, **결과** 이동 전과 같은 순서로 같은
   작업이 수행된다.
2. **전제** Composition 프로덕션 코드를 검색한다, **실행** `Firebase`로 시작하는 타입 이름을
   찾는다, **결과** 하나도 없다.

---

### 예외·경계 사례

- 저장 타입을 옮기는 과정에서 키 문자열이 한 글자라도 바뀌면 기존 사용자의 로그인 세션이
  끊긴다. 이동 전후 같은 키로 읽고 쓰는지 확인하는 테스트가 없으면 이동을 완료로 보지 않는다.
- App Group 접근 그룹을 쓰는 Keychain 저장소와 쓰지 않는 레거시 저장소가 함께 있다. 이동 후
  두 경로가 모두 살아 있어야 마이그레이션이 깨지지 않는다.
- 푸시 클라이언트가 아직 활성화되지 않은 상태에서 기기 등록을 호출하면 현재는 전용 오류를
  던진다. 기동 절차를 옮긴 뒤에도 같은 조건에서 같은 오류가 나야 한다.
- `SessionAvailability`는 App의 공유 확장이 사용한다. 소유 패키지를 옮길 때 App이 참조할 수
  있는 패키지에 두어야 하며, 그렇지 않으면 아키텍처 3.1의 의존 방향을 어긴다.
- 공유 확장(ShareExtension)은 앱 본체와 다른 프로세스다. 기동 절차를 App으로 옮길 때 공유
  확장 쪽 조립이 앱 본체의 기동에 의존하게 되어서는 안 된다.

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: `Adapter/Codings/`의 3개 파일(`SessionRecordKeychainCoding`,
  `PendingGenerationReminderCoding`, `SharedSessionStateMarkerCoding`), `Adapter/Layouts/`의 3개
  파일(`SessionKeychainLayout`, `AppleIdentityKeychainLayout`, `SharedSessionLayout`),
  `Adapter/Migrations/SessionKeychainMigration.swift`를 해당 도메인의 Data 모듈로 옮겨야 한다.
- **FR-002**: 이동 후 Composition은 저장 키·네임스페이스·인코딩 형식을 정의하지 않아야 하며,
  이동한 타입을 조립 인자로만 사용해야 한다.
- **FR-003**: 이동 전후로 같은 Keychain 키와 UserDefaults 네임스페이스를 사용해 기존에 저장된
  값을 읽을 수 있어야 하고, 이를 확인하는 테스트가 소유 패키지에 있어야 한다.
- **FR-004**: access token 만료 판정과 `signInRequired` / `appLaunchRequired` / `available`
  분기를 Domain으로 옮기고, `SessionAvailability` 타입의 소유 패키지를 App이 참조할 수 있는
  곳으로 결정해야 한다. Composition에는 저장소 조회와 계약 연결만 남는다.
- **FR-005**: deviceID 발급·보관 계약을 Domain에 정의하고 구현은 Data에 두며,
  `MemberDeviceInfo` 구성과 등록 호출을 Domain UseCase로 옮겨야 한다. 앱 버전·OS 버전은
  주입받아야 하며 Composition이 `Bundle.main`이나 `ProcessInfo`를 직접 읽지 않아야 한다.
- **FR-006**: 리마인드 등록 대상 집합 관리, 완료 판정, 예약 시각 계산을 Domain으로 옮기고,
  Composition에는 Domain 계약을 `InfrastructureLocalNotification`에 잇는 Adapter만 남겨야 한다.
- **FR-007**: 사용자에게 표시되는 문자열은 Composition에 두지 않아야 한다. 알림 제목·본문의
  소유 위치를 결정하고 그에 따라 배치한다. 개발자용 로그 메시지는 이 요구사항의 대상이 아니다.
- **FR-008**: `AppComposition`이 `FirebaseMessagingPushClient`를 직접 생성하지 않아야 하며,
  푸시 클라이언트 구현 선택은 Infrastructure가 제공하는 진입점을 통해 수행해야 한다.
  Composition 프로덕션 코드에 외부 라이브러리 타입 이름이 등장하지 않아야 한다.
- **FR-009**: `AppComposition.bootstrap`이 수행하는 순서 있는 기동 절차와
  `PushNotificationAppDelegate` 구성을 App이 소유하는 타입으로 옮겨야 한다. Composition은
  기동에 필요한 개별 조각만 제공하고 실행 순서를 결정하지 않는다.
- **FR-010**: 로컬에 보관하는 상태는 예외 없이 `Domain 계약 → Composition Adapter → Data
  store → Infrastructure 저장 API` 경로를 따라야 하며, Composition 프로덕션 코드가
  Infrastructure 저장 API를 직접 생성하거나 호출하는 지점이 없어야 한다.
- **FR-011**: 이동한 정책 각각에 대해 이동 전 테스트가 보장하던 항목이 이동 후 소유 패키지의
  테스트로 유지되어야 한다.
- **FR-012**: Domain↔Data 경계 구조와 Adapter의 소유 위치는 바꾸지 않는다. Adapter는
  Composition에 남는다.
- **FR-013**: `CompositionAdapter` target 분할, UseCase 개수 통합, 생성 상태 모델 통합은 이
  명세가 다루지 않는다. 각각 별도 명세가 소유한다.

### 핵심 엔터티

- **세션 저장 스키마**: Keychain 네임스페이스·키와 세션 레코드의 인코딩 형식. 값이 바뀌면
  기존 사용자의 로그인이 끊기므로 이동 시 불변이어야 하는 대상.
- **세션 유효성**: 저장된 세션과 현재 시각으로 결정되는 판정 결과. 사용 가능·재로그인 필요·앱
  본체 기동 필요 세 가지.
- **리마인드 정책**: 어떤 프로젝트를 리마인드 대상으로 두고, 어떤 결과를 완료로 보며, 언제
  알림을 예약할지 정하는 규칙.
- **기기 등록 정보**: deviceID, 기기 종류, 앱 버전, OS 버전, 푸시 토큰의 묶음. deviceID는 발급
  후 보관되어 재사용된다.
- **기동 절차**: 앱 기동 시 정해진 순서로 실행되는 작업의 나열.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: `sources/Projects/Composition/` 아래에 `Codings/`, `Layouts/`, `Migrations/`,
  `Resolvers/` 폴더가 없다.
- **SC-002**: Composition 프로덕션 코드에서 `UserDefaults`, `UserDefaultsStore`,
  `KeychainStore`를 생성하거나 읽고 쓰는 지점이 0개다.
- **SC-003**: Composition 프로덕션 코드에서 `Bundle.main`과 `ProcessInfo`를 읽는 지점이 0개다.
- **SC-004**: Composition 프로덕션 코드에 `Firebase`로 시작하는 타입 이름이 0개다.
- **SC-005**: Composition 프로덕션 코드에 사용자에게 표시되는 문자열 리터럴이 0개다.
- **SC-006**: `AppComposition`에 순서 의존적인 기동 절차를 실행하는 클로저가 없다.
- **SC-007**: 이동한 정책마다 이동 전 테스트가 보장하던 항목의 이관처 또는 제거 근거가 1:1로
  기록되어 있고, 이동 대상 정책의 테스트 검증 항목 수가 이동 전보다 줄지 않는다.
- **SC-008**: 적용 후 Composition 프로덕션 코드 줄수가 적용 전(2,348줄)보다 적고, 남은 파일이
  `Adapter/Adapters/`와 조립(`Assemblies/`, `Factories/HTTPClientFactory.swift`)으로만 구성된다.
- **SC-009**: 기존 Keychain·UserDefaults 값으로 로그인 세션이 유지되는지 확인하는 테스트가
  통과한다.
- **SC-010**: 변경 전후로 앱 기동 시 수행되는 작업과 그 순서가 같다.

## 가정

- `RepositoryCreationStateRepositoryAdapter`는 명세 030에서 `GenerationStateRepositoryAdapter`로
  대체되어 이미 사라졌다. 근거 문서 FR-2가 지목한 "UserDefaults 직접 IO + 900초 만료 정책 + URL
  정규화"는 현재 코드에 없으므로 이 명세의 대상이 아니다. 남은 것은 조립 시점에
  `UserDefaultsStore`를 직접 만드는 지점이며 FR-010이 덮는다.
- 근거 문서가 기록한 Composition 프로덕션 2,451줄은 다른 커밋(`bee2388`)의 값이다. 이 명세는
  브랜치 시작 시점에서 다시 센 2,348줄을 기준선으로 삼는다.
- Composition에 남아 있는 한국어 문자열 중 사용자에게 표시되는 것은
  `GenerationCompletionReminderCoordinator`의 알림 제목·본문 2개뿐이며 나머지는 `logger.debug`
  인자다. SC-005는 표시 문자열만을 대상으로 한다.
- `HTTPClientFactory`는 조립 헬퍼이므로 이동 대상이 아니다.
- 서버 API 스키마와 저장 값의 형식은 바꾸지 않는다. 옮기는 것은 소유 위치뿐이다.
- Feature는 단일 target을 유지한다.
