# 계약: 현지화 컨벤션 문서

**기능**: [spec.md](../spec.md) FR-010 | **계획**: [plan.md](../plan.md) | **조사**: [research.md 결정 10](../research.md#결정-10-현지화-컨벤션-문서-구조)

이 문서는 구현 단계에서 새로 쓰거나 고칠 컨벤션 문서의 **구조와 규칙 본문**을 확정한다. 구현 단위는
이 계약을 [컨벤션 공통 원칙](../../../docs/conventions/common/README.md)의 형식에 맞춰 옮겨 쓰며, 계약에
없는 규칙을 새로 만들지 않는다. [research.md R1](../research.md#위험과-확인-절차) 확인 결과 생성 심볼
규칙이 다르면 §C.2·§C.5의 해당 문장만 확인 결과로 바꾼다.

## A. 문서 목록

| 구분 | 경로 | 역할 |
| --- | --- | --- |
| 신규 인덱스 | `docs/conventions/localization.md` | 현지화 컨벤션의 `##` 추상 원칙과 `###` 링크, 체크리스트, 관련 문서, 변경 기준 |
| 신규 참고 단위 | `docs/conventions/localization/target-text.md` | §C.1 현지화 대상 |
| 〃 | `docs/conventions/localization/exclusion.md` | §C.2 제외 대상 |
| 〃 | `docs/conventions/localization/string-catalog.md` | §C.3 카탈로그 형식·배치·소유 |
| 〃 | `docs/conventions/localization/key.md` | §C.4 키 |
| 〃 | `docs/conventions/localization/entry-value.md` | §C.5 값·주석·보간 |
| 〃 | `docs/conventions/localization/localized-text.md` | §C.6 `LocalizedText` |
| 〃 | `docs/conventions/localization/call-site.md` | §C.7 호출부 |
| 〃 | `docs/conventions/localization/development-language.md` | §C.8 개발 언어와 빌드 설정 |
| 〃 | `docs/conventions/localization/adding-language.md` | §C.9 언어 추가 |
| 〃 | `docs/conventions/localization/verification.md` | §C.10 검증 |
| 기존 수정 | §D의 문서 | 소유 규칙은 현지화 컨벤션에 두고 한 줄 요약과 링크만 추가 |

참고 단위 문서는 제목, `[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.` 한 줄, 규칙
본문만 가진다([document-structure.md](../../../docs/conventions/common/document-structure.md)).

## B. 인덱스 `docs/conventions/localization.md`

```text
# Git It iOS 현지화 컨벤션

**상태**: 초안
**작성일**: <구현 날짜>
**최종 수정일**: <구현 날짜>

## 목적
사용자에게 보이는 고정 문구를 소스 리터럴이 아니라 모듈이 소유하는 String Catalog에서 조회하도록 하고,
카탈로그 배치·키·주석·조회 진입점·제외 대상과 검증 방식을 통일한다. 패키지 책임은 package-rules가,
`Resources/`·`Localization/` 폴더 목록은 형태 어휘 표(file-vocabulary/shape-vocabulary.md)가, View
`Constant`는 View 내부 선언 컨벤션이 소유한다. 문서 우선순위·구조·참조 규칙은 컨벤션 공통 원칙이 소유한다.

## 1. 적용 범위
- sources/Projects/UI/Component/**, sources/Projects/Feature/**, sources/Projects/App/GitIt/**의
  production 소스와 `Resources/*.xcstrings`
- 위 target의 표시 문구를 검증하는 테스트
- Domain·Data·Infrastructure·Composition은 사용자 노출 문구를 소유하지 않으므로 대상이 아니다.
  사용자에게 보여야 하는 값이 이 패키지에서 나오면 표시 책임을 가진 Feature·App이 현지화한다.
- 포맷 도구 설정과 Tuist helper 구현 자체는 대상이 아니다. 이 문서는 그 helper가 지켜야 할 설정 값만 정한다.

## 2. 현지화 대상            (추상: 사용자에게 보이거나 읽히는 고정 문구는 모두 대상이고,
                             시스템 밖에서 온 값과 개발자만 보는 문자열은 대상이 아니다)
### 2.1 현지화 대상 → localization/target-text.md
### 2.2 제외 대상   → localization/exclusion.md

## 3. 문구 리소스            (추상: 문구의 정본은 코드가 아니라 모듈이 소유한 카탈로그의 수동 항목이다.
                             키는 의미를, 값은 표시를, 주석은 번역 맥락을 소유한다)
### 3.1 String Catalog → localization/string-catalog.md
### 3.2 키            → localization/key.md
### 3.3 값과 주석      → localization/entry-value.md

## 4. 조회 진입점            (추상: 모듈마다 하나의 문구 전용 타입이 카탈로그를 String으로 제공하며,
                             호출부는 그 타입만 거친다)
### 4.1 LocalizedText → localization/localized-text.md
### 4.2 호출부        → localization/call-site.md

## 5. 개발 언어와 빌드 설정   (추상: 개발 언어는 한국어이며 어떤 기기 언어에서도 키가 노출되지 않아야 한다)
### 5.1 개발 언어와 빌드 설정 → localization/development-language.md

## 6. 언어 추가              (추상: 언어 추가는 카탈로그 변경만으로 끝나야 한다)
### 6.1 언어 추가 절차 → localization/adding-language.md

## 7. 검증                   (추상: 자동 검출 도구가 없으므로 테스트와 리뷰 검사로 지킨다)
### 7.1 검증 → localization/verification.md

## 8. 검토 체크리스트
- [ ] 새로 추가한 사용자 노출 문구가 모두 소유 모듈의 카탈로그 항목인가?
- [ ] 제외 대상(서버 값, 사용자 입력, 로그, 진단, 프리뷰, 테스트 픽스처)을 카탈로그에 넣지 않았는가?
- [ ] 키가 lowerCamelCase 식별자이며 테이블 문맥을 반복하지 않는가?
- [ ] 같은 한국어 값이라도 용도가 다르면 다른 키인가?
- [ ] 모든 항목에 주석이 있고, 보간 항목의 주석이 인자마다 의미를 설명하는가?
- [ ] 호출부가 `LocalizedText`만 거치며 한국어 리터럴·생성 심볼·`String(localized:)`를 직접 쓰지 않는가?
- [ ] View `Constant`와 표시 모델에 현지화 문구가 없는가?
- [ ] 컴포넌트 공개 입력이 `String`으로 유지되는가?
- [ ] 한국어 표시 문구 테스트가 키가 아니라 한국어 최종 문구를 기대하는가?
- [ ] 한국어 리터럴 잔여 검사(§7.1) 결과가 제외 대상뿐인가?

## 관련 문서
아키텍처, UI·Feature·App 패키지 규칙, 디렉터리·파일 컨벤션, 파일·형태 어휘 컨벤션, View 내부 선언 컨벤션,
UIComponent 컨벤션, 네이밍 컨벤션, 테스트 컨벤션

## 문서 변경 기준
현지화 대상·제외 기준, 카탈로그 배치·형식, 키·주석 규칙, 조회 진입점 형태, 개발 언어·지원 언어, 빌드 설정
또는 검증 방식이 바뀌면 수정한다. `Localization/`·`Resources/` 폴더 자리가 바뀌면 이 문서보다 형태 어휘 표를
먼저 갱신한다. `Constant`의 일반 규칙이 바뀌면 View 내부 선언 컨벤션을 갱신한다.
```

괄호 안의 “추상” 문장은 해당 `##` 절 본문으로 풀어 쓴다.

## C. 참고 단위 문서의 규칙 본문

### C.1 `localization/target-text.md` — 현지화 대상

다음 고정 문구는 카탈로그 항목이어야 한다.

- 화면 제목·본문·안내·빈 상태·실패 안내·확인 대화상자 문구
- 버튼·메뉴·탭·칩 등 컨트롤의 제목과 상태 표기(예: 켜짐·꺼짐, 필수·선택, 정답·오답)
- 입력 필드의 placeholder, 보조 문구, 검증 오류 문구
- 접근성 레이블·힌트·값·사용자 지정 동작 이름
- 로컬 알림 제목·본문
- Reducer가 State에 담는 사용자 노출 사유 문구(예: 공유 등록 실패 사유)
- 고정 문구와 동적 값이 합쳐진 문장(동적 값은 보간 인자로 받는다)

### C.2 `localization/exclusion.md` — 제외 대상

다음은 카탈로그 항목으로 만들지 않고, 조회 없이 받은 값 그대로 쓰거나 리터럴로 남긴다.

- 서버·GitHub에서 받은 콘텐츠: 퀴즈 문제·선택지, 프로젝트·저장소 이름과 설명, 서버 오류 메시지
- 사용자가 입력한 값
- `Logger` 메시지, `fatalError`·`precondition`·`assert` 메시지
- `#Preview` 이름, 프리뷰 전용 타입과 프리뷰 샘플 데이터
- 테스트 이름과 테스트 픽스처
- 브랜드·제품 고유 명칭(`Git-It`, `GitHub`, `Apple`)만으로 이루어진 값. 고유 명칭이 문장 안에 들어가면
  그 문장은 대상이다(예: “GitHub에서 보기”, “Apple로 시작하기”)
- 식별자·URL·알림 identifier처럼 화면에 표시되지 않는 값

동적 값을 현지화 키로 넘겨 조회하지 않는다. 동적 값은 SwiftUI `Text`에 `String`으로 넘겨 키로 다시
해석되지 않게 한다.

### C.3 `localization/string-catalog.md` — String Catalog

- 형식은 String Catalog(`.xcstrings`)다. `.strings`·`.stringsdict`를 새로 만들지 않는다.
- 카탈로그는 문구를 쓰는 target이 소유하며 그 target의 `Resources/`에 둔다.

  | target | 경로 | 테이블 이름 |
  | --- | --- | --- |
  | `UIComponent` | `UI/Component/Resources/Localizable.xcstrings` | `Localizable` |
  | `Feature` | `Feature/<흐름>/Resources/<흐름>.xcstrings` | 흐름 이름 |
  | `GitIt` | `App/GitIt/Resources/Localizable.xcstrings` | `Localizable` |

- `Feature`는 target이 하나이므로 흐름마다 테이블 하나를 둔다. 흐름 안의 `<흐름>/Shared/`·화면 폴더가 쓰는
  문구도 그 흐름 테이블에 둔다. 둘 이상의 흐름이 같은 용도로 쓰는 문구가 생기면 `Feature/Shared/Resources/Shared.xcstrings`를
  만들고 형태 어휘 표에 행을 추가한다.
- 다른 target의 카탈로그나 번들을 조회하지 않는다. Feature는 UIComponent 문구를, App은 Feature 문구를 참조하지 않는다.
- `sourceLanguage`는 `ko`다. 지원 언어는 현재 `ko`뿐이며 다른 언어 값을 미리 만들지 않는다.
- 모든 항목은 수동 관리 항목(`extractionState: manual`)이다. 컴파일러 추출 항목을 두지 않는다.
- 카탈로그는 Xcode String Catalog 편집기로 편집하는 것을 기본으로 한다. 직접 편집한 경우 Xcode가 저장한 JSON
  형식을 유지한다.
- 쓰이지 않게 된 항목은 호출부를 지우는 같은 커밋에서 삭제한다.

### C.4 `localization/key.md` — 키

- 키는 소문자로 시작하는 lowerCamelCase Swift 식별자다. 점·밑줄·공백·한국어를 쓰지 않는다.
- 이름은 `<화면·컴포넌트><용도>` 순서다(`profileNicknameTitle`, `webSheetCloseAccessibilityLabel`, `savedEmptyMessage`).
  `Localizable` 테이블을 여러 컴포넌트·기능이 함께 쓰는 `UIComponent`·`GitIt`은 첫 단어가 반드시 컴포넌트·기능
  이름이어야 키가 테이블 안에서 유일하다.
- 테이블 이름이 주는 문맥(흐름 이름)은 키에 따로 붙이지 않는다. 키의 첫 단어는 화면·컴포넌트 이름이다.
  `Settings` 흐름의 `Profile` 화면 제목은 `profileTitle`이고, 흐름과 이름이 같은 `Settings` 화면의 제목은
  `settingsTitle`이다(`settingsSettingsTitle`이 아니다). 흐름의 `Router`·`Shared`가 쓰는 문구는 첫 단어를
  `router`·`shared`가 아니라 그 문구가 보이는 화면·컴포넌트 이름으로 쓴다.
- 용도 어휘는 `Title`, `Message`, `Description`, `ButtonTitle`, `Placeholder`, `ErrorMessage`,
  `AccessibilityLabel`, `AccessibilityHint`, `AccessibilityValue`처럼 표시 위치를 드러내는 명사로 끝낸다.
- 같은 한국어 값이라도 용도나 화면이 다르면 다른 키를 둔다. 값이 같다는 이유로 키를 공유하지 않는다.
- 한국어 값을 고쳐도 키는 바꾸지 않는다. 용도가 바뀌면 기존 항목을 지우고 새 키를 만든다.
- 이름 판단의 일반 기준은 [네이밍 컨벤션](../../../docs/conventions/naming.md)이 소유한다.

### C.5 `localization/entry-value.md` — 값과 주석

- 값은 화면에 보이는 최종 한국어 문구이며 줄바꿈은 `\n`으로 유지한다.
- 모든 항목은 주석을 가진다. 주석은 “어느 화면·컴포넌트의 어디에 보이는 무엇인지”를 한 문장으로 쓴다.
- 동적 값이 들어가는 문구는 이름 있는 위치 지정자를 쓴다. 수량은 `%1$(count)lld`, 문자열은
  `%1$(projectName)@` 형식이며, 주석에 `인자이름: 의미`를 인자마다 적는다.
- 문장을 여러 항목으로 쪼개 코드에서 이어 붙이지 않는다. 한 문장은 한 항목이다.
- 한국어는 복수 변형을 만들지 않는다. 수량 문구는 정수 지정자로 두어 다른 언어가 복수 변형을 추가할 수 있게 한다.
- 항목 형태의 예시는 [String Catalog 항목 계약](./string-catalog-entry.md)을 옮겨 둔다.

### C.6 `localization/localized-text.md` — `LocalizedText`

- 문구를 쓰는 target마다 case와 인스턴스 멤버가 없는 `internal enum LocalizedText` 하나를 둔다.
- 위치:
  - `Feature`: `Feature/Shared/Localization/LocalizedText.swift`에 루트, 흐름마다
    `Feature/Shared/Localization/LocalizedText+<흐름>.swift`에 `extension LocalizedText { enum <흐름> { … } }`
  - `UIComponent`: `UI/Component/Localization/LocalizedText.swift` 한 파일에 컴포넌트별 중첩 enum
  - `GitIt`: `App/GitIt/Localization/LocalizedText.swift` 한 파일에 기능별 중첩 enum
- 중첩 enum 이름은 `Feature`에서는 테이블(흐름) 이름, `UIComponent`에서는 컴포넌트 이름, `GitIt`에서는 기능 이름이다.
- 항목마다 멤버 하나를 둔다. 멤버 이름은 키에서 중첩 enum 이름과 같은 첫 단어를 뗀 이름이며, 첫 단어가 다르면
  키를 그대로 쓴다(`webSheetCloseAccessibilityLabel` → `LocalizedText.WebSheet.closeAccessibilityLabel`).
  인자가 없으면 `static var <멤버>: String`, 인자가 있으면 `static func <멤버>(<인자>) -> String`이다.
- 멤버 본문은 생성 심볼(`.<테이블>.<key>`, 기본 테이블은 `.<key>`)을 `String(localized:)`로 해석하는 식 하나다.
  값을 저장하는 `static let`을 쓰지 않는다.
- `LocalizedText`는 동적 문자열을 키로 받는 멤버를 두지 않는다.
- `LocalizedText`와 그 확장은 문자열 조회만 하며 흐름·화면 타입을 참조하지 않는다. 그래서 흐름별 확장을
  `Feature/Shared/`에 두어도 `Feature/Shared/**`의 참조 방향 제약을 지킨다.
- 선언 예시는 [LocalizedText 계약](./localized-text.md)을 옮겨 둔다.

### C.7 `localization/call-site.md` — 호출부

- 사용자 노출 문구는 `LocalizedText.<중첩>.<멤버>`로만 얻는다.
- production 소스에서 한국어 문자열 리터럴, 생성 심볼, `String(localized:)`, `LocalizedStringKey` 리터럴을
  `LocalizedText` 밖에서 직접 쓰지 않는다.
- View `Constant`는 현지화 문구를 소유하지 않는다. 한 View에서만 쓰는 문구라도 `LocalizedText`에 둔다.
- 표시 모델(`ViewModels/`)과 Reducer가 사용자 노출 문구를 만들 때도 `LocalizedText`를 쓴다.
- `UIComponent` 공개 입력은 `String`이다. Feature는 `LocalizedText`로 얻은 `String`을 넘기고,
  `UIComponent`가 내부 고정 문구를 스스로 조회한다. 현지화를 이유로 컴포넌트 공개 API를 바꾸지 않는다.
- SwiftUI `Text`·`accessibilityLabel` 등에는 `String` 값을 넘긴다. `Text("리터럴")`로 문구를 넘기지 않는다.

### C.8 `localization/development-language.md` — 개발 언어와 빌드 설정

- 모든 Tuist 프로젝트의 개발 언어는 `ko`다. `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의
  `Project.Options`가 `developmentRegion: "ko"`와 `defaultKnownRegions: ["ko", "Base"]`를 소유한다.
- 기기 언어가 지원 언어가 아니면 개발 언어(`ko`)로 대체된다. 따라서 어떤 기기 언어에서도 키나 빈 문자열이
  보이지 않아야 한다.
- 카탈로그를 가진 target은 `STRING_CATALOG_GENERATE_SYMBOLS = YES`, `SWIFT_EMIT_LOC_STRINGS = NO`다.
  프레임워크는 `Target+Module.swift`의 `module(...)`, 앱은 `AppModuleName.swift`가 설정을 소유한다.
- 카탈로그 리소스 선언은 target의 manifest가 소유한다. `Feature`는 `FeatureModuleName.swift`가
  `*/Resources/**`를 리소스로 선언한다.
- Tuist 리소스 합성기가 만드는 문자열 접근자는 쓰지 않는다.

### C.9 `localization/adding-language.md` — 언어 추가

- 언어 추가는 각 카탈로그에 그 언어 값을 추가하고 `defaultKnownRegions`에 언어를 더하는 것으로 끝난다.
  `LocalizedText`와 호출부를 바꾸지 않는다.
- 수량 문구는 그 언어에서 필요하면 카탈로그에서 복수 변형을 켠다.
- 번역하지 않은 항목이 남아 있으면 그 언어 환경에서 개발 언어 값이 보이므로, 릴리스 전 카탈로그의 번역 상태가
  모두 완료인지 확인한다.

### C.10 `localization/verification.md` — 검증

- 표시 문구를 검증하는 테스트는 키가 아니라 한국어 최종 문구를 기대값으로 삼는다. 조회에 실패하면 키가
  반환되어 테스트가 실패해야 한다.
- 카탈로그를 가진 target마다 대표 항목 하나가 한국어로 조회되는지 검증하는 테스트를 둔다
  (`Tests/<역할>/Localization/LocalizedTextTests.swift`). 테스트 이름과 구성은 [테스트 컨벤션](../../../docs/conventions/test.md)을 따른다.
- 리뷰는 다음 검사 결과가 제외 대상(§C.2)뿐인지 확인한다.

  ```sh
  grep -rn '"[^"]*[가-힣]' --include='*.swift' \
    sources/Projects/UI/Component sources/Projects/Feature sources/Projects/App/GitIt \
    | grep -v '/Tests/' | grep -v '/Previews/' | grep -v '/Derived/'
  ```

- 자동 누락 검출과 pre-commit·CI 강제는 이 컨벤션의 범위 밖이다.

## D. 기존 문서 수정

규칙은 현지화 컨벤션이 소유하고, 아래 문서에는 해당 자리의 한 줄 요약과 링크만 둔다
([cross-reference.md](../../../docs/conventions/common/cross-reference.md)).

| 문서 | 수정 |
| --- | --- |
| `docs/conventions/README.md` | 표에 `[현지화](./localization.md)` — “사용자 노출 문구의 카탈로그, 키, `LocalizedText` 조회 진입점과 제외 대상” 행 추가 |
| `docs/conventions/file-vocabulary/shape-vocabulary.md` | **UIComponent 단위 첫 작업**: `Feature/Shared/`·`UI/Component/`·`App/GitIt/`에 `Localization/` 행(“모듈 문구 전용 타입 `LocalizedText`”, `Feature/Shared/` 행은 “와 흐름별 확장”)을 추가하고, `Feature/<흐름>/Resources/`, `UI/Component/Resources/`, `App/GitIt/Resources/`의 설명에 “문구 카탈로그”를 추가. **문서 단위**: 세 행에 현지화 컨벤션 §4.1 링크를 연결 |
| `docs/conventions/directory-file/resources.md` | “String Catalog(`*.xcstrings`)도 `Resources/`가 소유하며 배치와 형식은 현지화 컨벤션 §3.1이 소유한다” 추가 |
| `docs/conventions/directory-file/feature-layout.md` | 1뎁스 표의 `Resources/` 설명을 “흐름이 소유하는 자산과 문구 카탈로그 (§6)”로 수정 |
| `docs/conventions/ui-component/folder-file.md` | **UIComponent 단위 첫 작업**: `UI/Component/` 1뎁스 허용 목록에 `Localization/`(모듈 문구 전용 타입) 추가. **문서 단위**: 현지화 컨벤션 §4.1 링크를 연결 |
| `docs/conventions/ui-component/asset.md` | “컴포넌트 고정 문구는 `Component/Resources/Localizable.xcstrings`가 소유하며 Feature는 UIComponent 문구를 조회하지 않는다” 추가 |
| `docs/conventions/view-declarations/constant.md` | 첫 문단의 “정적 문자열”을 “사용자에게 보이지 않는 정적 문자열”로 바꾸고, “사용자 노출 문구는 `Constant`가 아니라 현지화 컨벤션 §4.1의 `LocalizedText`가 소유한다” 추가 |
| `docs/conventions/view-declarations.md` | §2.1 요약 문장을 위와 같게 수정 |
| `docs/package-rules/ui.md` | “구현 컨벤션”에 “사용자 노출 문구의 소유와 조회는 [현지화 컨벤션](../conventions/localization.md)을 따릅니다” 추가 |
| `docs/package-rules/feature.md` | 같은 문장을 “구현 컨벤션”에 추가 |
| `docs/package-rules/app.md` | “정책”에 “앱이 표시하는 문구(로컬 알림 등)는 [현지화 컨벤션](../conventions/localization.md)을 따릅니다” 추가 |

수정한 문서의 `최종 수정일`을 구현 날짜와 변경 요약으로 갱신한다.
