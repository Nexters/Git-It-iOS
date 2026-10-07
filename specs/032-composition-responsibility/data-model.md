# 데이터 모델: Composition 책임 되돌리기

이 명세는 저장 값의 **형식**을 바꾸지 않는다. 바뀌는 것은 각 값을 정의하고 다루는 코드의
소유 패키지다. 아래 표의 "키·형식"은 이동 전후로 동일해야 한다.

## 1. 이동 대상과 소유 패키지

| 현재 위치 | 이동 후 소유 | 옮기는 것 |
| --- | --- | --- |
| `Composition/Adapter/Codings/SessionRecordKeychainCoding.swift` | `DataAuthentication` | 세션 레코드 인코딩·디코딩 |
| `Composition/Adapter/Layouts/SessionKeychainLayout.swift` | `DataAuthentication` | 세션 Keychain 네임스페이스와 키 |
| `Composition/Adapter/Layouts/AppleIdentityKeychainLayout.swift` | `DataAuthentication` | Apple 사용자 식별자 네임스페이스와 키 |
| `Composition/Adapter/Migrations/SessionKeychainMigration.swift` | `DataAuthentication` | 레거시 Keychain → 공유 Keychain 이관 |
| `Composition/Adapter/Codings/SharedSessionStateMarkerCoding.swift` | `DataAuthentication` | 로그인 상태 마커 저장 |
| `Composition/Adapter/Codings/PendingGenerationReminderCoding.swift` | `DataLearningProject` | 대기 중 리마인드 목록 저장 |
| `Composition/Adapter/Layouts/SharedSessionLayout.swift` (App Group 좌표) | `InfrastructureStorage`·`InfrastructureAuthentication` | App Group 식별자, Keychain 접근 그룹, 공유 저장소 생성 |
| `Composition/Adapter/Layouts/SharedSessionLayout.swift` (도메인 키) | `DataAuthentication`·`DataLearningProject` | 네임스페이스와 각 키, 스키마 버전, 보관 한도 |
| `Composition/Adapter/Resolvers/SessionAvailabilityResolver.swift` | `DomainAuthentication`(판정) + Composition Adapter(조회 연결) | 만료 판정과 분기 |
| `Composition/Adapter/Models/SessionAvailability.swift` | `DomainAuthentication` | 판정 결과 타입 |
| `Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift` | `DomainLearningProject`(정책) + Composition Adapter(알림 연결) + App(문구) | 대상 집합, 완료 판정, 예약 시각 계산, 표시 문구 |
| `Composition/App/Assemblies/AppComposition.swift`의 `bootstrap` | App | 기동 순서 |
| `Composition/App/Assemblies/AppComposition.swift`의 `registerCurrentDevice` | `DomainMember`(UseCase) + `DataMember`(deviceID 저장) + App(앱·OS 버전) | 기기 등록 절차 |
| `Composition/App/Factories/PushNotificationAppDelegate.swift` | `InfrastructurePushMessaging`(타입 은닉) + App(구성 호출) | AppDelegate 별칭과 구성 |

## 2. 불변이어야 하는 저장 좌표

이동 과정에서 문자열이 바뀌면 기존 사용자의 상태가 사라진다.

| 항목 | 값 |
| --- | --- |
| App Group 식별자 | `group.com.nexters.hytime.gitit` |
| Keychain 접근 그룹 | `6924CABL23.com.nexters.hytime.gitit.shared` |
| 세션 Keychain 네임스페이스 | `com.nexters.hytime.gitit.session` |
| 세션 Keychain 키 | `sessionRecord` |
| Apple 식별자 Keychain 네임스페이스 | `com.nexters.hytime.gitit.authentication` |
| Apple 식별자 Keychain 키 | `appleUserID` |
| 공유 세션 UserDefaults 네임스페이스 | `com.nexters.hytime.gitit.sharedSession` |
| 로그인 상태 마커 키 | `stateMarker` (스키마 버전 `1`) |
| 대기 리마인드 키 | `pendingGenerationReminders` (보관 한도 32) |
| 약관 동의 네임스페이스 | `com.nexters.hytime.gitit.legalConsent` |

세션 레코드와 마커의 인코딩 형식(필드 이름과 타입)도 바뀌지 않는다.

## 3. 새로 정의하는 Domain 개념

| 이름(가칭) | 소유 | 표현하는 것 |
| --- | --- | --- |
| `SessionAvailability` | `DomainAuthentication` | 사용 가능(access token 포함) / 재로그인 필요 / 앱 본체 기동 필요 |
| 세션 유효성 판정 UseCase | `DomainAuthentication` | 저장된 세션과 현재 시각으로 위 세 값 중 하나를 결정 |
| `DeviceIdentifierRepository` | `DomainMember` | deviceID를 발급하고 보관하며 이후 같은 값을 돌려준다 |
| 기기 등록 UseCase | `DomainMember` | 앱·OS 버전과 푸시 토큰을 받아 `MemberDeviceInfo`를 구성하고 등록 |
| 생성 완료 리마인드 정책 | `DomainLearningProject` | 대상 등록, 완료 판정, 예약 시각 결정 |
| 리마인드 예약 계약 | `DomainLearningProject` | "이 식별자로 이 시각에 알림을 예약하라" |

리마인드 예약 계약은 표시 문구를 인자로 받지 않는다. 문구는 그 계약을 구현하는 Composition
Adapter가 App에서 주입받아 채운다.

## 4. 상태 전이

세션 유효성 판정에는 상태 전이가 없다. 저장된 값과 현재 시각을 읽어 매번 새로 계산한다.

리마인드 대상은 `등록됨 → (완료 결과 도착) → 예약됨` 또는 `등록됨 → (완료가 아닌 결과 도착)
→ 해제됨`으로 한 번만 소비된다. 같은 프로젝트의 결과를 두 번 받아도 두 번째는 대상이 아니다.
이 성질은 이동 후에도 유지한다.
