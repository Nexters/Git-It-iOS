# 조사: 등록 흐름·홈 화면 UX 결함 해소

**입력**: [spec.md](./spec.md) | **날짜**: 2026-09-01(초판), 2026-09-02(R-013·R-014 추가)

명세의 요구사항 중 구현 방식이 하나로 정해지지 않은 지점을 조사하고 결정을 기록한다.
모든 결정은 현재 소스(`dfa8604`)와 저장소의 기존 패턴을 근거로 한다.

## R-001. 하단 액션 버튼의 키보드 회피 억제 (FR-001)

- **결정**: 링크 입력 화면의 콘텐츠 루트에 키보드 안전 영역 무시를 적용해 시스템 키보드
  회피가 레이아웃을 밀어 올리지 않게 한다. 입력 필드는 화면 상단(헤더 아래)에 있어 키보드에
  가려지지 않으므로 화면 전체에 적용해도 입력이 막히지 않는다.
- **근거**: `ProjectRegistrationScreen.linkInputContent`는 `Spacer` + 하단 `ActionButton`
  구조라 기본 키보드 회피가 버튼까지 이동시킨다. 스크롤 컨테이너가 없어
  `.scrollDismissesKeyboard` 계열 수단을 쓸 수 없다.
- **검토한 대안**:
  - 하단 버튼만 `safeAreaInset(edge: .bottom)`으로 분리 — `QuizGenerationProgressScreen`이
    쓰는 방식이지만 `safeAreaInset`도 키보드 회피를 받으므로 문제가 그대로 남는다.
  - `ScreenContainer`에서 일괄 적용 — UI 패키지 전 화면의 키보드 동작을 바꾸므로 이번
    명세 범위를 넘는다. 기각.

## R-002. 입력 필드 밖 터치로 키보드 닫기 (FR-002~004)

- **결정**: `LabeledTextField`에 선택적 포커스 바인딩 입력을 추가하고, 화면은 그 바인딩을
  해제하는 방식으로 키보드를 닫는다. 터치 인식은 기존 조작 요소를 덮지 않도록 배경 레이어에
  두어 안내 패널 버튼·입력 지우기 버튼·액션 버튼의 히트 테스트를 가로채지 않는다.
- **근거**: `LabeledTextField`는 현재 포커스 상태를 전혀 노출하지 않아 화면이 키보드를 내릴
  수단이 없다. 포커스 바인딩은 UI 컴포넌트의 정당한 공개 계약이고 다른 입력 화면에서도
  재사용된다.
- **검토한 대안**:
  - Feature에서 UIKit `resignFirstResponder`를 전역 전송 — UI 패키지를 바꾸지 않아도 되지만
    Feature가 UIKit 응답자 체인에 직접 의존하고 어떤 필드가 닫히는지 표현되지 않는다. 기각.
  - 화면 최상위에 전체를 덮는 탭 제스처 — FR-004(기존 조작 보존)를 위반한다. 기각.

## R-003. 첫 카드 기울기가 0이 되도록 보장하는 방법 (FR-021~023)

- **결정**: 기준 위치 `p0CenterX`를 상수로 두지 않고, 카드 목록 콘텐츠의 선행 가장자리에 놓은
  0 크기 앵커 뷰의 x를 카드 중심과 **같은 좌표 공간**에서 읽어 계산한다
  (`p0CenterX = 앵커x + cardWidth / 2`). `HomeCardScrollLayout`의 각도 계산 자체는 그대로
  두고 주입되는 기준값만 측정값으로 바꾼다.
- **근거**: 현재 `HomeScreen.projectCardScroll`은 카드 중심을 `.scrollView` 좌표계에서 읽으면서
  기준값은 `screenMargin + cardWidth / 2`라는 화면 좌표 가정으로 계산한다. 선행
  `safeAreaPadding(.leading)`이 두 값의 원점 가정을 어긋나게 하면 정지 상태의 첫 카드가
  `position != 0`이 되어 0이 아닌 각도가 나온다. 측정값을 쓰면 이 원점 가정 자체가 사라져
  padding 값이 바뀌어도 FR-021이 유지된다.
- **검토한 대안**:
  - 상수를 `cardWidth / 2`로 보정 — 좌표계가 padding을 포함하지 않는다는 반대 방향의 암묵적
    가정을 남긴다. 같은 결함이 반복될 수 있어 기각.
  - `position <= 0`에서 각도를 0으로 고정(변경 전 동작으로 되돌리기) — FR-022의 연속성
    요구를 위반한다. 기각.
- **검증**: 각도 함수는 `HomeCardScrollLayoutTests`로 계속 단위 검증하고(FR-023), 기준값
  주입은 화면 프리뷰 스냅샷으로 확인한다.

