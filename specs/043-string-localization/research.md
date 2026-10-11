# 조사: 사용자 노출 문자열 현지화 적용

**기능**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md) | **작성일**: 2026-09-24

## 현황 조사

2026-09-24 `feature/string-localization`(`4edd3e4`) 기준이다.

| 범위 | 한국어 리터럴이 있는 production 파일(프리뷰 제외) | 비고 |
| --- | --- | --- |
| `UI/Component` | 14개 파일, 26곳 | 닫기·뒤로 가기, 정답·오답, 필수·선택, 접근성 레이블·힌트·값. `TabShell`의 탭 이름은 프리뷰 전용이라 제외하며 실제 탭 이름은 `Feature/MainShell/Router/MainShellTab.swift`가 소유한다 |
| `Feature` | 11개 흐름, 63개 파일, 256곳 | 화면·서브뷰·`ViewModels`·`Router`, `SharedRepositoryRegistrationFeature`의 실패 사유 |
| `App/GitIt` | `GenerationReminderContent.swift` 1개 파일, 4곳 | 로컬 알림 제목·본문. `AppRootView`의 한국어는 프리뷰 값 |
| `App/ShareExtension` | 사용자 노출 문구 없음 | 로그·`fatalError`만 존재. 화면은 `Feature`의 `ShareRegistration` 흐름이 그린다 |
| `Domain`·`Data`·`Infrastructure`·`Composition` | 사용자 노출 문구 없음 | 로그 문자열만 존재(명세 가정과 일치) |

- 현지화 리소스(`.xcstrings`, `.strings`, `.stringsdict`)는 저장소에 없다.
- 모든 Tuist 프로젝트는 `developmentRegion`을 지정하지 않아 개발 언어가 Tuist 기본값(`en`)이다.
- `GitIt` target은 이미 `STRING_CATALOG_GENERATE_SYMBOLS = YES`를 선언했지만 카탈로그가 없어 효과가 없다.
- `Feature`는 target 하나(`sourceDirectory: "."`)이며 `resources`를 선언하지 않았다. `UIComponent`는
  `Component/Resources/**`를 리소스로 선언했고 Tuist가 `Bundle.module`(`Bundle(for:)`)을 합성한다.
- 한국어 표시 문구를 기대값으로 검증하는 테스트는 `Feature/Tests`의 5개 파일과 `UI/Tests/Component`의
  8개 파일이다(나머지 한국어 `#expect`는 서버 값·저장 값 검증이라 대상이 아니다).
- 도구 버전: Xcode 26.6(17F113), Tuist 4.202.2.

## 결정 1. 리소스 형식 — String Catalog

- **결정**: 각 모듈의 사용자 노출 문구를 String Catalog(`.xcstrings`)로 관리한다.
- **근거**: iOS 26·Xcode 26 표준 형식이다. 번역용 주석, 번역 상태, 언어별 복수 변형을 한 파일에서
  다루므로 FR-003·FR-004·FR-012를 도구 차원에서 충족한다. Tuist 4.202.2는 `xcstrings`를 리소스로
  빌드한다(`CompileXCStrings` 단계).
- **검토한 대안**: `.strings` + `.stringsdict` — 복수·주석 관리가 두 파일로 나뉘고 Xcode의 번역 상태
  추적을 쓸 수 없어 기각했다.

## 결정 2. 카탈로그가 정본이며 코드는 생성 심볼로 조회한다

- **결정**: 카탈로그 항목은 **수동 관리(manual) 항목**으로 추가하고 키·한국어 값·주석을 카탈로그가
  소유한다. 코드는 `STRING_CATALOG_GENERATE_SYMBOLS`가 만드는 `LocalizedStringResource` 심볼
  (`.<Table>.<key>`)로 조회한다.
