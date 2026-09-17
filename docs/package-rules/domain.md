# Domain 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

## 설명

Domain은 프로젝트의 비즈니스 언어와 규칙을 표현하는 핵심 경계입니다. 도메인 모델, Value Object, 비즈니스 정책, Use Case와 비즈니스 기능이 요구하는 외부 기능 계약을 소유합니다.

Domain의 공개 API는 비즈니스 의미를 기준으로 설계하며 Feature와 Composition이 동일한 비즈니스 언어로 기능을 사용할 수 있도록 제공합니다.

## 정책

- 공개 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 비즈니스 책임과 필요한 최소 문맥을 사용하고 공급자, 서버 schema 또는 저장·플랫폼 기술 용어를 노출해서는 안 됩니다. 계약 접미어와 연산 이름의 판정 기준은 [아키텍처 결정 기록 D-ARCH-004](../architecture.md#9-아키텍처-결정-기록)를 따릅니다.
- 모든 내부 target은 도메인 모델, Value Object, 비즈니스 규칙, 정책, Use Case 또는 외부 기능 계약을 소유해야 합니다.
- 외부 데이터 기능이 필요한 경우 Domain의 필요와 언어로 계약을 정의해야 합니다.
- 모든 공개 API는 기술이나 실행 환경과 무관한 도메인 의미로 표현해야 합니다.
- Domain 계약은 Test Double로 대체할 수 있는 형태로 설계해야 합니다.

## UseCase 분해 기준

UseCase를 독립 타입으로 둘지, 모듈 능력 단위 계약에 합칠지는 아래 기준 하나로 판정합니다.

**독립 타입으로 둡니다.** 다음 두 조건 중 하나 이상을 충족하는 경우입니다.

1. 저장소 호출 외에 판단, 조율, 보상 또는 동시성 제어를 수행한다. 조건 분기로 다음 호출을
   결정하거나, 실패 시 앞선 효과를 되돌리거나, 호출 사이의 순서를 보장하는 경우가 여기에
   해당합니다.
2. 둘 이상의 계약을 조합해 하나의 비즈니스 결과를 만든다.

**모듈 능력 단위 계약으로 통합합니다.** 위 두 조건을 모두 충족하지 않는 경우입니다. 인자를
그대로 넘기고 결과를 그대로 돌려주는 단일 저장소 호출은 독립 타입으로 두지 않고, 같은 기능
모듈의 능력 단위 계약에 메서드로 둡니다.

통합 계약은 하나의 기능 모듈이 외부에 제공하는 능력을 담으며, 이름은 그 능력을 드러냅니다.
계약 하나가 여러 메서드를 갖는 것 자체는 이 기준의 위반이 아닙니다.

통합 계약이 순서 보장이나 중복 억제 같은 실행 보장을 제공해야 하면, 그 보장은 계약 구현
내부의 상태로 둡니다. 별도의 직렬화 전용 타입을 만들어 생성자로 주입하지 않습니다.

이 기준은 Domain 안에서만 판정합니다. Feature가 어떤 단위로 주입받는지는 기준의 입력이
아니며, 통합 계약을 받은 Router가 하위 Feature에 개별 동작만 전달하는 것은 허용됩니다.

## 관심사별 UseCase와 타깃 구성

명세 037 적용 결과입니다. UseCase 계약은 관심사 7개로 정리되고, 각 관심사는 자기 타깃을 갖습니다.

| UseCase | 타깃 | 담는 동작 |
| --- | --- | --- |
| `AccountUseCase` | `DomainAccount` | `signIn(with:)`, `signOut()`, `signInStates()`, `restoreSignIn()`, `verifySignIn()`, `signInAvailability()`, `policyConsentStatus()`, `consent(to:)`, `withdraw()` |
| `UserInfoUseCase` | `DomainUserInfo` | `detail()`, `curation()`, `updateCuration(_:)`, `updatePosition(_:)`, `updateCareerLevel(_:)` |
| `AppSettingUseCase` | `DomainAppSetting` | `notificationAuthorization()`, `requestNotificationAuthorization()`, `registerDevice()`, `updateDeviceToken(_:)` |
| `ExternalRepositoryUseCase` | `DomainExternalRepository` | `repository(at:)` |
| `QuizDetailUseCase` | `DomainQuizDetail` | `quizSet(_:in:)`, `grade(_:)`(객관식·서술형), `bookmark(_:in:)`, `unbookmark(_:in:)`, `bookmarks(_:)` |
| `ProjectUseCase` | `DomainProject` | `projects()`, `refresh()`, `requestNextPage()`, `detail(of:)`, `delete(_:)` |
| `ProjectGenerationUseCase` | `DomainProjectGeneration` | `request(_:)`, `states()` |

관심사 하나는 UseCase 계약 하나와 그 구현, 모델, 오류, 저장소 계약을 소유합니다. 앱에서 각 UseCase는
인스턴스 하나만 만들고, 상태를 가진 관심사는 `actor`로 구현해 변경과 관찰의 순서를 보장합니다.

### `DomainIdentifier`

`DomainIdentifier`는 여러 관심사가 공유하는 식별자 `typealias`(`ProjectID`, `QuizSetID`, `QuizID`,
`ExternalRepositoryURL`)만 소유합니다. 모델, 계약, UseCase, 오류를 두지 않습니다.

관심사 타깃은 서로 import하지 않으며, 필요할 때만 `DomainIdentifier`를 import합니다. 같은 개념을 두
관심사가 모두 다루면 각 관심사가 자기 언어의 모델을 따로 소유하고, 식별자만 공유합니다.

말단 화면 Feature는 UseCase 계약 전체를 받지 않고 자신이 쓰는 동작 하나만 클로저로 받아, 쓰지 않는
능력에 닿지 않습니다. UseCase 계약은 Router와 루트 Feature까지만 쓰입니다.

## 제약조건

- 프로젝트 내부 패키지 의존성은 [아키텍처 문서 3.1](../architecture.md)이 정한 허용 목록(Domain: 없음)을 벗어나서는 안 됩니다.
- Data 모델, DTO 또는 서버 API 형식을 참조해서는 안 됩니다.
- Infrastructure 또는 외부 라이브러리의 기술 API를 참조해서는 안 됩니다.
- 네트워크, 저장소, 파일 시스템과 같은 구체 기술을 계약 이름이나 타입에 노출해서는 안 됩니다.
- Repository와 외부 기능 계약의 production 구현을 소유해서는 안 됩니다.
- Feature 상태, 화면 표현 또는 Navigation 로직을 포함해서는 안 됩니다.
- 관심사 타깃은 다른 관심사 타깃을 import해서는 안 됩니다. Domain 안에서 허용하는 유일한 import 대상은
  `DomainIdentifier`입니다.
- `DomainIdentifier`는 식별자 `typealias` 외의 선언을 소유해서는 안 됩니다.
