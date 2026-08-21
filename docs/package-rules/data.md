# Data 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

## 설명

Data는 데이터의 획득, 저장, 캐시와 동기화를 담당하는 데이터 경계입니다. 서비스가 정의한 API와 DTO, Data 모델과 데이터 처리 정책을 Data 자체의 언어로 표현합니다.

Data는 네트워크, 저장소, Keychain, 파일 시스템과 같은 외부 기술 기능을 사용할 때 필요한 계약을 정의하고, 그 계약의 concrete 구현을 Infrastructure가 제공하는 기술 API 위에서 직접 소유합니다. 이 계약과 구현을 통해 데이터 처리 로직을 독립적인 테스트 단위로 구성합니다.

## 정책

- 공개 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 획득·저장·캐시·동기화 책임과 DTO·저장 모델의 방향 및 수명을 드러내고 Domain 구현 용어를 노출해서는 안 됩니다.
- 모든 내부 target은 서버 API, DTO, Data 모델, 데이터 접근, 캐시, 저장 또는 동기화 정책에 기여해야 합니다.
- 서비스가 정의한 요청과 응답 형식은 Data가 소유한 DTO로 표현해야 합니다.
- 데이터 획득 결과는 Data가 소유한 타입으로 반환해야 합니다.
- 외부 기술 기능이 필요한 경우 Data가 필요한 형태의 계약을 정의하고, 그 계약의 concrete 구현을 Infrastructure 기술 API 위에서 소유해야 합니다.
- 외부 시스템의 기술 오류는 Data가 소유한 오류 타입으로 변환해야 합니다.
- 외부 기술 계약은 Test Double로 대체할 수 있는 형태로 설계해야 합니다.
- Data target은 독립적인 테스트 실행 단위를 구성해야 하며, 요청 구성·응답 변환·오류 변환을 검증해야 합니다.
- Data target은 사용하는 Infrastructure target을 Tuist에 명시적으로 선언해야 합니다.

## 제약조건

- Domain, Composition, Feature, App, UI를 의존하거나 import해서는 안 됩니다.
- Domain 타입을 참조하거나 Domain 모델로 변환하는 API를 제공해서는 안 됩니다.
- Domain Repository를 구현해서는 안 됩니다.
- Infrastructure가 제공하는 기술 API의 범위를 넘어 외부 라이브러리의 구체 API를 직접 참조해서는 안 됩니다.
- Domain 비즈니스 규칙을 정의해서는 안 됩니다.
- 화면, 사용자 기능 상태 또는 Navigation을 소유해서는 안 됩니다.
