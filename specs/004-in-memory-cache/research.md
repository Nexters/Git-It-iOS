# 조사: InMemoryCache

**날짜**: 2026-08-15 | **명세**: [spec.md](./spec.md)

## 1. 동시성 안전성 구현 방식

- **결정**: Swift `actor`로 캐시 저장소를 구현한다.
- **근거**: 이 프로젝트는 이미 `Infrastructure` 하위 `InfrastructureNetworkClient`에서 Swift Concurrency와 `Sendable`을 전면 채택했다(`sources/Projects/Infrastructure/NetworkClient/Client/HTTPClient.swift`, `ConcurrencyIsolationTests.swift`). `actor`는 내부 상태에 대한 상호 배제를 언어 차원에서 보장하므로 별도의 lock 관리 코드 없이 FR-008(동시 접근 시 손상·유실 없음)을 가장 단순하게 충족한다. "최대한 심플하게"라는 요청과도 부합한다.
- **검토한 대안**:
  - `NSLock`/`os_unfair_lock` 기반 `final class`: lock/unlock을 수동으로 짝지어야 하고 실수 시 교착·데이터 경합 위험이 있어 actor보다 코드가 늘어난다.
  - 직렬 `DispatchQueue.sync`: 호출부가 `async` 문맥과 자연스럽게 통합되지 않고, actor 대비 얻는 이점이 없다.

## 2. 저장 값과 키의 타입 범위

- **결정**: 캐시 타입을 `Key: Hashable & Sendable`, `Value: Sendable`로 제네릭화한다.
- **근거**: FR-010(특정 Data 모델·DTO에 종속되지 않음)과 FR-012(독립된 여러 인스턴스)를 충족하려면 캐시가 임의의 키·값 타입을 다룰 수 있어야 한다. `Sendable` 제약은 `actor` 경계를 넘나드는 값의 동시성 안전성을 컴파일 타임에 보장한다.
- **검토한 대안**: 특정 타입(`String` 키, `Data`/`Any` 값)으로 고정하는 방식은 FR-010의 "특정 Data 모델에 종속되지 않는다"는 요구와 충돌하고, 사용처마다 형변환이 필요해 오히려 복잡해진다.

## 3. 존재하지 않는 키 조회 결과 표현

- **결정**: `Value?`를 반환하는 조회 연산으로 값 없음을 표현한다(`nil` = 없음).
- **근거**: FR-003은 "오류를 발생시키지 않고 값이 없음을 알려야 한다"고 명시한다. Swift `Dictionary`의 관용적 조회 패턴과 동일해 사용하는 개발자가 별도 학습 없이 이해할 수 있다.
- **검토한 대안**: 값 없음을 별도 오류 타입으로 던지는 방식은 FR-003의 "오류 없이"라는 요구와 정면으로 충돌해 채택하지 않았다.

## 4. 내부 저장 구조

- **결정**: actor 내부에 표준 라이브러리 `Dictionary<Key, Value>` 하나만 둔다.
- **근거**: 명세가 요구하는 동작(저장, 조회, 개별 제거, 전체 비우기)은 `Dictionary`의 기본 연산만으로 충분하다. 범위 밖으로 명시한 TTL·용량 제한·축출 정책이 없으므로 추가 자료구조나 메타데이터가 필요 없다.
- **검토한 대안**: 만료 시각을 함께 저장하는 구조는 범위 밖으로 정한 TTL 지원을 전제하므로 채택하지 않았다.

## 5. Target 배치

- **결정**: 기존 `Infrastructure` 패키지 아래 새 target `InfrastructureCache`(소스 디렉터리 `Cache/`)와 테스트 target `InfrastructureCacheTests`(소스 디렉터리 `CacheTests/`)를 추가한다. 다른 내부 target에는 의존하지 않는다.
- **근거**: 기존 `InfrastructureAuthentication`, `InfrastructureNetworkClient`가 각각 하나의 범용 기술 기능을 독립 target으로 제공하는 패턴(`sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`)을 그대로 따른다. `infrastructure.md` 정책상 "모든 내부 target은 하나의 범용 기술 기능을 프로젝트 내부 API로 제공해야 한다"는 규칙과 일치한다.
- **검토한 대안**: 기존 `Utility` 폴더(현재 placeholder만 존재)에 편입하는 방안은 검토했으나, `Utility`가 아직 명확한 target으로 승격되지 않았고 캐시가 독립적으로 테스트·배포 가능한 별도 범용 기술 기능이므로 새 target으로 분리하는 편이 기존 패턴과 더 일치한다.

## NEEDS CLARIFICATION 해소 현황

명세와 위 조사 결과에 `NEEDS CLARIFICATION` 표식은 남아 있지 않다.
