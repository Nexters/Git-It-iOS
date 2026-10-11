# scheme은 패키지와 그 패키지의 test target을 연결합니다

[Git It iOS 테스트 컨벤션](../test.md)의 규칙 문서입니다.

- 공유 scheme은 target별로 만들지 않고 패키지마다 하나만 둡니다. scheme 이름은
  `App`, `Composition`, `Feature`, `Domain`, `Data`, `Infrastructure`, `UI`처럼 패키지
  이름을 사용합니다.
- 패키지 scheme의 Build Action에는 그 패키지의 production target을, Test Action에는
  그 production target을 검증하는 모든 test target을 연결합니다.
- 여러 패키지의 test target을 하나의 scheme에 섞지 않습니다. 각 패키지는 자신의 공유
  scheme에서 독립적으로 컴파일하고 실행할 수 있어야 합니다.
- UI 자동화 test target은 별도 target과 host 구성을 유지하되 `UI` 패키지 scheme의
  Build·Test Action에 함께 연결합니다.
- scheme과 test target 연결의 정본은 `ProjectDescriptionHelpers`의 프로젝트 선언입니다.
  Tuist가 생성한 `.xcscheme` 파일을 직접 수정하지 않습니다.
