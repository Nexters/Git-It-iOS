# 조사: Composition 책임 되돌리기

## 1. Composition이 저장 타입을 "생성"하는 것은 위반인가

**결정**: 위반이 아니다. 금지 대상은 (1) Composition이 저장 **스키마**(네임스페이스·키·인코딩
형식)를 정의하는 것과 (2) Composition이 Infrastructure 저장 API로 값을 직접 **읽고 쓰는**
것이다. Data가 소유한 구체 저장 타입을 실행 환경에 맞게 **골라서 만들어 넘기는** 것은
Composition의 일이다.

**근거**: [아키텍처 3.5](../../docs/architecture.md)가 Composition을 "Data가 Infrastructure 기술
API 위에서 소유하는 concrete 구현을 실행 환경에 맞게 선택해 객체 생성 순서와 수명을 결정"하는
경계로 정의한다. 생성 자체를 금지하면 조립 경계가 할 일이 없어진다. 실제로 문제가 되는 것은
`SharedSessionLayout`이 키 문자열을, `SessionRecordKeychainCoding`이 인코딩 형식을 Composition에
정의해 두어 저장 형식 변경이 조립 코드 변경으로 잡히는 점이다.

**명세와의 차이**: [spec.md](./spec.md)의 SC-002는 "생성하거나 읽고 쓰는 지점이 0개"라고
적었다. 이 계획은 SC-002를 **"Composition이 저장 API로 직접 읽고 쓰는 지점 0개, 저장 스키마를
정의하는 지점 0개"**로 읽는다. 조립 시점의 인스턴스 생성은 남는다. 근거 문서의 수용 기준을
그대로 옮긴 문장이 아키텍처 3.5와 충돌하므로 아키텍처를 우선한다
([CLAUDE.md](../../CLAUDE.md)의 우선순위 2).

**검토한 대안**:

- 조립 인자를 전부 App에서 주입하기 — App은 Infrastructure와 Data에 의존할 수 없다
  (아키텍처 3.1). 주입할 타입을 App이 만들 방법이 없다.
- Data가 자기 저장소를 전역 팩토리로 만들기 — 실행 환경(앱 본체/공유 확장/테스트)별 선택
  지점을 잃는다. 테스트가 격리된 suite를 넣을 수 없다.

## 2. `SharedSessionLayout`을 어디로 옮기는가

**결정**: 둘로 나눈다.

- **App Group 좌표**(`appGroupIdentifier`, `keychainAccessGroup`, 팀 식별자 접두어와 공유
  `UserDefaults`·`KeychainStore` 생성) → `InfrastructureStorage`와
  `InfrastructureAuthentication`
- **도메인 키**(`stateMarkerKey`, `pendingGenerationRemindersKey`, `markerSchemaVersion`,
  `pendingReminderLimit`, 그리고 네임스페이스 문자열) → 그 값을 쓰는 각 Data 모듈

**근거**: App Group 식별자와 Keychain 접근 그룹은 앱이 플랫폼에 등록한 **좌표**이지 도메인
정책이 아니다. Infrastructure는 이미 `KeychainAccessGroup`·`KeychainNamespace`·`UserDefaultsStore`를
소유하므로 같은 어휘에 속한다. 반면 `stateMarkerKey`처럼 무엇을 저장하는지 아는 값은 그
데이터를 소유하는 Data 모듈에 있어야 한다. 이렇게 나누면 `DataAuthentication`과
`DataLearningProject`가 서로 의존하지 않고도 같은 App Group을 공유할 수 있다.

**검토한 대안**:

- 통째로 `DataAuthentication`으로 옮기기 — `DataLearningProject`가 생성 상태 네임스페이스를
  위해 그 값을 필요로 한다. Data → Data 의존이 생겨 아키텍처 3.1을 어긴다.
- 새 `DataSharedSession` 모듈 만들기 — 같은 이유로 Data → Data 의존이 필요하다. 또한 이
  명세는 새 target을 만들지 않는 것을 전제로 한다.
- 각 Data 모듈에 App Group 식별자를 복제하기 — 같은 문자열이 두 곳에 생겨 한쪽만 바뀌면
  공유 저장소가 조용히 갈라진다.

## 3. `SessionAvailability`의 소유 패키지

**결정**: `DomainAuthentication`이 소유한다. 판정 로직도 Domain UseCase로 옮긴다.

**근거**: 공유 확장(`App/ShareExtension/ShareViewController.swift`)이 이 타입을 쓴다. App의
허용 의존은 `{Feature, Composition, Domain}`이므로 Domain이 App이 참조할 수 있는 가장 아래
패키지다. 판정 내용(access token 만료 여부로 재로그인 필요를 결정)이 전송·저장 어휘가 아니라
도메인 규칙이라는 점도 Domain 소유를 뒷받침한다.

**검토한 대안**:

- Composition에 그대로 두기 — 판정 규칙이 Domain 테스트 대상에서 빠진다. 이 명세가 없애려는
  문제 그 자체다.
- Data에 두기 — App이 Data에 의존할 수 없다(아키텍처 3.1).

## 4. 알림 제목·본문을 누가 소유하는가

**결정**: **App**이 문구를 소유하고, 조립 시점에 Composition Adapter로 주입한다. "언제 예약할
것인가"는 Domain UseCase가 결정한다.

