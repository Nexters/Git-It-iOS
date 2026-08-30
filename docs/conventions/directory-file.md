# Git It iOS 디렉터리·파일 컨벤션

**상태**: 초안

**작성일**: 2026-08-27

**최종 수정일**: 2026-08-27

## 목적

이 문서는 `sources/Projects/` 아래 모든 패키지가 **공통으로** 지키는 폴더 구조와 파일
분할 기준을 정의합니다.

배치 기준은 원래 패키지마다 달랐습니다. Domain·Data는 1뎁스를 형태(`Models/`,
`Contracts/`)로, Infrastructure는 기술 영역(`Keychain/`, `AppleAuthentication/`)으로,
UIComponent는 구현 의존 구조(`Leaf/`, `Composite/`)로 사용했고 같은 역할의 폴더 이름도
`Mocks/`와 `TestDouble/`로 갈라져 있었습니다. 이 문서는 그 기준을 하나로 통일하고 각
패키지가 사용할 수 있는 **폴더 어휘의 정본**(§7)을 소유합니다.

공개 이름의 어휘 선택은 [네이밍 컨벤션](./naming.md), 테스트 target·scheme 연결은
[테스트 컨벤션](./test.md), View 내부 선언을 중첩할지 여부는
[View 컨벤션](./view.md)이 소유합니다. 이 문서는 **그 선언이 어느 폴더의 어느 파일에
놓이는지**만 정합니다. Constitution 또는 [아키텍처 문서](../architecture.md)와 충돌하면
상위 문서를 따르고 이 문서를 수정합니다.

## 1. 적용 범위

적용합니다.

- `sources/Projects/<패키지>/` 아래 production·test Swift 소스 파일과 그 폴더
- 각 target이 소유하는 `Resources/` 자산 폴더의 최상위 구성
- `sources/Tuist/ProjectDescriptionHelpers/Projects/*ModuleName.swift`가 계산하는
  `sourceDirectory` 경로

적용하지 않습니다.

- Tuist·Xcode 생성물: `Derived/`, `build/`, `*.xcodeproj`, `*.xcworkspace`
- 패키지 루트의 `Project.swift`와 `Config/`
- `*.xcassets` 내부 구조와 서드파티가 배포한 폰트·리소스 폴더 구조 — 도구와 배포본이
  소유합니다(§8)
- `docs/`, `tools/`, `.agents/`, `specs/`

## 2. 경로 구조

```text
sources/Projects/<패키지>/<소스 루트>/<형태>/<타입 패밀리>/<파일>.swift
                          └─────────┘ └────┘ └──────────┘
                            target 경계   1뎁스      2뎁스
```

- 뎁스는 **소스 루트부터** 셉니다. `sources/Projects/<패키지>`까지의 경로는 뎁스에
  포함하지 않습니다.
- 소스 루트 아래 폴더는 **최대 2뎁스**입니다. 3뎁스 폴더는 만들지 않습니다.
- 1뎁스는 **형태**(선언의 종류) 하나만 사용합니다(§4).
- 2뎁스는 **관심사**(하나의 메인 타입 또는 하나의 책임) 하나만 사용합니다(§5).
- 두 축을 뒤섞지 않습니다. 1뎁스에 관심사를, 2뎁스에 형태를 두는 배치는 사용하지
  않습니다. `UseCases/Protocols/`처럼 형태 안에 형태를 다시 두는 배치도 같은 이유로
  사용하지 않습니다.

## 3. 소스 루트

