# Git It iOS 파일·형태 어휘 컨벤션

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-08-31 ([디렉터리·파일 컨벤션](./directory-file.md)에서 분리)

## 목적

이 문서는 한 Swift 파일이 정의할 수 있는 타입 개수와 파일 이름 규칙, 그리고 각
패키지의 1뎁스 형태 폴더가 사용할 수 있는 **형태 어휘의 정본**을 정의합니다. 폴더가
몇 뎁스까지 허용되는지, 1뎁스가 형태이고 2뎁스가 관심사라는 배치 축 자체는
[디렉터리·파일 컨벤션](./directory-file.md)이 소유합니다. 이 문서는 그 폴더 **안에
놓이는 파일**의 이름·개수 규칙과, 형태 폴더 자리에 쓸 수 있는 **이름의 목록**만
소유합니다. 상위 문서와의 우선순위는
[컨벤션 공통 규칙](./README.md#상위-문서와-충돌-해소)을 따릅니다.

## 1. 적용 범위

적용합니다.

- `sources/Projects/<패키지>/` 아래 production·test Swift 소스 파일 이름과 파일당
  타입 개수
- [디렉터리·파일 컨벤션 §4](./directory-file.md#4-1뎁스--형태-폴더)가 정의하는 1뎁스
  형태 폴더 자리에 쓸 수 있는 이름의 목록

적용하지 않습니다.

- 폴더 뎁스, 소스 루트 계산과 타입 패밀리 폴더 판단 기준 —
  [디렉터리·파일 컨벤션](./directory-file.md)이 소유합니다.
- View 내부 선언을 중첩할지 여부 —
  [View 내부 선언 컨벤션 §2](./view-declarations.md#2-view-내부-선언)가 소유합니다.

## 2. 파일 규칙

### 2.1 파일 하나에 타입 하나

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
`AnswerDTOs.swift` 같은 이름은 사용하지 않고 타입별 파일로 나눈 뒤
[디렉터리·파일 컨벤션 §5](./directory-file.md#5-2뎁스--타입-패밀리-폴더)의 폴더로
묶습니다.

### 2.2 중첩 타입 분리

타입에 중첩한 선언을 별도 파일로 나눌 때는 `{상위타입}+{중첩타입}.swift`를 사용하고,
파일 안에서는 `extension`으로 선언합니다.

```swift
// Scaffolds/ScreenHeader/ScreenHeader+Style.swift
extension ScreenHeader {
    public enum Style { ... }
}
```

중첩할지 여부 자체는
[View 내부 선언 컨벤션 §2](./view-declarations.md#2-view-내부-선언)가 정합니다. 이
문서는 나눈 파일의 이름과 위치만 정합니다.

### 2.3 기존 타입 확장

프로젝트 밖 타입이나 다른 형태의 타입을 확장하는 파일은 `{확장 대상}+{주제}.swift`를
사용합니다.

```text
Extensions/View+ColorToken.swift
Models/HTTPRequest+QueryItem.swift
```

`+` 뒤에는 그 파일이 추가하는 개념을 씁니다. `Extension`, `Helper`, `Utils` 같은
포괄어를 뒤에 붙이지 않습니다.

### 2.4 중첩할 수 없는 타입

프로토콜처럼 Swift 제약으로 중첩할 수 없거나, 제네릭 타입에 중첩하면 호출부가 제네릭
인자를 적어야 하는 선언은 최상위에 두고 이름에 소유 타입을 남깁니다
([View 내부 선언 컨벤션 §2.4](./view-declarations.md#24-중첩할-수-없는-경우)). 파일은
소유 타입의 패밀리 폴더에 둡니다.

```text
Scaffolds/TabShell/
├── TabShell.swift
├── TabShellItem.swift          # protocol이라 중첩 불가
└── TabShellPreviewItem.swift   # 프리뷰 전용(§2.5)
```

### 2.5 프리뷰 전용 타입

프리뷰 전용 타입은 컴포넌트의 계약이 아니므로 컴포넌트 파일에 두지 않고
`{소유타입}Preview{역할}.swift`로 분리해 같은 패밀리 폴더에 둡니다
([View 컨벤션 §5](./view.md#5-프리뷰)).

### 2.6 테스트 파일 이름

테스트 파일 이름은 `<검증 대상>Tests.swift`를 사용합니다. 검증 대상이 타입이 아니라
동작 범위이면 그 범위를 이름으로 씁니다(`SensitiveValueExposureTests.swift`).

## 3. 패키지별 형태 어휘

아래 표가 형태 폴더 이름의 정본이며 현재 저장소 구조와 일치합니다. 표에 없는 형태를
추가하려면 같은 PR에서 이 표를 갱신합니다. 형태 폴더를 판단하는 기준 자체는
[디렉터리·파일 컨벤션 §4.1](./directory-file.md#41-판단-기준)을 따릅니다.

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
| | `Sources/` | 외부에서 주입되는 프로세스 내 데이터 소스 구현 |
| | `Stores/` | 로컬 저장 계약 구현 |
| | `Models/` | Data 내부 모델 |
| | `Errors/` | Data 오류 타입 |
| `Infrastructure/<능력>/[<하위 능력>/]` | `Clients/` | 기술 능력의 공개 진입 타입 |
| | `Transports/` | 전송 계층 계약과 구현 |
| | `Stores/` | 저장 계층 계약과 구현 |
| | `Providers/` | 플랫폼 API를 감싸는 제공자 |
| | `Models/` | 요청·응답·설정 값 타입 |
| | `Errors/` | 기술 오류 타입 |
| | `AppDelegates/` | 플랫폼 생명주기 delegate 타입 |
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
검사, 생명주기 검증 — 은 형태 폴더가 아니라
[디렉터리·파일 컨벤션 §3.3](./directory-file.md#33-test-소스-루트)의 test 소스 루트에
둡니다.

## 4. 검토 체크리스트

- [ ] 파일 밖에서 참조되는 최상위 타입이 파일당 하나인가?
- [ ] 파일 이름이 타입 이름과 정확히 일치하는가?
- [ ] 중첩 타입 분리 파일이 `{상위타입}+{중첩타입}.swift`인가?
- [ ] 기존 타입 확장 파일이 `{확장 대상}+{주제}.swift`이고 포괄어를 쓰지 않았는가?
- [ ] 테스트 파일 이름이 `<대상>Tests.swift`이고 공유 Double이 `TestDoubles/`에 있는가?
- [ ] 형태 폴더 이름이 이 문서 §3의 표에 있는가? 표에 없으면 같은 PR에서 표를
      갱신했는가?
- [ ] 형태 폴더 이름이 복수형 PascalCase인가?

## 관련 문서

- [디렉터리·파일 컨벤션](./directory-file.md)
- [테스트 컨벤션](./test.md)
- [View 컨벤션](./view.md)
- [View 내부 선언 컨벤션](./view-declarations.md)
- [UIComponent 컨벤션](./ui-component.md)

## 문서 변경 기준

파일당 타입 개수, 파일 이름 규칙 또는 패키지별 형태 어휘가 바뀔 때 수정합니다. 폴더
뎁스와 소스 루트 계산 방식이 바뀌면 이 문서보다
[디렉터리·파일 컨벤션](./directory-file.md)을 먼저 갱신합니다.