## R-004. 카드 로딩 영역 높이 일치 (FR-017~019)

- **결정**: 로딩·빈 상태 컨테이너의 높이를 실제 카드 영역과 같은
  `cardHeight + verticalPadding * 2`로 고정하고, 빈 데크 실루엣은 그 안에서 원본 비율을
  유지한 채 배치한다.
- **근거**: 실루엣 원본 크기는 236.627pt인데 카드 영역은 `192 + 24 * 2 = 240pt`라 현재는
  3.373pt 차이가 난다. 컨테이너 높이를 카드 영역 값으로 고정하면 SC-006(높이 차 0)이
  성립하고 실루엣 자체는 그대로 재사용할 수 있다.
- **검토한 대안**: 실루엣을 240pt로 늘려 그리기 — Figma `1542:19623` 원본 비율이 깨진다. 기각.

## R-005. 최소 대기 시간 정책의 소유 위치 (FR-010~013)

- **결정**: 최소 대기 시간(300초)과 "준비 완료 시각" 계산을 Domain이 소유한다. Feature(진행
  화면 전이)와 Composition(알림 예약)이 같은 값을 참조한다.
- **근거**: 같은 규칙을 두 패키지가 각각 구현하면 SC-009(세 시점 차이 1초 이내)를 보장할 수
  없다. Domain은 내부 패키지 의존이 없어 Feature와 Composition 양쪽에서 참조 가능한 유일한
  위치다(아키텍처 문서 3.1).
- **검토한 대안**:
  - Feature와 Composition에 각각 상수를 둔다 — 값이 갈라질 수 있어 기각.
  - Composition이 정책을 소유하고 Feature에 주입 — Feature는 Composition에 의존할 수 없다
    (허용 의존성 위반). 기각.

## R-006. 현재 시각 주입 방식 (FR-010, FR-013)

- **결정**: 시간 의존은 생성자 인자 `now: @Sendable () -> Date`로 주입하고, 대기는 취소
  가능한 Effect의 sleep으로 구현한다. 테스트는 고정된 `now`와 TCA `TestStore`의 Effect 제어로
  검증한다.
- **근거**: `AppleAuthorizationProvider`가 이미
  `now: @escaping @Sendable () -> Date = { Date() }` 패턴을 쓴다. Constitution은
  `@Dependency` 키와 전역 container를 production 의존성 전달 수단으로 금지한다.
- **검토한 대안**: TCA `@Dependency(\.continuousClock)` — Constitution의 명시적 금지 대상. 기각.

## R-007. 지연 로컬 알림 발송·취소 (FR-010, FR-014)

- **결정**: `LocalNotificationClient`에 예약 발송과 취소를 **추가**한다. 기존 `present`는
  유지해 다른 호출자에 영향을 주지 않는다. 구현은 `UNTimeIntervalNotificationTrigger`와
  `removePendingNotificationRequests(withIdentifiers:)`를 쓴다.
- **근거**: 현재 `UserNotificationCenterLocalClient.present`는 `trigger: nil`로 즉시 발송만
  한다. 시스템이 예약을 보관하므로 앱이 백그라운드·종료 상태여도 예정 시각에 도착한다
  (FR-010). 인프로세스 타이머는 앱 정지 시 발화하지 않아 요구를 충족하지 못한다.
- **검토한 대안**:
  - Composition에서 `Task.sleep` 후 `present` 호출 — 앱이 정지되면 발화하지 않는다. 기각.
  - 요청 시점에 미리 예약하고 실패 시 취소 — 명확화 4에서 기각된 방식(취소 불가 상태에서
    잘못된 완료 알림). 기각.

## R-008. 생성 진행 상태의 저장과 복원 (FR-005, FR-008)

- **결정**: 저장소 패턴은 기존 `PolicyConsent` 경로를 그대로 따른다.
  - Domain: `GenerationProgress` 모델과 `GenerationProgressRepository` 계약
  - Data: DTO와 `LocalGenerationProgressStore`(`UserDefaultsStore` 기반)
  - Composition: 두 계약을 잇는 어댑터
- **근거**: `LocalPolicyConsentStore` → `PolicyConsentStore`(Data 계약) →
  Composition 어댑터 → Domain 계약 경로가 이미 확립돼 있다. Data는 Domain에 의존할 수
  없으므로(아키텍처 3.1) 어댑터 경유가 유일한 방법이다. 저장 대상은 `projectID`와 요청
  시각뿐이라 `UserDefaultsStore`로 충분하다.
- **검토한 대안**:
  - Keychain — 민감 정보가 아니라 과하다. 기각.
  - SwiftData/파일 — 단일 레코드에 비해 도입 비용이 크다. 기각.
