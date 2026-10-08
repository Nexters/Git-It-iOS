# 조사: 생성 완료 리마인드 알림의 실제 권한 요청과 로컬 알림 발송

## 1. 알림 권한 확인·요청과 설정 화면 안내의 경계

- **결정**: 새 Infrastructure API가 `UNUserNotificationCenter.notificationSettings()`로 현재
  권한 상태를 먼저 조회하고, `notDetermined`일 때만 `requestAuthorization(options:)`을
  호출한다. 이미 `denied`인 경우는 다이얼로그를 띄우지 않고(iOS가 재요청 시 조용히 거부만
  반환하므로) 그 사실을 Composition을 거쳐 Feature에 알려 기존 `openNotificationSettings`
  closure로 안내한다. 이미 `authorized`/`provisional`/`ephemeral`인 경우는 곧바로 허용으로
  간주한다.
- **근거**: iOS는 사용자가 한 번 응답한 뒤에는 `requestAuthorization`을 다시 호출해도 시스템
  다이얼로그를 다시 띄우지 않고 기존 결정을 그대로 반환한다. 따라서 "이미 거부됨"과
  "방금 거부함"을 구분해 전자만 설정 화면으로 안내해야 spec 시나리오 1의 수용 기준(수용
  시나리오 1, 2)을 만족한다.
- **검토한 대안**: 매번 무조건 `requestAuthorization`만 호출하고 결과가 거부면 곧바로 설정
  화면으로 안내하는 방식도 고려했으나, `notDetermined` 상태에서 사용자가 시스템 다이얼로그를
  거절한 직후 다시 설정 화면으로 강제 이동시키는 것은 spec 수용 시나리오 1의 "사용자의 응답과
  무관하게 이어서 홈에서 기다리기 동작이 진행된다"(설정 화면 강제 이동 없이)와 맞지 않아
  기각했다.

## 2. 리마인드 대상 등록을 Feature 화면 생존 여부와 분리하는 방법

- **결정**: 리마인드 대상 등록(`projectID` 집합)과 완료 신호 구독을 Composition이 소유하는
  새 조정자(`GenerationCompletionReminderCoordinator`)로 옮긴다. Domain의
  `RequestGenerationReminderUseCase`는 등록 자체를 `GenerationReminderRegistry`(Domain 계약)로
  위임하며, Composition의 Adapter가 이 계약을 구현해 조정자의 `register(projectID:)`를
  호출한다. 조정자는 `AppComposition.live(...)`가 조립되는 시점에 기존
  `learningProjectOutcomes`(019가 이미 구현한 멀티캐스트 `LearningProjectOutcomesUseCase`)를
  독립적으로 한 번 더 구독하는 백그라운드 `Task`를 시작하며, 이 구독은 앱 프로세스가 살아있는
  동안 유지된다.
- **근거**: 019는 이미 `ProjectRegistrationFeature`와 `HomeFeature`가 각각 독립적으로
  `learningProjectOutcomes()`를 구독하도록 만들어 두었다(멀티캐스트 허브,
  `PushProjectGenerationOutcomeRemote`의 `[UUID: AsyncStream.Continuation]` 구조). 같은
  패턴으로 세 번째 구독자를 추가하면, `ProjectRegistrationFeature`의 화면이 살아있는지와
  무관하게 리마인드 판단이 계속 동작한다. 또한 `AppComposition.live(...)`는 이미
  디바이스 등록을 위해 화면과 무관한 `Task { ... }`를 소유하고 있어(기존
  `registerMemberDevice` 배선) 같은 방식의 프로세스 수명 `Task`를 추가하는 것이
  기존 관례와 일치한다.
