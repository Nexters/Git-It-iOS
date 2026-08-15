# 빠른 시작: InMemoryCache 검증

**날짜**: 2026-08-15 | **명세**: [spec.md](./spec.md) |
**계약**: [contracts/in-memory-cache-api.md](./contracts/in-memory-cache-api.md)

이 문서는 구현이 끝난 뒤 기능이 실제로 동작하는지 확인하는 실행 절차입니다. 타입의 상세
정의는 [data-model.md](./data-model.md), 서명은 계약 문서를 참조합니다. 구현 코드는 여기에
싣지 않으며 실제 작업 배정은 `tasks.md`가 담당합니다.

## 사전 조건

- `make init`으로 workspace와 Git 훅이 설치되어 있어야 합니다.
- Tuist 설정에 `InfrastructureCache`·`InfrastructureCacheTests` target과
  `InfrastructureCache` scheme이 추가된 뒤 `tuist generate`가 실행되어 있어야 합니다.
- **네트워크 연결, 디스크 접근, 화면 실행이 필요하지 않습니다.** 모든 검증은 메모리 안에서만
  수행합니다(SC-005).

## 실행 절차

저장소 루트에서 실행합니다.

```bash
cd sources && tuist install && tuist generate
```

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER) && "$project_build_runner" build
```

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER) && "$project_build_runner" compile && "$project_build_runner" test
```

세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 순차 실행을 전제로 합니다. 기본
테스트 대상은 `platform=iOS Simulator,name=iPhone 17 Pro`이며 `GIT_IT_TEST_DESTINATION`으로
바꿀 수 있습니다.

**기대 결과**: `InfrastructureCache` scheme 빌드가 성공하고 `InfrastructureCacheTests`의
모든 테스트가 통과합니다.

## 검증 시나리오

각 시나리오는 `InfrastructureCacheTests`에서 자동 테스트로 확인합니다. 괄호 안은 명세의
수용 시나리오와 성공 기준입니다.

### A. 저장과 조회 (사용자 스토리 1)

| # | 확인 내용 | 기대 결과 |
| --- | --- | --- |
| A-1 | 빈 캐시에 키 A로 값 V를 저장한 뒤 같은 키로 조회 | V가 그대로 반환된다(US1-1, SC-001) |
| A-2 | 키 A에 값 V1이 있는 상태에서 같은 키에 V2를 저장한 뒤 조회 | V1이 아닌 V2가 반환된다(US1-2, FR-004) |

### B. 제거와 전체 비우기 (사용자 스토리 2)

| # | 확인 내용 | 기대 결과 |
| --- | --- | --- |
| B-1 | 키 A에 값이 있는 상태에서 키 A를 제거한 뒤 조회 | `nil`이 반환된다(US2-1, SC-003) |
| B-2 | 여러 키에 값이 있는 상태에서 전체 비우기를 실행한 뒤 각 키를 조회 | 모든 키가 `nil`을 반환한다(US2-2, SC-003) |
| B-3 | 빈 캐시에서 존재하지 않는 키를 제거 | 오류 없이 완료된다(US2-3, FR-007) |
| B-4 | 저장된 적 없는 키를 조회 | 오류·예외 없이 `nil`이 반환된다(FR-003, SC-002) |

### C. 동시 접근 안전성 (사용자 스토리 3)

| # | 확인 내용 | 기대 결과 |
| --- | --- | --- |
| C-1 | 서로 다른 키 100개에 대한 저장 요청을 동시에 실행한 뒤 모든 키를 조회 | 100개 모두 각자의 값과 정확히 일치하고 유실·혼선이 없다(US3-1, SC-004) |
| C-2 | 같은 키에 대한 저장 요청 여러 건을 동시에 실행한 뒤 조회 | 여러 요청 중 하나의 값이 손상 없이 남아 있다(US3-2, FR-008) |

## 완료 기준

위 A~C의 모든 시나리오가 통과하고, 검증 전 과정에서 화면 실행·네트워크 접근·디스크 접근이
전혀 없었다면(SC-005) 이 기능은 명세를 충족한 것으로 간주합니다.
