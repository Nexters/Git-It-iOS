# 구현 계획: 기능·상태 단위 Feature 분해와 화면 Feature 합성

**Git-flow 유형**: `feature`

**브랜치**: `feature/feature-composition-refactor` (speckit-specify가 생성, 현재 HEAD에서 재사용 확인)

**날짜**: 2026-09-21 | **명세**: [spec.md](./spec.md)

**입력**: `specs/041-feature-composition-refactor/spec.md`의 기능 명세

## 요약

Feature 패키지의 Reducer 29개를 "기능 관심사와 그 상태 모델" 기준으로 기능 Feature, 화면 합성
Feature, 전환 계층 세 분류로 판정하고, 둘 이상의 Reducer에 선언된 같은 관심사를 기능 Feature
하나로 추출한다. 추출한 기능 Feature는 그것을 쓰던 모든 상위 Feature가 `Scope`로 합성하도록 같은
작업 단위 안에서 전환한다(명세 FR-013).

조사 결과는 [research.md](./research.md)에 있다.
- 분해 기준(세 분류와 보조 규칙)을 정했다.
- 판정: 중복 관심사 4건(I1~I4)은 통합하고 8건(E1~E8)은 제외한다.
- 자식을 합성하게 되는 화면에서 그 화면만 쓰는 관심사 5건(I2′, S1~S4)을 분리한다(SC-008).
- 전환 계층의 기능 상태 5건(R1~R5)을 반납시킨다(시나리오 3-4).
- FR-022 위반 경로 3건(P1~P3)을 옮긴다.

결과적으로 `GuestSignInFeature`가 사라지고 기능 Feature 11개가 생겨 Reducer는 39개가 된다.

추출한 기능 Feature는 Reducer만 소유한다(FR-027). 둘 이상 흐름이 쓰면 `Feature/Shared/Reducers/`,
한 화면이나 한 전환 계층만 쓰면 그 화면 폴더나 `Router/`에 둔다. 의존성은 기존 규칙대로 상위
Feature가 최소 subset을 받아 자식을 직접 생성한다(FR-024). 동작 불변은 단위 테스트로
판정한다(SC-002). 마지막 단계에서 분해 기준과 최종 분류를 TCA 컨벤션 문서에 옮긴다(FR-020).

## 기술 맥락

**언어/버전**: Swift 6 (Tuist 프로젝트 설정 기준), iOS 26.0 이상

**주요 의존성**: The Composable Architecture(TCA), SwiftUI, 프로젝트 내부 `Domain*`·`UI*` 모듈

**저장소**: 해당 없음 — Presentation 상태 리팩토링이며 저장 형식을 바꾸지 않는다

**테스트**: Swift Testing + TCA `TestStore` (`sources/Projects/Feature/Tests/**`, `FeatureTests`
target). UI 자동화 테스트는 추가하지 않는다(명세 명확화 2026-09-21, SC-002)

**대상 플랫폼**: iOS Simulator `platform=iOS Simulator,name=iPhone 17 Pro` (빌드 실행기 기본값)

**프로젝트 유형**: 모바일 앱 — Tuist 멀티 패키지 중 `Feature` 단일 target 내부 리팩토링

**성능 목표**: 해당 없음 — 사용자 관찰 동작 불변이 목표이며 새 성능 목표를 두지 않는다

**제약 조건**: 사용자 관찰 동작 불변(FR-008), 패키지 의존 방향 불변(FR-011), 생성자 주입
유지(FR-012), `Feature` 단일 target 유지(FR-022), View는 최소 변경(FR-023)