- **근거**:
  - 명세 시나리오 1 수용 2(“Swift 소스를 수정하지 않고 카탈로그 값만 고쳐 문구가 바뀐다”)는 코드에
    기본값을 두는 `String(localized:defaultValue:)` 방식으로는 충족되지 않는다. 자동 추출 항목은
    빌드 때 코드의 기본값으로 다시 동기화된다.
  - 의미 기반 키(FR-013)와 키·값 분리를 도구가 직접 지원한다. 존재하지 않는 키를 쓰면 심볼이 없어
    컴파일 오류가 나므로 조회 실패가 런타임까지 가지 않는다.
  - 생성 심볼은 자기 target의 번들을 가리키므로 `bundle:` 인자를 호출부마다 반복하지 않는다(FR-005).
- **검토한 대안**:
  - `String(localized: "key", defaultValue: "값", bundle: .module, comment:)` — 한국어 값과 주석이
    Swift 소스에 남아 카탈로그만 고쳐 문구를 바꿀 수 없어 기각했다.
  - 한국어 문구를 키로 쓰는 SwiftUI 자동 추출 — 명확화에서 의미 기반 키로 결정되어 기각했다.
  - Tuist 리소스 합성기(`TuistStrings+*.swift`) — Xcode 생성 심볼과 역할이 겹치고 번역 상태를
    다루지 않아 쓰지 않는다. 공통 manifest에서 strings 합성기를 미리 제외한다(아래 위험 R2).

## 결정 3. 개발 언어는 한국어(`ko`)

