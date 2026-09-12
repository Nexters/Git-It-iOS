# Git It iOS 테스트 컨벤션

**상태**: 정본

**작성일**: 2026-08-19

**최종 수정일**: 2026-09-13 (기존 테스트 일괄 변경 금지 조항 삭제)

## 목적

이 문서는 Git It iOS의 테스트를 읽을 수 있는 동작 명세로 유지하기 위한 작성 기준입니다.
패키지별 테스트 대상과 의존성 경계는 [아키텍처 문서](../architecture.md#5-테스트-정책)를
함께 따릅니다. 문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](common/README.md)이 소유합니다.

## 1. 적용 범위

- `sources/Projects/<Package>/Tests/` 아래의 단위·통합·계약 테스트에 적용합니다.
- 같은 `Tests/` 루트 아래의 UI 자동화 테스트에도 적용하되, 테스트 프레임워크 선택은
  §2.2의 예외를 따릅니다.
- 제품 소스의 타입·메서드·프로퍼티 이름은 [네이밍 컨벤션](./naming.md)을 따릅니다.

## 2. 테스트 프레임워크

테스트 프레임워크는 하나를 기본으로 정해 두고, 그 프레임워크로 표현할 수 없는 플랫폼 기능에만 다른 것을 씁니다. 선택 기준을 사람마다 다르게 두지 않기
위한 것입니다.

### 2.1 Swift Testing을 기본으로 사용합니다

→ [Swift Testing을 기본으로 사용합니다](./test/swift-testing.md)

### 2.2 XCTest는 필요한 플랫폼 기능에만 사용합니다

→ [XCTest는 필요한 플랫폼 기능에만 사용합니다](./test/xctest.md)

## 3. 테스트 이름

테스트 이름은 그 테스트가 보장하는 동작 계약을 그대로 문장으로 드러냅니다. 실패한 테스트 이름만 읽고도 무엇이 깨졌는지 알 수 있어야 합니다.

### 3.1 테스트 함수 이름은 한국어 동작 문장으로 작성합니다

→ [테스트 함수 이름은 한국어 동작 문장으로 작성합니다](./test/korean-behavior-sentence.md)

### 3.2 한 테스트는 하나의 동작 계약을 설명합니다

→ [한 테스트는 하나의 동작 계약을 설명합니다](./test/one-contract-per-test.md)

## 4. 테스트 구성

테스트 본문은 준비, 실행, 검증 순서를 유지합니다.

→ [테스트 구성](./test/structure.md)

## 5. 의존성 격리와 Test Double

외부 의존성은 소유 패키지의 Protocol을 구현한 Test Double로 대체하고 initializer로 주입합니다.

→ [의존성 격리와 Test Double](./test/dependency-isolation.md)

## 6. Feature와 TCA 테스트

Feature 테스트는 Swift Testing 안에서 TCA의 `TestStore`를 사용하고, 초기 State와 initializer로 주입할 Domain
Use Case를 테스트 본문에서 명시합니다.

→ [Feature와 TCA 테스트](./test/feature-tca.md)

## 7. 파일과 Target 구성

테스트 코드는 검증 대상과 같은 축으로 배치하고, test target과 scheme이 그 경계를 그대로 반영합니다. 어느 패키지의 무엇을 검증하는 테스트인지
경로와 scheme에서 드러나야 합니다.

### 7.1 물리 폴더와 test target을 분리합니다

→ [물리 폴더와 test target을 분리합니다](./test/test-folder-target.md)

### 7.2 scheme은 패키지와 그 패키지의 test target을 연결합니다

→ [scheme은 패키지와 그 패키지의 test target을 연결합니다](./test/scheme.md)

## 8. 실행 결과와 기록

테스트 컴파일과 테스트 실행은 서로 다른 검증 단계입니다.

→ [실행 결과와 기록](./test/execution-record.md)

## 9. 검토 체크리스트

- [ ] 일반 테스트가 Swift Testing으로 작성되었는가?
- [ ] XCTest 사용이 UI 자동화 등 필요한 플랫폼 기능으로 제한되었는가?
- [ ] 테스트 함수 이름이 조건·행동과 결과를 설명하는 한국어 문장인가?
- [ ] 테스트가 하나의 동작 계약에 집중하는가?
- [ ] 의존성이 initializer와 최소 Test Double로 격리되었는가?
- [ ] 비동기 작업과 미완료 Effect가 결정적으로 종료되는가?
- [ ] 테스트가 `<Package>/Tests/<Module>/` 원칙에 따라 역할별로 배치되었는가?
- [ ] Tuist test target이 실제 폴더를 `sourceDirectory`로 명시하는가?
- [ ] 패키지 scheme이 같은 패키지의 production·test target만 연결하는가?
- [ ] `compile`과 `test` 결과를 구분해 기록했는가?
- [ ] 테스트 본문에 진입하지 못한 환경 실패를 테스트 통과 또는 제품 실패로 오해하지
  않았는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [네이밍 컨벤션](./naming.md)
- [파일·형태 어휘 컨벤션](./file-vocabulary.md)
- [TCA 컨벤션](./tca/README.md)

## 문서 변경 기준

기본 테스트 프레임워크, 테스트 이름·구성, Test Double, TCA 테스트 또는 test target
배치 규칙이 바뀔 때 수정합니다. 패키지별 테스트 책임이 바뀌면 아키텍처와 해당 패키지
규칙을 먼저 갱신합니다.
