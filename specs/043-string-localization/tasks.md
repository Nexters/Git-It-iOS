---
description: "사용자 노출 문자열 현지화 적용 작업 목록"
---

# 작업 목록: 사용자 노출 문자열 현지화 적용

**입력**: `specs/043-string-localization/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세 FR-014와 [research.md 결정 9](./research.md#결정-9-테스트)가 요구하므로 target마다
`LocalizedTextTests`를 추가한다. 기존 한국어 기대값 테스트는 수정하지 않는다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 추적한다. 순서는
[plan.md “실행 단위”](./plan.md#실행-단위)를 따른다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: `S1`(고정 문구를 현지화 리소스에서 제공), `S2`(보간·수량 문구 현지화). 명세의 시나리오는 두 개다.
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후
  `git status --porcelain`을 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 파일 변경 작업은 정확한 저장소 상대 경로와 책임 실행 단위를 가진다. 디렉터리와 glob은 구현 권한이 아니다.
- 문서 경로는 `GIT_IT_DOCS_ROOT`(`docs`) 기준이다.
- `project_build_runner`는 `./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER`의 결과다.
  단위 검증은 `GIT_IT_ONLY_SCHEME=<scheme> "$project_build_runner" compile`(필요 시 `test`)로 실행한다.
- 새 내부 이름은 [research.md 결정 5·7](./research.md)과 [contracts/localized-text.md](./contracts/localized-text.md)를
  따른다: 타입 `LocalizedText`, 중첩 enum은 `Feature`에서 흐름 이름·`UIComponent`에서 컴포넌트 이름·`GitIt`에서
  기능 이름이다. 멤버 이름은 카탈로그 키에서 중첩 enum 이름과 같은 첫 단어를 뗀 이름이며, 첫 단어가 다르면 키를
  그대로 쓴다(`webSheetCloseAccessibilityLabel` → `LocalizedText.WebSheet.closeAccessibilityLabel`).
- 카탈로그 항목은 [contracts/string-catalog-entry.md](./contracts/string-catalog-entry.md), 키는
  [contracts/localization-convention.md §C.4](./contracts/localization-convention.md#c4-localizationkeymd--키)를 따른다.

## 공통 작업 규칙

각 “문구 교체” 작업은 대상 파일 하나에 대해 다음을 모두 수행한다.

1. `#Preview` 블록·프리뷰 전용 타입 밖의 한국어 문자열 리터럴 가운데 사용자 노출 문구를 찾는다.
   `Logger`·`fatalError`·`precondition` 메시지와 서버·사용자 입력 값은 건드리지 않는다
   ([contracts/localization-convention.md §C.2](./contracts/localization-convention.md#c2-localizationexclusionmd--제외-대상)).
2. 각 문구를 같은 실행 단위의 카탈로그 작업에서 만든 항목의 `LocalizedText.<중첩>.<멤버>`로 바꾼다. 보간 문구는
   인자를 넘기는 `static func`를 호출한다.
3. View `Constant`의 문구 멤버를 제거하고 호출부가 `LocalizedText`를 직접 참조하게 한다. `Constant`의 다른 멤버는 유지한다.
4. `Text("리터럴")`은 `Text(LocalizedText…)`처럼 `String`을 넘기는 형태로 바꾼다.
5. 레이아웃·토큰·동작·공개 API는 바꾸지 않는다(FR-011, FR-015).

각 “카탈로그 작성” 작업은 그 단위의 문구 교체 대상 파일 전체에서 1의 문구를 모아 항목으로 만든다. 한국어 값은
원문과 글자 단위로 같게, `\n`을 유지하며, 모든 항목에 주석을 달고 보간 항목은 인자마다 의미를 적는다.
같은 한국어 값이라도 용도가 다르면 다른 키를 만든다.

## 실행 단위 소유권 규칙

- 패키지 소스·테스트와 패키지 전용 manifest는 그 패키지 실행 단위가 소유한다.
- `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`, `Target+Module.swift`,
  `Projects/AppModuleName.swift`의 공통 설정은 실행 단위 1(integration unit)이 소유한다.
- `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`는 Feature 리소스 선언을 처음 필요로 하는
  실행 단위 4가 소유한다.
- `docs/**`는 패키지에 속하지 않으며 실행 단위 3(문서 단위)이 소유한다. 단, `Localization/` 폴더를 허용하는
  `docs/conventions/file-vocabulary/shape-vocabulary.md`와 `docs/conventions/ui-component/folder-file.md`의 폴더 목록 변경은
  그 폴더를 처음 만드는 실행 단위 2(integration unit)가 소유하고, 실행 단위 3은 두 문서에 링크만 연결한다.
- 전체 기능 검증은 마지막 실행 단위 뒤에 `[no-write]`로만 둔다.
- `docs/spec-kit/043-string-localization/trouble-shooting.md`와 `tacit-knowledge.md`는 구현 작업으로 만들지 않는다.

## 설계 반영 기록

- 2026-09-24 `/speckit-analyze` 지적(C1, D1, F1, F2, F3, I1, U1)을 명세·계획에 반영한 뒤 이 목록을 다시 만들었다.
- 탭 이름(홈·프로젝트·저장·마이)은 Feature `MainShellTab`이 소유하므로 실행 단위 5.1(MainShell)에서 현지화한다.
  `UIComponent/Scaffolds/TabShell.swift`의 탭 이름은 프리뷰 전용이라 대상이 아니다.
- 대상 규모는 프리뷰·로그를 뺀 `UIComponent` 14개 파일 26곳, `Feature` 63개 파일 256곳, `GitIt` 1개 파일 4곳이다.

## 실행 단위 1: 공통 manifest (integration unit: App, Composition, Feature, Domain, Data, Infrastructure, UI)

**목표**: 모든 Tuist 프로젝트의 개발 언어를 `ko`로 바꾸고 카탈로그 심볼 생성·추출 설정을 마련한다.

**분리 불가 근거**: `ProjectName.swift`의 `Project.Options`와 `Target+Module.swift`의 `module(...)`은 7개 프로젝트가
함께 쓰는 helper다. 개발 언어가 `ko`가 아닌 상태에서 카탈로그를 추가하면 영어 환경에서 키가 노출되므로 어느
카탈로그보다 먼저 한 번에 적용해야 한다([plan.md](./plan.md#실행-단위)).

**소유 경로**: `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`

**관련 변경 시나리오**: S1

**통합 검증**: `make tuist` 후 전체 `build`, 앱 실행으로 폰트·이미지·정책 문서 표시 확인(R4)

### 구현

- [X] T001 [S1] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `Project(...)` 생성에 `Project.Options.options(automaticSchemesOptions: .disabled, defaultKnownRegions: ["ko", "Base"], developmentRegion: "ko")`를 적용하고, `resourceSynthesizers: [.assets(), .plists(), .fonts()]`로 strings 합성기를 제외한다(research 결정 3, R2)
- [X] T002 [P] [S1] `sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift`의 `module(...)` 기본 설정에 `"STRING_CATALOG_GENERATE_SYMBOLS": "YES"`와 `"SWIFT_EMIT_LOC_STRINGS": "NO"`를 추가한다(research 결정 8)
- [X] T003 [P] [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 `GitIt` target 설정에 `"SWIFT_EMIT_LOC_STRINGS": "NO"`를 추가한다. 기존 `STRING_CATALOG_GENERATE_SYMBOLS`는 유지한다

### 정리와 단위 검증

- [X] T004 [no-write] `make tuist`를 실행하고 전후 `git status --porcelain`을 비교한다. `sources/Projects/UI/Derived/Sources`에 `TuistAssets+UIComponent.swift`·`TuistFonts+DesignSystem.swift`가 계속 생성되고 `TuistStrings+*.swift`가 없는지 확인한다
- [X] T005 [no-write] `"$project_build_runner" build`로 전체 build를 통과시키고, 시뮬레이터에서 앱을 실행해 폰트·아이콘·정책 문서 화면이 변경 전과 같게 표시되는지 확인한다(R4)

**진행 점검**: T001~T005의 변경 파일과 검증 결과를 보고하고 실행 단위 2로 진행한다.

---

## 실행 단위 2: UIComponent (integration unit: UI, 문서)

**목표**: `Localization/` 폴더를 허용하는 컨벤션을 먼저 고치고, `UIComponent` 내부 고정 문구를 `UIComponent`
카탈로그와 `LocalizedText`로 옮기며 생성 심볼 규칙(R1)을 확인한다.

**분리 불가 근거**: [shape-vocabulary.md](../../docs/conventions/file-vocabulary/shape-vocabulary.md)는 표에 없는 형태
폴더를 추가하면 표를 함께 갱신하라고 요구한다. `UI/Component/Localization/`을 처음 만드는 커밋이 그 폴더를 허용하는
문서 변경을 함께 담아야 중간 커밋이 컨벤션에 없는 폴더를 갖지 않는다([plan.md](./plan.md#실행-단위)).

**소유 경로**: `docs/conventions/file-vocabulary/shape-vocabulary.md`, `docs/conventions/ui-component/folder-file.md`,
`sources/Projects/UI/Component/Resources/Localizable.xcstrings`,
`sources/Projects/UI/Component/Localization/LocalizedText.swift`, 아래 문구 교체 14개 파일,
`sources/Projects/UI/Tests/Component/Unit/Localization/LocalizedTextTests.swift`

**관련 변경 시나리오**: S1, S2

**독립 검증**: UI scheme compile·test가 통과하고, 영어 시뮬레이터에서 `LocalizedTextTests`가 한국어 값을 받는다.

### 준비와 기반

- [X] T006 [P] `docs/conventions/file-vocabulary/shape-vocabulary.md` 표에 `Feature/Shared/`(“모듈 문구 전용 타입 `LocalizedText`와 흐름별 확장”), `UI/Component/`, `App/GitIt/`(“모듈 문구 전용 타입 `LocalizedText`”)의 `Localization/` 행을 추가하고 `Feature/<흐름>/Resources/`, `UI/Component/Resources/`, `App/GitIt/Resources/` 설명에 “문구 카탈로그”를 추가한다. 링크는 실행 단위 3에서 연결한다. `최종 수정일`을 갱신한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정))
- [X] T007 [P] `docs/conventions/ui-component/folder-file.md`의 `UI/Component/` 1뎁스 허용 목록에 `Localization/`(모듈 문구 전용 타입)을 추가하고 `최종 수정일`을 갱신한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정))

- [X] T008 [S1] `sources/Projects/UI/Component/Resources/Localizable.xcstrings`를 만들고 아래 문구 교체 대상 파일의 사용자 노출 문구를 수동 항목으로 등록한다. 보간 항목(`PageIndicator` 페이지 안내 값, `ProgressSegments` 진행 레이블, `ContinuousProgressBar` 퍼센트 값, `PolicyAgreementRow` 전문 보기, `HomeProjectCard`·`LearningSetRow`·`ProjectRow` 레이블)은 이름 있는 위치 지정자로 만든다
- [X] T009 [no-write] `make tuist` 후 `GIT_IT_ONLY_SCHEME=UI "$project_build_runner" compile`을 실행하고, Xcode Attributes inspector 또는 생성 소스에서 고정 항목과 보간 항목의 생성 심볼 이름·인자 레이블이 키·위치 지정자 이름과 같은지 확인한다(R1). 다르면 이후 작업을 멈추고 결과를 보고해 `research.md` 결정 5·6과 계약 문서를 먼저 갱신한다
- [X] T010 [S1] `sources/Projects/UI/Component/Localization/LocalizedText.swift`에 `internal enum LocalizedText`와 컴포넌트별 중첩 enum(`ChoiceResultRow`, `HomeProjectCard`, `LearningSetRow`, `ProjectRow`, `SavedQuestionCard`, `AppleSignInButton`, `ChoiceAnswerOption`, `LabeledTextField`, `PolicyAgreementRow`, `ScreenControlBar`, `ContinuousProgressBar`, `PageIndicator`, `ProgressSegments`, `WebSheet`)을 만들고 항목마다 멤버를 선언한다([contracts/localized-text.md](./contracts/localized-text.md))

### 테스트

- [X] T011 [S2] `sources/Projects/UI/Tests/Component/Unit/Localization/LocalizedTextTests.swift`에 `@testable import UIComponent`로 고정 항목 하나와 보간 항목 하나가 변경 전 한국어 문구를 반환하는지 검증하는 Swift Testing 테스트를 작성한다(한국어 동작 문장 이름)

### 구현

- [X] T012 [P] [S1] `sources/Projects/UI/Component/CollectionItems/ChoiceResultRow.swift`의 문구 2곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T013 [P] [S1] `sources/Projects/UI/Component/CollectionItems/HomeProjectCard.swift`의 문구 3곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T014 [P] [S1] `sources/Projects/UI/Component/CollectionItems/LearningSetRow.swift`의 문구 1곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T015 [P] [S1] `sources/Projects/UI/Component/CollectionItems/ProjectRow.swift`의 문구 2곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T016 [P] [S1] `sources/Projects/UI/Component/CollectionItems/SavedQuestionCard.swift`의 문구 1곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T017 [P] [S1] `sources/Projects/UI/Component/Controls/AppleSignInButton.swift`의 문구 1곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T018 [P] [S1] `sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift`의 문구 3곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T019 [P] [S1] `sources/Projects/UI/Component/Controls/LabeledTextField.swift`의 문구 1곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T020 [P] [S1] `sources/Projects/UI/Component/Controls/PolicyAgreementRow.swift`의 문구 2곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T021 [P] [S1] `sources/Projects/UI/Component/Controls/ScreenControlBar.swift`의 문구 2곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T022 [P] [S1] `sources/Projects/UI/Component/Indicators/ContinuousProgressBar.swift`의 문구 2곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T023 [P] [S1] `sources/Projects/UI/Component/Indicators/PageIndicator.swift`의 문구 2곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T024 [P] [S1] `sources/Projects/UI/Component/Indicators/ProgressSegments.swift`의 문구 1곳을 `LocalizedText`로 교체한다(공통 작업 규칙)
- [X] T025 [P] [S1] `sources/Projects/UI/Component/Overlays/WebSheet.swift`의 문구 1곳을 `LocalizedText`로 교체한다(공통 작업 규칙)

### 정리와 단위 검증

- [X] T026 [no-write] `GIT_IT_ONLY_SCHEME=UI "$project_build_runner" compile`과 `GIT_IT_ONLY_SCHEME=UI "$project_build_runner" test`를 통과시키고, 기존 `UI/Tests/Component` 한국어 기대값 테스트가 수정 없이 통과하는지 확인한다. `quickstart.md` §3의 검사를 `sources/Projects/UI/Component`로 한정해 실행하고 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T006~T026의 변경 파일, R1 확인 결과와 검증 결과를 보고하고 실행 단위 3으로 진행한다.

---

## 실행 단위 3: 현지화 컨벤션 문서 (문서 단위)

**목표**: [contracts/localization-convention.md](./contracts/localization-convention.md)가 확정한 현지화 컨벤션을
`docs/`에 반영한다(FR-010). 실행 단위 2에서 확인한 R1 결과와 실제 코드 형태를 그대로 적는다.

**소유 경로**: 아래 각 작업의 `docs/` 파일

**관련 변경 시나리오**: S1, S2

**독립 검증**: `quickstart.md` §7

### 구현

- [X] T027 [S1] `docs/conventions/localization.md` 인덱스를 [계약 §B](./contracts/localization-convention.md#b-인덱스-docsconventionslocalizationmd)대로 작성한다
- [X] T028 [P] [S1] `docs/conventions/localization/target-text.md`를 [계약 §C](./contracts/localization-convention.md#c1-localizationtarget-textmd--현지화-대상)의 규칙 본문으로 작성한다
- [X] T029 [P] [S1] `docs/conventions/localization/exclusion.md`를 [계약 §C](./contracts/localization-convention.md#c2-localizationexclusionmd--제외-대상)의 규칙 본문으로 작성한다
- [X] T030 [P] [S1] `docs/conventions/localization/string-catalog.md`를 [계약 §C](./contracts/localization-convention.md#c3-localizationstring-catalogmd--string-catalog)의 규칙 본문으로 작성한다
- [X] T031 [P] [S1] `docs/conventions/localization/key.md`를 [계약 §C](./contracts/localization-convention.md#c4-localizationkeymd--키)의 규칙 본문으로 작성한다
- [X] T032 [P] [S2] `docs/conventions/localization/entry-value.md`를 [계약 §C](./contracts/localization-convention.md#c5-localizationentry-valuemd--값과-주석)의 규칙 본문으로 작성한다
- [X] T033 [P] [S1] `docs/conventions/localization/localized-text.md`를 [계약 §C](./contracts/localization-convention.md#c6-localizationlocalized-textmd--localizedtext)의 규칙 본문으로 작성한다
- [X] T034 [P] [S1] `docs/conventions/localization/call-site.md`를 [계약 §C](./contracts/localization-convention.md#c7-localizationcall-sitemd--호출부)의 규칙 본문으로 작성한다
- [X] T035 [P] [S1] `docs/conventions/localization/development-language.md`를 [계약 §C](./contracts/localization-convention.md#c8-localizationdevelopment-languagemd--개발-언어와-빌드-설정)의 규칙 본문으로 작성한다
- [X] T036 [P] [S2] `docs/conventions/localization/adding-language.md`를 [계약 §C](./contracts/localization-convention.md#c9-localizationadding-languagemd--언어-추가)의 규칙 본문으로 작성한다
- [X] T037 [P] [S1] `docs/conventions/localization/verification.md`를 [계약 §C](./contracts/localization-convention.md#c10-localizationverificationmd--검증)의 규칙 본문으로 작성한다
- [X] T038 [P] [S1] `docs/conventions/README.md`의 표에 현지화 컨벤션 행을 추가한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정)). `최종 수정일`을 갱신한다
- [X] T039 [P] [S1] `docs/conventions/file-vocabulary/shape-vocabulary.md`의 세 `Localization/` 행에 현지화 컨벤션 §4.1(`../localization.md#41-localizedtext`) 링크를 연결한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정))
- [X] T040 [P] [S1] `docs/conventions/directory-file/resources.md`의 String Catalog 소유 문장과 현지화 컨벤션 링크를 추가한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정)). `최종 수정일`을 갱신한다
- [X] T041 [P] [S1] `docs/conventions/directory-file/feature-layout.md`의 1뎁스 표 `Resources/` 설명을 “흐름이 소유하는 자산과 문구 카탈로그 (§6)”로 고친다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정)). `최종 수정일`을 갱신한다
- [X] T042 [P] [S1] `docs/conventions/ui-component/folder-file.md`의 `Localization/` 항목에 현지화 컨벤션 §4.1 링크를 연결한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정))
- [X] T043 [P] [S1] `docs/conventions/ui-component/asset.md`의 컴포넌트 고정 문구 카탈로그 소유 문장을 추가한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정)). `최종 수정일`을 갱신한다
- [X] T044 [P] [S1] `docs/conventions/view-declarations/constant.md`의 “사용자에게 보이지 않는 정적 문자열”로 고치고 사용자 노출 문구는 `LocalizedText`가 소유한다는 문장과 링크를 추가한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정)). `최종 수정일`을 갱신한다
- [X] T045 [P] [S1] `docs/conventions/view-declarations.md`의 §2.1 요약 문장을 `constant.md`와 같게 고친다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정)). `최종 수정일`을 갱신한다
- [X] T046 [P] [S1] `docs/package-rules/ui.md`의 “구현 컨벤션”에 현지화 컨벤션 링크를 추가한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정)). `최종 수정일`을 갱신한다
- [X] T047 [P] [S1] `docs/package-rules/feature.md`의 “구현 컨벤션”에 현지화 컨벤션 링크를 추가한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정)). `최종 수정일`을 갱신한다
- [X] T048 [P] [S1] `docs/package-rules/app.md`의 “정책”에 현지화 컨벤션 링크를 추가한다([계약 §D](./contracts/localization-convention.md#d-기존-문서-수정)). `최종 수정일`을 갱신한다

### 정리와 단위 검증

- [X] T049 [no-write] `quickstart.md` §7을 실행해 문서 목록, 인덱스 순서, `###`의 링크 형식, 기존 문서의 링크 전용 서술, 모든 상대 링크 대상의 존재를 확인한다

**진행 점검**: T027~T049의 변경 파일과 검증 결과를 보고하고 실행 단위 4로 진행한다.

---

## 실행 단위 4: Feature 기반과 AppEntry 흐름 (단일 패키지: Feature)

**목표**: `Feature` target의 카탈로그 리소스 선언과 `LocalizedText` 루트를 만들고, 문구가 가장 적은 `AppEntry` 흐름에 적용한다.

**소유 경로**: `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`,
`sources/Projects/Feature/Shared/Localization/LocalizedText.swift`,
`sources/Projects/Feature/Shared/Localization/LocalizedText+AppEntry.swift`,
`sources/Projects/Feature/AppEntry/Resources/AppEntry.xcstrings`, `sources/Projects/Feature/AppEntry/AppEntryScreen.swift`,
`sources/Projects/Feature/Tests/Shared/Localization/LocalizedTextTests.swift`

**관련 변경 시나리오**: S1

**독립 검증**: Feature scheme compile·test 통과, `LocalizedTextTests`가 영어 시뮬레이터에서 한국어 값을 받는다.

### 준비와 기반

- [X] T050 [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`의 `Feature` target `.module(...)`에 `resources: .resources([.glob(pattern: "*/Resources/**")])`를 추가한다. source glob과 `sourceExcludes`는 바꾸지 않는다
- [X] T051 [P] [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText.swift`에 case 없는 `internal enum LocalizedText {}` 루트를 만든다
- [X] T052 [P] [S1] `sources/Projects/Feature/AppEntry/Resources/AppEntry.xcstrings`를 만들고 `AppEntryScreen.swift`의 문구를 등록한다
- [X] T053 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+AppEntry.swift`에 `extension LocalizedText { enum AppEntry { … } }`로 항목별 멤버를 선언한다

### 테스트

- [X] T054 [S1] `sources/Projects/Feature/Tests/Shared/Localization/LocalizedTextTests.swift`에 `@testable import Feature`로 `LocalizedText.AppEntry`의 항목 하나가 변경 전 한국어 문구를 반환하는지 검증하는 테스트를 작성한다

### 구현

- [X] T055 [S1] `sources/Projects/Feature/AppEntry/AppEntryScreen.swift`의 문구 3곳을 `LocalizedText.AppEntry`로 교체한다(공통 작업 규칙)

### 정리와 단위 검증

- [X] T056 [no-write] `make tuist`(전후 `git status --porcelain` 비교) 후 `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`과 `test`를 통과시킨다

**진행 점검**: T050~T056의 변경 파일과 검증 결과를 보고하고 실행 단위 5로 진행한다.

---

## 실행 단위 5: Feature 흐름별 적용 (단일 패키지: Feature)

**목표**: 나머지 10개 흐름의 문구를 흐름 카탈로그와 `LocalizedText+<흐름>`으로 옮긴다. 흐름마다 독립적으로
되돌릴 수 있는 하위 단위이며, 흐름 사이에 의존이 없어 문구가 적은 흐름부터 진행한다(plan.md 단위 4–5 근거).

**관련 변경 시나리오**: S1, S2

**독립 검증**: 하위 단위마다 Feature scheme compile. 해당 흐름의 기존 테스트가 있으면 함께 실행한다.

### 5.1 MainShell (4개 파일, 13곳)

- [X] T057 [S1] `sources/Projects/Feature/MainShell/Resources/MainShell.xcstrings`를 만들고 아래 4개 파일의 문구를 등록한다(보간 항목 포함, S2). `MainShellTab.tabTitle`의 탭 이름(홈·프로젝트·저장·마이)을 포함한다.
- [X] T058 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+MainShell.swift`에 `extension LocalizedText { enum MainShell { … } }`로 항목별 멤버를 선언한다
- [X] T059 [P] [S1] `sources/Projects/Feature/MainShell/Router/MainShellRouter.swift`의 문구 7곳을 `LocalizedText.MainShell`로 교체한다(공통 작업 규칙)
- [X] T060 [P] [S1] `sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`의 문구 1곳을 `LocalizedText.MainShell`로 교체한다(공통 작업 규칙)
- [X] T061 [P] [S1] `sources/Projects/Feature/MainShell/Router/MainShellTab.swift`의 문구 3곳을 `LocalizedText.MainShell`로 교체한다(공통 작업 규칙)
- [X] T062 [P] [S1] `sources/Projects/Feature/MainShell/Router/SubViews/MainShellRouter+SignInPromptView.swift`의 문구 2곳을 `LocalizedText.MainShell`로 교체한다(공통 작업 규칙)
- [X] T063 [no-write] `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`을 통과시킨다. `quickstart.md` §3 검사를 `sources/Projects/Feature/MainShell`로 한정해 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T057~T063의 변경 파일과 검증 결과를 보고하고 다음 흐름으로 진행한다.

### 5.2 Saved (4개 파일, 9곳)

- [X] T064 [S1] `sources/Projects/Feature/Saved/Resources/Saved.xcstrings`를 만들고 아래 4개 파일의 문구를 등록한다(보간 항목 포함, S2).
- [X] T065 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+Saved.swift`에 `extension LocalizedText { enum Saved { … } }`로 항목별 멤버를 선언한다
- [X] T066 [P] [S1] `sources/Projects/Feature/Saved/SavedScreen.swift`의 문구 2곳을 `LocalizedText.Saved`로 교체한다(공통 작업 규칙)
- [X] T067 [P] [S1] `sources/Projects/Feature/Saved/SubViews/SavedScreen+FilterSection.swift`의 문구 2곳을 `LocalizedText.Saved`로 교체한다(공통 작업 규칙)
- [X] T068 [P] [S1] `sources/Projects/Feature/Saved/SubViews/SavedScreen+QuestionCollectionView.swift`의 문구 3곳을 `LocalizedText.Saved`로 교체한다(공통 작업 규칙)
- [X] T069 [P] [S1] `sources/Projects/Feature/Saved/ViewModels/SavedQuestionDisplay.swift`의 문구 2곳을 `LocalizedText.Saved`로 교체한다(공통 작업 규칙)
- [X] T070 [no-write] `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`을 통과시킨다. `quickstart.md` §3 검사를 `sources/Projects/Feature/Saved`로 한정해 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T064~T070의 변경 파일과 검증 결과를 보고하고 다음 흐름으로 진행한다.

### 5.3 ProjectList (3개 파일, 14곳)

- [X] T071 [S1] `sources/Projects/Feature/ProjectList/Resources/ProjectList.xcstrings`를 만들고 아래 3개 파일의 문구를 등록한다(보간 항목 포함, S2).
- [X] T072 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+ProjectList.swift`에 `extension LocalizedText { enum ProjectList { … } }`로 항목별 멤버를 선언한다
- [X] T073 [P] [S1] `sources/Projects/Feature/ProjectList/ProjectListScreen.swift`의 문구 9곳을 `LocalizedText.ProjectList`로 교체한다(공통 작업 규칙)
- [X] T074 [P] [S1] `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+NextPageFooter.swift`의 문구 2곳을 `LocalizedText.ProjectList`로 교체한다(공통 작업 규칙)
- [X] T075 [P] [S1] `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+ProjectCollectionView.swift`의 문구 3곳을 `LocalizedText.ProjectList`로 교체한다(공통 작업 규칙)
- [X] T076 [no-write] `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`을 통과시킨다. `quickstart.md` §3 검사를 `sources/Projects/Feature/ProjectList`로 한정해 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T071~T076의 변경 파일과 검증 결과를 보고하고 다음 흐름으로 진행한다.

### 5.4 Home (5개 파일, 23곳)

- [X] T077 [S1] `sources/Projects/Feature/Home/Resources/Home.xcstrings`를 만들고 아래 5개 파일의 문구를 등록한다(보간 항목 포함, S2).
- [X] T078 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+Home.swift`에 `extension LocalizedText { enum Home { … } }`로 항목별 멤버를 선언한다
- [X] T079 [P] [S1] `sources/Projects/Feature/Home/HomeScreen.swift`의 문구 4곳을 `LocalizedText.Home`로 교체한다(공통 작업 규칙)
- [X] T080 [P] [S1] `sources/Projects/Feature/Home/SubViews/HomeScreen+ProfileHeaderView.swift`의 문구 3곳을 `LocalizedText.Home`로 교체한다(공통 작업 규칙)
- [X] T081 [P] [S1] `sources/Projects/Feature/Home/SubViews/HomeScreen+ProjectSection.swift`의 문구 7곳을 `LocalizedText.Home`로 교체한다(공통 작업 규칙)
- [X] T082 [P] [S1] `sources/Projects/Feature/Home/SubViews/HomeScreen+RegistrationPanelView.swift`의 문구 6곳을 `LocalizedText.Home`로 교체한다(공통 작업 규칙)
- [X] T083 [P] [S1] `sources/Projects/Feature/Home/SubViews/HomeScreen+SignInSectionView.swift`의 문구 3곳을 `LocalizedText.Home`로 교체한다(공통 작업 규칙)
- [X] T084 [no-write] `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`을 통과시킨다. `quickstart.md` §3 검사를 `sources/Projects/Feature/Home`로 한정해 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T077~T084의 변경 파일과 검증 결과를 보고하고 다음 흐름으로 진행한다.

### 5.5 Onboarding (6개 파일, 25곳)

- [X] T085 [S1] `sources/Projects/Feature/Onboarding/Resources/Onboarding.xcstrings`를 만들고 아래 6개 파일의 문구를 등록한다(보간 항목 포함, S2).
- [X] T086 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+Onboarding.swift`에 `extension LocalizedText { enum Onboarding { … } }`로 항목별 멤버를 선언한다
- [X] T087 [P] [S1] `sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift`의 문구 12곳을 `LocalizedText.Onboarding`로 교체한다(공통 작업 규칙)
- [X] T088 [P] [S1] `sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementScreen.swift`의 문구 3곳을 `LocalizedText.Onboarding`로 교체한다(공통 작업 규칙)
- [X] T089 [P] [S1] `sources/Projects/Feature/Onboarding/LegalAgreement/SubViews/LegalAgreementScreen+AllAgreementRow.swift`의 문구 1곳을 `LocalizedText.Onboarding`로 교체한다(공통 작업 규칙)
- [X] T090 [P] [S1] `sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift`의 문구 3곳을 `LocalizedText.Onboarding`로 교체한다(공통 작업 규칙)
- [X] T091 [P] [S1] `sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+PageView.swift`의 문구 3곳을 `LocalizedText.Onboarding`로 교체한다(공통 작업 규칙)
- [X] T092 [P] [S1] `sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+SignInSection.swift`의 문구 3곳을 `LocalizedText.Onboarding`로 교체한다(공통 작업 규칙)
- [X] T093 [no-write] `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`을 통과시킨다. `quickstart.md` §3 검사를 `sources/Projects/Feature/Onboarding`로 한정해 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T085~T093의 변경 파일과 검증 결과를 보고하고 다음 흐름으로 진행한다.

### 5.6 ProjectDetail (6개 파일, 25곳)

- [ ] T094 [S1] `sources/Projects/Feature/ProjectDetail/Resources/ProjectDetail.xcstrings`를 만들고 아래 6개 파일의 문구를 등록한다(보간 항목 포함, S2).
- [ ] T095 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+ProjectDetail.swift`에 `extension LocalizedText { enum ProjectDetail { … } }`로 항목별 멤버를 선언한다
- [ ] T096 [P] [S1] `sources/Projects/Feature/ProjectDetail/ProjectDetailScreen.swift`의 문구 13곳을 `LocalizedText.ProjectDetail`로 교체한다(공통 작업 규칙)
- [ ] T097 [P] [S1] `sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouter.swift`의 문구 4곳을 `LocalizedText.ProjectDetail`로 교체한다(공통 작업 규칙)
- [ ] T098 [P] [S1] `sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift`의 문구 1곳을 `LocalizedText.ProjectDetail`로 교체한다(공통 작업 규칙)
- [ ] T099 [P] [S1] `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+DetailContentView.swift`의 문구 2곳을 `LocalizedText.ProjectDetail`로 교체한다(공통 작업 규칙)
- [ ] T100 [P] [S1] `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+RepositorySummaryView.swift`의 문구 3곳을 `LocalizedText.ProjectDetail`로 교체한다(공통 작업 규칙)
- [ ] T101 [P] [S1] `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+SetListSection.swift`의 문구 2곳을 `LocalizedText.ProjectDetail`로 교체한다(공통 작업 규칙)
- [ ] T102 [no-write] `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`을 통과시킨다. `quickstart.md` §3 검사를 `sources/Projects/Feature/ProjectDetail`로 한정해 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T094~T102의 변경 파일과 검증 결과를 보고하고 다음 흐름으로 진행한다.

### 5.7 ShareRegistration (2개 파일, 20곳)

- [ ] T103 [S1] `sources/Projects/Feature/ShareRegistration/Resources/ShareRegistration.xcstrings`를 만들고 아래 2개 파일의 문구를 등록한다(보간 항목 포함, S2). `SharedRepositoryRegistrationFeature`의 실패 사유 문구를 포함한다.
- [ ] T104 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+ShareRegistration.swift`에 `extension LocalizedText { enum ShareRegistration { … } }`로 항목별 멤버를 선언한다
- [ ] T105 [P] [S1] `sources/Projects/Feature/ShareRegistration/ShareRegistrationScreen.swift`의 문구 12곳을 `LocalizedText.ShareRegistration`로 교체한다(공통 작업 규칙)
- [ ] T106 [P] [S1] `sources/Projects/Feature/ShareRegistration/SharedRepositoryRegistrationFeature.swift`의 문구 8곳을 `LocalizedText.ShareRegistration`로 교체한다(공통 작업 규칙)
- [ ] T107 [no-write] `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`을 통과시킨다. `quickstart.md` §3 검사를 `sources/Projects/Feature/ShareRegistration`로 한정해 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T103~T107의 변경 파일과 검증 결과를 보고하고 다음 흐름으로 진행한다.

### 5.8 Quiz (11개 파일, 33곳)

- [ ] T108 [S1] `sources/Projects/Feature/Quiz/Resources/Quiz.xcstrings`를 만들고 아래 11개 파일의 문구를 등록한다(보간 항목 포함, S2).
- [ ] T109 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+Quiz.swift`에 `extension LocalizedText { enum Quiz { … } }`로 항목별 멤버를 선언한다
- [ ] T110 [P] [S1] `sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionFeature.swift`의 문구 1곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T111 [P] [S1] `sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionScreen.swift`의 문구 3곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T112 [P] [S1] `sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroScreen.swift`의 문구 3곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T113 [P] [S1] `sources/Projects/Feature/Quiz/LearningSetIntro/SubViews/LearningSetIntroScreen+IntroContentView.swift`의 문구 2곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T114 [P] [S1] `sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift`의 문구 7곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T115 [P] [S1] `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+EssayResultSection.swift`의 문구 2곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T116 [P] [S1] `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+QuestionPrompt.swift`의 문구 1곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T117 [P] [S1] `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+SourceSheet.swift`의 문구 3곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T118 [P] [S1] `sources/Projects/Feature/Quiz/QuestionSolving/ViewModels/ChoiceOptionDisplay.swift`의 문구 4곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T119 [P] [S1] `sources/Projects/Feature/Quiz/QuestionSolving/ViewModels/QuestionSourceDisplay.swift`의 문구 5곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T120 [P] [S1] `sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift`의 문구 2곳을 `LocalizedText.Quiz`로 교체한다(공통 작업 규칙)
- [ ] T121 [no-write] `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`을 통과시킨다. 기존 한국어 기대값 테스트 `Feature/Tests/Quiz/LearningCompletion/LearningCompletionFeatureTests.swift`, `Feature/Tests/Quiz/QuestionSolving/QuestionSolvingFeatureTests.swift`, `Feature/Tests/Quiz/QuestionSolving/ViewModels/ChoiceOptionDisplayTests.swift`, `Feature/Tests/Quiz/QuestionSolving/ViewModels/QuestionSourceDisplayTests.swift`가 수정 없이 통과하는지 `test`로 확인한다. `quickstart.md` §3 검사를 `sources/Projects/Feature/Quiz`로 한정해 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T108~T121의 변경 파일과 검증 결과를 보고하고 다음 흐름으로 진행한다.

### 5.9 ProjectRegistration (10개 파일, 43곳)

- [ ] T122 [S1] `sources/Projects/Feature/ProjectRegistration/Resources/ProjectRegistration.xcstrings`를 만들고 아래 10개 파일의 문구를 등록한다(보간 항목 포함, S2).
- [ ] T123 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+ProjectRegistration.swift`에 `extension LocalizedText { enum ProjectRegistration { … } }`로 항목별 멤버를 선언한다
- [ ] T124 [P] [S1] `sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationScreen.swift`의 문구 3곳을 `LocalizedText.ProjectRegistration`로 교체한다(공통 작업 규칙)
- [ ] T125 [P] [S1] `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+ChecklistView.swift`의 문구 9곳을 `LocalizedText.ProjectRegistration`로 교체한다(공통 작업 규칙)
- [ ] T126 [P] [S1] `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+FailureView.swift`의 문구 3곳을 `LocalizedText.ProjectRegistration`로 교체한다(공통 작업 규칙)
- [ ] T127 [P] [S1] `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GeneratingView.swift`의 문구 3곳을 `LocalizedText.ProjectRegistration`로 교체한다(공통 작업 규칙)
- [ ] T128 [P] [S1] `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GenerationReminderSheet.swift`의 문구 4곳을 `LocalizedText.ProjectRegistration`로 교체한다(공통 작업 규칙)
- [ ] T129 [P] [S1] `sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionScreen.swift`의 문구 5곳을 `LocalizedText.ProjectRegistration`로 교체한다(공통 작업 규칙)
- [ ] T130 [P] [S1] `sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen.swift`의 문구 3곳을 `LocalizedText.ProjectRegistration`로 교체한다(공통 작업 규칙)
- [ ] T131 [P] [S1] `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift`의 문구 1곳을 `LocalizedText.ProjectRegistration`로 교체한다(공통 작업 규칙)
- [ ] T132 [P] [S1] `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputScreen.swift`의 문구 4곳을 `LocalizedText.ProjectRegistration`로 교체한다(공통 작업 규칙)
- [ ] T133 [P] [S1] `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/SubViews/RepositoryLinkInputScreen+GuideSectionView.swift`의 문구 8곳을 `LocalizedText.ProjectRegistration`로 교체한다(공통 작업 규칙)
- [ ] T134 [no-write] `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`을 통과시킨다. `quickstart.md` §3 검사를 `sources/Projects/Feature/ProjectRegistration`로 한정해 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T122~T134의 변경 파일과 검증 결과를 보고하고 다음 흐름으로 진행한다.

### 5.10 Settings (11개 파일, 50곳)

- [ ] T135 [S1] `sources/Projects/Feature/Settings/Resources/Settings.xcstrings`를 만들고 아래 11개 파일의 문구를 등록한다(보간 항목 포함, S2).
- [ ] T136 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+Settings.swift`에 `extension LocalizedText { enum Settings { … } }`로 항목별 멤버를 선언한다
- [ ] T137 [P] [S1] `sources/Projects/Feature/Settings/Profile/ProfileScreen.swift`의 문구 3곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T138 [P] [S1] `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+LoadFailureView.swift`의 문구 3곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T139 [P] [S1] `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+StatisticsCardView.swift`의 문구 5곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T140 [P] [S1] `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+WeeklyChartView.swift`의 문구 2곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T141 [P] [S1] `sources/Projects/Feature/Settings/Profile/ViewModels/ProfileDisplay.swift`의 문구 3곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T142 [P] [S1] `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`의 문구 14곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T143 [P] [S1] `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift`의 문구 6곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T144 [P] [S1] `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift`의 문구 2곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T145 [P] [S1] `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift`의 문구 2곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T146 [P] [S1] `sources/Projects/Feature/Settings/Shared/ViewModels/CareerLevelDisplay.swift`의 문구 9곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T147 [P] [S1] `sources/Projects/Feature/Settings/Shared/ViewModels/PositionDisplay.swift`의 문구 1곳을 `LocalizedText.Settings`로 교체한다(공통 작업 규칙)
- [ ] T148 [no-write] `GIT_IT_ONLY_SCHEME=Feature "$project_build_runner" compile`을 통과시킨다. 기존 한국어 기대값 테스트 `Feature/Tests/Settings/Profile/ViewModels/ProfileDisplayTests.swift`가 수정 없이 통과하는지 `test`로 확인한다. `quickstart.md` §3 검사를 `sources/Projects/Feature/Settings`로 한정해 결과가 제외 대상뿐인지 확인한다

**진행 점검**: T135~T148의 변경 파일과 검증 결과를 보고하고 다음 흐름으로 진행한다.

---

## 실행 단위 6: GitIt (단일 패키지: App)

**목표**: 로컬 알림 문구를 `GitIt` 카탈로그와 `LocalizedText`로 옮기고 문구만 보유하던 `GenerationReminderContent`를 제거한다.

**소유 경로**: `sources/Projects/App/GitIt/Resources/Localizable.xcstrings`,
`sources/Projects/App/GitIt/Localization/LocalizedText.swift`, `sources/Projects/App/GitIt/GitItApp.swift`,
`sources/Projects/App/GitIt/GenerationReminderContent.swift`(삭제),
`sources/Projects/App/Tests/GitIt/Localization/LocalizedTextTests.swift`

**관련 변경 시나리오**: S1

**독립 검증**: AppTests scheme compile·test 통과

### 준비와 기반

- [ ] T149 [S1] `sources/Projects/App/GitIt/Resources/Localizable.xcstrings`를 만들고 `GenerationReminderContent.swift`의 알림 제목·본문 4개(생성 완료 제목·본문, 생성 실패 제목·본문)를 등록한다
- [ ] T150 [S1] `sources/Projects/App/GitIt/Localization/LocalizedText.swift`에 `internal enum LocalizedText`와 중첩 `enum GenerationReminder`를 만들고 4개 멤버를 선언한다

### 테스트

- [ ] T151 [S1] `sources/Projects/App/Tests/GitIt/Localization/LocalizedTextTests.swift`에 `@testable import GitIt`로 `LocalizedText.GenerationReminder`의 4개 멤버가 변경 전 한국어 문구를 반환하는지 검증하는 테스트를 작성한다

### 구현

- [ ] T152 [S1] `sources/Projects/App/GitIt/GitItApp.swift`에서 `GenerationReminderContent` 참조 4곳을 `LocalizedText.GenerationReminder` 멤버로 교체한다
- [ ] T153 [S1] `sources/Projects/App/GitIt/GenerationReminderContent.swift`를 삭제하고 저장소에 다른 참조가 없는지 확인한다

### 정리와 단위 검증

- [ ] T154 [no-write] `make tuist`(전후 `git status --porcelain` 비교) 후 `GIT_IT_ONLY_SCHEME=AppTests "$project_build_runner" compile`과 `test`를 통과시킨다

**진행 점검**: T149~T154의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 진행한다.

---

## 전체 완료 검증

**선행 조건**: 실행 단위 6의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할 마지막 커밋 단위를 아직
commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 실행 단위 6의 마지막 커밋 단위에 배정한다. 모든 검증과 필수
`after_implement` hook(`speckit.swift-format.run`)을 마친 뒤 그 단위를 최종 commit한다. 이미 파일 변경 단위가
모두 commit된 단순 재개에서는 `tasks.md` 완료 표시를 위한 별도 최종 검증 단위를 둔다.

- [ ] T155 [no-write] `make tuist` 후 `"$project_build_runner" build`, `compile`, `test`를 순서대로 실행해 모두 통과시킨다(SC-004)
- [ ] T156 [no-write] `quickstart.md` §1·§3·§4를 실행해 strings 합성 파일 부재, 한국어 리터럴 잔여가 제외 대상뿐임(SC-001), 13개 카탈로그의 `sourceLanguage`·주석·`manual`·키 형식(SC-003)을 확인한다
- [ ] T157 [no-write] [S1] `quickstart.md` §5를 한국어 시뮬레이터에서 실행해 대표 화면 6종과 로컬 알림 2종, VoiceOver 레이블이 변경 전과 같은지 확인한다(SC-002)
- [ ] T158 [no-write] [S2] `quickstart.md` §5의 저장 필터 개수(0·1·여러 개)와 페이지·진행률 접근성 값 등 보간 문구가 변경 전과 같은지 확인한다
- [ ] T159 [no-write] `quickstart.md` §6을 영어 시뮬레이터에서 실행해 키·빈 문자열 노출이 0건이고 모든 문구가 한국어인지 확인한다(SC-006, FR-008)
- [ ] T160 [no-write] `quickstart.md` §8을 이 checkout이 아닌 scratchpad의 임시 `git worktree`에서 실행해 카탈로그 값만 바꿔 문구가 바뀌는지 확인하고, 임시 worktree를 제거한다(시나리오 1 수용 2). 이 checkout의 `git status`가 전후 같아야 한다
- [ ] T161 [no-write] `quickstart.md` §7을 다시 실행해 최종 코드와 현지화 컨벤션 문서가 일치하는지 확인한다(FR-010)

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- 순서: 실행 단위 1(공통 manifest) → 2(UIComponent) → 3(컨벤션 문서) → 4(Feature 기반) → 5(Feature 흐름별)
  → 6(GitIt) → 전체 완료 검증.
- 근거: [architecture.md §3.1](../../docs/architecture.md)의 `App → Feature → UI` 의존에서 UI → Feature → App 순서를
  도출했다. 공통 manifest는 모든 카탈로그보다 먼저 필요하다. `Localization/` 폴더 허용 문서는 그 폴더를 처음 만드는
  단위 2의 첫 작업이고, 나머지 컨벤션 문서는 R1 확인(단위 2) 뒤, Feature 일괄 적용 전에 둔다. 변경하지 않는 `Composition`·`Domain`·`Data`·`Infrastructure`는 건너뛴다.
- 실행 단위 5의 흐름 순서(MainShell → Saved → ProjectList → Home → Onboarding → ProjectDetail → ShareRegistration →
  Quiz → ProjectRegistration → Settings)는 문구가 적은 흐름부터이며 흐름 사이 의존은 없다. 구현이 끝날 때까지 바꾸지 않는다.
- 각 단위의 변경 파일과 검증 결과를 보고하되 같은 기능 범위에서는 반복 승인을 요구하지 않는다.
- R1 확인 결과가 계약과 다르면(실행 단위 2의 확인 작업) 중단하고 계획 산출물 갱신을 요청한다. 그 밖에 새 범위,
  파괴적 작업, remote·외부 상태 변경, 새 제품 결정이 필요할 때만 중단한다.

### 변경 시나리오 추적성

- **S1(고정 문구)**: 실행 단위 1–6의 카탈로그·`LocalizedText`·문구 교체 작업, 전체 검증의 §5·§6·§8.
  독립 수용 기준: 한국어 환경에서 모든 화면 문구가 동일하고 카탈로그 값만 고쳐 문구가 바뀐다.
- **S2(보간·수량 문구)**: 각 카탈로그 작업의 보간 항목, UIComponent `LocalizedTextTests`, 문서 `entry-value.md`·
  `adding-language.md`, 전체 검증의 보간 확인. 독립 수용 기준: 값 0·1·여러 개에서 한국어 표시가 동일하고 항목에
  인자 의미 주석이 있다.

### 실행 단위 내부 실행

- 카탈로그 작업 → (UIComponent는 R1 확인) → `LocalizedText` 작업 → 테스트 → 문구 교체 순서다. 문구 교체 작업은
  카탈로그·`LocalizedText` 작업 완료 뒤 `[P]`로 병렬 실행할 수 있다.
- `[P]`는 현재 실행 단위(실행 단위 5는 현재 흐름 하위 단위) 안의 서로 다른 파일에만 사용한다.
- 서로 다른 실행 단위의 Git index·같은 파일 변경은 병렬 실행하지 않는다. `LocalizedText+<흐름>.swift`는 흐름마다 다른 파일이다.
- `/speckit-implement`는 파일을 수정하기 전에 현재 단위의 미완료 작업을 하나의 목적과 독립적인 rollback 경계를 갖는
  순서화된 커밋 단위로 묶는다. 각 커밋 단위는 포함 작업 ID, 정확한 파일 경로, 검증과 커밋 메시지를 먼저 제시하고,
  검증과 `[X]` 표시 뒤 해당 파일과 이 `tasks.md`만 stage·commit한다.
- 마지막 단위는 전체 완료 검증과 필수 `after_implement` hook이 끝날 때까지 commit하지 않는다.

## 병렬 실행 예시

- 실행 단위 1: T002와 T003은 서로 다른 파일이라 동시에 수정할 수 있다.
- 실행 단위 2: `LocalizedText.swift` 작업 뒤 14개 컴포넌트 파일의 문구 교체를 동시에 진행할 수 있다.
- 실행 단위 2: T006과 T007은 서로 다른 문서라 동시에 수정할 수 있다.
- 실행 단위 3: 인덱스 작성 뒤 참고 단위 10개와 기존 문서 11개를 동시에 작성할 수 있다.
- 실행 단위 5.8(Quiz): 카탈로그와 확장 작업 뒤 11개 파일의 문구 교체를 동시에 진행할 수 있다.

## 구현 전략

1. 이 tasks.md의 blob hash와 전체 diff를 기준선으로 고정하고 첫 미완료 실행 단위를 선택한다.
2. 선택한 단위의 미완료 작업을 논리적 커밋 단위로 설계한다(예: 실행 단위 5는 흐름마다 한 커밋 단위).
3. 각 단위의 구현·검증·완료 표시·커밋을 순서대로 완료하고 생성된 커밋을 확인한다.
4. 최소 가치 범위는 실행 단위 1–2(개발 언어 전환과 UIComponent 적용)다. 새 권한이 필요하지 않으므로 이어서 진행한다.
5. 마지막 단위에서 전체 읽기 전용 검증, 변경 시나리오 수용 검증, 필수 `after_implement` hook을 실행하고 결과를
   재검증한 뒤 최종 commit한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 문구 교체 작업의 “N곳”은 2026-09-24 조사에서 프리뷰·로그를 뺀 한국어 리터럴 줄 수이며, 실제 교체는 공통 작업 규칙의 판정을 따른다.
- 문제 해결과 암묵지 기록은 작업 ID로 만들지 않는다.