- **미결(계획 후 결정)**: 보존 상한. 결과가 끝내 도착하지 않는 경우를 위해 상한을 둔다.
  홈이 이미 학습 프로젝트 목록을 조회하므로 복원된 `projectID`가 목록에 있으면 해제하는
  경로를 1차 해소 수단으로 삼고, 그마저 실패할 때를 위한 절대 상한을 데이터 모델에 둔다.

## R-009. 진행 중 상태를 홈까지 전달하는 경로 (FR-005~009)

- **결정**: `AppRootFeature`가 진행 상태의 수명을 소유한다. 등록 제출 성공 시 시작하고,
  준비 완료 시각까지 대기한 뒤 해제하며, 변화를 `MainShell`을 거쳐 `HomeFeature`에 기존
  `Input` 경로로 전달한다. 앱 시작 시 저장된 상태를 복원한다.
- **근거**: `AppRootFeature`는 이미 `projectRegistration` 표시와
  `mainShell.home(.input(.learningProjectsReloadRequested))` 전달을 모두 소유한다. 등록 흐름이
  닫힌 뒤에도 살아 있는 유일한 지점이라 진행 상태를 붙잡을 수 있다.
- **검토한 대안**:
  - `HomeFeature`가 직접 소유 — 홈이 표시되기 전(등록 화면 위)에는 상태를 시작할 수 없다. 기각.
  - Composition에 관찰 가능한 서비스를 두고 Feature가 구독 — Feature는 Composition에 의존할
    수 없고, Domain에 관찰 서비스를 새로 만드는 것은 TCA 상태 흐름과 이중 관리가 된다. 기각.

## R-010. 공유 시트 진입 수단 (FR-024~029)

- **결정**: 앱 확장(Share Extension) target을 새로 추가한다. `NSExtensionActivationRule`을
  URL 항목이 있는 공유로 한정하고(FR-024), 확장은 전달받은 URL을 App Group 공유 컨테이너에
  기록한 뒤 컨테이너 앱을 커스텀 URL 스킴으로 연다. 앱은 실행·포그라운드 복귀 시 그 값을
  1회 읽고 즉시 비운다.
- **근거**: iOS 공유 시트에 앱을 노출하는 방법은 앱 확장뿐이다. URL 스킴이나 Universal Link
  단독으로는 공유 시트에 나타나지 않는다. App Group은 확장과 앱이 값을 주고받는 표준 수단이고,
  현재 `GitIt.entitlements`에 없으므로 앱·확장 양쪽에 추가해야 한다.
- **검토한 대안**:
  - URL 스킴 쿼리로 값을 직접 전달 — 값이 URL에 노출되고 길이 제한이 있다. 공유 URL은
    사용자 데이터이므로 컨테이너 전달이 낫다. 기각.
  - 확장 없이 Universal Link만 등록 — 공유 시트 노출 요구를 충족하지 못한다. 기각.
- **보안**: 공유 값은 외부 입력이다. 앱은 읽은 값을 기존 링크 검증 경로에 그대로 넘기고,
  검증 전에는 어떤 요청에도 사용하지 않는다(Constitution 원칙 2).
- **미결(계획 후 결정 아님, tasks 단계 확인)**: App Group 식별자와 URL 스킴 문자열은
  `AppModuleName.swift`에서 확정한다.

## R-011. 공유 URL의 1회 소비와 수명 (FR-025~028)

- **결정**: 공유 값은 App Group 컨테이너에 기록되지만, 앱이 읽는 즉시 컨테이너에서 지우고
  이후 수명은 앱 실행 중 메모리 상태로만 유지한다. 앱 종료 시 자연히 사라진다.
- **근거**: FR-026은 "해당 앱 실행 동안만 유효"를 요구한다. 읽는 즉시 지우면 재실행 후
  다시 채워지는 일이 구조적으로 불가능하다.
- **검토한 대안**: 컨테이너에 남겨 두고 앱이 만료 시각으로 판단 — 만료 상수를 하나 더
  도입하고 재실행 시 채워질 위험이 남는다. 기각.

## R-012. 항목 8(유저 프로필 이미지)의 처리

- **결정**: 코드를 변경하지 않는다. `HomeScreen.profileHeader`가 이미 `MemberProfile`과
  무관하게 고정 아바타를 표시한다(`Display.usesDefaultAvatar = true`). 이 상태가 FR-030을
  이미 충족하므로 회귀 방지 확인만 수행한다.
- **근거**: 명세가 항목 8을 명시적 범위 제외로 규정했다.
- **검토한 대안**: 없음.

## R-013. 공유 URL 랜딩 후 "다음" 자동 실행의 소유 위치 (FR-025a)

