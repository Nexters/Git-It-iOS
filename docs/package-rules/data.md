# Data 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

## 설명

Data는 데이터의 획득, 저장, 캐시와 동기화를 담당하는 데이터 경계입니다. 서비스가 정의한 API와 DTO, Data 모델과 데이터 처리 정책을 Data 자체의 언어로 표현합니다.

Data는 획득·저장·캐시·동기화의 실행 역할을 자신의 언어로 정의한 타입으로 소유하고, 그 내부 구현에서만 Infrastructure가 제공하는 기술 API를 사용합니다. Data의 공개 선언은 실행 역할만 표현하고 기술을 Data 밖으로 노출하지 않으며, 이 원칙의 정본과 판정 기준은 [아키텍처 결정 기록 D-ARCH-004](../architecture.md#9-아키텍처-결정-기록)가 소유합니다. Infrastructure를 직접 사용할 수 있는 패키지는 Data뿐이므로, Composition과 테스트가 기술 능력을 선택·대체해야 하는 경우 Data가 그 역할 계약과 생성 진입점을 소유합니다. 이 구조로 데이터 처리 로직을 독립적인 테스트 단위로 구성합니다.

## 정책

- 공개 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 획득·저장·캐시·동기화 책임과 DTO·저장 모델의 방향 및 수명을 드러내고 Domain 구현 용어를 노출해서는 안 됩니다.
- 모든 내부 target은 서버 API, DTO, Data 모델, 데이터 접근, 캐시, 저장 또는 동기화 정책에 기여해야 합니다.
- 서비스가 정의한 요청과 응답 형식은 Data가 소유한 DTO로 표현해야 합니다.
- 데이터 획득 결과는 Data가 소유한 타입으로 반환해야 합니다.
- 외부 기술 기능이 필요한 경우 Data가 소유한 실행 역할 타입의 내부 구현에서 Infrastructure 기술 API를 사용해야 하며, 그 타입의 공개 선언(이름·시그니처)에 기술을 노출해서는 안 됩니다.
- Composition이나 테스트가 기술 능력을 선택·대체해야 하면 Data가 기술 이름 없는 역할 계약(`KeyValueStorage`, `SecureValueStorage`, `RequestTransport`, `LocalReminderNotifier`, `RemoteMessageReceiver`)과 실제 구현을 만드는 생성 진입점(`Factories/`)을 공개해야 합니다.
- Data target 사이에서 Infrastructure 타입을 주고받아야 하면 `package` 접근 수준으로만 공개해야 하며, 모든 Data target은 같은 package 이름(`GitItData`)으로 빌드합니다.
- 외부 시스템의 기술 오류는 Data가 소유한 오류 타입으로 변환해야 합니다.
- 외부 기술 계약은 Test Double로 대체할 수 있는 형태로 설계해야 하며, Data 저장·전송 타입 테스트는 Infrastructure 실제 구현 대신 Data 역할 계약 더블을 주입합니다.
- Data target은 독립적인 테스트 실행 단위를 구성해야 하며, 요청 구성·응답 변환·오류 변환을 검증해야 합니다.
- Data target은 사용하는 Infrastructure target을 Tuist에 명시적으로 선언해야 합니다.

## 제약조건

- Domain, Composition, Feature, App, UI를 의존하거나 import해서는 안 됩니다.
- Domain 타입을 참조하거나 Domain 모델로 변환하는 API를 제공해서는 안 됩니다.
- Domain Repository를 구현해서는 안 됩니다.
- Infrastructure가 제공하는 기술 API의 범위를 넘어 외부 라이브러리의 구체 API를 직접 참조해서는 안 됩니다.
- Domain 비즈니스 규칙을 정의해서는 안 됩니다.
- 화면, 사용자 기능 상태 또는 Navigation을 소유해서는 안 됩니다.
