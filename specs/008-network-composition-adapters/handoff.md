# 핸드오프: GitHub·Git-It 프로젝트 API Composition Adapter

**기능**: [008-network-composition-adapters](./spec.md) | **상태**: 구현 완료(T001~T012, 12/12)
**브랜치**: `feature/network-composition-adapters` | **커밋**: `fca7963`
**작성일**: 2026-08-20

이 문서는 이 기능을 이어받아 Feature(화면)를 붙이거나 인증 Composition Adapter를 추가할
다음 작업자를 위한 요약이다. 세부 근거는 [spec.md](./spec.md)·[plan.md](./plan.md)·
[data-model.md](./data-model.md)·[contracts/](./contracts/)에 있고, 이 문서는 "무엇이
준비됐고 무엇이 아직 비어 있는지"만 빠르게 파악하기 위한 진입점이다.

## 무엇이 준비됐는가

007-learning-project-lifecycle이 정의한 5개 UseCase 중 4개(`FetchExternalRepository`,
`CreateLearningProject`, `FetchLearningProjects`, `FetchLearningProjectDetail`,
`DeleteLearningProject` — 정확히는 GitHub 확인 1개 + Git-It 서버 CRUD 4개)가 이제 Fake가
아닌 실제 `HTTPClient` 네트워크 호출로 동작한다.

| Adapter | 위치 | 구현하는 계약 |
| --- | --- | --- |
| `ExternalRepositoryRemoteAdapter` | `sources/Projects/Composition/Composition/LearningProjectLifecycle/` | `ExternalRepositoryRemote`(Data↔Infrastructure, GitHub) |
| `ExternalRepositoryLookupAdapter` | 〃 | `ExternalRepositoryLookup`(Domain↔Data, GitHub) |
| `LearningProjectRemoteAdapter` | 〃 | `LearningProjectRemote`(Data↔Infrastructure, Git-It 서버) |
| `LearningProjectRepositoryAdapter` | 〃 | `LearningProjectRepository`(Domain↔Data, Git-It 서버) |

**사용 방법(다음 작업자가 App/Feature DI에서 조립할 때)**:

```swift
// GitHub — 인증 불필요
let githubClient = HTTPClient(transport: /* 실제 URLSession 기반 HTTPTransport */, baseURL: "https://api.github.com")
let externalRepositoryRemote = ExternalRepositoryRemoteAdapter(httpClient: githubClient)
let externalRepositoryLookup = ExternalRepositoryLookupAdapter(remote: externalRepositoryRemote)

// Git-It 서버 — Bearer 토큰 필요
let gitItClient = HTTPClient(transport: /* 동일 HTTPTransport 또는 별도 구성 */, baseURL: "https://<git-it-server-base-url>")
let learningProjectRemote = LearningProjectRemoteAdapter(httpClient: gitItClient, sessionStorage: /* LoginSessionStorage 실제 구현 */)
let learningProjectRepository = LearningProjectRepositoryAdapter(remote: learningProjectRemote)
```

두 base URL은 서로 다른 `HTTPClient` 인스턴스로 구성해야 한다(FR-011, 단일 인스턴스로
공유하지 않음).

## 검증 상태

