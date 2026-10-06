# Git It iOS 디렉터리·파일 컨벤션

**상태**: 초안

**작성일**: 2026-08-27

**최종 수정일**: 2026-08-31 (문서 간 중복 제거와 소유 문서 정리)

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
[View 컨벤션](./view.md)이 소유합니다. 파일당 타입 개수, 파일 이름 규칙과 형태 폴더
어휘의 정본은 [파일·형태 어휘 컨벤션](./file-vocabulary.md)이 소유합니다. 이 문서는
**그 선언이 어느 폴더에 놓이는지**만 정합니다. 상위 문서와의 우선순위는
[컨벤션 공통 규칙](./README.md#상위-문서와-충돌-해소)을 따릅니다.

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

파일 하나에 타입을 몇 개 담을 수 있는지, 파일 이름 규칙과 형태 폴더 이름의 어휘
목록은 [파일·형태 어휘 컨벤션](./file-vocabulary.md)이 소유합니다.

## 6. 자산과 생성물

- 자산은 소스 루트 아래 `Resources/`가 소유합니다. Swift 소스와 같은 형태 폴더에 섞지
  않습니다.
- `*.xcassets` 내부 폴더 구조는 Xcode 자산 카탈로그가 소유하므로 §2의 뎁스 규칙을
  적용하지 않습니다.
- 서드파티가 배포한 폰트 폴더는 배포 구조를 그대로 보존한 채 `Resources/Fonts/` 아래에
  둡니다.
- `Derived/`, `build/`, `*.xcodeproj`는 Tuist 생성물이므로 손으로 만들거나 옮기지
  않습니다.

## 7. Tuist 매니페스트와의 일치

- 실제 폴더 경로와 `*ModuleName.swift`의 `sourceDirectory` 계산 결과는 항상 같아야
  합니다.
- 폴더를 옮기거나 이름을 바꾸면 매니페스트를 **같은 커밋에서** 갱신합니다.
- `sourceDirectory`는 각 `ModuleName` enum의 연산 프로퍼티에서 target 이름 앞의
  패키지명을 제거해 계산하며, 문자열을 직접 적어 우회하지 않습니다
  ([네이밍 컨벤션 §4](./naming.md#4-패키지-문맥)).
- 계산한 경로는 `Target.module` 또는 `Target.testModule`의 필수 `sourceDirectory`
  인자로 전달합니다. 테스트 target은 §3.3의 `Tests/<역할>/` 아래에 배치합니다.
- 형태 폴더나 타입 패밀리 폴더를 추가할 때 source glob은 바꾸지 않습니다. 공통 Tuist
  helper는 전달받은 경로에 `/**`만 붙이며, target 이름을 glob의 기본값으로 사용하거나
  별도 폴더명을 덧붙이지 않습니다.

## 8. 검토 체크리스트

### 경로

- [ ] 소스 루트 아래 폴더 뎁스가 2 이하인가?
- [ ] 1뎁스 폴더가 형태이고 2뎁스 폴더가 관심사인가? 두 축이 뒤바뀌지 않았는가?
- [ ] 형태 폴더 이름이 [파일·형태 어휘 컨벤션 §3](./file-vocabulary.md#3-패키지별-형태-어휘)의
      표에 있는가? 표에 없으면 같은 PR에서 표를 갱신했는가?
- [ ] 형태 폴더 자리에 `Common`, `Shared`, `Utils`, `Etc` 같은 잔여 이름을 쓰지
      않았는가?
- [ ] 관심사 세그먼트를 추가했다면 target 분리를 먼저 검토했는가?
- [ ] 타입 패밀리 폴더가 파일 둘 이상일 때만 존재하는가?

### 매니페스트

- [ ] 실제 폴더와 `sourceDirectory` 계산 결과가 일치하는가?
- [ ] 폴더 이동을 매니페스트 갱신과 같은 커밋에 담았는가?
- [ ] source glob이 소스 루트 아래 `/**` 하나로 유지되는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [네이밍 컨벤션](./naming.md)
- [파일·형태 어휘 컨벤션](./file-vocabulary.md)
- [테스트 컨벤션](./test.md)
- [View 컨벤션](./view.md)
- [UIComponent 컨벤션](./ui-component.md)

## 문서 변경 기준

소스 루트 계산 방식, 폴더 뎁스 규칙 또는 관심사 세그먼트 기준이 바뀔 때 수정합니다.
파일 분할 기준이나 패키지별 형태 어휘가 바뀌면 이 문서가 아니라
[파일·형태 어휘 컨벤션](./file-vocabulary.md)을 갱신합니다. target 이름과 폴더
이름의 관계가 바뀌면 이 문서보다 [네이밍 컨벤션](./naming.md)을 먼저 갱신합니다.
컴포넌트 역할 폴더의 목록과 판정 기준은 이 문서가 아니라
[UIComponent 컨벤션](./ui-component.md)이 소유합니다.
