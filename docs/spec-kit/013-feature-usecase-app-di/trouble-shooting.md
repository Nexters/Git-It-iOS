# 013-feature-usecase-app-di 문제 해결 기록

**대상 기능**: `013-feature-usecase-app-di`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260822-001: CODE_SIGNING_ALLOWED=NO 환경에서 실제 Keychain을 쓰는 Composition 테스트 4건이 `.temporarilyUnavailable`로 실패함

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: 작업 패키지 4(Composition) T055 정리와 패키지 검증
**관련 항목**: T053(`AuthenticationAssemblyTests.swift`), T054(`SharedLifetimeTests.swift`), FR-027, SC-010

### 증상

`"$project_build_runner" test` 실행 시 Composition scheme에서만 4개 테스트가 실패했다.

```text
LoginSessionRepositoryAdapterTests.`로그인 응답을 저장하고 idToken 기반 사용자를 반환한다`()
LoginSessionRepositoryAdapterTests.`저장된 세션이 없으면 restore가 nil을 반환한다`()
AuthenticationRepositoryAdapterTests.`저장된 사용자가 없으면 재인증이 필요하다고 판정한다`()
SharedLifetimeTests.`같은 KeychainStore를 공유해도 Authentication과 LoginSession의 저장 값이 서로 섞이지 않는다`()
```

`build`와 `compile`은 전부 성공했고 나머지 6개 scheme(Domain, Infrastructure, Data, App,
UI 계열)는 통과했다.

### 영향

Composition 패키지 검증(T055)이 중단되어 승인 게이트로 진행할 수 없었다. 원인을 오인하면
Domain↔Data Adapter나 조립 진입점(`AuthenticationAssembly`) 자체의 결함으로 착각해 이미
완료된 T044~T050 구현을 잘못 수정할 위험이 있었다.

### 근거

- `GIT_IT_XCRESULTS_PATH`를 지정해 재실행한 Composition xcresult(`xcrun xcresulttool get
  test-results tests`)에서 4건 모두 동일한 실패 메시지를 확인:
  `LoginSessionRepositoryAdapter.swift:33: Caught error: .temporarilyUnavailable`,
  `AuthenticationRepositoryAdapter.swift:68: Caught error: .temporarilyUnavailable` 등.
- `tools/githooks/project-build/core/xcodebuild.sh:90`에서 모든 test 실행에
  `CODE_SIGNING_ALLOWED=NO`를 고정 전달함을 확인.
- 실패한 4개 테스트만 `let keychainStore = KeychainStore()`(production 초기화, 실제
  Keychain Services 경로)를 사용했고, 같은 파일의 통과한
  `서버 인증 실패를 Domain 오류로 변환한다` 테스트는 Keychain 접근 이전에 오류가 발생해
  우연히 영향을 받지 않았음을 코드 검토로 확인.
- `sources/Projects/Infrastructure/Tests/Authentication/Keychain/KeychainStoreTests.swift`는
  이미 `KeychainStore(backend: KeychainStore.InMemoryBackend())`(non-public이지만
  `@testable import`로 접근 가능한 in-memory 경로)를 사용해 같은 문제를 피하고 있음을
  확인.

### 원인

이 저장소 경로(`/Users/jerry/Desktop/...`)가 iCloud Drive의 "데스크탑과 문서 폴더" 동기화
대상이라 codesign이 간헐적으로 `resource fork, Finder information, or similar detritus
not allowed`로 실패하는 환경 제약이 있다(별도 항목으로 기록하지 않음, 프로젝트
`project-build` 도구가 이미 `CODE_SIGNING_ALLOWED=NO`로 우회 중). 그 결과 테스트 번들이
서명·entitlement 없이 실행되며, 실제 Keychain Services(`SecItemAdd`/
`SecItemCopyMatching`)를 호출하는 코드가 Simulator에서 entitlement 누락으로 실패하고
`AuthenticationRepositoryAdapter`/`LoginSessionRepositoryAdapter`가 이를
`.temporarilyUnavailable`로 변환한다. Composition Adapter 구현 자체의 결함이 아니다.

### 조치

`AuthenticationAssemblyTests.swift`(4곳)와 `SharedLifetimeTests.swift`(1곳)의
`KeychainStore()`를 `KeychainStore(backend: KeychainStore.InMemoryBackend())`로 교체했다.
Infrastructure의 `KeychainStoreTests`가 이미 검증한 것과 동일한 in-memory 경로이므로
namespace 분리·CRUD 동작 검증 목적은 유지되고, entitlement에 의존하는 real Keychain 경로
검증 책임은 지지 않는다.

### 검증

- `"$project_build_runner" compile`: 성공(7/7).
- `"$project_build_runner" test`: 성공(7/7), Composition 포함 전 scheme 통과.

### 재발 방지

Composition(또는 다른 패키지) 테스트에서 `KeychainStore()`(production 초기화)를 직접
사용하려는 경우, 이 저장소의 `test`/`compile` 실행이 `CODE_SIGNING_ALLOWED=NO`로 고정되어
있어 실제 Keychain Services 호출이 항상 entitlement 오류로 실패함을 먼저 확인한다.
`KeychainStore(backend: KeychainStore.InMemoryBackend())` 경로를 사용해야 한다.

### 연결

없음