- **검토한 대안**:
  - `ProjectRegistrationFeature`의 State에 리마인드 대상을 저장하는 방식은 화면이 닫히면
    Reducer와 Effect가 취소되어 spec의 명확화 결정("Home 복귀 후에도 도착해야 함")을 만족할
    수 없어 기각했다.
  - `HomeFeature`가 리마인드 판단까지 함께 수행하는 방식은 진행 화면에 머무는 동안(Home으로
    복귀하지 않은 경우)에는 `HomeFeature`가 아직 활성화되지 않을 수 있어 수용 시나리오 2-1을
    만족하지 못해 기각했다.
  - Domain에 새 UseCase/Repository를 추가해 대상 등록을 영속화하는 방식은 019의 예외
    허용 범위(FCM 수신을 위한 Domain 계약 추가)를 넘어서고, spec의 가정("앱 프로세스가
    메모리에 유지하는 동안만 유효하면 충분")과도 맞지 않아 기각했다.

## 3. Feature가 알림 권한·리마인드 등록에 갖는 의존성의 형태

- **결정**: Feature의 의존성을 Bool/String으로 깎은 익명 closure 여러 개로 쪼개 "경계를
  넘지 않는 형태"로 우회하지 않는다. 대신 019가 이미 확립한 Domain UseCase + Domain↔외부
  Adapter 패턴(`LearningProjectOutcomesUseCase` + `LearningProjectGenerationOutcomeRepository`
  + Composition Adapter)을 그대로 따라, 알림 권한 확인·요청과 리마인드 등록을 하나의 명시적
  Domain UseCase 의존성 `RequestGenerationReminderUseCase`로 표현한다.
  `ProjectRegistrationFeature`는 이 UseCase 하나만 생성자로 주입받는다(기존
  `fetchExternalRepository: any FetchExternalRepositoryUseCase`와 동일한 형태).
- **근거**: 아키텍처 문서 3.1에서 Feature와 Composition이 공통으로 의존할 수 있는 프로젝트
  내부 패키지는 Domain뿐이다. "권한 확인 후 요청하고, 허용되면 리마인드 대상으로 등록한다"는
  절차는 실제 비즈니스 규칙(리마인드 기능의 핵심 정책)이므로, 이를 익명 closure 조합으로
  흩어 놓기보다 하나의 이름 있는 Domain UseCase로 명시하는 편이 책임을 더 정확히 드러낸다.
  결과 타입(`NotificationAuthorizationOutcome`)도 Domain이 소유하는 enum으로 정의하면
  Feature는 이미 허용된 Domain 의존성을 통해 그대로 받을 수 있어, Infrastructure 타입을
  Bool로 깎아 넘길 필요 자체가 없어진다.
- **검토한 대안**:
  - "이미 거부되었는가"와 "권한을 요청해 허용받았는가"를 별도의 두 `Bool` closure로
    분리하는 방식을 먼저 검토했으나, 이는 비즈니스 규칙(거부 상태면 요청을 건너뛰고 설정으로
    안내한다)을 Feature Reducer 쪽에 노출하고 Composition에는 기술적 위임만 남겨 책임이
    역전된다. 또한 결과를 Bool로 깎으면서 "방금 거부"와 "이미 거부"를 구분하지 못해 별도
    조회 closure(`isNotificationPermissionDenied`)를 추가로 만들어야 했는데, 이는 명시적
    타입 하나로 표현 가능한 정보를 여러 개의 암묵적 계약으로 쪼개는 결과였다.
  - Infrastructure의 결과 enum을 그대로 Feature까지 노출하는 방식도 검토했으나, 이는 Feature가
    Infrastructure에 의존하게 되어 아키텍처 문서 3.1을 직접 위반한다. Domain에 새 enum을
    정의해 Composition Adapter가 Infrastructure enum → Domain enum으로 변환하는 방식을
    채택했다(019의 Data DTO → Domain 모델 변환과 동일한 형태).

## 4. 로컬 알림 발송 시점과 재확인

- **결정**: 로컬 알림은 예약이 아니라 완료 신호 수신 즉시 `UNUserNotificationCenter.add(_:)`로
  발송한다(`trigger: nil`). 발송 직전에 `LocalNotificationClient.isAuthorized()`로 권한
  상태를 다시 확인하고, 그 시점에 허용 상태가 아니면 발송하지 않는다.
- **근거**: spec 가정에 "예약된 미래 시각이 아니라 완료 신호 수신 시점에 즉시 발송"이 명시돼
  있고, FR-009는 발송 직전 재확인을 요구한다. 사용자가 수락 시점 이후 시스템 설정에서 권한을
  껐다가 켤 수 있으므로 등록 시점의 권한 상태만 신뢰하면 안 된다.
- **검토한 대안**: 없음(spec이 이미 즉시 발송·재확인 요구사항을 명시).
