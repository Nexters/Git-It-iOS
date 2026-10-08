# 의존성 격리와 Test Double

[Git It iOS 테스트 컨벤션](../test.md)의 규칙 문서입니다.

- Domain Use Case, Repository와 외부 기술 기능은 소유 패키지의 Protocol을 구현한
  Test Double로 대체하고 initializer로 주입합니다.
- 테스트를 위해 production 코드에 Service Locator, 전역 mutable container 또는
  별도 `@Dependency` 경로를 추가하지 않습니다.
- Test Double은 필요한 반환·실패·대기 동작과 호출 기록만 제공합니다. production
  정책을 복제하지 않습니다.
- 동시 접근이 가능한 호출 기록은 `actor` 등 데이터 경쟁을 막는 소유자 안에 두고,
  검증에는 불변 snapshot을 사용합니다.
- 실제 네트워크, Keychain, 파일 시스템 또는 영속 저장소를 사용하는 테스트는 해당
  기술 통합이 검증 대상일 때만 별도 target 또는 명확한 Suite 경계에 둡니다.