**규모/범위**: `sources/Projects/Feature`의 비테스트 `@Reducer` 29개(완료 후 39개), 테스트 파일
82개. 통합 4건, 화면 고유 분리 5건, 전환 계층 반납 5건, 경로 정리 3건, 제외 8건
([research.md](./research.md) §3)

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1. 명시적인 경계 | 통과 | 패키지 경계와 Tuist 의존을 바꾸지 않는다. Feature 안의 공용 경계는 디렉터리로 표현하고 리뷰에서 대조한다(FR-022) |
| 2. 상태와 데이터 안전성 | 통과 | 추출한 기능 Feature마다 상태 소유자가 하나다. 화면마다 독립 인스턴스를 두어 수명을 화면에 묶는다(FR-026). 요청 식별과 취소 경로는 정본 동작 선택에서 보존하거나 강화한다([research.md](./research.md) §4) |
| 3. 검증 가능한 변경 | 통과 | 단위마다 compile·test를 실행하고, 이관한 단언의 대응표를 `research.md`에 남긴다(SC-011). 동작 차이는 FR-008에 따라 기록한다 |
| 4·5. 스킬별 수정 경로 | 통과(예외 1건 기록) | 이 계획은 `plan.md`·`research.md`·`data-model.md`·`quickstart.md`·`contracts/**`만 작성했다. **예외**: 계획 단계에서 FR-024와 [Composition 패키지 규칙](../../docs/package-rules/composition.md)의 충돌을 발견했고, 사용자 승인에 따라 `spec.md`의 FR-024·SC-013·가정 절과 명확화 기록을 함께 정정했다. PR에 기록한다 |
| 6. 한국어 산출물 | 통과 | 모든 산출물을 한국어로 작성했다 |
| 7. 위험 기반 실행 단위 | 통과 | 변경 패키지는 `Feature` 하나다. `App`은 최상위 Feature 생성자나 App이 직접 참조하는 Feature 상태 경로가 바뀌는 단위(U3·U8)에서만 불가분 integration unit으로 묶는다(아래 "실행 단위") |
| 8. Git-flow 브랜치 | 통과 | `feature/feature-composition-refactor` 하나에서 한 PR로 닫는다(FR-021) |
| 9. 세션 지식 기록 | 해당 없음 | 기록 조건을 충족하는 사건이 없다 |
| 10. 책임 기반 네이밍 | 통과 | 기능 Feature와 화면 Feature에 구분 접두어·접미어를 두지 않는다(FR-025). 새 이름은 관심사 책임을 드러내며, 이동과 rename을 설계 변경과 섞지 않도록 단위를 나눈다([research.md](./research.md) §5) |
| 11. 컨벤션 근거 | 통과(공백 1건 기록) | 아래 "적용 컨벤션"에 기록했다. 여러 흐름이 쓰는 Reducer의 배치 자리는 컨벤션에 없다. 결정과 근거를 [research.md](./research.md) §2에 남기고, 형태 어휘 표 갱신은 같은 PR의 작업으로 둔다 |

**설계 후 재점검(1단계 완료 시점)**: 판정이 바뀐 원칙은 없다.
- 원칙 7: 모든 최상위 생성자 시그니처가 유지됨을 계약 문서에서 확인했다. 단, `AppRootFeature`가
  `mainShell.home.projectLoad`·`mainShell.projectList.projects`를, App 테스트가
  `projectDetail.projectDetail.loadStatus`를 직접 참조한다. 그래서 U3·U8은 Feature+App integration
  unit이다(tasks·분석 단계에서 확인).
- 원칙 1: 공용 → 흐름 참조 금지를 [quickstart.md](./quickstart.md) §2의 리뷰 대조 절차로 고정했다.
- 원칙 11: 추가된 공백은 `ShareRegistration/` 흐름 루트 배치 편차 1건이며 복잡성 추적에 기록했다.

**브랜치 네임스페이스**: 이 헌법 개정 후 생성된 `feature/` 브랜치다. `/speckit-specify`가
현재 HEAD에서 생성했으며 이 계획은 같은 브랜치를 재사용한다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정할 수 있다. 이 산출물 밖의 구현 파일은 정확한 경로를
`tasks.md`에 기록하며 계획 단계에서는 수정하지 않는다. 위 원칙 4·5 행의 `spec.md` 정정은 사용자가
명시적으로 승인한 예외다.

**세션 지식 기록**: Constitution 원칙 9를 따른다. 조건을 충족하면 전용 스킬을 별도로 사용하며,
계획 산출물이나 구현 작업으로 만들지 않는다.

**Git 실행 직렬화**: 같은 checkout에서 `git commit`, pre-commit, staged formatter 체인은 한 번에
하나만 실행한다. 빌드 실행기의 `build`·`compile`·`test`는 `sources/DerivedData/PreCommit`을
공유하므로 순차 실행한다.

**커밋 단위 구현**: `/speckit-implement`는 아래 "실행 단위"를 커밋 단위로 쓴다. 단위마다 작업
ID, 정확한 파일, 검증과 커밋 메시지를 명시하고, 구현·검증·완료 표시·정확한 staging·commit 확인을
마친 뒤 다음 단위로 간다. 마지막 단위는 전체 검증과 `after_implement` 포맷 훅까지 실행한 뒤
commit한다.

**컨벤션 근거**: 아래 "적용 컨벤션"에 기록했다.