2026-09-02 명확화로 추가된 요구다. 공유된 URL로 링크 입력 화면에 랜딩하면 "다음"이 사용자가
누른 것과 동일하게 즉시 1회 실행되어야 한다.

- **결정**: 자동 실행의 소유자는 `ProjectRegistrationFeature`다.
  `State.init(initialRepositoryURL:)`이 비어 있지 않은 값을 받으면 1회용 자동 실행 표식을
  함께 세우고, 화면이 보내는 View lifecycle Action(`task`)에서 그 표식을 소비해 검증을
  시작한다. `validateTapped`와 `task`는 같은 내부 시작 경로를 공유해 "사용자가 누른 것과
  동일"을 구조로 보장한다. 표식은 소비 시 즉시 지워 공유 1건당 1회만 실행된다.
- **근거**:
  - [TCA Action 컨벤션](../../docs/conventions/tca/action.md)의 분류 표는 `view`를 "SwiftUI
    화면"이 보내는 Action으로 규정한다. App이나 부모 Feature가 보낼 수 있는 것은 `input`이다.
    따라서 App이 `.view(.validateTapped)`를 직접 보내는 방식은 컨벤션 위반이다.
  - 자동 실행 여부는 등록 화면의 상태이므로 그 화면을 소유한 Feature가 가져야 "1회만"을
    상태로 보장하고 `TestStore`로 검증할 수 있다.
  - `AppRootFeature`에는 이미 소비 지점이 두 곳(즉시 소비, 보류 후 소비) 있다. 초기값 주입만으로
    두 경로가 모두 자동 실행을 얻으므로 App 쪽 분기를 늘리지 않는다.
  - 기존 `validateTapped`가 이미 `!repositoryURLInput.isEmpty` 가드를 가지고 있어, URL을
    얻지 못한 경우 자동 실행하지 않는다는 경계 규칙이 그대로 성립한다.
- **검토한 대안**:
  - `AppRootFeature`가 상태를 연 직후 `.send(.projectRegistration(.view(.validateTapped)))` —
    View Action의 발신 주체 규칙 위반이고, 소비 지점마다 중복된다. 기각.
  - `ProjectRegistrationFeature.Action.Input`을 새로 만들어 App이 자동 실행을 지시 — 분류상
    적법하지만 초기값 주입과 자동 실행이 항상 같이 움직이므로 경로를 둘로 나눌 이유가 없다.
    기각.
  - 화면의 `onAppear`에서 View가 직접 판단 — 자동 실행 여부가 View 상태가 되어 재생성 시
    중복 실행을 막을 수 없다. 기각.

## R-014. 이미 구현된 확장 측 URL 판정의 되돌림 (FR-028, FR-029)

- **결정**: 공유 확장은 URL 형식을 판정하지 않는다. 확장에서
  `GitHubRepositoryURLParser` 사용과 `DataExternalRepository` 의존을 제거하고, URL 항목의
  첫 번째 값을 형식과 무관하게 그대로 App Group 컨테이너에 기록한다.
- **근거**: 2026-09-02 명확화가 검증 소유자를 앱의 링크 입력 경로 하나로 확정했다(FR-029).
  확장이 걸러 내면 저장소 링크가 아닌 URL이 앱에 도달하지 못해, 자동 실행된 "다음"의 결과로
  검증 실패 안내를 보여 주는 FR-025a·시나리오 6 수용 6을 만족할 수 없다. FR-028의 "형식과
  무관하게 첫 번째 URL"도 확장이 판정하면 성립하지 않는다.
- **부수 효과**: 확장이 Data 패키지를 참조할 이유가 사라져, 사용자가 승인한 "확장 target은
  아키텍처 의존 규칙 미적용" 예외를 더 이상 행사하지 않는다. 예외 자체는 승인된 상태로 남지만
  이번 구현에서는 사용하지 않는다.
- **유지 대상**: `ExternalRepositoryURLParser`(Domain 계약) · `GitHubRepositoryURLParser`(Data
  구현) · `ExternalRepositoryURLParserAdapter`(Composition)로 URL 해석 책임을 Data로 옮긴
  리팩터는 앱의 `FetchExternalRepository` 경로에서 계속 쓰이므로 유지한다. 되돌리는 것은
  확장이 그 구현을 직접 참조하는 부분뿐이다.
- **검토한 대안**:
  - 확장이 판정하되 실패해도 앱을 열어 URL을 넘긴다 — 판정 결과를 아무도 쓰지 않으므로
    의미 없는 의존이 남는다. 기각.
  - `NSExtensionActivationRule`을 host 기준 predicate로 좁혀 GitHub URL에만 노출 — 검증 규칙이
    parser와 plist 두 곳으로 갈라지고 FR-024를 바꿔야 한다. 2026-09-02 명확화에서 기각된
    선택지다.
