# Composition 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

## 설명

Composition은 Domain과 Data 사이의 Adapter를 구현하고 production dependency graph를 구성하는 조립 경계입니다. Data 생성 진입점이 만드는 구현과 Data 역할 계약의 대체 구현, Data concrete 구현, Domain↔Data Adapter와 Domain UseCase 구현을 조립해 실행 환경에 맞는 구현 선택, 객체 생성 순서, 공유 범위와 수명 관리를 담당합니다.

Domain이 요구하는 외부 기능 계약은 Data 기능을 이용하는 Adapter로 연결합니다. Data가 요구하는 기술 계약의 concrete 구현은 Data가 Infrastructure 기술 API 위에서 직접 소유하므로, Composition은 이를 변환하는 별도 Adapter를 두지 않고 그 구현을 조립 대상으로만 사용합니다. Composition은 App이 Feature에 주입할 수 있는 Domain UseCase Protocol 타입의 실행 가능한 dependency만 제공한다.

## 정책

- 공개 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 Adapter, 조립, 구현 선택과 객체 수명 책임을 드러내고 새로운 Domain·Data 책임을 암시해서는 안 됩니다.
- 모든 내부 target은 Adapter 구현, 객체 생성, 구현 선택 또는 수명 관리에 기여해야 합니다.
- Domain이 정의한 계약은 Data가 제공하는 기능을 이용한 Domain↔Data Adapter로 충족해야 합니다.
- Data 모델·DTO·오류와 Domain 모델·오류 사이의 변환은 Domain↔Data Adapter가 담당해야 합니다.
- 실행 환경별 production/test/stub 구현 선택이 필요한 경우 Composition에서 결정해야 합니다. 실제 구현은 Data 생성 진입점으로 얻고, 대체 구현은 Data 역할 계약 타입의 선택 인자(`nil`이면 실제 구현)로 받습니다.
- 객체 수명과 공유 범위는 Composition이 명시적으로 결정해야 합니다. 공유 수명이 필요한 Repository·세션 객체는 중복 생성해서는 안 됩니다.
- App이 Feature에 주입할 수 있도록 Domain UseCase Protocol 타입의 실행 가능한 dependency를 공개해야 합니다. 내부 Adapter는 공개 API에 노출해서는 안 되며, 공개 API 인자는 Domain·Data 타입만 사용해야 합니다.

## Target 구성

- Composition target은 Domain 관심사 축으로 나눕니다. 조립 루트는 앱·확장처럼 실행 진입점마다
  두고, 실제로 사용하는 축 target만 참조합니다.
- Adapter와 조립은 **구현하거나 공개하는 Domain 계약이 속한 관심사**의 축에 둡니다.
- 여러 Remote가 공유하는 요청 인증 정보 공급자는 하나만 만들어 모든 Remote의 인증 정보
  공급과 로그인 무효화 신호에 연결합니다. 이 연결은 인증 계약이 속한 관심사 축이 소유합니다.
- 공용 target은 둘 이상의 축이 같은 의미로 쓰는 조립 요소만 담고 Domain·Data 모듈에
  의존해서는 안 됩니다.
- 모든 Composition target은 다른 패키지 모듈 의존 수가 6개를 넘어서는 안 됩니다. 의존 수는
  target manifest 블록의 `.from<패키지>(…)` 선언 수이며 같은 패키지 `.target`, `.external`,
  `.sdk`는 세지 않습니다. 조립 루트가 Data 타입을 직접 만들어야 한다면 그 생성을 해당 축
  조립 API로 옮깁니다.
- 패키지 간 허용 방향과 target manifest에 선언하지 않은 모듈 import는
  `.tools/package-dependencies`가 검사합니다. target을 추가하거나 이름을 바꾸면
  `.tools/package-dependencies/config/source-roots`도 함께 갱신합니다.

## 조립 책임의 범위

조립 시점에 객체를 생성하고 실행 환경에 맞는 구현을 선택하는 일은 Composition의 책임입니다.
무엇이 옳은지 정하는 규칙과 어디에 어떤 이름으로 저장할지 정하는 스키마는 Composition의
책임이 아닙니다.

- 저장 네임스페이스·키·저장 형식은 소유 `Data<기능>` 모듈이 정하고, Composition은 Domain
  타입과 저장 레코드 사이의 변환만 담당합니다.
- App Group 식별자와 Keychain 접근 그룹 같은 저장 좌표는 Infrastructure와 Data 생성
  진입점이 소유하고, Composition은 생성 진입점이 제공하는 저장 위치 중 하나를 선택합니다.
- 가용성 판정, 등록 대상 구성, 예약 정책 같은 비즈니스 판정은 Domain 관심사가 소유하고,
  Composition은 그 판정이 요구하는 계약의 Adapter만 구현합니다.
- 사용자에게 보이는 문구와 앱 기동 순서는 App이 소유합니다. Composition은 문구를 조립
  인자로 받고, 순서 없는 개별 조각을 공개합니다.
- 외부 라이브러리 타입은 Data 내부 구현만 사용하고, Composition은 Data 생성 진입점을
  호출합니다.

## 제약조건

- 비즈니스 규칙을 Adapter 내부에 구현해서는 안 됩니다.
- 데이터 캐시·저장·동기화 정책을 Composition에 구현해서는 안 됩니다.
- 화면, 사용자 기능 상태 또는 Navigation 정책을 소유해서는 안 됩니다.
- Feature reducer, Feature dependency 묶음, Store 또는 View를 생성해서는 안 됩니다.
- Feature, App 또는 UI target을 의존성으로 선언해서는 안 됩니다.
- Feature가 Composition에 직접 접근하도록 Service Locator API를 제공해서는 안 됩니다.
- Infrastructure target을 의존성으로 선언하거나 import해서는 안 됩니다. 기술 능력은 Data 생성 진입점과 역할 계약으로만 사용합니다.
- 저장 네임스페이스·키·저장 형식을 Composition이 정의해서는 안 됩니다. 그 좌표는 소유 `Data<기능>` 모듈과 Data 생성 진입점이 소유합니다.
- 사용자에게 보이는 문구를 Composition이 가져서는 안 됩니다. 문구는 App이 조립 인자로 전달합니다.
- 실행 순서를 강제하는 클로저를 공개해서는 안 됩니다. 조각을 공개하고 순서는 App이 정합니다.
- 앱·OS 버전처럼 실행 환경에서 읽는 값을 Composition이 직접 조회해서는 안 됩니다. App이 전달합니다.