**책임 기반 네이밍**: 추출한 기능 Feature의 이름은 소유하는 관심사를 드러낸다. 화면 분류를
이름에 표시하지 않는다. 기존 타입을 옮기기만 하는 변경은 순수 이동으로 두고 설계 변경과 분리한다.

**실행 단위 진행**: 아래 "실행 단위"를 따른다.

## 적용 컨벤션

| 문서 | 이번 설계에 부과한 제약 |
| --- | --- |
| [docs/architecture.md](../../docs/architecture.md) | Feature는 Domain·UI에만 의존한다. Feature→Composition 의존은 금지이며, App이 Composition의 dependency를 Feature 초기화 인자에 주입한다. 변경 패키지의 위상 순서는 Feature → App이다 |
| [docs/package-rules/feature.md](../../docs/package-rules/feature.md) | `@Dependency`·Service Locator를 쓰지 않는다. 상위 Feature는 하위가 쓰는 **최소 subset** UseCase만 전달하고 구현을 교체하거나 새로 만들지 않는다(FR-024의 근거). Feature 공개 표면은 App이 생성하는 Reducer·화면과 delegate로 제한한다. Store 상태를 복제하는 ViewModel을 두지 않는다. Domain 계약을 Feature 안에서 구현하지 않는다(테스트는 Test Double을 `Tests/`에만 둔다) |
| [docs/package-rules/composition.md](../../docs/package-rules/composition.md) | Composition은 Feature reducer·dependency 묶음을 생성하지 않고 Feature에 의존하지 않는다. 그래서 이번 변경 대상에서 제외한다 |
| [docs/package-rules/app.md](../../docs/package-rules/app.md) | App은 각 Feature에 실제로 쓰는 UseCase만 주입하며 root Feature를 생성한다. App 호출부는 최상위 Feature 생성자나 App이 직접 참조하는 Feature 상태 경로가 바뀔 때만 함께 바꾼다 |
| [docs/conventions/tca/feature.md](../../docs/conventions/tca/feature.md) 및 [feature/definition-unit.md](../../docs/conventions/tca/feature/definition-unit.md) | Feature의 정의 단위는 관심사이고 화면과 1:1이 아니다. 화면 없는 Feature도 정상 형태다. 관심사 판별 5항목과 "관심사가 아닌 것" 목록이 분해 기준(FR-001)의 판정 근거다 |
| [docs/conventions/tca/feature/composition.md](../../docs/conventions/tca/feature/composition.md) | 상위는 하위 State를 프로퍼티로 보유하고 `Scope`로 연결한다. 하위는 `delegate`로만 결과를 알리고 상위는 `input`으로 조정 신호를 보낸다. 여러 곳에서 쓰는 관심사는 복제하지 않고 각 상위가 조합한다 |
| [docs/conventions/tca/feature/test-validation.md](../../docs/conventions/tca/feature/test-validation.md) | 기능 Feature 테스트는 그 관심사의 Test Double만 주입한다. 화면 Feature 테스트의 종착점은 `delegate` 방출이다(FR-010의 합성 지점 검증 범위) |
| [docs/conventions/tca/navigation/router.md](../../docs/conventions/tca/navigation/router.md) | Router는 전환 컨텍스트 하나의 전환 상태만 소유하고, 진입 준비·결과 판단은 별개 Feature로 조합한다. 다른 흐름의 진입 Feature를 조합할 수 있다(전환 계층의 참조 허용 근거). `@Shared`·`Binding`으로 상태를 공유하지 않는다(FR-026과 일치). 상위가 하위 내부 상태를 직접 바꾸지 않는다 |
| [docs/conventions/tca/state.md](../../docs/conventions/tca/state.md) 및 하위 문서 | 배타 상태는 enum으로 둔다. 교체 가능한 요청은 request identity로 늦은 결과를 거부한다. 파생값을 저장하지 않는다. 통합 시 정본 동작은 이 규칙을 만족하는 쪽으로 고른다 |
| [docs/conventions/tca/effect/dependency-injection.md](../../docs/conventions/tca/effect/dependency-injection.md) | dependency는 initializer로 받아 `private let`으로 보존하고, 테스트는 같은 initializer로 Test Double을 주입한다 |
| [docs/conventions/directory-file.md](../../docs/conventions/directory-file.md) 및 [directory-file/feature-layout.md](../../docs/conventions/directory-file/feature-layout.md) | Feature 패키지 1뎁스는 흐름이다. 흐름 아래에는 `Router/`·`<화면>/`·`Previews/`·`Shared/`·`Resources/`만 둔다. `Shared/`는 여러 화면이 쓰는 선언만 담고 그 아래에서만 형태 폴더를 쓴다. 테스트는 `Tests/<흐름>/<화면>/`으로 미러링한다. 흐름 폴더를 옮겨도 manifest는 바꾸지 않는다 |
| [docs/conventions/directory-file/concern-segment.md](../../docs/conventions/directory-file/concern-segment.md) · [shape-criteria.md](../../docs/conventions/directory-file/shape-criteria.md) · [shape-rules.md](../../docs/conventions/directory-file/shape-rules.md) | 여러 관심사가 함께 쓰는 선언은 `Shared` 세그먼트(`Feature/Shared/`)에 두고 그 아래는 형태 폴더다. 형태 어휘 표에 없는 폴더(`Reducers/`)를 쓰려면 같은 PR에서 표를 갱신한다 |
| [docs/conventions/file-vocabulary.md](../../docs/conventions/file-vocabulary.md) 및 [file-vocabulary/shape-vocabulary.md](../../docs/conventions/file-vocabulary/shape-vocabulary.md) | 파일 하나에 타입 하나. 중첩 타입 분할은 `{상위타입}+{중첩타입}.swift`. `Feature/Shared/`·`Feature/<흐름>/Shared/`에 `Reducers/`, `Tests/Shared/`에 미러링 행을 추가해야 한다 |
| [docs/conventions/naming.md](../../docs/conventions/naming.md) (public-type, affixes, rename) | 기능 Feature 이름은 관심사 책임을 드러낸다. 분류 표시용 일괄 접미어를 쓰지 않는다(FR-025). 이동·rename은 동작 변경과 분리한다 |
| [docs/conventions/test.md](../../docs/conventions/test.md) 및 [test/feature-tca.md](../../docs/conventions/test/feature-tca.md) | Swift Testing + `TestStore`를 쓰고, 테스트 이름은 한국어 동작 문장이다. Test Double은 initializer로 주입한다. 둘 이상의 파일이 쓰는 Test Double은 `TestDoubles/`에 둔다 |
| [docs/conventions/view.md](../../docs/conventions/view.md) · [view/screen-subview.md](../../docs/conventions/view/screen-subview.md) | View는 화면 디렉터리에 남는다(FR-027). 자식 store 스코핑으로 분리하는 서브뷰는 화면 타입에 중첩한 서브뷰 규칙을 따른다. 레이아웃·토큰·컴포넌트는 바꾸지 않는다(FR-023) |

