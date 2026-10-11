# 구현 계획: 사용자 노출 문자열 현지화 적용

**Git-flow 유형**: `feature`

**브랜치**: `feature/string-localization`

**날짜**: 2026-09-24 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/043-string-localization/spec.md`의 기능 명세

## 요약

`UIComponent`, `Feature`, `GitIt`이 소스에 직접 쓰는 한국어 사용자 노출 문구(286곳)를 모듈이 소유하는
String Catalog로 옮긴다. 카탈로그의 수동 항목(의미 기반 키, 한국어 값, 번역 주석)이 정본이고, Xcode
생성 심볼을 감싼 모듈별 `internal enum LocalizedText`가 `String`을 제공하는 유일한 진입점이다. 모든
Tuist 프로젝트의 개발 언어를 `ko`로 바꿔 어떤 기기 언어에서도 한국어가 표시되게 한다. 화면 결과,
컴포넌트 공개 API, 기존 한국어 기대값 테스트는 바뀌지 않는다. 결정 근거는 [research.md](./research.md)다.

## 기술 맥락

**언어/버전**: Swift 5 language mode(`SWIFT_VERSION = 5.0`), Xcode 26.6

**주요 의존성**: SwiftUI, Foundation `LocalizedStringResource`·`String(localized:)`, Xcode String Catalog
심볼 생성(`STRING_CATALOG_GENERATE_SYMBOLS`), Tuist 4.202.2

**저장소**: N/A. 빌드에 포함되는 `.xcstrings` 리소스만 추가한다

**테스트**: Swift Testing(`import Testing`), 기존 `TestStore` 기반 Feature 테스트

**대상 플랫폼**: iOS 26.0 이상, 시뮬레이터 `iPhone 17 Pro`

**프로젝트 유형**: 모바일 앱(Tuist 멀티 패키지 workspace)

**성능 목표**: 추가 목표 없음. 문구 조회는 호출 시 번들 테이블 조회 한 번이며 화면 렌더링 비용을 바꾸지 않는다

**제약 조건**: 한국어 표시 결과 글자 단위 동일(FR-002), 컴포넌트 공개 API 불변(FR-015), 의존 방향 불변(FR-011),
지원 언어 `ko`만(FR-008)

**규모/범위**: 프리뷰·로그를 뺀 `UIComponent` 14개 파일 26곳, `Feature` 11개 흐름 63개 파일 256곳, `GitIt` 1개 파일 4곳.
카탈로그 13개(`UIComponent` 1, `Feature` 11, `GitIt` 1)

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1. 명시적인 경계 | 통과 | 새 의존성 없음. `LocalizedText`는 `internal`이라 모듈 밖으로 나가지 않는다 |
| 2. 상태와 데이터 안전성 | 통과 | 런타임 상태·저장 형식 변경 없음 |
| 3. 검증 가능한 변경 | 통과 | build·compile·test와 [quickstart.md](./quickstart.md)의 검사로 검증한다 |
| 4·5. 수정 경로 | 통과 | 이 명령은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 작성했다 |
| 6. 한국어 산출물 | 통과 | 모든 산출물을 한국어로 작성했다 |
| 7. 위험 기반 실행 단위 | 통과 | 아래 “실행 단위”의 위상 순서와 integration unit 근거 참고 |
| 8. Git-flow 브랜치 | 통과 | `feature/string-localization`, 이번 명세에서 생성 |
| 9. 세션 지식 기록 | 해당 없음 | 기록 조건을 충족한 사건이 없다 |
| 10. 네이밍 | 통과 | `LocalizedText`, 키 규칙은 [research.md 결정 5·7](./research.md) |
| 11. 컨벤션 근거 | 통과(공백 기록) | 아래 “적용 컨벤션”. `Localization/` 형태 폴더는 컨벤션 공백이며 복잡성 추적에 기록 |

**설계 후 재점검(1단계 이후)**: 통과. 설계가 새 패키지 의존성, 공개 API 변경, Feature의 UI 소유를 만들지 않는다.
컨벤션 공백 두 가지(`Localization/` 형태 폴더, 현지화 문구의 선언 위치)는 사용자 결정으로 확정했고, 새 현지화
컨벤션의 구조와 규칙 본문을 [contracts/localization-convention.md](./contracts/localization-convention.md)로 확정해
단위 3에서 컨벤션 문서로 반영한다.

**브랜치 네임스페이스**: 이 헌법 개정 후 새로 생성한 브랜치는 `feature/`, `hotfix/`,
`release/` 중 목적에 맞는 네임스페이스를 사용해야 한다. 개정 전에 생성된 기존 브랜치는
소급해 바꾸지 않고 기존 브랜치임을 기록한다. `/speckit-specify`는 명세 산출물을 만들기
전에 현재 HEAD에서 검증된 브랜치를 직접 생성하거나 이미 현재인 동일 브랜치를 재사용해야
하며, branch 생성에 실패한 명세로 계획을 진행하지 않는다. `before_specify` hook은 브랜치
생성이나 전환을 대신 수행하지 않는다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정할 수 있다. 이 산출물 밖의 구현 파일은 정확한
경로를 `tasks.md`에 기록하며 계획 단계에서는 수정하지 않는다.

**세션 지식 기록**: 적용 여부와 문턱은 Constitution 원칙 9를 정본으로 따른다. 기록 조건을
충족하면 해당 전용 스킬을 별도로 사용하며 계획 산출물이나 구현 작업으로 만들지 않는다.

**Git 실행 직렬화**: 같은 checkout에서 `git commit`, pre-commit과 staged formatter처럼
Git index, 작업 파일 또는 공유 formatter cache를 사용하는 변경 체인은 하나만 실행한다.
기존 체인의 종료와 결과를 확인하기 전에는 재시도하지 않으며, 중복 실행을 발견하면 실행
소유자와 index·작업 파일 상태를 확인하고 사용자 승인 없이 임의로 종료하지 않는다. 읽기
전용 Git 조회, 서로 다른 checkout과 실행별로 격리된 build·test 경로는 이 제한에서 제외한다.

**커밋 단위 구현**: `/speckit-implement`는 미완료 작업을 실행 시점에 논리적이고 독립적으로
되돌릴 수 있는 커밋 단위로 설계한다. 단일 패키지가 기본이며, 분리하면 compile되지 않는
공개 API 이전이나 공용 manifest 변경은 근거와 통합 검증을 가진 다중 패키지 단위로 묶는다.
각 단위는 작업 ID, 정확한 파일,
검증과 커밋 메시지를 명시하고, 구현·검증·`tasks.md` 완료 표시·정확한 staging·commit 성공
확인을 마친 뒤에만 다음 단위로 진행한다. 훅을 우회하거나 무관한 변경을 포함하거나 amend,
rebase, push하지 않는다. 마지막 적용 패키지의 마지막 단위는 전체 읽기 전용 검증과 필수
`after_implement` hook까지 실행·재검증한 뒤 최종 commit한다. 시작 전 tasks.md의 일반 변경은
blob hash와 전체 diff로 기준선을 고정하며 별도 commit은 선택 사항이다. 확정된 기능 범위의
후속 단위와 읽기 전용 전체 검증은 반복 승인 없이 진행하고 새 권한이 필요한 경우에만 중단한다.

**컨벤션 근거**: 설계 전에 `.specify/memory/constitution.md`, 공통 컨벤션
인덱스(`docs/conventions/README.md`), 변경 대상 패키지의 `docs/package-rules/<패키지>.md`와
`docs/architecture.md`를 읽는다. 문서 루트는 `GIT_IT_DOCS_ROOT` 판독 결과를 사용한다.
아래 "적용 컨벤션"에 적용한 문서와 그 문서가 이번 설계에 부과한 제약을 저장소
상대경로로 기록하고, 컨벤션과 명세·기존 관행이 충돌하면 계획을 중단한다. 컨벤션이 이번
요구를 다루지 않으면 결정과 근거를 복잡성 추적 또는 `research.md`에 남기고 컨벤션 문서
자체는 수정하지 않는다.

**책임 기반 네이밍**: 프로젝트가 소유하는 공개 API와 경계를 넘는 값은 실제 책임과 필요한
최소 문맥을 드러내야 한다. 표면적인 통일만을 위한 공통 접두어·접미어·축약은 적용하지 않고,
저장·전달되는 값은 독립적으로 목적을 식별할 수 있게 계획한다. 외부 계약의 고정 이름은
보존하고 공급자 중립 경계에는 특정 공급자나 저장 기술의 용어를 노출하지 않는다. 네이밍과
설계·동작 변경이 함께 필요하면 범위와 검증을 분리한다. `docs/conventions/naming.md`가 없으면
Constitution 원칙 10을 직접 적용하고, 문서가 작성된 뒤에는 세부 기준과 예외를 함께 참조한다.

**실행 단위 진행**: 현재 명세가 변경하는 패키지를 식별하고 의존성 위상 순서로 구현 경계를
계획한다. 단일 패키지 단위를 기본으로 하되 분리하면 중간 상태가 깨지는 경우에는 불가분한
다중 패키지 integration unit을 사용한다. 각 단위의 변경 파일과 검증 결과를 진행 상황으로
보고하며 같은 기능 범위의 다음 단위는 반복 승인 없이 진행한다. 공용 구성 파일이나 공개 API
이전이 여러 패키지를 함께 바꿔야 안전하면 분리 불가 근거, 정확한 경로와 통합 검증을 기록한다.
패키지에 속하지 않는 파일도 책임 단위에 배정하며, 배정할 수 없으면 계획을 중단한다.

## 적용 컨벤션

| 문서 | 이번 설계에 부과한 제약 |
| --- | --- |
| [docs/architecture.md](../../docs/architecture.md) | §3.1 의존성 표(`App → Feature → UI`)로 구현 순서를 UI → Feature → App으로 정한다. 새 패키지 의존성을 만들지 않는다 |
| [docs/package-rules/ui.md](../../docs/package-rules/ui.md) | `UIComponent`는 Feature 문맥을 참조하지 않는다. 컴포넌트 고정 문구는 `UIComponent`가 소유하고 공개 입력(`String`, `DisplayModel`)은 유지한다 |
| [docs/package-rules/feature.md](../../docs/package-rules/feature.md) | Feature 문구는 Feature가 소유하고 UIComponent 공개 API로만 전달한다. 표시 모델·Reducer는 `LocalizedText`만 참조하고 컴포넌트 `DisplayModel`을 보유하지 않는 기존 제약을 유지한다 |
| [docs/package-rules/app.md](../../docs/package-rules/app.md) | `GitIt`은 UI 패키지에 의존하지 않는다. 알림 문구는 `GitIt` 자신의 카탈로그가 소유한다 |
| [docs/conventions/directory-file/resources.md](../../docs/conventions/directory-file/resources.md) | 카탈로그는 소스 루트 아래 `Resources/`에 두고 Swift 형태 폴더에 섞지 않는다 |
| [docs/conventions/directory-file/feature-layout.md](../../docs/conventions/directory-file/feature-layout.md) | Feature 흐름 1뎁스는 `Router/`·`<화면>/`·`Previews/`·`Shared/`·`Resources/`뿐이다. 카탈로그는 `<흐름>/Resources/`, 흐름 공용이 아닌 Swift 선언은 흐름 1뎁스에 두지 않는다 |
| [docs/conventions/directory-file/tuist-manifest.md](../../docs/conventions/directory-file/tuist-manifest.md) | 리소스 glob은 manifest helper에서 선언하고 source glob은 바꾸지 않는다. 폴더 추가와 manifest 갱신은 같은 커밋에서 한다 |
| [docs/conventions/file-vocabulary/shape-vocabulary.md](../../docs/conventions/file-vocabulary/shape-vocabulary.md) | 표에 없는 형태 폴더(`Localization/`)를 추가하면 같은 PR에서 표를 갱신한다 |
| [docs/conventions/file-vocabulary/nested-type-split.md](../../docs/conventions/file-vocabulary/nested-type-split.md) | Feature `LocalizedText`의 흐름별 중첩 enum은 `LocalizedText+<흐름>.swift`에 `extension`으로 선언한다 |
| [docs/conventions/ui-component/folder-file.md](../../docs/conventions/ui-component/folder-file.md) | `UI/Component/` 1뎁스 허용 목록에 `Localization/`을 추가해야 한다. UIComponent 선언은 중첩 타입을 파일로 나누지 않으므로 `LocalizedText`는 한 파일이다 |
| [docs/conventions/ui-component/asset.md](../../docs/conventions/ui-component/asset.md) | 컴포넌트 자산은 `Component/Resources/`가 소유한다. Feature는 UIComponent 번들을 직접 해석하지 않는다 |
| [docs/conventions/view-declarations/constant.md](../../docs/conventions/view-declarations/constant.md) | `Constant`는 View 하나에서만 의미 있는 비현지화 값을 소유한다. 현지화 문구는 사용자 결정으로 `LocalizedText`가 소유하며 이 문서에 그 경계를 명시한다 |
| [docs/conventions/naming.md](../../docs/conventions/naming.md) | `LocalizedText`·키 이름은 책임을 드러내고 축약(`L10n`)·흐름 이름 반복을 피한다 |
| [docs/conventions/test.md](../../docs/conventions/test.md) · [test/swift-testing.md](../../docs/conventions/test/swift-testing.md) · [test/korean-behavior-sentence.md](../../docs/conventions/test/korean-behavior-sentence.md) | 새 테스트는 Swift Testing, 한국어 동작 문장 이름, production 형태 폴더를 미러링한 위치에 둔다 |
| [docs/conventions/view/component-init.md](../../docs/conventions/view/component-init.md) | 컴포넌트 초기화 인자와 시각 속성 메서드 계약을 바꾸지 않는다 |
| [docs/conventions/common/document-structure.md](../../docs/conventions/common/document-structure.md) | 새 현지화 컨벤션은 인덱스(`##` 추상 원칙 + `###` 링크)와 참고 단위 문서로 나눈다. 체크리스트는 인덱스가 소유한다 |
| [docs/conventions/common/document-format.md](../../docs/conventions/common/document-format.md) | 인덱스는 제목·상태·날짜 → 목적 → 적용 범위 → 세부 규칙 → 검토 체크리스트 → 관련 문서 → 문서 변경 기준 순서다 |
| [docs/conventions/common/cross-reference.md](../../docs/conventions/common/cross-reference.md) | 현지화 규칙은 현지화 컨벤션 한 곳이 소유한다. 기존 문서에는 한 줄 요약과 링크만 두고, 기존 인덱스 경로·제목은 유지한다 |