- **결정**: `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 공통 `Project.Options`에
  `developmentRegion: "ko"`와 `defaultKnownRegions: ["ko", "Base"]`를 지정한다.
- **근거**: 카탈로그의 소스 언어와 각 번들의 `CFBundleDevelopmentRegion`(`$(DEVELOPMENT_LANGUAGE)`)이
  모두 `ko`여야 기기·시뮬레이터 언어가 영어일 때도 한국어로 대체된다(FR-008, SC-006). 테스트
  러너도 시뮬레이터 기본 언어(영어)로 실행되므로 FR-014의 한국어 기대값이 같은 대체 규칙에 기대어
  통과한다. 모든 프로젝트가 같은 helper로 생성되므로 한 곳에서 지정한다.
- **검토한 대안**: 모듈별 `Info.plist`에 `CFBundleDevelopmentRegion`만 덮어쓰기 — Xcode 프로젝트의
  개발 언어와 카탈로그 소스 언어가 어긋나 기각했다. 영어를 개발 언어로 두고 한국어 번역을 추가 —
  영어 값이 없는 동안 영어 환경에서 키가 노출되어 기각했다.

## 결정 4. 카탈로그 배치와 테이블 이름

- **결정**:
  - `UIComponent`: `sources/Projects/UI/Component/Resources/Localizable.xcstrings` 하나.
  - `Feature`: 흐름마다 `sources/Projects/Feature/<흐름>/Resources/<흐름>.xcstrings` 하나. 이번 대상은
    `AppEntry`, `Home`, `MainShell`, `Onboarding`, `ProjectDetail`, `ProjectList`,
    `ProjectRegistration`, `Quiz`, `Saved`, `Settings`, `ShareRegistration` 11개다.
  - `App/GitIt`: `sources/Projects/App/GitIt/Resources/Localizable.xcstrings` 하나.
- **근거**: [shape-vocabulary](../../docs/conventions/file-vocabulary/shape-vocabulary.md)는
  `Feature/<흐름>/Resources/`(흐름이 소유하는 자산), `UI/Component/Resources/`, `App/GitIt/Resources/`를
  이미 허용한다. `Feature`는 target이 하나라 테이블 이름이 target 안에서 유일해야 하며, 흐름 이름은
  유일하다. 흐름별 테이블은 생성 심볼을 `.Settings.<key>`처럼 흐름 단위로 묶어 소유 흐름을 드러낸다
  (FR-005, FR-013). `UIComponent`와 `App`은 문구가 적어 기본 테이블 하나로 충분하다.
- **검토한 대안**: `Feature` 전체를 `Localizable.xcstrings` 하나로 관리 — 250여 항목이 한 파일에
  섞여 흐름 소유가 드러나지 않고 동시 편집 충돌이 커져 기각했다.

## 결정 5. 키 규칙

- **결정**: 키는 소문자로 시작하는 lowerCamelCase Swift 식별자이며 `<화면·컴포넌트><용도>` 순서로
  짓는다(예: `Settings` 테이블의 `profileNicknameTitle`, `UIComponent`의 `webSheetCloseAccessibilityLabel`).
  테이블이 흐름을 이미 나타내므로 키에 흐름 이름을 따로 붙이지 않는다. `Localizable` 테이블을 여러 컴포넌트·기능이
  함께 쓰는 `UIComponent`·`GitIt`은 첫 단어가 반드시 컴포넌트·기능 이름이어야 키가 테이블 안에서 유일하다.
  점(`.`)·밑줄·공백은 쓰지 않는다.
- **근거**: 생성 심볼 이름이 키에서 파생되므로 키 자체를 유효한 Swift 식별자로 두면 심볼 이름을
  예측할 수 있다. [네이밍 — 필요한 최소 문맥](../../docs/conventions/naming/minimal-context.md)에 따라
  테이블이 주는 문맥은 반복하지 않는다. 같은 한국어 문구라도 용도가 다르면 다른 키를 둔다.
- **검토한 대안**: `settings.profile.nicknameTitle`처럼 점으로 구분한 키 — 심볼 이름 변환 규칙이
  문서화되어 있지 않아 기각했다.

## 결정 6. 보간·수량 문구

- **결정**: 값이 들어가는 문구는 카탈로그 값에 이름 있는 위치 지정자(예: `%1$(count)lld개`,
  `%1$(projectName)@ 학습 시작`)를 쓰고, 생성 심볼이 만드는 인자 레이블로 호출한다. 주석에는 각 인자의
  의미를 적는다. 한국어는 복수 변형이 없으므로 이번에는 복수 변형을 만들지 않고, 추가 언어가
  필요할 때 카탈로그에서 해당 항목에 “Vary by plural”을 켠다.
- **근거**: FR-003·FR-004와 FR-012(호출부 수정 없이 언어 추가)를 동시에 충족한다. 위치 지정자는
  언어별 어순 변경을 허용한다.
- **검토한 대안**: 문자열 연결(`"\(count)" + 단위`) — 어순을 번역할 수 없어 기각했다.

## 결정 7. 모듈별 문구 전용 타입 `LocalizedText`

사용자 결정(2026-09-24 계획 세션): 현지화 문구는 View의 `Constant`에 두지 않고 **모듈마다 문구 전용
타입**으로 분리한다.

- **결정**: `UIComponent`, `Feature`, `GitIt` 각 target에 case 없는 `internal enum LocalizedText`를 둔다.
  이 타입은 그 모듈의 사용자 노출 문구를 `String`으로 제공하는 유일한 진입점이다.
  - `Feature`는 흐름 테이블마다 같은 이름의 중첩 enum(`LocalizedText.Settings`, `LocalizedText.Quiz`)을,
    `UIComponent`·`GitIt`은 `Localizable` 테이블 안의 컴포넌트·기능마다 중첩 enum(`LocalizedText.TabShell`,
    `LocalizedText.GenerationReminder`)을 둔다. 키마다 `static var`(고정 문구) 또는 `static func`(보간 문구)
    하나를 두며, 멤버 이름은 키에서 중첩 enum 이름과 같은 첫 단어를 뗀 이름이다(예: 키
    `webSheetCloseAccessibilityLabel` → `LocalizedText.WebSheet.closeAccessibilityLabel`). 첫 단어가 중첩 enum
    이름과 다르면 키를 그대로 쓴다. 중첩으로 이미 드러난 문맥을 멤버 이름에 반복하지 않기 위해서다
    ([네이밍 — 필요한 최소 문맥](../../docs/conventions/naming/minimal-context.md)). 본문은 생성 심볼을
    `String(localized:)`로 해석하는 한 줄이다.
  - 호출부는 `LocalizedText.<중첩>.<멤버>`로 조회한다. View의 `Constant`는 현지화 문구를 소유하지 않는다.
  - 파일 배치:
    - `Feature`: `Feature/Shared/Localization/LocalizedText.swift`(루트)와 흐름별
      `Feature/Shared/Localization/LocalizedText+<흐름>.swift`
      ([중첩 타입 분리](../../docs/conventions/file-vocabulary/nested-type-split.md)).
    - `UIComponent`: `UI/Component/Localization/LocalizedText.swift` 한 파일
      ([UIComponent는 중첩 타입을 파일로 나누지 않는다](../../docs/conventions/ui-component/folder-file.md)).
    - `GitIt`: `App/GitIt/Localization/LocalizedText.swift` 한 파일.
- **근거**:
  - 컴포넌트 공개 입력이 `String`이므로(FR-015로 공개 API 유지) 변환을 한 곳에 모은다.
  - `internal`이라 모듈마다 같은 이름을 써도 충돌하지 않고, 다른 모듈의 문구를 참조할 수 없어
    모듈 소유(FR-005)가 컴파일러로 보장된다.
  - 이름은 “현지화된 표시 문구”라는 책임을 드러낸다. `L10n`은
    [축약 규칙](../../docs/conventions/naming/abbreviation.md)에 맞지 않고, `Strings`는 책임이
    드러나지 않으며, `Display*`는 Feature 표시 모델(`SavedQuestionDisplay` 등)과 혼동되어 쓰지 않는다.
- **검토한 대안**:
  - `Constant`에 `String(localized:)`로 두기 — 사용자가 기각했다. 제네릭 View의 `Constant`는 리터럴만
    반환해야 한다는 [constant.md](../../docs/conventions/view-declarations/constant.md) 규칙과도 맞지 않는다.
  - 생성 심볼을 호출부에서 직접 사용 — 사용자가 전용 타입을 선택해 기각했다.
- **컨벤션 공백**: `Localization/` 형태 폴더는 현재 형태 어휘 표에 없다. 표에 없는 형태는 같은 PR에서
  표를 갱신해야 하므로 FR-010 문서 작업에서 `Feature/Shared/`, `UI/Component/`, `App/GitIt/`의
  `Localization/` 행을 추가한다(plan.md 복잡성 추적, 결정 10 참고).

## 결정 8. 추출 설정

- **결정**: `Feature`, `UIComponent`, `GitIt` target에 `STRING_CATALOG_GENERATE_SYMBOLS = YES`와
  `SWIFT_EMIT_LOC_STRINGS = NO`를 둔다. 프레임워크 공통 설정은
  `sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift`의 `module(...)`에 추가하고 `GitIt`은
  `AppModuleName.swift`에 추가한다.
- **근거**: 카탈로그는 수동 항목만 정본으로 가진다. 컴파일러 추출을 끄면 프리뷰의 `Text("…")` 같은
  제외 대상(FR-007)이 카탈로그에 섞이지 않는다. 심볼 생성은 카탈로그가 없는 target에서는 효과가 없어
  helper에 두어도 다른 모듈에 영향이 없다.
- **검토한 대안**: 추출을 켜 두고 추출 항목을 수동 정리 — 빌드마다 제외 대상이 다시 들어와 기각했다.

## 결정 9. 테스트

- **결정**: 기존 한국어 기대값 테스트는 수정하지 않고 그대로 통과해야 한다(FR-014). 모듈마다 대표
  문구 하나가 한국어로 조회되는지 확인하는 테스트를 추가한다. 테스트는 시뮬레이터 기본 언어(영어)에서
  실행되므로 개발 언어 대체와 번들 조회를 함께 검증한다.
- **근거**: 조회 실패 시 `String(localized:)`는 키 문자열을 반환하므로 한국어 기대값과 달라 테스트가
  실패한다. 추가 테스트는 기존 기대값 테스트가 없는 `GitIt`까지 같은 보장을 준다.
- **검토한 대안**: 키 일치 검증 — 명확화에서 기각했다.

## 결정 10. 현지화 컨벤션 문서 구조

사용자 요청(2026-09-24 두 번째 계획 세션): `Localization/`을 포함한 현지화 컨벤션을 이번 기능에서 정의한다.

- **결정**: 새 주제 컨벤션 `docs/conventions/localization.md`(인덱스)와 `docs/conventions/localization/`
  참고 단위 문서 10개를 만든다. 대상·제외, 카탈로그, 키, 값·주석, `LocalizedText`, 호출부, 개발 언어·빌드
  설정, 언어 추가, 검증을 각각 한 문서가 소유한다. `Localization/`·`Resources/` 폴더 자리는 기존 형태 어휘
  표가 계속 소유하고 행만 추가한다. 기존 문서 11개에는 한 줄 요약과 링크만 둔다. 구조와 규칙 본문은
  [contracts/localization-convention.md](./contracts/localization-convention.md)가 확정한다.
- **근거**:
  - 현지화 규칙은 View 선언, 자산 배치, 빌드 설정, 테스트에 걸쳐 있어 기존 한 문서에 넣으면 그 문서의 소유
    범위를 벗어난다. [cross-reference.md](../../docs/conventions/common/cross-reference.md)의 “규칙 하나는
    문서 하나가 소유” 원칙에 따라 새 주제 문서가 소유하고 나머지는 링크한다.
  - [document-structure.md](../../docs/conventions/common/document-structure.md)의 인덱스·참고 단위
    구조와 [document-format.md](../../docs/conventions/common/document-format.md)의 작성 순서를 그대로 따른다.
  - 폴더 목록의 정본을 형태 어휘 표에 두면 다른 형태 폴더와 같은 자리에서 검토할 수 있다.
- **검토한 대안**:
  - `view-declarations`에 현지화 절을 추가 — 카탈로그 배치·빌드 설정·App 알림 문구를 소유할 수 없어 기각했다.
  - `directory-file`에 `Localization/` 규칙만 추가 — 키·주석·호출부 규칙이 소유 문서 없이 남아 기각했다.
- **적용 순서**: `Localization/` 폴더를 허용하는 두 문서(`file-vocabulary/shape-vocabulary.md`,
  `ui-component/folder-file.md`)는 그 폴더를 처음 만드는 `UIComponent` 단위의 첫 작업으로 고친다. 그래야 중간 커밋이
  컨벤션에 없는 폴더를 담지 않는다. 나머지 현지화 컨벤션 문서는 생성 심볼 규칙(R1)을 확인한 `UIComponent` 단위 직후,
  `Feature` 일괄 적용 전에 작성하고 두 문서에 현지화 컨벤션 링크를 연결한다.

## 위험과 확인 절차

| ID | 위험 | 확인·대응 |
| --- | --- | --- |
| R1 | 생성 심볼 이름·인자 레이블이 키·위치 지정자에서 예상과 다르게 파생될 수 있다 | `UIComponent` 단위 첫 작업에서 고정 문구 1개와 보간 문구 1개로 빌드해 생성 심볼 이름을 확인한다. 다르면 결정 5·6의 키 규칙을 실제 규칙에 맞추고 이 문서를 갱신한 뒤 진행한다 |
| R2 | Tuist가 `xcstrings`에 대해 `TuistStrings+*.swift`를 합성할 수 있다 | 공통 manifest 단위에서 모든 `Project`의 `resourceSynthesizers`를 `[.assets(), .plists(), .fonts()]`로 지정해 strings 합성기를 미리 제외한다. 카탈로그를 추가하는 단위 2 전에는 합성 여부를 확인할 수 없어 조건부 대응이면 순서가 흔들리기 때문이다. 같은 단위의 `make tuist` 뒤 기존 `TuistAssets+UIComponent.swift`·`TuistFonts+DesignSystem.swift`가 그대로 생성되는지로 목록 누락을 확인하고, 달라지면 Tuist 기본 목록을 확인해 누락된 합성기를 더한다 |
| R3 | 생성 심볼이 Tuist 프레임워크 번들을 올바르게 찾지 못할 수 있다 | 결정 9의 모듈별 대표 테스트가 영어 시뮬레이터에서 한국어를 반환하는지로 확인한다 |
| R4 | `developmentRegion` 변경이 기존 자산(xcassets, 정책 문서) 번들링에 영향을 줄 수 있다 | 공통 manifest 단위 뒤 전체 build와 앱 실행으로 폰트·이미지·정책 문서 표시를 확인한다 |