## 프로젝트 구조

### 문서(이 기능)

```text
specs/041-feature-composition-refactor/
├── plan.md              # 이 파일
├── research.md          # 분해 기준, 전수 식별 결과, 정본 동작 선택, 단언 이관 대응표 자리
├── data-model.md        # 분류 엔터티와 추출 기능 Feature의 상태 모델
├── quickstart.md        # 단위별·최종 검증 절차
├── contracts/
│   └── feature-composition-contracts.md  # 추출 기능 Feature의 공개 입력·delegate 계약
└── tasks.md             # /speckit-tasks 산출물(이 명령이 생성하지 않음)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/Feature/
├── Shared/                                    # 관심사 세그먼트 — 둘 이상 흐름이 쓰는 선언
│   ├── Views/FeedbackActionButton.swift       # (기존)
│   ├── Models/MainShellAccess.swift           # (이동) P1
│   └── Reducers/                              # (신규 형태 폴더)
│       ├── UserProfileLoadFeature.swift       # I1
│       ├── ProjectSummaryListFeature.swift    # I2
│       ├── ProjectDeletionFeature.swift       # I3
│       ├── SignInFeature/                     # I4 (타입 패밀리)
│       │   ├── SignInFeature.swift
│       │   └── SignInFeature+Phase.swift
│       ├── LegalAgreementFeature.swift        # (이동) P3
│       └── SingleQuestionEntryFeature.swift   # (이동) P2
├── Home/HomeFeature.swift                     # 화면 합성: I1·I2
├── ProjectList/
│   ├── ProjectListFeature.swift               # 화면 합성: I2·I3·I2′
│   └── ProjectListPaginationFeature.swift     # I2′
├── ProjectDetail/
│   ├── ProjectDetailFeature.swift             # 화면 합성: I3·S4
│   └── ProjectDetailLoadFeature.swift         # S4
├── Settings/
│   ├── Profile/ProfileFeature.swift           # 화면 합성: I1
│   ├── Settings/SettingsFeature.swift         # 화면 합성: I1·S1·S2·S3
│   ├── Settings/{CurationUpdate,AccountAction,NotificationPermission}Feature.swift
│   └── Router/SettingsRouterFeature.swift     # 전환 계층: R3
├── MainShell/Router/                          # 전환 계층: GuestSignInFeature(+Phase) 제거, SignInFeature 합성
├── Onboarding/
│   ├── Tutorial/TutorialFeature.swift         # 화면 합성: I4
│   ├── LegalAgreement/LegalAgreementScreen.swift   # View는 제자리
│   └── Router/OnboardingRouterFeature.swift   # 전환 계층: R4
├── ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift  # 전환 계층: R5
├── Quiz/Router/
│   ├── QuizRouterFeature.swift                # 전환 계층: R1
│   └── LearningSessionFeature.swift           # R1
├── ShareRegistration/
│   ├── ShareRegistrationFeature.swift         # 전환 계층: R2 (이름·위치 유지)
│   └── SharedRepositoryRegistrationFeature.swift   # R2
└── Tests/
    ├── Shared/Reducers/                       # 공용 기능 Feature 단독 테스트
    └── <흐름>/<화면|Router>/                  # 분리 Feature 테스트와 합성 지점 검증

docs/conventions/file-vocabulary/shape-vocabulary.md   # U1: Feature/Shared/ 행과 Reducers/ 어휘
docs/conventions/directory-file/feature-layout.md      # U1: Shared/Reducers 배치 규칙
docs/conventions/tca/feature.md                        # U12: 분해 기준, 분류 문서 링크
docs/conventions/tca/feature/classification.md         # U12: 최종 분류·제외 사유·동작 차이
```

