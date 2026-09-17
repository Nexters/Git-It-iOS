# App 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

## 설명

App은 Feature와 Composition을 연결하고 애플리케이션 전체 Navigation과 화면 흐름을 조정하는 **Coordination Layer**입니다. Feature가 표현하는 사용자 흐름과 Composition이 제공하는 실행 가능한 Domain 기능을 연결하며, 플랫폼 생명주기와 실행 진입점을 담당합니다.

App은 여러 Feature의 navigation intent를 애플리케이션 수준의 화면 전환으로 연결합니다. 또한 실행 환경을 선택하고 Composition이 제공한 dependency를 각 Feature의 명시적인 초기화 인터페이스에 주입합니다.

## 정책

- 공개 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 실행 진입점, 애플리케이션 전체 Navigation과 Feature↔Composition 연결 책임만 드러내야 합니다.
- 모든 내부 target은 실행 진입점, 플랫폼 생명주기 연결, Feature↔Composition 조립 또는 Navigation에 기여해야 합니다.
- production Composition을 정확히 1회 생성하고, 각 Feature에 그 Feature가 실제로 사용하는 UseCase만 initializer 또는 명시적인 초기화 인자로 주입해야 합니다. Composition 컨테이너 전체를 전달하지 않습니다.
- root Feature와 root Store를 생성하고 세션·온보딩 판정 결과에 따라 root 경로를 선택해야 합니다.
- Feature가 외부 화면 흐름 변경을 요청하면 App이 목적지와 전환 방식을 결정해야 합니다.
- 실행 환경 선택이 필요한 경우 App이 실행 환경을 결정해 Composition 생성 시 전달해야 합니다.
- Navigation과 조립에 필요한 Domain 타입을 직접 사용할 수 있습니다.
- 프로젝트 내부 의존성은 아키텍처 문서에서 App에 허용한 패키지로 한정해야 합니다. Infrastructure는 직접 의존하거나 import해서는 안 되며, 플랫폼 앱 델리게이트 같은 기술 연결은 Composition이 공개한 타입으로만 사용합니다.

## 제약조건

- Domain의 비즈니스 규칙을 App에서 구현하거나 다시 판단해서는 안 됩니다.
- Data 또는 Core의 구체 구현을 직접 생성하거나 사용해서는 안 됩니다.
- Domain↔Data 또는 Data↔Infrastructure Adapter를 App에 구현해서는 안 됩니다.
- Feature의 Presentation 상태나 화면 구현을 App에 옮겨서는 안 됩니다.
- 공용 UI 구성요소를 소유하거나 UI 패키지에 직접 의존해서는 안 됩니다.
- Service Locator나 전역 dependency container를 통해 Feature dependency를 조회하게 해서는 안 됩니다.
- production App이 sample, preview 또는 test 구현을 주입해서는 안 됩니다.
