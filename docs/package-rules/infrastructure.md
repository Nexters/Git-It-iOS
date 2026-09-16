# Infrastructure 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

## 설명

Infrastructure는 외부 라이브러리, 플랫폼 기능과 기술 API를 프로젝트가 소유한 범용 기술 API로 변환하는 기술 경계입니다. 외부 기술의 요청·응답 타입과 오류를 프로젝트 내부의 기술 타입과 오류로 변환합니다.

Infrastructure는 네트워크, 저장소, 로깅, 분석과 같은 범용 기술 기능을 독립적인 API로 제공하며 Data 내부 구현이 해당 API를 사용해 Data가 소유한 실행 역할을 구현할 수 있도록 합니다.

## 정책

- 공개 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 Infrastructure가 직접 감싸는 외부 고정 명칭은 보존하되 Domain·Data 의미를 프로젝트의 범용 기술 API에 노출해서는 안 됩니다. Domain·Data·Infrastructure 사이의 관심사 경계와 판정 기준은 [아키텍처 결정 기록 D-ARCH-004](../architecture.md#9-아키텍처-결정-기록)가 소유합니다.
- 모든 내부 target은 하나의 범용 기술 기능을 프로젝트 내부 API로 제공해야 합니다.
- 현행 `InfrastructureAuthentication`은 Apple 인증, Keychain, 보안 난수 세 능력을 한 target에 담습니다. 이 구성은 위 항의 예외로 유지하며, 분리는 [설계 점검 결과](../review/domain-data-infra-design-review.md)의 DS-07이 후속 설계 변경으로 다룹니다.
- 외부 라이브러리, 플랫폼 기능과 기술 오류는 Infrastructure가 소유한 타입과 오류 뒤에 격리해야 합니다.
- 외부 의존성은 해당 기술 기능을 구현하는 데 필요한 범위로 한정해야 합니다.
- 공개 API는 외부 기술 교체 시 Data 내부 구현이 안정적으로 사용할 수 있는 프로젝트 소유 인터페이스를 제공해야 합니다.

## 제약조건

- 프로젝트 내부 패키지 의존성은 [아키텍처 문서 3.1](../architecture.md)이 정한 허용 목록(Infrastructure: 없음)을 벗어나서는 안 됩니다.
- 외부 기술의 구체 타입이나 오류를 Infrastructure 밖으로 노출해서는 안 됩니다.
- Domain 모델과 비즈니스 규칙을 정의해서는 안 됩니다.
- Data DTO, 서버 API 또는 서비스 고유 데이터 형식을 소유해서는 안 됩니다.
- Data가 정의한 계약을 직접 구현해서는 안 됩니다.
- 화면, 사용자 기능 또는 애플리케이션 흐름을 포함해서는 안 됩니다.