소스 루트는 Tuist target의 `sourceDirectory`가 가리키는 폴더이며 **하나의 관심사
경계**를 담습니다. 폴더 이름은 [네이밍 컨벤션 §4](./naming.md#4-패키지-문맥)에 따라
target 이름에서 패키지 접두어를 제거한 역할 이름을 사용합니다.

### 3.1 production 소스 루트

```text
sources/Projects/<패키지>/<역할>/
```

`DomainAuthentication` target의 소스 루트는 `Domain/Authentication/`, `UIComponent`
target의 소스 루트는 `UI/Component/`입니다.

### 3.2 관심사 세그먼트

하나의 target이 서로 독립적인 관심사를 둘 이상 담고 있으면 소스 루트 아래에 **관심사
세그먼트**를 하나 더 두고, 형태·타입 패밀리 뎁스는 그 아래에서 셉니다.

```text
sources/Projects/Feature/Onboarding/Screens/
                 └─────┘ └────────┘ └──────┘
                  소스 루트  관심사    1뎁스

sources/Projects/Infrastructure/Authentication/Keychain/Stores/
                 └────────────────────────────┘ └──────┘ └────┘
                          소스 루트              관심사   1뎁스
```

Infrastructure는 하나의 기술 능력 target이 여러 하위 능력을 담을 수 있으므로 관심사
세그먼트를 기본으로 사용합니다. `Authentication` target의 Apple 인증·Keychain·난수는
서로 대체되지 않는 기술 능력이며, target을 쪼개지 않고 관심사 세그먼트로 구분합니다.

여러 관심사가 함께 쓰는 선언은 `Shared` 관심사 세그먼트에 모으고, 그 아래에서도 형태
폴더 규칙을 그대로 적용합니다(`Feature/Shared/Models/`). `Shared`는 관심사 세그먼트
자리에서만 쓸 수 있고 형태 폴더 이름으로는 쓰지 않습니다(§4.1).

관심사 세그먼트는 **target 분리를 미루기 위한 수단이 아닙니다.** 새 관심사가 생기면
target 분리를 먼저 검토하고, 분리하지 않기로 했다면 그 이유를 PR에 남깁니다. 관심사
세그먼트는 한 단계만 허용하며 중첩하지 않습니다.

### 3.3 test 소스 루트

```text
sources/Projects/<패키지>/Tests/<역할>/
```

test 소스 루트 아래 구조는 production과 동일한 규칙을 따릅니다. 같은 production 모듈에
test target이 둘 이상이면 [테스트 컨벤션 §7.1](./test.md#7-파일과-target-구성)에 따라
`Tests/<역할>/<구분>/`을 소스 루트로 사용합니다 — 이때 소스 루트는 두 세그먼트이며
뎁스는 그 아래부터 셉니다.

### 3.4 진입점 파일

`@main`을 선언하는 실행 진입점 파일은 형태 폴더에 넣지 않고 소스 루트 바로 아래에
둡니다. 진입점은 종류가 아니라 target 자체를 대표하는 단 하나의 파일입니다.

```text
App/GitIt/GitItApp.swift
UI/ComponentPreviewApp/UIComponentPreviewAppApp.swift
```

## 4. 1뎁스 — 형태 폴더

### 4.1 판단 기준

형태는 **"이 파일이 무슨 종류의 선언인가"**에 대한 답입니다. 모델인지, 계약인지, 유스
케이스인지, 오류인지처럼 **선언이 코드에서 맡는 종류**로만 판단합니다.

다음은 형태의 기준이 아닙니다.

- 구현 의존 구조 — 다른 프로젝트 타입을 참조하는지 여부
- 파일 크기, 줄 수, 사용처 개수
- 어느 기능에서 처음 만들어졌는지
- `Common`, `Shared`, `Utils`, `Etc`, `Misc`처럼 나머지를 모으는 이름 — 형태 폴더
  자리에 쓰지 않습니다. `Shared`는 §3.2의 관심사 세그먼트 자리에서만 허용합니다.

형태를 정할 수 없는 선언은 폴더가 아니라 **책임이 불명확한 것**입니다. 폴더를 만들기
전에 선언의 책임을 먼저 정리합니다.

### 4.2 규칙

- 형태 폴더는 담는 파일이 **하나뿐이어도 만듭니다.** 모든 target에서 같은 경로로 같은
  종류를 찾을 수 있어야 합니다.
- 이름은 그 종류를 나타내는 **복수형 영문 명사**를 PascalCase로 씁니다.
  (`Models`, `Contracts`, `UseCases`, `Errors`, `Tokens`, `TestDoubles`)
- 표준 약어는 [네이밍 컨벤션 §6](./naming.md#6-축약과-약어)을 따르고 복수형 `s`만
  소문자로 붙입니다. (`DTOs` ○ / `DTOS` ×, `Dtos` ×)
- 형태 어휘는 자유롭게 늘리지 않습니다. §7의 표에 없는 형태 폴더를 추가하려면 같은
  PR에서 §7을 함께 갱신합니다.

## 5. 2뎁스 — 타입 패밀리 폴더

### 5.1 규칙

한 메인 타입에 딸린 파일이 **둘 이상일 때만** 그 타입 이름의 폴더를 만들고 파일을
모읍니다. 파일이 하나면 폴더를 만들지 않고 형태 폴더에 직접 둡니다.

```text
Controls/
├── ActionButton.swift              # 파일이 하나이므로 폴더를 만들지 않는다
└── TextField/
    ├── TextField.swift
    └── TextField+Style.swift
```

타입 패밀리 폴더에 함께 두는 파일은 다음과 같습니다.

- 메인 타입 파일
- 중첩 타입을 분리한 `{메인타입}+{중첩타입}.swift`(§6.2)
- 중첩할 수 없어 최상위로 꺼낸 보조 타입(§6.4)
- 그 메인 타입 전용 프리뷰 타입(§6.5)

두 타입이 공유하는 보조 타입은 **이름을 소유한 타입**의 패밀리 폴더에 둡니다. 예를
들어 `SelectionCardStyle`은 `SelectionCard`와 `SelectionCardList`가 함께 쓰더라도
`SelectionCard/`에 둡니다.

### 5.2 책임 이름 폴더

메인 타입이 없지만 하나의 외부 계약이나 한 가지 책임에 함께 속하는 파일이 둘 이상이면
**책임 이름**의 폴더를 사용할 수 있습니다. 같은 API 연산의 요청·응답 DTO 묶음이
대표적입니다.

```text
DTOs/
└── Answer/
    ├── SubmitChoiceAnswerRequestDTO.swift
    ├── SubmitChoiceAnswerResponseDTO.swift
    ├── SubmitEssayAnswerRequestDTO.swift
    └── SubmitEssayAnswerResponseDTO.swift
```

책임 이름 폴더는 형태 폴더의 대체물이 아닙니다. 묶으려는 파일들의 **형태가 서로
다르면** 폴더로 묶을 것이 아니라 각자의 형태 폴더로 나눕니다.

## 6. 파일 규칙

### 6.1 파일 하나에 타입 하나

**파일 하나는 파일 밖에서 참조되는 최상위 타입을 하나만 정의하고, 파일 이름은 그 타입
이름과 정확히 일치합니다.** `struct`, `enum`, `class`, `actor`, `protocol` 모두 같은
규칙을 따릅니다.

다음은 개수에 포함하지 않습니다.

- `private`·`fileprivate` 보조 선언
- 같은 파일의 타입에 대한 `extension`
- `#Preview` 매크로

테스트 파일은 `@Suite` 또는 `XCTestCase` 타입 하나와, 그 파일에서만 사용하는 `private`
Test Double을 함께 둘 수 있습니다([테스트 컨벤션 §7.1](./test.md#7-파일과-target-구성)).
둘 이상의 파일에서 쓰는 Double은 `TestDoubles/`로 옮깁니다.

파일 이름은 타입 이름을 축약하거나 복수화하지 않습니다. 여러 타입을 한 파일에 묶은
`AnswerDTOs.swift` 같은 이름은 사용하지 않고 타입별 파일로 나눈 뒤 §5의 폴더로
묶습니다.

### 6.2 중첩 타입 분리

타입에 중첩한 선언을 별도 파일로 나눌 때는 `{상위타입}+{중첩타입}.swift`를 사용하고,
파일 안에서는 `extension`으로 선언합니다.

```swift
// Scaffolds/ScreenHeader/ScreenHeader+Style.swift
extension ScreenHeader {
    public enum Style { ... }
}
```

중첩할지 여부 자체는 [View 컨벤션 §5](./view.md#5-view-내부-선언)가 정합니다. 이
문서는 나눈 파일의 이름과 위치만 정합니다.

### 6.3 기존 타입 확장

프로젝트 밖 타입이나 다른 형태의 타입을 확장하는 파일은 `{확장 대상}+{주제}.swift`를
사용합니다.

```text
Extensions/View+ColorToken.swift
Models/HTTPRequest+QueryItem.swift
```

`+` 뒤에는 그 파일이 추가하는 개념을 씁니다. `Extension`, `Helper`, `Utils` 같은
포괄어를 뒤에 붙이지 않습니다.

### 6.4 중첩할 수 없는 타입

프로토콜처럼 Swift 제약으로 중첩할 수 없거나, 제네릭 타입에 중첩하면 호출부가 제네릭
인자를 적어야 하는 선언은 최상위에 두고 이름에 소유 타입을 남깁니다
([View 컨벤션 §5.4](./view.md#54-중첩할-수-없는-경우)). 파일은 소유 타입의 패밀리
폴더에 둡니다.

```text
Scaffolds/TabShell/
├── TabShell.swift
├── TabShellItem.swift          # protocol이라 중첩 불가
└── TabShellPreviewItem.swift   # 프리뷰 전용(§6.5)
```

### 6.5 프리뷰 전용 타입

프리뷰 전용 타입은 컴포넌트의 계약이 아니므로 컴포넌트 파일에 두지 않고
`{소유타입}Preview{역할}.swift`로 분리해 같은 패밀리 폴더에 둡니다
([View 컨벤션 §8](./view.md#8-프리뷰)).

### 6.6 테스트 파일 이름

테스트 파일 이름은 `<검증 대상>Tests.swift`를 사용합니다. 검증 대상이 타입이 아니라
동작 범위이면 그 범위를 이름으로 씁니다(`SensitiveValueExposureTests.swift`).

## 7. 패키지별 형태 어휘

아래 표가 형태 폴더 이름의 정본이며 현재 저장소 구조와 일치합니다. 표에 없는 형태를
추가하려면 같은 PR에서 이 표를 갱신합니다.

| 소스 루트 | 형태 폴더 | 담는 선언 |
| --- | --- | --- |
| `Domain/<관심사>/` | `Models/` | 비즈니스 모델과 값 타입 |
| | `Contracts/` | Domain이 외부에 요구하는 계약 프로토콜 |
| | `UseCases/` | 유스케이스 계약과 그 구현 |
| | `Errors/` | Domain 오류 타입 |
| `Data/<관심사>/` | `DTOs/` | 외부 전송 모델 |
| | `Requests/` | 요청 값 타입 |
| | `Endpoints/` | 엔드포인트와 요청 조립 |
| | `Contracts/` | Data가 정의하는 remote·store 계약 |
| | `Remotes/` | 네트워크 계약 구현 |
| | `Stores/` | 로컬 저장 계약 구현 |
| | `Models/` | Data 내부 모델 |
| | `Errors/` | Data 오류 타입 |
| `Infrastructure/<능력>/[<하위 능력>/]` | `Clients/` | 기술 능력의 공개 진입 타입 |
| | `Transports/` | 전송 계층 계약과 구현 |
| | `Stores/` | 저장 계층 계약과 구현 |
| | `Providers/` | 플랫폼 API를 감싸는 제공자 |
| | `Models/` | 요청·응답·설정 값 타입 |
| | `Errors/` | 기술 오류 타입 |
| `Composition/Adapter/` | `Adapters/` | Domain 계약을 구현하는 Adapter |
| | `Assemblies/` | 조립 진입 타입과 객체 수명 선택 |
| | `Codings/` | 경계 간 인코딩·디코딩 |
| | `Layouts/` | 저장소 키 배치 |
| | `Factories/` | 구현 선택과 생성 |
| `Feature/<기능>/` | `Reducers/` | Feature, State, Action, Reducer |
| | `Screens/` | 화면 View |
| | `Previews/` | 화면 프리뷰와 프리뷰 전용 타입 |
| | `Models/` | 화면 전용 표시 모델 |
| `UI/DesignSystem/` | `Tokens/` | 원시·의미 디자인 토큰 |
| | `Extensions/` | 토큰 적용 API와 폰트 등록 |
| | `Resources/` | 폰트 자산 |
| `UI/Component/` | 역할 폴더 | [UIComponent 컨벤션 §3](./ui-component.md#3-컴포넌트-역할-분류)이 소유 |
| | `Resources/` | 이미지·애니메이션 자산 |
| `UI/ComponentPreviewApp/` | `Catalogs/` | 레이아웃 계약 검토 카탈로그 |
| `App/GitIt/` | `Reducers/` · `Screens/` | 앱 루트 Feature와 화면 |
| | `Configurations/` | 실행 환경과 번들 설정 |
| | `Loaders/` | 번들 리소스 해석 |
| | `Resources/` | 앱 자산과 정책 문서 |
| | `AppDelegates/` | 플랫폼 생명주기 delegate 타입 |
| `Tests/<역할>/` | production과 같은 형태 폴더 | 대상 형태를 그대로 사용 |
| | `TestDoubles/` | 둘 이상의 파일에서 쓰는 Test Double |

`Mocks/`는 사용하지 않습니다. Stub·Spy·Fake를 모두 포함하는 `TestDoubles/`로 통일합니다.

여러 형태에 걸쳐 있어 하나의 형태로 판정할 수 없는 테스트 — 앱 조립 검증, 민감 값 노출
검사, 생명주기 검증 — 은 형태 폴더가 아니라 test 소스 루트에 둡니다.

## 8. 자산과 생성물

- 자산은 소스 루트 아래 `Resources/`가 소유합니다. Swift 소스와 같은 형태 폴더에 섞지
  않습니다.
- `*.xcassets` 내부 폴더 구조는 Xcode 자산 카탈로그가 소유하므로 §2의 뎁스 규칙을
  적용하지 않습니다.
- 서드파티가 배포한 폰트 폴더는 배포 구조를 그대로 보존한 채 `Resources/Fonts/` 아래에
  둡니다.
- `Derived/`, `build/`, `*.xcodeproj`는 Tuist 생성물이므로 손으로 만들거나 옮기지
  않습니다.

## 9. Tuist 매니페스트와의 일치

- 실제 폴더 경로와 `*ModuleName.swift`의 `sourceDirectory` 계산 결과는 항상 같아야
  합니다.
- 폴더를 옮기거나 이름을 바꾸면 매니페스트를 **같은 커밋에서** 갱신합니다.
- `sourceDirectory`는 target 이름에서 패키지 접두어를 제거해 계산하며, 문자열을 직접
  적어 우회하지 않습니다([네이밍 컨벤션 §4](./naming.md#4-패키지-문맥)).
- 형태 폴더나 타입 패밀리 폴더를 추가할 때 source glob은 바꾸지 않습니다. glob은 소스
  루트 아래 `/**` 하나만 사용합니다.

## 10. 검토 체크리스트

### 경로

- [ ] 소스 루트 아래 폴더 뎁스가 2 이하인가?
- [ ] 1뎁스 폴더가 형태이고 2뎁스 폴더가 관심사인가? 두 축이 뒤바뀌지 않았는가?
- [ ] 형태 폴더 이름이 §7의 표에 있는가? 표에 없으면 같은 PR에서 표를 갱신했는가?
- [ ] 형태 폴더 이름이 복수형 PascalCase인가?
- [ ] 형태 폴더 자리에 `Common`, `Shared`, `Utils`, `Etc` 같은 잔여 이름을 쓰지
      않았는가?
- [ ] 관심사 세그먼트를 추가했다면 target 분리를 먼저 검토했는가?

### 파일

- [ ] 파일 밖에서 참조되는 최상위 타입이 파일당 하나인가?
- [ ] 파일 이름이 타입 이름과 정확히 일치하는가?
- [ ] 중첩 타입 분리 파일이 `{상위타입}+{중첩타입}.swift`인가?
- [ ] 기존 타입 확장 파일이 `{확장 대상}+{주제}.swift`이고 포괄어를 쓰지 않았는가?
- [ ] 타입 패밀리 폴더가 파일 둘 이상일 때만 존재하는가?
- [ ] 테스트 파일 이름이 `<대상>Tests.swift`이고 공유 Double이 `TestDoubles/`에 있는가?

### 매니페스트

- [ ] 실제 폴더와 `sourceDirectory` 계산 결과가 일치하는가?
- [ ] 폴더 이동을 매니페스트 갱신과 같은 커밋에 담았는가?
- [ ] source glob이 소스 루트 아래 `/**` 하나로 유지되는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [네이밍 컨벤션](./naming.md)
- [테스트 컨벤션](./test.md)
- [View 컨벤션](./view.md)
- [UIComponent 컨벤션](./ui-component.md)

## 문서 변경 기준

소스 루트 계산 방식, 폴더 뎁스 규칙, 파일 분할 기준 또는 패키지별 형태 어휘가 바뀔 때
수정합니다. target 이름과 폴더 이름의 관계가 바뀌면 이 문서보다
[네이밍 컨벤션](./naming.md)을 먼저 갱신합니다. 컴포넌트 역할 폴더의 목록과 판정
기준은 이 문서가 아니라 [UIComponent 컨벤션](./ui-component.md)이 소유합니다.