## 프로젝트 구조

### 문서(이 기능)

```text
specs/043-string-localization/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── localized-text.md
│   └── string-catalog-entry.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks 산출물
```

### 소스 코드(저장소 루트)

```text
sources/
├── Tuist/ProjectDescriptionHelpers/
│   ├── ProjectName.swift                  # developmentRegion·defaultKnownRegions·resourceSynthesizers
│   ├── Target+Module.swift                # module(): 심볼 생성 켜기, 컴파일러 추출 끄기
│   └── Projects/
│       ├── AppModuleName.swift            # GitIt: 컴파일러 추출 끄기
│       └── FeatureModuleName.swift        # Feature: `*/Resources/**` 리소스 선언
└── Projects/
    ├── UI/
    │   ├── Component/
    │   │   ├── Localization/LocalizedText.swift         # 신규
    │   │   ├── Resources/Localizable.xcstrings          # 신규
    │   │   └── <역할>/…                                   # 14개 파일 문구 교체
    │   └── Tests/Component/Unit/Localization/LocalizedTextTests.swift   # 신규
    ├── Feature/
    │   ├── Shared/Localization/
    │   │   ├── LocalizedText.swift                      # 신규(루트)
    │   │   └── LocalizedText+<흐름>.swift               # 신규 11개
    │   ├── <흐름>/Resources/<흐름>.xcstrings            # 신규 11개
    │   ├── <흐름>/…                                      # 63개 파일 문구 교체
    │   └── Tests/Shared/Localization/LocalizedTextTests.swift          # 신규
    └── App/
        ├── GitIt/
        │   ├── Localization/LocalizedText.swift         # 신규
        │   ├── Resources/Localizable.xcstrings          # 신규
        │   ├── GitItApp.swift                           # 알림 문구 조회 교체
        │   └── GenerationReminderContent.swift          # 삭제(문구만 보유하던 타입)
        └── Tests/GitIt/Localization/LocalizedTextTests.swift           # 신규

docs/
├── conventions/
│   ├── README.md                                # 현지화 컨벤션 행 추가
│   ├── localization.md                          # 신규 인덱스
│   ├── localization/                            # 신규 참고 단위 10개
│   │   ├── target-text.md · exclusion.md
│   │   ├── string-catalog.md · key.md · entry-value.md
│   │   ├── localized-text.md · call-site.md
│   │   └── development-language.md · adding-language.md · verification.md
│   ├── file-vocabulary/shape-vocabulary.md      # `Localization/` 행, `Resources/` 설명 추가
│   ├── directory-file/resources.md              # `.xcstrings` 소유 명시
│   ├── directory-file/feature-layout.md         # 흐름 `Resources/` 설명 수정
│   ├── ui-component/folder-file.md              # 1뎁스 허용 목록에 `Localization/` 추가
│   ├── ui-component/asset.md                    # 컴포넌트 문구 카탈로그 소유 명시
│   ├── view-declarations.md                     # §2.1 요약 수정
│   └── view-declarations/constant.md            # 현지화 문구는 `LocalizedText` 소유
└── package-rules/
    ├── ui.md · feature.md                       # 구현 컨벤션에 현지화 컨벤션 링크
    └── app.md                                   # 정책에 현지화 컨벤션 링크
```

컨벤션 문서의 구조와 규칙 본문은 [contracts/localization-convention.md](./contracts/localization-convention.md)가 확정한다.

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 유지하고 새 target이나 패키지 의존성을 만들지 않는다.
카탈로그는 각 target의 기존 `Resources/` 자리에, `LocalizedText`는 새 `Localization/` 형태 폴더에 둔다. 이 배치와
현지화 규칙 전체는 새 `docs/conventions/localization.md`가 소유한다.

## 실행 단위

패키지 위상 순서는 [architecture.md §3.1](../../docs/architecture.md)의 `App → Feature → UI`에서
UI → Feature → App이다. `Composition`·`Domain`·`Data`·`Infrastructure`는 변경하지 않으므로 건너뛴다.

| 순서 | 단위 | 종류 | 파일 범위 | 집중 검증 |
| --- | --- | --- | --- | --- |
| 1 | 공통 manifest | integration unit | `ProjectName.swift`(개발 언어, `resourceSynthesizers`로 strings 합성기 제외), `Target+Module.swift`, `Projects/AppModuleName.swift` | `make tuist`, 기존 assets·fonts 생성 파일 유지와 strings 합성 파일 부재(R2), 전체 `build`, 앱 실행으로 폰트·이미지·정책 문서 표시 확인(R4) |
| 2 | UIComponent | integration unit(UI, 문서) | `docs/conventions/file-vocabulary/shape-vocabulary.md`, `docs/conventions/ui-component/folder-file.md`, `UI/Component/Localization/`, `UI/Component/Resources/Localizable.xcstrings`, 문구 교체 14개 파일, `UI/Tests/Component/Unit/Localization/` | 폴더 허용 문서를 먼저 고친 뒤 생성 심볼 이름 확인(R1). UI scheme compile·test |
| 3 | 현지화 컨벤션 문서 | 문서 단위 | [contracts/localization-convention.md §A·§D](./contracts/localization-convention.md)의 `docs/conventions/**`(단위 2가 고친 두 문서는 링크 연결만), `docs/package-rules/{ui,feature,app}.md` | 인덱스·참고 단위 구조와 링크 대상 존재 확인, 단위 2의 실제 코드가 새 규칙과 일치하는지 대조 |
| 4 | Feature 기반 + 첫 흐름 | 단일 패키지(Feature) | `Projects/FeatureModuleName.swift`(Feature 리소스 선언), `Feature/Shared/Localization/LocalizedText.swift`, 첫 흐름의 카탈로그·확장·교체, `Feature/Tests/Shared/Localization/` | Feature scheme compile·test |
| 5 | Feature 흐름별 | 단일 패키지(Feature), 흐름마다 1단위 | 흐름마다 `<흐름>/Resources/<흐름>.xcstrings`, `LocalizedText+<흐름>.swift`, 그 흐름의 교체 파일 | Feature scheme compile, 해당 흐름 테스트 |
| 6 | GitIt | 단일 패키지(App) | `App/GitIt/Localization/`, `App/GitIt/Resources/Localizable.xcstrings`, `GitItApp.swift`, `GenerationReminderContent.swift` 삭제, `App/Tests/GitIt/Localization/` | App scheme compile·test |
| 7 | 전체 검증·마무리 | 최종 단위 | 코드 변경 없음(포맷 훅 결과만) | build·compile·test 전체, [quickstart.md](./quickstart.md) §1–§8, `after_implement` 포맷 훅 |

**단위 1이 integration unit인 이유**: `ProjectName.swift`의 `Project.Options`와 `Target+Module.swift`의
`module(...)`은 7개 Tuist 프로젝트가 함께 쓰는 helper다. 개발 언어가 `ko`가 아닌 상태에서 카탈로그를
추가하면 영어 환경에서 키가 노출되므로, 이 변경은 어느 카탈로그보다 먼저 한 번에 모든 프로젝트에
적용되어야 한다. 패키지별로 나눌 수 없으며 통합 검증은 전체 `build`와 앱 실행이다.

**단위 2에 폴더 허용 문서를 포함하는 이유**: [shape-vocabulary.md](../../docs/conventions/file-vocabulary/shape-vocabulary.md)는
표에 없는 형태 폴더를 추가하면 표를 함께 갱신하라고 요구한다. `UI/Component/Localization/`을 처음 만드는 커밋이 그
폴더를 허용하는 문서 변경을 함께 담아야 중간 커밋이 컨벤션에 없는 폴더를 갖지 않는다. `Feature/Shared/`·`App/GitIt/`의
`Localization/` 행도 같은 표 변경에 포함해 표를 한 번만 고친다. 링크 대상인 `localization.md`는 아직 없으므로 링크는
단위 3에서 연결한다.

**단위 4–5의 분할 근거**: `Feature`는 target 하나지만 흐름마다 카탈로그·확장·교체 파일이 독립적이어서
흐름 단위로 되돌릴 수 있다. 흐름 사이 순서는 서로 의존하지 않으므로 `tasks.md`가 정하되, 문구가 적은
흐름을 먼저 두어 규칙을 확인한다. 한 흐름의 교체 파일이 다른 흐름의 `LocalizedText` 중첩 enum을 참조하지
않는다.

**단위 6이 Feature 뒤인 이유**: `GitIt`이 `Feature`에 의존하므로 위상 순서상 마지막 패키지다. 알림 문구는
Feature와 무관하지만 순서를 깨지 않는다.

**문서 단위 배정과 순서**: `docs/conventions/**`와 `docs/package-rules/**`는 패키지에 속하지 않으며 FR-010을
충족하는 독립 단위다. 단, 폴더 허용 문서 두 개는 위 근거로 단위 2가 먼저 고친다. 생성 심볼 규칙(R1)을 확인한 단위 2 직후, Feature 일괄 적용 전에 두어 단위 4–6이 작성된
컨벤션을 근거로 진행하게 한다. R1 결과가 계약과 다르면 이 단위에서 [contracts/localization-convention.md](./contracts/localization-convention.md)가
허용한 문장만 확인 결과로 바꾼다.

## 복잡성 추적

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| 형태 어휘 표와 UIComponent 1뎁스 목록에 없는 `Localization/` 폴더 | 사용자 결정으로 현지화 문구를 View `Constant`가 아닌 모듈별 전용 타입(`LocalizedText`)에 둔다. 이 타입은 기존 형태(`Models/`, `Contracts/`, 역할 폴더) 어느 것에도 속하지 않는다 | `Feature/Shared/Models/`는 값 타입 자리라 문구 조회 진입점의 책임과 맞지 않고, `Resources/`에는 Swift 소스를 두지 않는다. 표 갱신은 컨벤션이 요구하는 절차이며 폴더를 처음 만드는 단위 2의 첫 작업으로 반영한다 |
| Feature `LocalizedText`의 흐름별 확장을 `Feature/Shared/Localization/`에 모음 | `LocalizedText`는 target당 하나의 타입이고, 흐름 1뎁스에는 Swift 선언용 형태 폴더를 둘 수 없다 | 흐름 폴더마다 확장을 두면 `feature-layout.md`의 흐름 1뎁스 제한을 어긴다. 확장은 문자열 조회만 하고 흐름 타입을 참조하지 않으므로 `Feature/Shared/**`의 참조 방향 제약을 지킨다 |