**근거**: 저장소에 로컬라이제이션 체계가 없고, 사용자 표시 문자열은 Feature(316개)와 UI(96개)에
직접 들어 있다. 두 패키지는 화면을 소유하는 계층이다. 완료 리마인드는 화면 없이 앱이 사용자에게
직접 내보내는 알림이므로 화면을 갖지 않는 표시 주체, 즉 App이 가장 가깝다. App은 이 명세의
FR-009로 기동 절차도 소유하게 되므로 앱 수준 표현을 한곳에 모을 수 있다. Domain에 두는 선택은
배제한다. Domain에는 현재 한국어 문자열이 0개이며, 표시 문구가 들어오면 Domain 테스트가 문구
변경에 흔들린다.

Composition Adapter는 주입받은 값을 그대로 전달만 하므로 리터럴을 갖지 않는다. SC-005를
충족한다.

**검토한 대안**:

- Feature가 소유 — Feature는 화면 상태와 Effect를 다루는 계층이고, 리마인드 예약은 화면 밖에서
  일어난다. Feature를 거치면 없는 의존이 생긴다.
- UI가 소유 — UI는 컴포넌트 패키지이며 알림은 컴포넌트가 아니다.
- Infrastructure가 소유 — 전송 수단이지 표현의 주체가 아니다.

## 5. 푸시 클라이언트 구현 선택을 어디에 두는가

**결정**: `InfrastructurePushMessaging`이 `PushMessagingClient` 구현을 만드는 진입점을 공개하고,
Composition은 그 진입점만 호출한다. `PushNotificationAppDelegate`가 노출하는
`FirebaseMessagingAppDelegate` 별칭도 Infrastructure가 감싼 타입으로 바꾼다.

**근거**: [아키텍처 4](../../docs/architecture.md)에서 Infrastructure는 "외부 라이브러리를
프로젝트가 소유한 범용 기술 API로 변환"하는 경계다. 구현이 하나뿐이어도 외부 타입 이름이
경계 밖으로 새어 나가지 않게 하는 것이 그 경계의 목적이다.

**검토한 대안**:

- Composition이 계속 직접 생성 — [Composition 패키지 규칙](../../docs/package-rules/composition.md)이
  명시적으로 금지한다.
- App이 생성해 주입 — App이 Infrastructure에 의존해야 한다(아키텍처 3.1 위반).

## 6. 기동 절차를 App의 무엇이 소유하는가

**결정**: App에 기동 절차를 실행하는 타입을 두고, `AppComposition`은 그 절차가 쓰는 조각
(마커 저장 함수, 푸시 클라이언트 활성화 함수, 관측 시작 함수)을 **순서 없이** 공개한다.

**근거**: 순서는 런타임 제어 흐름이고, 제어 흐름의 소유자는 앱 수명 주기를 아는 App이다.
현재 `bootstrap` 클로저는 네 작업의 순서를 Composition에 고정해 두어, 순서를 바꾸려면 조립
코드를 열어야 한다.

**검토한 대안**:

- `bootstrap`을 그대로 두고 이름만 바꾸기 — 순서가 여전히 Composition에 있다.
- Domain UseCase로 옮기기 — 푸시 클라이언트 활성화와 AppDelegate 구성은 플랫폼 수명 주기
  작업이지 도메인 규칙이 아니다.

## 7. deviceID 발급·보관을 어떻게 나누는가

**결정**: Domain이 `DeviceIdentifierRepository`(가칭) 계약을 정의하고, Keychain 기반 구현은
`DataMember`가 소유한다. 앱 버전·OS 버전은 App이 읽어 Composition 조립 인자로 넣는다.
`MemberDeviceInfo` 구성과 등록 호출은 Domain UseCase가 맡는다.

**근거**: deviceID는 "한 번 발급하면 계속 같은 값을 쓴다"는 규칙이 있는 도메인 값이고, 그
값이 어디에 어떤 키로 저장되는지는 Data의 일이다. 앱 버전과 OS 버전은 번들과 프로세스에서만
알 수 있으므로 App이 읽어 내려보내는 것이 유일하게 의존 방향을 지키는 경로다.

**검토한 대안**:

- Infrastructure가 앱·OS 버전을 읽어 제공 — 가능하지만 값이 App 번들에 종속이라 테스트에서
  주입 지점이 한 단계 멀어진다. App이 읽어 넣으면 Composition 조립 인자 하나로 끝난다.

## 8. 키 보존을 어떻게 증명하는가

**결정**: 이동 대상 저장소마다 "이동 전 코드가 쓴 바이트를 이동 후 코드가 읽는다"를 확인하는
테스트를 소유 Data 모듈에 둔다. 키 문자열은 테스트에 **상수로 직접 적어** 비교한다.

**근거**: 이동 후 코드가 정의한 상수끼리 비교하면 상수를 함께 바꿔도 테스트가 통과한다. 키가
바뀌면 기존 사용자의 로그인이 끊기므로, 테스트가 이동과 무관한 고정 문자열을 들고 있어야
회귀를 잡는다.

**검토한 대안**:

- 이동 전후 상수를 서로 비교 — 이동이 끝나면 이동 전 상수가 사라져 비교 대상이 없다.
- 수동 회귀만 — 재현 조건(기존 설치 상태)을 CI가 만들 수 없다.