추출 대상과 각 파일의 정확한 경로는 [research.md](./research.md) §3·§5, 상태 모델은
[data-model.md](./data-model.md), 공개 표면은 [contracts](./contracts/feature-composition-contracts.md)가
정한다. 위 트리의 새 타입 이름은 이번 설계에서 확정한 공개 이름이다. 최상위 Feature 생성자는
바뀌지 않는다. App에서는 상태 경로 변경을 따라가는 `App/GitIt/Reducers/AppRootFeature.swift`(U3)와
`App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`(U3·U8)만 수정한다. `App/ShareExtension/ShareViewController.swift`는
변경 대상이 아니다.

**구조 결정**: Feature 단일 target의 흐름 배치(feature-layout)를 유지한다. 기능 Feature의 자리는
사용 범위로 정한다.
- 둘 이상 흐름이 쓰면 기존 관심사 세그먼트 `Feature/Shared/` 아래 새 형태 폴더 `Reducers/`에 둔다.
- 한 흐름 안의 여러 화면이 쓰면 `Feature/<흐름>/Shared/Reducers/`에 둔다. 이번 식별 결과에는 해당이
  없다.
- 한 화면만 쓰면 그 화면 폴더, 한 전환 계층만 쓰면 그 흐름의 `Router/`에 둔다(FR-022, 선례
  `OnboardingExitFeature`).

근거와 기각한 대안은 [research.md](./research.md) §2에 있다.

## 실행 단위

변경 패키지는 `Feature`다. `App`은 두 경우에만 함께 바뀐다. 하나는 `AppRootFeature`가 생성하는
최상위 Feature(`AppEntryFeature`, `OnboardingRouterFeature`, `MainShellRouterFeature` 등)의 생성자
시그니처가 바뀔 때이고, 다른 하나는 App이 직접 참조하는 Feature 상태 경로가 바뀔 때다. 어느 쪽이든
Feature 변경과 App 변경을 떼면 compile되지 않으므로 불가분 integration unit으로 묶는다.

이번 설계에서 최상위 생성자가 바뀌는 단위는 없다(각 Router가 이미 필요한 UseCase를 받는다). 상태
경로 의존은 U3·U8 두 곳이다. U3은 `AppRootFeature.loadedProject`와 App 테스트가
`mainShell.home.projectLoad`·`mainShell.projectList.projects`를 읽는다. U8은 App 테스트가
`projectDetail.projectDetail.loadStatus`를 읽는다. 위상 순서는 Feature → App이다.

