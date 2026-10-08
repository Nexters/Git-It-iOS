# 빠른 시작: GitHub·Git-It 프로젝트 API Composition Adapter 검증

**명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md) | **데이터 모델**:
[data-model.md](./data-model.md) | **계약**: [contracts/](./contracts/)

이 문서는 구현이 끝난 뒤 4개 Composition Adapter가 spec.md의 수용 시나리오대로 "실제로
동작함"을 검증하는 절차다. `/speckit-implement` 이후 실행 대상이다.

## 사전 조건

- `make init`으로 Tuist 프로젝트가 생성되어 있어야 한다(`GitIt.xcworkspace` 존재).
- **007-learning-project-lifecycle의 Domain(`DomainLearningProject`)·Data(`DataLearningProject`)
  패키지가 먼저 구현·검증되어 있어야 한다** — 이 기능은 그 타입을 소비만 하며 재정의하지
  않는다(research.md 결정 0). 007이 구현되지 않았다면 이 기능을 구현할 수 없다.
- Tuist 구성 변경(`CompositionModuleName.swift`) 후에는 `tuist generate`(또는 `make init`)로
  스킴을 다시 생성해야 한다.

## 시나리오 1 — GitHub 확인이 실제 네트워크 호출로 동작한다 (P1, SC-001·SC-003)

1. `CompositionTests`에서 `ExternalRepositoryRemoteAdapter` 계약 테스트를 실행해 Fake
   `HTTPTransport`를 통과하는 성공·오류(offline/other) 경로를 확인한다
   (contracts/github-composition-adapter.md).
2. 같은 target에서 `ExternalRepositoryLookupAdapter` 계약 테스트를 실행해 DTO→Domain 모델
   변환과 오류 매핑을 확인한다.
3. 실행:

   ```sh
   xcodebuild test \
     -workspace GitIt.xcworkspace \
     -scheme Composition \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
   ```

**기대 결과**: 실패 0건. 실제로 구성된 `HTTPTransportRequest`의 URL이
`https://api.github.com/repos/{owner}/{name}`과 일치함을 확인하는 테스트가 통과한다(SC-003).

## 시나리오 2 — Git-It 서버 CRUD가 실제 네트워크 호출로 동작한다 (P2, SC-002·SC-003·SC-004)

1. `LearningProjectRemoteAdapter` 계약 테스트로 4개 메서드 각각의 성공·오류(400/401/404/500)
   매핑과 `Authorization: Bearer` 헤더 첨부를 확인한다(contracts/git-it-server-composition-adapter.md).
2. 액세스 토큰이 없는 상태(Fake `LoginSessionStorage`가 `nil` 반환)에서 서버가 401을 반환하면
   `LearningProjectError.unauthorized`로 도달하는지 확인한다(SC-004).
3. `LearningProjectRepositoryAdapter` 계약 테스트로 DTO→Domain 모델 변환을 확인한다.
4. 실행: 시나리오 1과 동일한 `xcodebuild test`(같은 `Composition` 스킴).

**기대 결과**: 실패 0건.

## 전체 재확인

```sh
xcodebuild test \
  -workspace GitIt.xcworkspace \
  -scheme Composition \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

실패 0건이면 SC-001~004가 충족된 것으로 본다. 이 기능이 끝나도 로그인·세션·토큰 발급
Adapter는 여전히 없으므로, 실제 기기에서 Git-It 서버 4개 엔드포인트를 끝까지 검증하려면
별도로 유효한 액세스 토큰을 수동으로 `LoginSessionStorage`에 주입해야 한다(범위 밖).
