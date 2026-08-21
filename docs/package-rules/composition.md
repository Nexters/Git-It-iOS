# Composition 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

## 설명

Composition은 Domain과 Data 사이의 Adapter를 구현하고 production dependency graph를 구성하는 조립 경계입니다. Infrastructure 객체, Data concrete 구현, Domain↔Data Adapter와 Domain UseCase 구현을 조립해 실행 환경에 맞는 구현 선택, 객체 생성 순서, 공유 범위와 수명 관리를 담당합니다.

Domain이 요구하는 외부 기능 계약은 Data 기능을 이용하는 Adapter로 연결합니다. Data가 요구하는 기술 계약의 concrete 구현은 Data가 Infrastructure 기술 API 위에서 직접 소유하므로, Composition은 이를 변환하는 별도 Adapter를 두지 않고 그 구현을 조립 대상으로만 사용합니다. Composition은 App이 Feature에 주입할 수 있는 Domain UseCase Protocol 타입의 실행 가능한 dependency만 제공한다.

## 정책

- 공개 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 Adapter, 조립, 구현 선택과 객체 수명 책임을 드러내고 새로운 Domain·Data 책임을 암시해서는 안 됩니다.
- 모든 내부 target은 Adapter 구현, 객체 생성, 구현 선택 또는 수명 관리에 기여해야 합니다.
- Domain이 정의한 계약은 Data가 제공하는 기능을 이용한 Domain↔Data Adapter로 충족해야 합니다.
- Data 모델·DTO·오류와 Domain 모델·오류 사이의 변환은 Domain↔Data Adapter가 담당해야 합니다.
- 실행 환경별 production/test/stub 구현 선택이 필요한 경우 Composition에서 결정해야 합니다.
- 객체 수명과 공유 범위는 Composition이 명시적으로 결정해야 합니다. 공유 수명이 필요한 Repository·세션 객체는 중복 생성해서는 안 됩니다.
- App이 Feature에 주입할 수 있도록 Domain UseCase Protocol 타입의 실행 가능한 dependency를 공개해야 합니다. 내부 Adapter와 Infrastructure 객체는 공개 API에 노출해서는 안 됩니다.

## 제약조건

- 비즈니스 규칙을 Adapter 내부에 구현해서는 안 됩니다.
- 데이터 캐시·저장·동기화 정책을 Composition에 구현해서는 안 됩니다.
- 화면, 사용자 기능 상태 또는 Navigation 정책을 소유해서는 안 됩니다.
- Feature reducer, Feature dependency 묶음, Store 또는 View를 생성해서는 안 됩니다.
- Feature, App 또는 UI target을 의존성으로 선언해서는 안 됩니다.
- Feature가 Composition에 직접 접근하도록 Service Locator API를 제공해서는 안 됩니다.
- Infrastructure의 외부 라이브러리 구체 API를 Data 구현이 아닌 Composition이 직접 사용해서는 안 됩니다.