| 순서 | 단위 | 시나리오 | 포함 내용 | 선행 |
| --- | --- | --- | --- | --- |
| U0 | 식별 결과 확정 | 1 | [research.md](./research.md) §1·§3(이 계획 산출물로 충족). 소스 변경 없음 | 없음 |
| U1 | 공용 경로 정리 | 2 | P1~P3 순수 이동과 참조·테스트 경로 갱신. 형태 어휘 표·feature-layout 갱신 | U0 |
| U2 | 사용자 프로필 조회 | 2 | I1 추출. Home·Profile·Settings 합성 전환, SettingsRouter 직접 쓰기 제거(R3). 테스트 이관 | U1 |
| U3 | 프로젝트 요약 목록 | 2 | I2 추출. Home·ProjectList 합성 전환. 테스트 이관 | U2 |
| U4 | 프로젝트 삭제 | 2 | I3 추출. ProjectList·ProjectDetail 합성 전환. 테스트 이관 | U3 |
| U5 | 로그인 | 2 | I4 추출. `GuestSignInFeature` 제거, MainShell·Tutorial·OnboardingRouter 합성 전환(R4의 동의 화면 부분). 테스트 이관 | U1 |
| U6 | Settings 화면 정리 | 3 | S1~S3 분리 | U2 |
| U7 | ProjectList 화면 정리 | 3 | I2′ 분리 | U4 |
| U8 | ProjectDetail 화면 정리 | 3 | S4 분리 | U4 |
| U9 | 전환 계층 input 전환 | 3 | R4(잔여)·R5 | U5 |
| U10 | Quiz 학습 세션 | 3 | R1 분리 | U1 |
| U11 | 공유 등록 | 3 | R2 분리 | U1 |
| U12 | 컨벤션 문서화와 최종 검증 | 4 | `docs/conventions/tca/feature.md`·`feature/classification.md` 작성, research §6 대응표 확인, 전체 build·compile·test, 포맷 훅 | U2~U11 |

- **순서의 근거**: `HomeFeature`를 함께 수정하는 U2→U3, `ProjectListFeature`·`ProjectDetailFeature`를
  이어서 수정하는 U3→U4→U7·U8은 직렬로 둔다. U5·U10·U11은 다른 단위와 파일이 겹치지 않아 순서를
  바꿀 수 있다.
- **단위 완료 조건**: 단위마다 `compile`을, 테스트를 옮긴 단위는 `test`까지 실행한다. 단위 완료
  시점에 그 관심사의 중복 선언이 남지 않는다(FR-013). 절차는 [quickstart.md](./quickstart.md)에 있다.
- **범위 주의**: U6~U11은 명세 SC-008(화면 Feature가 관심사 상태를 직접 선언하지 않음)과 시나리오
  3-4(전환 계층의 기능 상태 반납)를 만족하기 위한 분리다. 사용자 관찰 동작 차이는 없다(research §4).

## 복잡성 추적

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
| --- | --- | --- |
| 계획 스킬이 `spec.md`를 수정함(원칙 4·5 예외) | FR-024가 [Composition 패키지 규칙](../../docs/package-rules/composition.md)과 충돌해 원칙 11에 따라 계획을 생성할 수 없었다 | 계획을 중단하고 `/speckit-clarify`를 다시 실행하는 대안을 사용자에게 제시했다. 사용자가 즉시 정정을 선택하고 명세 수정을 승인했다 |
| 형태 어휘 표에 없는 `Reducers/`를 Feature 패키지 `Shared/` 아래 도입 | 둘 이상 흐름이 쓰는 기능 Feature의 자리가 컨벤션에 없다. FR-022는 공용 디렉터리를 요구한다 | 흐름 하나를 골라 그 아래 화면 폴더로 두는 기존 관행(`ProjectDetail/SingleQuestionEntry`)은 화면 없는 Feature를 화면 폴더에 두어 feature-layout과 어긋나고, 공용 Feature가 흐름을 참조하게 만든다. [shape-rules](../../docs/conventions/directory-file/shape-rules.md)가 요구하는 대로 같은 PR에서 표를 갱신한다(U1) |
| `ShareRegistration/` 흐름 루트에 새 Feature 파일 추가 | R2 분리 Feature의 자리가 필요하다. 사용자 결정에 따라 `ShareRegistrationFeature`의 이름·위치를 유지한다 | 흐름 루트에 파일을 두는 기존 편차를 이번에 `Router/`로 정리하면 이동·rename이 설계 변경과 섞인다([rename 분리](../../docs/conventions/naming/rename.md)). 배치 정리는 후속 과제로 남긴다 |
