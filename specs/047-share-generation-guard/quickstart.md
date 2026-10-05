# 빠른 시작: 공유 확장에서 진행 중인 생성이 있으면 새 생성 요청 차단

**명세**: [spec.md](./spec.md) | **계약**: [contracts/generation-state-read.md](./contracts/generation-state-read.md)

## 1. 준비

```sh
make init   # 최초 1회. 이미 설치했다면 생략
project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

## 2. 자동 검증

저장소 루트에서 순서대로 실행한다. 세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 병렬 실행하지 않는다.

```sh
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

기대 결과:

| 대상 | 확인 내용 | 명세 근거 |
|---|---|---|
| Data `LocalKeyValueStorageTests`, `StorageFactoryTests`, `LocalPendingGenerationStoreTests` | 값 없음은 `nil`·빈 상태, 손상 값은 `unreadable`, 저장소 없음은 `unavailable` | FR-003a |
| Domain `ProjectGenerationStateTests`, `ProjectGenerationTests` | `hasRequestInProgress` 판정, `currentState()`의 관찰 미시작·만료 제외·`stateUnavailable` 변환 | FR-001, FR-008, FR-011, SC-004 |
| Composition `PendingGenerationRepositoryAdapterTests` | `confirmedPendingState()`의 만료 정리와 저장소 오류의 `stateUnavailable` 변환 | FR-003a |
| Feature `ShareRegistration/ShareRegistration/`의 `SharedRepositoryRegistrationFeatureTests`, 루트 `ShareRegistrationFeature` 테스트 | 상태 조회 대역의 진행 중·완료만·실패만·빈 상태·오류별 분기, 조회 전·등록 직전 판정별 상태, 조회·등록 호출 0회, 재시도, 진단 로그 | 시나리오 1·2, SC-001~SC-003a |
| App `AppRootFeatureTests` | 홈 잠금 결과 유지 | FR-010, SC-004 |
| 기존 공유 확장·생성 요청·앱 루트 테스트 | 흐름 배치 이동 뒤와 변경 후 모두 통과 | SC-005, FR-012 |

## 3. 실기기 검증 (SC-006)

전제: 회원으로 로그인한 실기기에 개발 빌드가 설치되어 있다.

1. 앱에서 저장소 A의 생성을 요청하고 결과가 오기 전에 앱을 백그라운드로 보낸다.
2. Safari에서 다른 저장소 B 페이지를 열고 공유 시트에서 Git-It을 선택한다.
3. 기대: 저장소 조회 없이 생성 중 안내와 닫기가 표시되고, 안내에 앱을 열면 최신 상태가 반영된다는 문구가 있다.
4. 닫고 앱으로 돌아간다. 기대: 홈이 "문제 생성 중"으로 잠겨 있고 진행 중 생성 기록은 A 하나다.
5. A의 결과가 도착한 뒤 B를 다시 공유한다. 기대: 저장소 조회 후 등록 가능 상태가 표시된다.

Console.app에서 `com.nexters.hytime.gitit` 하위 공유 확장 진단 로그에 `generationInProgressBlocked`가 남는지 확인한다.

확인 실패 안내(`generationUnverified`)는 실기기에서 저장소 손상을 만들기 어려우므로 자동 테스트로만 검증한다. PR에 미검증 범위로 적는다.
