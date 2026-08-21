# Composition 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

## 설명

Composition은 Domain, Data와 Infrastructure 사이의 Adapter를 구현하고 production dependency graph를 구성하는 조립 경계입니다. 실행 환경에 맞는 구현 선택, 객체 생성 순서, 공유 범위와 수명 관리를 담당합니다.

Domain이 요구하는 외부 기능 계약은 Data 기능을 이용하는 Adapter로 연결하고, Data가 요구하는 기술 계약은 Infrastructure API를 이용하는 Adapter로 연결합니다. Composition은 App이 Feature에 주입할 수 있는 실행 가능한 Domain dependency를 제공합니다.

## 정책

- 공개 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 Adapter, 조립, 구현 선택과 객체 수명 책임을 드러내고 새로운 Domain·Data 책임을 암시해서는 안 됩니다.
- 모든 내부 target은 Adapter 구현, 객체 생성, 구현 선택 또는 수명 관리에 기여해야 합니다.
- Domain이 정의한 계약은 Data가 제공하는 기능을 이용한 Adapter로 충족해야 합니다.
- Data가 정의한 기술 계약은 Core가 제공하는 내부 API를 이용한 Adapter로 충족해야 합니다.
- Data 모델·DTO·오류와 Domain 모델·오류 사이의 변환은 Domain↔Data Adapter가 담당해야 합니다.
- Data 계약의 요청·응답과 Infrastructure API 사이의 변환은 Data↔Infrastructure Adapter가 담당해야 합니다.
- 실행 환경별 production/test/stub 구현 선택이 필요한 경우 Composition에서 결정해야 합니다.
- 객체 수명과 공유 범위는 Composition이 명시적으로 결정해야 합니다.
- App이 Feature에 주입할 수 있도록 실행 가능한 Domain dependency를 공개해야 합니다.

## 제약조건

- 비즈니스 규칙을 Adapter 내부에 구현해서는 안 됩니다.
- 데이터 캐시·저장·동기화 정책을 Composition에 구현해서는 안 됩니다.
- 화면, 사용자 기능 상태 또는 Navigation 정책을 소유해서는 안 됩니다.
- Feature가 Composition에 직접 접근하도록 Service Locator API를 제공해서는 안 됩니다.
- 외부 라이브러리의 구체 API를 직접 사용해서는 안 됩니다. 외부 기술은 Infrastructure를 통해 사용합니다.
