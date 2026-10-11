# 기능 명세: 레거시 이관 코드 제거, 생성 대기 Repository 도입, Infrastructure 의존의 Data 한정과 Home 생성 결과 관찰 재개

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/pending-repository-legacy-cleanup`

**브랜치 상태**: `재사용`

**생성일**: 2026-09-17

**상태**: 초안

**입력**: 사용자 설명: "1. migration 관련 코드 삭제 2. generation pending 을 담당하는 Repository 를 정의하고, App Groups UserDefaults 를 통해 pending 상태 저장 3. Data 패키지 내부의 기술 관련 코드 (HTTPMethod 와 같은)에 대한 구현 코드 삭제 4. Infra 패키지에 의존하는 타겟은 Data 만 존재하도록 리팩토링 계획 수립"

## 배경

[명세 035](../035-domain-data-infra-design-review/spec.md)의 점검 결과
([`docs/review/domain-data-infra-design-review.md`](../../docs/review/domain-data-infra-design-review.md))는
이름 교정 뒤에도 남은 설계 과제를 기록했습니다. 이 기능은 그중 다음 네 가지를 다룹니다.
명세 작성 시점에 관찰한 근거는 다음과 같습니다.

- **레거시 이관 코드**: Data의 `GenerationStateMigration`(옛 생성 진행 값과 저장소 생성 상태를
  새 생성 상태로 변환)과 `LegacyGenerationProgressDTO`·`LegacyRepositoryCreationStateDTO`,
  `SessionStorageMigration`(옛 Keychain 세션 기록을 공유 Keychain으로 이동), Infrastructure
  `AppGroupKeychainStore.makeLegacy()`, Composition `AuthenticationAssembly.migrateSessionKeychain`
  호출과 `LearningProjectAssembly`의 이관 조립, 각 테스트가 남아 있습니다. `LocalGenerationStateStore`도
  이관 시도 여부를 상태로 가집니다.
- **생성 대기 상태 경로**: Share Extension은 Composition의
  `GenerationReminderAssembly.makePendingReminderEnqueue`가 만든 클로저로 Data
  `PendingGenerationReminderCoding.append`를 Domain 계약 없이 직접 호출하고, 앱은 Domain
  `PendingGenerationReminders.drainProjectIDs()`를 Composition `PendingGenerationRemindersAdapter`의
  단순 위임으로 읽습니다(점검 결과 DS-03). 생성 진행 기록은 Domain `GenerationStateRepository`,
  Data `GenerationStateStore`·`LocalGenerationStateStore`, Composition `GenerationStateRepositoryAdapter`가
  연산 단위 1:1로 이어지며(DS-02), App Group UserDefaults를 만들지 못하면 앱 전용 기본
  UserDefaults로 대체 저장합니다. 생성 요청(`CreateLearningProject`)의 중복 요청 확인과 목록
  조회(`FetchLearningProjects`)의 생성 중 프로젝트 제외는 `TrackGenerationUseCase`를 거쳐 이 기록을
  간접적으로 확인합니다.
- **Data의 기술 재구현**: Data `LearningProject/Models/HTTPMethod.swift`가 Infrastructure
  `HTTPMethod`와 같은 이름의 기술 타입을 다시 선언하고 `LearningProjectRequest.method`로 공개하며
  (DS-05), `AuthenticationEndpoint.Method`·`MemberEndpoint.Method`, 문자열 method를 가진
  `GitHubRepositoryRequest`, 헤더 이름·값을 직접 조립하는 `AuthorizedRequestHeaders`·
  `AuthenticationEndpoint.headers(accessToken:)`가 각 Remote 안에서 Infrastructure 타입으로 다시
  변환됩니다.
- **Infrastructure 의존 target**: 현재 Infrastructure에 의존하는 프로젝트 target은 Data와
  Composition(프로덕션 target과 테스트 target)입니다. Composition은 `HTTPTransport`·`HTTPClient`,
  `KeychainStore`·`AppGroupKeychainStore`, `UserDefaultsStore`·`AppGroupUserDefaults`,
  `LocalNotificationAuthorizationClient`, 푸시 메시징 등을 직접 생성하거나 공개 인자로 받습니다.
  [허용 의존성 설정](../../tools/package-dependencies/config/allowed-dependencies)도
  `Composition: Domain Data Infrastructure`를 허용합니다. Data 저장 타입(`PendingGenerationReminderCoding`,
  `SharedSessionStateMarkerCoding`, `LocalGenerationStateStore`, `LocalPolicyConsentStore`)은 Foundation
  `UserDefaults`나 Infrastructure `UserDefaultsStore<Value>`를 공개 initializer 인자로 그대로 받습니다.
- **Home 생성 결과 관찰**: `HomeFeature`는 첫 `.task`에서 `generationOutcomeObservation`을 `.observing`으로
  바꾸고 관찰 Effect를 시작합니다. 화면이 사라지면 `HomeScreen`의 `.task` 취소로 Effect는 끝나지만 상태는
  `.observing`으로 남아, 다시 나타난 화면의 `.task`가 관찰을 재개하지 않습니다.

## 명확화

### 세션 2026-09-17

- Q: 생성 대기 Repository가 완료 알림 대기 목록만 맡는가, 생성 진행 기록까지 통합하는가? → A: 생성
  진행 기록(`GenerationStateRepository` 계열)과 완료 알림 대기 목록(`PendingGenerationReminders` 계열)을
  모두 대상으로 설계하고, 생성 요청(Generation)과 목록 조회(Fetch)의 대기 확인 경계(Pending Check
  Gateway)로 사용한다.
- 질문: Home 화면을 다시 열면 생성 결과 관찰이 재개되지 않는 문제를 이 기능에서 해소하는가? → 답변: 해소한다.
- 질문: Infrastructure 의존 제한은 계획 수립까지인가, 이 기능에서 실제로 적용하는가? → 답변: 이 기능에서
  적용해 Infrastructure에 대한 의존을 Data 패키지에서만 가능하게 한다.
- 질문: Data가 UserDefaults 인터페이스를 그대로 쓰는가? → 답변: 쓰지 않는다. Protocol로 정의해 주입받는다.
- 질문: UserDefaults 인터페이스를 대신할 Protocol의 소유자와 실제 구현 생성 위치는? → 답변: Data가 기술
  이름 없는 역할 Protocol(키 기반 값 저장)을 정의하고, Infrastructure `UserDefaultsStore`를 감싼 실제
  구현은 Data 내부에 둔다. App Group·기본 저장소를 고르는 공개 생성 진입점은 Data가 제공하며,
  Composition과 테스트는 Protocol만으로 주입한다.
- 질문: UserDefaults 외 기술(HTTP 전송, Keychain, 로컬 알림, 푸시)의 대체 주입도 같은 방식인가? → 답변: 같은
  방식이다. Data가 기술 이름 없는 역할 Protocol(요청 전송, 보안 저장, 알림 권한·예약, 푸시 수신)을 정의하고
  Infrastructure를 감싼 실제 구현과 공개 생성 진입점을 Data에 두며, Composition과 테스트는 Protocol로 주입한다.

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - 생성 대기 상태를 하나의 Repository로 통합하고 생성·조회의 대기 확인 경계로 사용 (우선순위: P1)

개발자는 학습 프로젝트 생성의 대기 상태를 Domain이 소유한 하나의 Repository 계약으로 다루기를
원합니다. 이 Repository는 두 가지를 함께 소유합니다.
- 생성 진행 기록: 요청한 저장소 URL, 프로젝트 식별자, 요청 시각, 진행·완료·실패 상태
- 완료 알림 대기 목록: Share Extension에서 요청해 앱이 완료 알림 대상으로 흡수할 프로젝트

생성 요청(Generation)과 목록 조회(Fetch)는 대기 여부를 이 Repository로 확인합니다. 생성 요청은
같은 저장소 URL이 이미 생성 대기 중인지 확인하고, 목록 조회는 생성 대기 중인 프로젝트를
확인합니다. 대기 상태는 앱과 Share Extension이 함께 접근하는 App Group UserDefaults에만 저장되어
어느 프로세스에서 기록해도 다른 프로세스가 같은 값을 봅니다.

**주요 행위자**: 개발자, 앱과 Share Extension 프로세스

**우선순위 이유**: 사용자가 Share Extension이나 앱에서 생성을 요청한 뒤 중복 요청 차단, 생성 중
프로젝트 목록 제외, 완료 알림이 이어지는 흐름을 유지해야 합니다. 동시에 Domain 계약 없이 Data를
직접 호출하는 경로, 연산 1:1 계약 쌍(DS-02), 단순 위임 Adapter(DS-03)를 없애는 핵심 변경입니다.
시나리오 2의 삭제 범위도 이 저장 위치를 전제로 확정됩니다.

**독립 테스트**: 세 가지로 검증합니다.
- 같은 App Group 저장소를 공유하는 두 Repository 인스턴스로 한쪽이 기록하고 다른 쪽이 확인·소비하는
  테스트
- 생성 요청과 목록 조회 UseCase가 Repository 테스트 더블의 대기 상태에 따라 중복 차단·목록 제외를
  수행하는 Domain 테스트
- Share Extension 조립과 앱 조립이 같은 Domain 계약으로 대기 상태를 다루는지 확인하는 Composition
  테스트

**수용 시나리오**:

1. **전제** 대기 상태가 비어 있음, **실행** Share Extension 경로에서 저장소 URL U의 생성을 요청해
   프로젝트 A를 받음, **결과** 앱 경로의 Repository가 U와 A를 생성 대기로 확인한다.
2. **전제** 저장소 URL U가 생성 대기 중임, **실행** 앱이나 Share Extension에서 U의 생성을 다시
   요청, **결과** 서버 등록을 호출하지 않고 중복 생성 요청 오류를 반환한다.
3. **전제** 서버 등록이 실패함, **실행** 저장소 URL U의 생성을 요청, **결과** U의 생성 대기가
   해제되어 같은 U로 다시 요청할 수 있다.
4. **전제** 프로젝트 A가 생성 대기 중이고 서버 목록에 A와 B가 있음, **실행** 학습 프로젝트 목록을
   조회, **결과** A는 제외되고 B만 반환되며 다음 페이지 여부는 서버 값과 같다.
5. **전제** 프로젝트 A의 생성이 완료되거나 실패해 대기가 끝남, **실행** 목록을 조회, **결과** A가
   목록 제외 대상이 아니다.
6. **전제** Share Extension에서 프로젝트 A의 완료 알림 대기를 기록함, **실행** 앱이 알림 대기를
   흡수, **결과** A가 반환되고 이후 흡수에서는 비어 있다. 같은 A를 다시 기록해도 한 번만 존재한다.
7. **전제** App Group 저장소를 사용할 수 없음, **실행** 대기 상태를 기록·확인·소비, **결과** 앱
   전용 저장소로 대체 저장하지 않고 기록은 무시되며 확인은 대기 없음, 소비는 빈 결과를 반환한다.
8. **전제** 변경 전 버전이 App Group의 기존 저장 위치에 생성 진행 기록과 알림 대기 항목을 남김,
   **실행** 변경 후 앱이 대기 상태를 확인·소비, **결과** 별도 이관 코드 없이 그 값이 반영된다.

---

### 시나리오 2 - 레거시 이관 코드 제거 (우선순위: P2)

개발자는 더 이상 필요하지 않은 옛 저장 형식 이관 코드를 제거해, 생성 상태 저장과 세션 저장
구현이 현재 형식만 다루기를 원합니다.

**주요 행위자**: 개발자

**우선순위 이유**: 이관 코드는 옛 저장 키·DTO·Keychain 생성 경로를 Data·Composition·
Infrastructure에 퍼뜨려 시나리오 1과 시나리오 4의 변경 범위를 넓힙니다.

**독립 테스트**: 프로덕션·테스트 소스에서 이관 전용 선언과 호출을 검색해 0건인지 확인하고, 생성
상태·세션 저장의 기존 현재 형식 테스트가 기대값 변경 없이 통과하는지 확인합니다.

**수용 시나리오**:

1. **전제** 변경 후 소스, **실행** 이관 전용 타입·옛 저장 DTO·옛 Keychain 생성 진입점·이관 호출을
   검색, **결과** 프로덕션·테스트·조립 코드에서 0건이다.
2. **전제** 현재 형식으로 저장된 생성 상태와 세션 기록이 있음, **실행** 앱 시작 후 조회, **결과**
   변경 전과 같은 값을 읽는다.
3. **전제** 현재 형식 값이 없고 옛 형식 값만 있음, **실행** 앱 시작 후 조회, **결과** 옛 값을 읽거나
   변환하지 않고 값이 없는 상태로 동작한다.

---

### 시나리오 3 - Data의 기술 재구현 제거 (우선순위: P3)

개발자는 Data가 Infrastructure가 이미 제공하는 기술 개념(HTTP method, 요청 헤더 이름 등)을 자기
타입으로 다시 구현하고 변환하는 코드를 제거해, 기술 표현은 Infrastructure에만 있고 Data는 요청의
역할과 서비스 값만 소유하기를 원합니다.

**주요 행위자**: 개발자

**우선순위 이유**: 같은 기술 개념의 중복 선언과 변환 분기를 없애 D-ARCH-004의 "기술은
Infrastructure가 담당하고 Data 공개 선언에 나타나지 않는다"는 원칙과 코드를 일치시킵니다.

**독립 테스트**: Data 프로덕션 소스에서 기술 개념 재선언과 재변환 분기를 검색해 0건인지 확인하고,
각 Remote의 요청 구성 테스트가 같은 method·경로·헤더를 Infrastructure 요청으로 만드는지 확인합니다.

**수용 시나리오**:

1. **전제** 변경 후 Data 프로덕션 소스, **실행** HTTP method를 표현하는 Data 소유 enum·문자열
   프로퍼티와 그 값을 Infrastructure 타입으로 바꾸는 변환 분기를 검색, **결과** 0건이다.
2. **전제** 변경 후 Data 공개 선언, **실행** 공개 타입·프로퍼티·initializer 시그니처를 검색,
   **결과** HTTP method·헤더 같은 전송 기술 개념이 공개 선언에 나타나지 않는다.
3. **전제** 각 Remote의 기존 요청 구성 테스트, **실행** 변경 후 실행, **결과** 전송되는 method,
   경로, query, 헤더 이름·값이 변경 전과 같다.

---

### 시나리오 4 - Infrastructure 의존을 Data 패키지로 한정 (우선순위: P4)

개발자는 Infrastructure에 의존할 수 있는 프로젝트 target이 Data 패키지 target뿐이기를 원합니다.
Composition은 Infrastructure 타입을 만들거나 이름을 쓰지 않고 Data가 제공하는 공개 진입점과 계약만으로
조립합니다. Data 저장 타입은 UserDefaults 인터페이스를 그대로 받지 않고, Data가 정의한 키 기반 값 저장
Protocol을 주입받습니다.

**주요 행위자**: 개발자, 패키지 의존성 자동 검사

**우선순위 이유**: 기술 의존을 Data 한 곳에 모아 Composition·App·Feature가 기술 변경에 영향받지 않게
하고, Data 저장 동작을 Protocol 테스트 더블로 검증할 수 있게 합니다. 시나리오 1~3으로 대상이 줄어든
뒤 적용합니다.

**독립 테스트**: Infrastructure 패키지 밖에서 Infrastructure를 import하거나 Tuist에서 의존하는 target을
검색해 Data 외 0건인지 확인하고, 패키지 의존성 자동 검사가 통과하는지와 Data 밖 Infrastructure 의존을
추가하면 실패하는지 확인합니다. Data 저장 타입 테스트는 Protocol 테스트 더블을 주입해 수행합니다.

**수용 시나리오**:

1. **전제** 변경 후 저장소, **실행** Infrastructure 모듈 import와 Tuist Infrastructure 의존을 검색,
   **결과** Infrastructure 패키지 자신을 제외하면 Data 패키지 프로덕션·테스트 target에서만 나온다.
2. **전제** 변경 후 저장소, **실행** 패키지 의존성 자동 검사를 실행, **결과** 통과한다. Composition
   소스에 Infrastructure import를 추가하고 다시 실행하면 실패한다.
3. **전제** 앱, Share Extension, Composition 테스트, **실행** 요청 전송·보안 저장·키 기반 값 저장·알림
   권한과 예약 구현을 대체 주입, **결과** Infrastructure 타입 없이 Data가 정의한 역할 Protocol의 테스트
   더블로 주입할 수 있다. 푸시 수신은 현재 대체 주입 지점이 없으므로 Composition이 Data 생성 진입점으로만
   만든다.
4. **전제** Data 저장 타입(생성 대기 Repository 구현, 공유 로그인 상태, 약관 동의 기록 등), **실행**
   생성과 테스트를 수행, **결과** Foundation `UserDefaults`나 Infrastructure `UserDefaultsStore`가 아니라
   Data의 키 기반 값 저장 Protocol을 주입받고, 테스트는 그 Protocol의 테스트 더블로 검증한다.
5. **전제** 변경 전 버전이 저장한 App Group·기본 저장소 값, **실행** 변경 후 앱이 읽음, **결과** 저장
   키·namespace·값 형식이 같아 그대로 읽힌다.

---

### 시나리오 5 - Home 화면 재진입 시 생성 결과 관찰 재개 (우선순위: P5)

사용자는 Home을 떠났다가 다시 돌아와도 생성이 끝난 학습 프로젝트가 Home에 반영되기를 원합니다.

**주요 행위자**: 앱 사용자

**우선순위 이유**: 현재는 Home을 한 번 벗어나면 다시 열어도 생성 완료·실패가 Home에 반영되지 않아
사용자가 앱을 다시 시작해야 할 수 있는 동작 결함입니다.

**독립 테스트**: Home Feature 테스트에서 `.task` 시작, 취소(화면 이탈), 재시작(재진입) 뒤 생성 결과를
전달해 Home이 결과를 반영하는지 확인합니다.

**수용 시나리오**:

1. **전제** Home이 한 번 나타났다가 사라짐, **실행** Home이 다시 나타난 뒤 프로젝트 A의 생성이 완료,
   **결과** Home이 A의 생성 결과를 반영한다.
2. **전제** Home이 사라진 동안 프로젝트 A의 생성이 완료됨, **실행** Home이 다시 나타남, **결과** Home이
   A의 생성 결과를 반영한다.
3. **전제** Home이 보이는 상태, **실행** 화면 이탈 없이 `.task`가 다시 전달됨, **결과** 관찰이 중복으로
   시작되지 않아 같은 생성 결과가 두 번 처리되지 않는다.

---

### 예외·경계 사례

- Share Extension과 앱이 거의 동시에 대기 상태를 기록·소비하면 기록된 항목이 소비와 삭제 사이에서
  사라지지 않아야 한다(기존 보장 수준보다 나빠지지 않는다).
- 대기 항목 수가 기존 상한(32개)을 넘으면 가장 오래된 항목부터 버린다.
- App Group entitlement가 없는 테스트·Preview 환경에서 대기 상태 Repository를 조립해도 앱이
  실패하지 않는다.
- 이관 코드 제거 뒤 옛 Keychain 서비스·옛 UserDefaults 키에 남은 값은 읽지도 지우지도 않는다.
- Data 기술 재구현 제거 뒤에도 GitHub API 요청처럼 서비스 고유 헤더 값(API 버전 등)은 Data가
  서비스 값으로 소유한다.
- Infrastructure 패키지 자신의 테스트 target은 Infrastructure에 의존할 수 있으며 제한 대상이 아니다.
- App Group 저장소를 만들 수 없는 환경에서도 Data 생성 진입점은 실패하지 않고, 대기 상태 저장은
  FR-003대로 기록을 무시한다.
- Home 이탈과 재진입이 빠르게 반복되어도 동시에 살아 있는 Home 생성 결과 관찰은 최대 하나다.

## 요구사항 *(필수)*

### 기능 요구사항

#### 생성 대기 Repository

- **FR-001**: Domain은 학습 프로젝트 생성 대기 상태를 담당하는 Repository 계약을 하나 소유해야 한다.
  계약 이름과 연산 이름은 저장 매체나 접근 방식 용어를 포함하지 않는다(명세 035 FR-020).
- **FR-002**: FR-001 Repository는 현재 두 계약 쌍이 나눠 가진 책임을 하나로 통합해야 한다.
  - 생성 진행 기록: 현재 Domain `GenerationStateRepository`, Data `GenerationStateStore`·
    `LocalGenerationStateStore`, Composition `GenerationStateRepositoryAdapter`가 맡는다. 생성 시작,
    프로젝트 식별자 연결, 완료·실패 반영, 대기 해제를 포함한다.
  - 완료 알림 대기 목록: 현재 Domain `PendingGenerationReminders`, Data
    `PendingGenerationReminderCoding`, Composition `PendingGenerationRemindersAdapter`와 enqueue
    클로저가 맡는다. 기록과 흡수(조회 후 비움)를 포함한다.
- **FR-003**: 대기 상태는 앱과 Share Extension이 공유하는 App Group UserDefaults에만 저장해야 하며,
  App Group 저장소를 만들 수 없을 때 앱 전용 UserDefaults로 대체 저장하지 않아야 한다.
- **FR-004**: 생성 요청(Generation)은 서버 등록 전에 FR-001 Repository로 같은 저장소 URL이 생성 대기
  중인지 확인해야 한다. 대기 중이면 서버 등록 없이 중복 생성 요청 오류를 반환한다. 대기 중이 아니면
  대기를 기록하고, 등록 성공 시 프로젝트 식별자를 연결하며, 등록 실패 시 대기를 해제한다.
- **FR-005**: 학습 프로젝트 목록 조회(Fetch)는 FR-001 Repository로 생성 대기 중인 프로젝트 식별자를
  확인해 조회 결과에서 제외해야 한다. 다음 페이지 여부는 서버 결과를 그대로 유지한다.
- **FR-006**: 생성 요청과 목록 조회의 대기 확인은 FR-001 Repository를 유일한 경계로 사용해야 한다.
  대기 확인을 위해 별도 UseCase나 Composition 클로저를 거치거나, 저장 구현을 직접 참조하지 않는다.
- **FR-007**: Share Extension의 대기 기록 경로와 앱의 대기 확인·흡수 경로, 완료 알림 예약과 푸시 결과
  반영은 모두 FR-001 계약을 통해야 한다. Composition이 Data 저장 구현을 Domain 계약 없이 직접
  호출하는 클로저 경로를 남기지 않아야 한다.
- **FR-008**: 다음 기존 동작을 유지해야 한다.
  - 완료 알림 대기 목록은 같은 프로젝트를 중복 기록하지 않는다.
  - 목록 상한(32개)을 넘으면 가장 오래된 항목부터 제거한다.
  - 생성 진행 기록이 완료·실패로 바뀌면 상태 변화를 관찰하는 쪽(완료 알림 예약, 화면 갱신)에 전달한다.
- **FR-009**: 변경 전 버전이 기록한 생성 진행 기록과 알림 대기 항목을 변경 후 버전이 이관 코드 없이
  읽어야 한다. 이를 위해 기존 App Group 저장 위치(namespace와 key)와 항목 형식의 호환을 유지한다.
- **FR-010**: 새 계약으로 대체된 선언은 제거하고, 참조하던 문서의 이름을 갱신해야 한다. 대상은
  위 두 계약 쌍의 Domain 계약, Data 계약, 단순 위임 Adapter와 조립 전용 enqueue 진입점이다.
#### 레거시 이관 코드 제거

- **FR-011**: 생성 상태 이관(`GenerationStateMigration`과 옛 저장 DTO 두 개, 저장소의 이관 시도
  상태·이관 인자)과 세션 Keychain 이관(`SessionStorageMigration`, 옛 Keychain 생성 진입점, 조립
  코드의 이관 호출)을 프로덕션·테스트·조립 코드에서 제거해야 한다.
- **FR-012**: 제거 후 생성 상태 저장과 세션 저장은 현재 형식만 읽고 써야 하며, 현재 형식 동작을
  검증하는 기존 테스트의 기대값은 바뀌지 않아야 한다.
- **FR-013**: 이관 코드만을 위해 존재하던 형태 폴더가 비면 제거하고, 파일·형태 어휘 문서와 점검
  결과 문서에서 제거된 항목을 가리키는 설명을 코드와 일치시켜야 한다.

#### Data 기술 재구현 제거

- **FR-014**: Data는 Infrastructure가 제공하는 전송 기술 개념(HTTP method 등)을 같은 의미의 자기
  타입·문자열 프로퍼티로 다시 선언하지 않아야 하며, 그 값을 Infrastructure 타입으로 다시 옮기는
  변환 분기를 두지 않아야 한다.
- **FR-015**: 제거 뒤 Data 공개 선언(타입·프로퍼티·initializer·연산 시그니처)에 HTTP method·헤더
  같은 전송 기술 개념이 나타나지 않아야 한다. 요청의 기술 표현은 Data 내부 구현에서만
  Infrastructure 타입으로 구성한다.
- **FR-016**: 서버·외부 서비스와 주고받는 실제 요청(method, 경로, query, 헤더 이름·값, 본문)은
  변경 전과 같아야 한다.
- **FR-017**: 이 요구사항은 전송 기술의 중복 표현 제거로 한정한다.
  공개 initializer의 Infrastructure 인자 제거(DS-06)는 FR-020이 다루고, 서버 응답 봉투 통합(DS-04)은
  이 기능의 범위가 아니다.

#### Infrastructure 의존의 Data 한정

- **FR-018**: Infrastructure 패키지 밖에서 Infrastructure target에 의존하거나 Infrastructure 모듈을
  import하는 target은 Data 패키지의 프로덕션·테스트 target뿐이어야 한다. App, Composition(프로덕션·
  테스트), Feature, UI, Domain은 Infrastructure에 의존하지 않는다.
- **FR-019**: 허용 의존성 설정과 Tuist target 의존성은 FR-018과 일치해야 하며, 패키지 의존성 자동 검사는
  Data 밖 Infrastructure 의존을 실패로 판정해야 한다.
- **FR-020**: Data 공개 선언(타입·프로퍼티·initializer·연산 시그니처)에 Infrastructure 타입과 Foundation
  `UserDefaults`가 나타나지 않아야 한다. Composition이 맡던 기술 구현 생성과 선택(HTTP client, Keychain·
  App Group 저장소, 로컬 알림, 푸시 메시징)은 Data가 제공하는 공개 진입점으로 옮긴다.
- **FR-021**: 앱·Share Extension·테스트의 기존 대체 주입 지점(현재 `transport`, `keychainStore`,
  `sharedDefaults`, `localNotificationClient` 인자)은 Infrastructure 타입 없이 유지해야 한다. 이를 위해 Data는
  기술 이름을 포함하지 않는 역할 Protocol을 요청 전송, 보안 저장, 알림 권한·예약, 푸시 수신 능력마다
  정의하고, Infrastructure를 감싼 실제 구현과 공개 생성 진입점을 Data 내부에 둔다. Composition과 테스트는
  이 Protocol로 대체 구현을 주입한다. 푸시 수신은 현재 대체 주입 지점이 없어(`AppComposition` 내부에서만
  생성) 새 주입 인자를 추가하지 않고 Data 생성 진입점으로만 만든다.
- **FR-022**: Data는 FR-021과 같은 방식으로 저장 기술 이름을 포함하지 않는 키 기반 값 저장 Protocol을
  정의해야 한다. Data 저장
  타입은 이 Protocol을 주입받고, Infrastructure `UserDefaultsStore`를 감싼 실제 구현은 Data 내부에 둔다.
  App Group 저장소와 기본 저장소를 고르는 공개 생성 진입점은 Data가 제공하며, Composition과 테스트는
  Protocol만으로 대체 구현을 주입한다.
- **FR-023**: FR-022 전환 뒤에도 저장 키, namespace, 값 형식은 변경 전과 같아야 한다.
- **FR-024**: 아키텍처 문서와 패키지 규칙의 허용·금지 의존성 설명을 FR-018과 일치시켜야 한다.

#### Home 생성 결과 관찰 재개

- **FR-025**: Home 화면이 사라졌다가 다시 나타나면 생성 결과 관찰을 다시 시작해야 하며, 사라진 동안 끝난
  생성 결과도 재진입 뒤 반영해야 한다.
- **FR-026**: Home이 보이는 동안 생성 결과 관찰은 하나만 유지해야 하며, 같은 생성 결과를 중복 처리하지
  않아야 한다.

### 핵심 엔터티 *(기능에 데이터가 포함되면 작성)*

- **생성 진행 기록**: 한 번의 생성 요청. 저장소 URL, 프로젝트 식별자(등록 성공 후), 요청 시각,
  진행·완료·실패 상태, 종료 시각을 가진다. 같은 저장소 URL의 진행 중 기록은 하나만 존재한다.
- **완료 알림 대기 항목**: Share Extension에서 생성을 요청해 앱이 완료 알림 대상으로 흡수할 프로젝트.
  프로젝트 식별자와 요청 시각을 가지며 같은 프로젝트는 한 번만 존재한다. 목록 상한은 32개다.
- **생성 대기 상태**: 생성 진행 기록과 완료 알림 대기 항목의 모음. 앱과 Share Extension이 App Group
  저장소를 통해 공유하며 FR-001 Repository 하나가 소유한다.
- **키 기반 값 저장 계약**: Data가 소유하는 Protocol. namespace와 key로 Codable 값을 저장·조회·삭제하며
  저장 기술 이름을 갖지 않는다. 실제 구현은 Data 내부에서 Infrastructure 저장 기능을 감싸고, 테스트는
  테스트 더블을 쓴다.
- **기술 능력 역할 계약**: Data가 소유하는 요청 전송, 보안 저장, 알림 권한·예약, 푸시 수신 Protocol.
  이름과 연산에 기술·공급자 이름이 없고, 실제 구현은 Data 내부에서 해당 Infrastructure 기능을 감싼다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: Share Extension 경로에서 기록한 생성 대기 항목을 앱 경로가 소비하는 자동 테스트가
  통과하고, 중복 기록·상한 초과·App Group 불가 사례를 각각 검증하는 테스트가 1개 이상씩 있다.
- **SC-002**: Composition·Share Extension 조립 코드에서 Data 대기 저장 구현을 Domain 계약 없이
  호출하는 경로가 0건이고, 대기 상태를 앱 전용 기본 UserDefaults에 저장하는 경로가 0건이다.
- **SC-003**: 생성 요청 UseCase와 목록 조회 UseCase가 FR-001 Repository 외의 생성 대기 확인 경로(생성
  추적 UseCase 의존 등)를 갖지 않고, 중복 요청 차단·등록 실패 시 대기 해제·생성 중 프로젝트 목록 제외를
  각각 검증하는 Domain 테스트가 1개 이상씩 있다.
- **SC-004**: `git grep -nE 'GenerationStateMigration|SessionStorageMigration|LegacyGenerationProgressDTO|LegacyRepositoryCreationStateDTO|makeLegacy|migrateSessionKeychain' -- sources`
  결과가 0건이다.
- **SC-005**: Data 프로덕션 소스에서 HTTP method를 표현하는 Data 소유 선언(`HTTPMethod`, 중첩
  `Method`, 문자열 `method` 프로퍼티)과 그 변환 함수가 0건이다.
- **SC-006**: Remote 요청 구성 테스트에서 기대하는 method·경로·query·헤더 값의 변경이 0건이다(테스트
  diff에서 기대값 변경 없음).
- **SC-007**: `git grep -lE '^import Infrastructure' -- sources/Projects ':!sources/Projects/Data' ':!sources/Projects/Infrastructure'`
  결과와 Tuist 설정에서 Data 외 target의 `.fromInfrastructure` 의존이 모두 0건이다.
- **SC-008**: 패키지 의존성 자동 검사가 통과하고, Composition 소스에 Infrastructure import를 추가한 검증
  사례에서는 실패한다.
- **SC-009**: Data 프로덕션 소스의 공개 선언에서 `UserDefaults`, `UserDefaultsStore`, `KeychainStore`,
  `HTTPClient`, `HTTPTransport`가 나타나는 경우가 0건이다.
- **SC-010**: Composition 테스트가 요청 전송·보안 저장·키 기반 값 저장·알림 대체 구현을 Data 역할
  Protocol의 테스트 더블로 주입하며, Composition 테스트 소스의 Infrastructure 타입 참조가 0건이다.
- **SC-011**: Data 저장 타입 테스트가 키 기반 값 저장 Protocol의 테스트 더블로 수행되고, 저장 키·
  namespace·값 형식을 고정하는 기존 테스트의 기대값 변경이 0건이다.
- **SC-012**: Home Feature 테스트에서 화면 이탈 후 재진입 시 생성 결과 반영, 이탈 중 끝난 결과의 재진입 뒤
  반영, 재진입 반복 시 결과 중복 처리 없음을 각각 검증하는 테스트가 1개 이상씩 통과한다.
- **SC-013**: 사용자가 실행한 `build`, `compile`, `test` 검증이 모두 통과한다.

## 가정

- 옛 저장 형식에서 이관해야 할 사용자는 더 이상 없다고 보고, 옛 값이 남은 기기에서 그 값이
  무시되는 결과를 허용한다(사용자가 이관 코드 삭제를 명시적으로 요청).
- 앱과 Share Extension은 같은 버전으로 함께 배포되며 같은 App Group 식별자를 사용한다.
- 기존 대기 항목의 App Group namespace와 key를 그대로 쓰는 것은 이관 코드가 아니라 저장 위치의
  유지로 본다.
- "기술 관련 코드"는 Infrastructure가 이미 표현하는 전송 기술 개념의 Data 측 중복 선언·변환으로
  해석한다. 서비스 경로, 서비스 고유 헤더 값, 서버 응답 DTO는 Data의 서비스 값으로 남는다.
- Infrastructure 의존의 Data 한정은 계획 문서가 아니라 코드·설정·문서 변경으로 이 기능에서 완료한다.
- 푸시 수신의 대체 주입 지점은 새로 만들지 않는다. 푸시 수신 동작은 기존처럼 앱 실행으로 확인한다.
- 빌드·컴파일·테스트 실행은 사용자가 직접 수행한다.