```sh
xcodebuild test -workspace GitIt.xcworkspace -scheme Composition \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

`** TEST SUCCEEDED **` — 25개 테스트, 4개 Suite, 실패 0건(Fake `HTTPTransport`·Fake
`LoginSessionStorage`만 사용, 실제 네트워크 호출 없음). spec.md 수용 시나리오 9개
(시나리오 1: 3개, 시나리오 2: 6개)와 SC-001~SC-004 전부 이 테스트로 커버된다. 상세 대조는
[tasks.md](./tasks.md) T011·T012, 절차는 [quickstart.md](./quickstart.md) 참고.

**검증하지 않은 것**: 실제 기기·실제 GitHub API·실제 Git-It 서버로의 End-to-End 호출.
로그인·세션 Adapter가 없어 유효한 액세스 토큰을 실제로 발급받을 방법이 이 저장소에 아직
없기 때문이다(아래 "다음에 무엇이 필요한가" 참고).

## 설계 결정(다음 작업자가 재질문하지 않아도 되도록)

- **재시도 없음(FR-015)**: 타임아웃·연결 실패도 즉시 대응 Domain 오류로 매핑한다. 재시도가
  필요하면 UseCase를 소비하는 Feature 계층이 결정한다.
- **로깅 없음(FR-016)**: 003-http-client가 정한 "자체 기록 수단 미제공" 경계를 그대로
  유지한다. 실패 관찰은 타입화된 Domain 오류(FR-004, FR-009)로만 한다.
- **토큰 조회는 `LoginSessionStorage` 재사용**: 001-apple-social-login이 이미 정의한
  `LoginSessionStorage.load()?.accessToken`을 그대로 소비한다. 새 프로토콜을 만들지
  않았다(근거: [tacit-knowledge.md](../../docs/spec-kit/008-network-composition-adapters/tacit-knowledge.md) TK-20260820-002). 토큰이 없으면
  헤더 없이 요청을 보내고, 서버의 401 응답이 자연스럽게 `LearningProjectError.unauthorized`로
  이어지도록 둔다(수용 시나리오 2-6).
- **Composition은 새 target을 만들지 않음**: 앱 전체가 공유하는 기존 `Composition`
  target 안에 `LearningProjectLifecycle/` 하위 폴더를 새로 도입했다. 후속 Composition
  Adapter(예: 인증)도 같은 방식으로 자기 기능 이름의 하위 폴더를 쓰는 것이 이 저장소의
  전례가 됐다(근거: [tacit-knowledge.md](../../docs/spec-kit/008-network-composition-adapters/tacit-knowledge.md) TK-20260820-001).

## 다음에 무엇이 필요한가 (이 기능의 범위 밖)

1. **로그인·세션·토큰 갱신 Composition Adapter** — `LoginSessionRemote.refreshSession`/
   `revokeRefreshToken`에 대응하는 서버 엔드포인트가 `Git-It-server-scheme.json`에서
   아직 확인되지 않아 이 기능이 명시적으로 범위에서 제외했다(spec.md FR-013·범위 밖).
   Git-It 서버 CRUD 4개 메서드를 실제 기기에서 끝까지 검증하려면 이 Adapter가 먼저
   필요하다.
2. **App 수준 DI Container 등록** — 이 기능은 4개 Adapter를 구현만 했을 뿐, `App` 패키지의
   DI Container에 실제로 조립·등록하지 않았다. 위 "사용 방법" 예시가 그 조립의 출발점이다.
3. **Feature(화면) 구현** — 007의 5개 UseCase를 소비하는 화면이 아직 없다.
4. **007이 이미 범위 밖으로 명시한 항목**: `FetchLearningSet` 등 나머지 UseCase, 로컬
   캐싱·영속화, Polling/Timer, Timeout 감시, 문제 생성 상태 재시도 전략.

## 알아두면 좋은 것

- `CompositionTests` 스킴에 Test Action이 아예 없던 기존 Tuist 구성 gap을 이번에 함께
  고쳤다(`ProjectName.swift`에 `testTarget: "CompositionTests"` 추가). 자세한 경위는
  [trouble-shooting.md](../../docs/spec-kit/008-network-composition-adapters/trouble-shooting.md) TS-20260820-001 참고 — 008의 코드 결함이
  아니라 `CompositionTests`가 그동안 placeholder뿐이라 드러나지 않았던 기존 gap이었다.
- `Git-It-server-scheme.json`은 구현 시점에 아직 커밋되지 않은 작업본이었다(spec.md
  가정). 실제 서버 스키마가 바뀌었다면 `LearningProjectRemoteAdapter`의 엔드포인트·오류
  코드 매핑(`data-model.md` §2)을 재확인해야 한다.
