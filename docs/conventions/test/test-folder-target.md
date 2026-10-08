# 물리 폴더와 test target을 분리합니다

[Git It iOS 테스트 컨벤션](../test.md)의 규칙 문서입니다.

- 테스트 소스의 폴더 경로는 [디렉터리·파일 컨벤션 — 소스 루트](../directory-file/test-source-root.md)이
  소유합니다. 패키지 루트에 `<TargetName>Tests/` 또는 `<TargetName>UITests/` 폴더를
  나란히 만들지 않습니다.
- Tuist test target 이름은 빌드 그래프 식별을 위해 패키지 문맥과 `Tests` 또는
  `UITests` 접미어를 유지할 수 있습니다. 폴더 이름과 target 이름을 같게 만들 필요는
  없습니다.
- 각 `Target.testModule`은 실제 테스트가 있는 가장 좁은 `sourceDirectory`를 명시합니다.
  하나의 package-wide test target이 여러 역할을 검증할 때는 `Tests`를 source root로
  지정하고 그 아래를 역할별로 나눌 수 있습니다.
- 같은 production 모듈에 일반 테스트와 UI 자동화 test target이 함께 있으면
  `Tests/<Module>/Unit/`, `Tests/<Module>/UI/`처럼 서로 겹치지 않는 역할 하위 폴더로
  분리합니다.

- 테스트 파일 이름, 파일당 타입 개수와 `TestDoubles/` 배치는
  [파일·형태 어휘 컨벤션 — 파일 규칙](../file-vocabulary.md#2-파일-규칙)과
  [패키지별 형태 어휘](../file-vocabulary/shape-vocabulary.md)를 따릅니다.
- Tuist test target과 공유 scheme에는 실제 `@Test` 함수 또는 `XCTestCase` 테스트가
  있는 target만 연결합니다. 빈 test target을 scheme에 등록하지 않습니다.
