# 조사: 공유 시트에서 GitHub 저장소를 등록하는 Share Extension

**대상 명세**: [spec.md](./spec.md) · **날짜**: 2026-09-05

기술 맥락의 미확정 항목과 명세가 남긴 계획 단계 결정(모듈 경계, 자격 증명 공유, 리마인더
예약 경로)을 저장소 근거로 해소한다. 각 항목은 결정, 근거, 검토한 대안을 기록한다.

## R1. Extension이 링크할 조립 경계

- **결정**: `CompositionAdapter`에서 원격 푸시 조립을 분리해 새 target `CompositionApp`으로
  옮기고, `CompositionAdapter`는 원격 푸시 의존이 없는 공유 조립 요소로 남긴다. Extension용
  조립 루트는 새 target `CompositionShareExtension`이 소유한다.
- **근거**: `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의
  `CompositionAdapter`는 `InfrastructurePushMessaging`을 의존하고, 그 target은
  `InfrastructureModuleName.swift:74-75`에서 `FirebaseCore`·`FirebaseMessaging`을 링크한다.
  Extension이 `CompositionAdapter`를 링크하면 Firebase가 함께 들어와 FR-027(불필요한 의존성
  배제)과 메모리 제약을 위반한다. 실제 원격 푸시를 참조하는 Composition 파일은
  `Assemblies/AppComposition.swift`와 `Factories/PushNotificationAppDelegate.swift` 두 개뿐이며
  (`Adapters/NotificationAuthorizationGatewayAdapter.swift`,
  `Factories/GenerationCompletionReminderCoordinator.swift`는 로컬 알림 API만 사용), 이 두 파일만
  옮기면 나머지 Assembly·Adapter·Coding을 그대로 재사용할 수 있다.
- **검토한 대안**:
  - Extension이 Domain·Data·Infrastructure를 직접 조립: `LearningProjectRepositoryAdapter` 등
    기존 Adapter를 재사용할 수 없어 조립 코드를 중복 구현해야 한다.
  - Firebase를 그대로 Extension에 링크: FirebaseMessaging은 애플리케이션 단위 API에 의존해
    Extension 환경에서 안전하지 않고 바이너리와 메모리 비용이 크다.
  - `InfrastructurePushMessaging`을 계약 target과 Firebase 구현 target으로 분리: Composition을
    나누지 않아도 되지만 Infrastructure의 "외부 기술을 내부 API로 변환" 책임을 두 target으로
    쪼개 경계가 흐려지고, App이 구현 target을 직접 조립하게 되어 조립 책임이 App으로 샌다.

## R2. 로컬 알림 API의 target 분리

- **결정**: `Infrastructure/PushMessaging/Local/**`를 새 target `InfrastructureLocalNotification`
  (`sources/Projects/Infrastructure/LocalNotification/`)로 옮기고, 기존
  `InfrastructurePushMessaging`은 `Remote/**`만 소유한다.
- **근거**: 현재 `Local/`은 `UserNotifications`만 사용하고 `Remote/`만 Firebase를 사용한다.
  Extension은 알림 권한 조회(FR-016b)를 위해 `LocalNotificationClient`가 필요하지만 Firebase는
  필요하지 않다. 폴더가 이미 Local/Remote로 나뉘어 있어 파일 이동만으로 target 경계를 만들 수
  있고, 한 target = 한 소스 디렉터리 규칙을 유지한다.
- **검토한 대안**: Extension에서 `UNUserNotificationCenter`를 직접 호출 — Infrastructure가
  플랫폼 기능을 변환한다는 책임 경계(아키텍처 문서 표)를 Extension이 침범한다.

## R3. 자격 증명 공유 방식

- **결정**: 앱과 Extension 양쪽 entitlements에 keychain access group을 추가하고,
  `KeychainStore`가 access group과 `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`를 사용하도록
  바꾼다. 본 앱은 최초 실행 시 access group이 없는 기존 항목을 읽어 공유 그룹에 다시 저장한 뒤
  기존 항목을 삭제한다.
- **근거**: `sources/Projects/Infrastructure/Authentication/Keychain/Stores/KeychainStore.swift:96`은
  현재 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`로 저장하고 access group을 지정하지 않는다.
  이 상태에서는 Extension 프로세스가 항목을 읽을 수 없고, 기기 잠금 상태에서도 읽히지 않아
  FR-010을 만족하지 못한다. 항목 키·네임스페이스는
  `Composition/Adapter/Layouts/SessionKeychainLayout.swift`가 이미 한 곳에서 정의하므로 이전
  대상이 하나로 한정된다.
- **검토한 대안**: 세션을 App Group 파일이나 UserDefaults에 복사 — 토큰을 Keychain 밖에 두게
  되어 Constitution 원칙 2(개인정보·자격 증명 취급)에 어긋난다.

## R4. "앱 실행 필요"와 "로그인 필요"의 구분

- **결정**: 본 앱이 App Group(`group.com.nexters.hytime.gitit`) UserDefaults에 세션 상태 마커를
  기록한다. Extension의 판정은 마커 없음 → 앱 실행 필요, 마커의 로그인 상태가 false → 로그인
  필요, true이지만 공유 Keychain 읽기 실패나 접근 토큰 만료 → 로그인 필요다.
- **근거**: Extension은 access group이 없는 기존 Keychain 항목을 읽을 수 없으므로 "이전 전"과
  "로그아웃"을 Keychain만으로 구분할 수 없다. 마커는 본 앱이 실행되어야만 생기므로 마커의
  부재가 곧 "본 앱을 아직 실행하지 않음"과 일치한다(명확화 세션 1번 결정).
  `Infrastructure/Storage/Stores/UserDefaultsStore.swift`는 이미 `UserDefaults` 인스턴스를 주입
  받으므로 `UserDefaults(suiteName:)`만 전달하면 App Group을 지원한다.
- **검토한 대안**: 마커 없이 Keychain 결과만으로 판정 — 로그인한 사용자에게 "로그인하세요"라는
  사실과 다른 안내를 표시한다.

## R5. 퀴즈 생성 리마인더 예약 경로

- **결정**: Extension은 알림 권한이 이미 허용된 경우에 한해 등록 성공한 `projectID`를 App Group
  공유 저장소의 리마인더 대기 목록에 기록한다. 본 앱의
  `GenerationCompletionReminderCoordinator`는 시작 시 이 목록을 흡수해 기존과 동일한 방식으로
  생성 완료 시점에 로컬 알림을 예약한다.
- **근거**: `Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`는 등록
  시점이 아니라 생성 완료(`GenerationOutcome`) 수신 시점에 알림을 예약하며, 대상 목록을
  메모리(`registeredProjectIDs`)에만 보관한다. Extension은 화면을 닫으면 종료되므로 생성 완료를
  관찰할 수 없고, 메모리 목록은 프로세스를 넘지 못한다. 본 앱은
  `AppModuleName.swift`의 `UIBackgroundModes: remote-notification`으로 푸시 수신 시 백그라운드
  기동이 가능하므로, 목록을 공유 저장소로 옮기면 사용자가 본 앱을 직접 열지 않아도 기존 예약
  경로가 동작한다. 이 변경은 본 앱 자체의 리마인더도 프로세스 재시작을 견디게 만든다.
- **검토한 대안**:
  - Extension이 즉시 시간 기반 알림을 예약: "본 앱과 동일한 리마인더"(FR-016a)가 아니며 생성이
    끝나지 않았는데 알림이 뜰 수 있다.
  - Extension이 생성 완료까지 관찰: 실행 시간 제약(명세 7절)에 위배된다.

## R6. Extension 화면이 속할 Feature 경계

- **결정**: 새 화면을 기존 `Feature` target에 `ShareRegistration` 관심사로 추가한다.
- **근거**: `FeatureModuleName.swift`의 `Feature` target 의존성은 ComposableArchitecture, Domain,
  `DesignSystem`, `UIComponent`뿐이고 Firebase나 애플리케이션 단위 API가 없어 FR-026·FR-027을
  위반하지 않는다. 본 앱과 동일한 디자인 시스템 사용(FR-022)이 자동으로 보장되고, 별도 target을
  만들면 Preview·테스트 구성과 스킴을 새로 만들어야 해 비용이 크다.
- **검토한 대안**: `FeatureShareRegistration` 별도 target — 링크 크기는 줄지만 SC-007의 메모리
  상한은 코드 크기가 아니라 실행 중 상주 메모리가 지배하므로 이득이 불확실하다. SC-007 측정에서
  상한에 근접하면 그때 분리를 별도 명세로 다룬다.

## R7. Extension의 엔드포인트 구성

- **결정**: Extension target의 Info.plist에 `GIT_IT_API_HOST`, `GIT_IT_EXTERNAL_REPOSITORY_HOST`를
  본 앱과 같은 xcconfig 변수로 주입하고, Extension이 자기 번들에서 값을 읽어
  `ShareExtensionComposition.Environment`로 전달한다.
- **근거**: `App/GitIt/Configurations/AppEndpointHost.swift`는 `Bundle.main`의 Info.plist를 읽으며
  `Bundle.main`은 프로세스별로 다르다. 본 앱 target의 타입을 Extension이 import할 수 없으므로
  Extension은 자기 번들용 해석기를 갖고, 값의 출처는 동일한 xcconfig로 통일한다.
- **검토한 대안**: 호스트 값을 App Group에 복사 — 본 앱을 실행하지 않으면 값이 없고 구성이
  런타임 상태에 의존하게 된다.

## R8. 본 앱 복귀 시 목록 갱신

- **결정**: 본 앱의 루트가 `scenePhase` 활성 전환을 감지해 프로젝트 목록 조회를 다시 실행한다.
  Extension이 남기는 신호는 사용하지 않는다(FR-029).
- **근거**: `Feature/Home/Home/HomeScreen.swift:51`의 `.task`는 화면 진입 시에만 실행되어 앱이
  메모리에 남아 있으면 재실행되지 않는다. 명확화 세션 3번 결정에 따라 복귀 시 갱신으로
  Extension·타 기기·타 경로의 변경을 함께 해소한다.
- **검토한 대안**: 공유 저장소 신호 기반 갱신 — 프로세스 간 결합이 늘고 신호 유실 시 목록이
  낡은 상태로 남는다.

## R9. Extension의 토큰 갱신 차단 보장

- **결정**: Extension 조립은 `LearningProjectAssembly`·`ExternalRepositoryAssembly`에 정적
  `accessTokenProvider`만 주입하고, 세션 갱신 사용 사례(`RefreshSession`)를 조립하지 않는다.
- **근거**: `Composition/Adapter/Assemblies/LearningProjectAssembly.swift`의 HTTP 경로는
  `accessTokenProvider`만 사용하며 401 응답에 대한 자동 갱신 경로가 없다. 갱신은
  `AuthenticationAssembly`가 조립하는 별도 사용 사례이므로, Extension 조립에서 이를 제외하면
  FR-007이 구조적으로 보장된다.
- **검토한 대안**: 런타임 플래그로 갱신 억제 — 조립에 갱신 경로가 남아 회귀 위험이 있다.

## R10. 진단 로그

- **결정**: 기존과 동일하게 `os.Logger(subsystem: "com.nexters.hytime.gitit", category:)`를 사용해
  Extension 상태 전이와 실패 사유만 남기고, 토큰·URL 전체·개인정보는 기록하지 않는다.
- **근거**: 저장소에 중앙 로깅 모듈이 없고 `AppComposition`,
  `GenerationCompletionReminderCoordinator` 등이 이미 같은 subsystem을 사용한다. 명확화 세션
  4번 결정에 따라 원격 수집은 추가하지 않는다.
- **검토한 대안**: 원격 분석 도입 — Extension 의존성이 늘어 FR-027과 충돌한다.

## R11. 공유 시트 노출 제한

- **결정**: Extension의 `NSExtensionActivationRule`을 web URL 1건으로 한정하고, 텍스트 항목은
  URL 항목이 없을 때의 보조 경로로만 처리한다.
- **근거**: FR-001은 web URL 공유 시에만 노출할 것을 요구하고, FR-002는 텍스트 전달을 보조로
  허용한다. 활성화 규칙을 텍스트까지 넓히면 GitHub와 무관한 공유에서도 Git-It이 노출된다.
- **검토한 대안**: 술어 기반 규칙으로 GitHub 호스트까지 필터 — 활성화 규칙 술어는 유지 비용이
  크고, 호스트 판정은 이미 FR-003의 로컬 판정이 담당한다.

## R12. 이 브랜치의 선행 구현 정리

- **결정**: 작업 트리에 남은 이전 방식(본 앱으로 링크를 넘기는 컨테이너·URL scheme 기반)의
  파일 삭제와 `AppRootFeature`·`GitItApp` 잔여 연결 정리를 이 기능의 작업 범위에 포함한다.
- **근거**: 명세 가정 항목이 이전 방식의 대체를 명시했고, 해당 파일들은 현재 작업 트리에서 이미
  삭제 상태로 표시되어 있어 정리하지 않으면 빌드와 테스트가 중간 상태로 남는다.
- **검토한 대안**: 별도 정리 명세 분리 — 같은 브랜치의 미완료 상태를 남겨 검증이 불가능하다.

## 미해결 항목

없음. 기술 맥락의 모든 NEEDS CLARIFICATION이 해소되었다.
