# 구현 계획: 프로젝트 목록 자동 갱신과 생성 상태 고착 해결

**Git-flow 유형**: `feature`

**브랜치**: `feature/project-list-refresh` (`/speckit-specify`가 생성, 2026-09-27 병합 시 재사용)

**날짜**: 2026-09-28 | **명세**: [spec.md](./spec.md)

**입력**: `specs/046-project-list-refresh/spec.md`의 기능 명세

## 요약

> 2026-09-28 추가: 시나리오 8, FR-023~FR-026(알림 누락 뒤 앱 아이콘 복귀 복구)의 계획은 아래 "추가 계획(2026-09-28)"에 있다.
> 이 절 이하의 기존 계획(목록 자동 갱신)은 구현 완료 상태로 유지한다.

남은 범위는 목록 자동 갱신(FR-001~FR-008)과 실기기 검증(FR-019)이다. 생성 상태 고착 해결(FR-009~FR-018,
FR-021, FR-022)은 `0a76670`~`78d065c`에서 구현되었으므로 이 계획은 그 설계를 [research.md](./research.md)의
이관 결정(R1~R12)으로 보존하고 새 작업을 만들지 않는다.

목록 자동 갱신의 기술 접근은 다음과 같다.

1. **Domain `ProjectGeneration`**이 생성 결과 스트림을 받을 때마다 결과가 도착한 프로젝트를 새 관찰 스트림
   `outcomeArrivals()`로 알린다. 파싱에 성공한 결과만 Domain에 도착하므로 FR-002의 "생성 결과 원격 알림"
   판정이 자동으로 성립하고, Data 결과 소스의 구독자는 `ProjectGeneration` 하나로 유지되어 구독 전에 보존한
   결과를 빼앗기지 않는다. 같은 결과가 여러 경로로 다시 도착하면 한 번만 알린다([research L1](./research.md#l1-생성-결과-도착-알림의-소유자)).
2. **Domain `Project`**에 진행 중인 목록 요청을 취소하고 첫 페이지를 새로 받는
   `refreshReplacingInFlightRequest()`(대체 새로고침)를 추가한다. 기존 `refresh()`의 합류 의미는 유지하고, 취소로 대체된
   요청을 기다리던 호출자는 오류 없이 최신 요청의 결과를 받는다([research L2·L3](./research.md#l2-취소-후-재요청을-새-연산으로-분리)).
3. **App `AppRootFeature`**가 두 계기를 판정한다. 백그라운드를 거쳐 활성화되었을 때, 그리고 포그라운드 중
   생성 결과가 도착했을 때 회원·메인 화면 흐름이면 `refreshReplacingInFlightRequest()`를 한 번 호출한다.
   `GitItApp`은 `scenePhase`의 `.background` 전환을 새 View Action으로 전달한다([research L4·L5](./research.md#l4-계기-판정의-소유자)).
4. Home과 프로젝트 목록 탭은 기존처럼 Domain 목록 스트림을 관찰하므로 Feature 동작은 바뀌지 않는다(FR-008).

## 기술 맥락

**언어/버전**: Swift 6 (strict concurrency), iOS 26.0 이상

**주요 의존성**: SwiftUI, The Composable Architecture, Swift Concurrency(`actor`, `AsyncStream`, `Task`)

**저장소**: 해당 없음. 목록은 `Project` actor의 메모리 상태이고 생성 기록 저장소는 변경하지 않는다.

**테스트**: Swift Testing(`@Suite`, `@Test`), TCA `TestStore`

**대상 플랫폼**: iOS 26.0 이상 iPhone. 기본 테스트 destination은 `platform=iOS Simulator,name=iPhone 17 Pro`

**프로젝트 유형**: 모바일 앱(Tuist 멀티 패키지)

**성능 목표**: 계기 발생 후 네트워크 정상 시 2초 안에 목록 일치(SC-001, SC-002). 계기당 목록 요청 시작 최대 1회,
동시 진행 첫 페이지 요청 1개 이하(SC-005)

**제약 조건**: 서버 API·payload 변경과 폴링 금지(FR-020). 목록 자동 갱신 전용 진단 로그 없음(명확화 2026-09-28).
알림 수신 직후 지연·재시도 없음(명확화 2026-09-28)

**규모/범위**: Domain 2개 관심사(`DomainProject`, `DomainProjectGeneration`), App 1개 target(`GitIt`),
Feature 공개 계약 변경 없음. 두 UseCase 프로토콜의 적합 타입 갱신이 App·Feature 테스트 더블과 App 프리뷰에 걸친다.

미해결 `NEEDS CLARIFICATION`은 없다.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 점검 | 결과 |
|---|---|---|
| 1. 명시적인 경계 | 변경 패키지는 Domain·Feature·App이며 허용 의존 방향(App→Feature·Domain, Feature→Domain)을 벗어나지 않는다. Domain 관심사 타깃끼리 import하지 않고, 두 관심사는 App이 연결한다 | 통과 |
| 2. 상태와 데이터 안전성 | 요청 대체·취소 상태는 `Project` actor가, 백그라운드 경유 여부는 `AppRootFeature.State`가 소유한다. 취소된 요청의 응답은 요청 세대 비교로 버리고, 대체된 호출자는 오류 없이 최신 결과를 받는다 | 통과 |
| 3. 검증 가능한 변경 | 단위마다 compile, 마지막에 build·compile·test를 실행하고 결과를 남긴다. 실기기 검증(FR-019)은 [quickstart](./quickstart.md) 절차로 수행하며 미수행 시 PR에 미검증 범위로 기록한다 | 통과 |
| 4·5. 스킬별 수정 경로 | 이 명령은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 수정했다. `device-verification.md` 보강은 작업으로 넘긴다 | 통과 |
| 6. 한국어 산출물 | 산출물 본문을 한국어로 작성했다 | 통과 |
| 7. 위험 기반 실행 단위 | 프로토콜 요구사항 추가는 적합 타입이 함께 바뀌어야 compile되므로 integration unit으로 계획하고, 단위별 파일·통합 검증을 기록했다. 모든 단위가 Domain → Feature → App 순서를 지킨다(아래 "실행 단위") | 통과 |
| 8. Git-flow | 기존 `feature/project-list-refresh` 브랜치를 사용한다 | 통과 |
| 10. 네이밍 | 새 공개 이름은 책임을 드러내도록 정했다([research L7](./research.md#l7-새-공개-이름)) | 통과 |
| 11. 컨벤션 근거 | 아래 "적용 컨벤션"에 근거와 제약을 기록했다. 기존 관행과 컨벤션의 충돌 1건을 발견해 컨벤션을 따르는 작업으로 계획했다(복잡성 추적) | 통과 |

**브랜치 네임스페이스**: 이 헌법 개정 후 새로 생성한 브랜치는 `feature/`, `hotfix/`,
`release/` 중 목적에 맞는 네임스페이스를 사용해야 한다. 개정 전에 생성된 기존 브랜치는
소급해 바꾸지 않고 기존 브랜치임을 기록한다. `/speckit-specify`는 명세 산출물을 만들기
전에 현재 HEAD에서 검증된 브랜치를 직접 생성하거나 이미 현재인 동일 브랜치를 재사용해야
하며, branch 생성에 실패한 명세로 계획을 진행하지 않는다. `before_specify` hook은 브랜치
생성이나 전환을 대신 수행하지 않는다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정할 수 있다. 이 산출물 밖의 구현 파일은 정확한
경로를 `tasks.md`에 기록하며 계획 단계에서는 수정하지 않는다.

**세션 지식 기록**: 적용 여부와 문턱은 Constitution 원칙 9를 정본으로 따른다. 기록 조건을
충족하면 해당 전용 스킬을 별도로 사용하며 계획 산출물이나 구현 작업으로 만들지 않는다.

**Git 실행 직렬화**: 같은 checkout에서 `git commit`, pre-commit과 staged formatter처럼
Git index, 작업 파일 또는 공유 formatter cache를 사용하는 변경 체인은 하나만 실행한다.
기존 체인의 종료와 결과를 확인하기 전에는 재시도하지 않으며, 중복 실행을 발견하면 실행
소유자와 index·작업 파일 상태를 확인하고 사용자 승인 없이 임의로 종료하지 않는다. 읽기
전용 Git 조회, 서로 다른 checkout과 실행별로 격리된 build·test 경로는 이 제한에서 제외한다.

**커밋 단위 구현**: `/speckit-implement`는 미완료 작업을 실행 시점에 논리적이고 독립적으로
되돌릴 수 있는 커밋 단위로 설계한다. 단일 패키지가 기본이며, 분리하면 compile되지 않는
공개 API 이전이나 공용 manifest 변경은 근거와 통합 검증을 가진 다중 패키지 단위로 묶는다.
각 단위는 작업 ID, 정확한 파일,
검증과 커밋 메시지를 명시하고, 구현·검증·`tasks.md` 완료 표시·정확한 staging·commit 성공
확인을 마친 뒤에만 다음 단위로 진행한다. 훅을 우회하거나 무관한 변경을 포함하거나 amend,
rebase, push하지 않는다. 마지막 적용 패키지의 마지막 단위는 전체 읽기 전용 검증과 필수
`after_implement` hook까지 실행·재검증한 뒤 최종 commit한다. 시작 전 tasks.md의 일반 변경은
blob hash와 전체 diff로 기준선을 고정하며 별도 commit은 선택 사항이다. 확정된 기능 범위의
후속 단위와 읽기 전용 전체 검증은 반복 승인 없이 진행하고 새 권한이 필요한 경우에만 중단한다.

**컨벤션 근거**: 설계 전에 `.specify/memory/constitution.md`, 공통 컨벤션
인덱스(`docs/conventions/README.md`), 변경 대상 패키지의 `docs/package-rules/<패키지>.md`와
`docs/architecture.md`를 읽었다. 아래 "적용 컨벤션"에 적용한 문서와 그 문서가 이번 설계에
부과한 제약을 기록했다.

**책임 기반 네이밍**: 새 공개 이름은 [research L7](./research.md#l7-새-공개-이름)에서 책임 문장을 먼저 쓰고
정했다. 네이밍만 바꾸는 작업은 없다.

**실행 단위 진행**: 변경 패키지는 Domain → Feature → App 위상 순서를 따른다. 단위와 순서 근거, 단위별 파일은 아래
"실행 단위"에 기록했다.

### 설계 후 재점검

2026-09-28 `/speckit-analyze` 결과(I1·F2·F3)를 반영했다. (I1) FR-005·SC-005를 지키도록 `ProjectGeneration`이 같은 생성 결과의 중복 도착을 도착 알림으로 다시 방출하지 않게 했다(Domain 규칙: 중복 억제는 구현 내부 상태). (F2) 실행 단위 표를 tasks.md 구성(단위 3개와 전체 완료 검증)에 맞췄다. (F3) "대체 새로고침" 약칭을 research에 정의했다.

2026-09-28 컨벤션 기준 재검토에서 다음을 고쳤다. (1) 새로고침 결과를 `try?`로 버리던 설계를 Effect event로 받도록 바꿨다(Reducer 책임). (2) 프리뷰 정리를 Feature 선행 단위에서 integration unit 1로 옮겨 위상 순서를 맞췄다. (3) 단위별 정확한 파일 경로와 통합 검증을 기록했다(원칙 7). (4) 적용 컨벤션 표에 프리뷰·테스트 파일 이름·추상화 근거를 추가했다.

1단계 산출물([data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md))을
작성한 뒤 다시 점검했다. 새 의존 방향, Service Locator, `@Dependency`, 전역 container를 추가하지 않고,
Router State에 전환 외 관심사를 넣지 않으며, Domain에 기술 용어를 노출하지 않는다. 위반은 없다.

## 적용 컨벤션

| 문서 | 이번 설계에 부과한 제약 |
| --- | --- |
| [docs/architecture.md](../../docs/architecture.md) | 위상 순서 Domain → Feature → App. App은 Feature·Composition·Domain만, Feature는 Domain·UI만 의존한다. Composition 조립 인자는 바뀌지 않으므로 Composition은 변경 대상이 아니다 |
| [docs/package-rules/domain.md](../../docs/package-rules/domain.md) | 관심사 타깃(`DomainProject`, `DomainProjectGeneration`)은 서로 import하지 않는다. 요청 대체·중복 억제 같은 실행 보장은 UseCase 구현(`actor`) 내부 상태로 두고 별도 직렬화 타입을 주입하지 않는다. 새 연산은 기존 능력 계약(`ProjectUseCase`, `ProjectGenerationUseCase`)의 메서드로 둔다 |
| [docs/package-rules/app.md](../../docs/package-rules/app.md) | 플랫폼 생명주기(`scenePhase`) 연결과 두 관심사의 조정은 App이 소유한다. 회원·메인 화면 흐름 판정은 App이 이미 가진 State로 하고 Domain 규칙을 다시 구현하지 않는다. production에 preview·test 구현을 주입하지 않는다 |
| [docs/package-rules/feature.md](../../docs/package-rules/feature.md) | Feature production target 안에서 Domain UseCase 프로토콜을 구현하지 않는다. 프리뷰는 Reducer 없이 State를 구성한다. 이 규칙에 따라 `ShareRegistrationPreviewSupport`의 기존 적합 타입을 제거한다(복잡성 추적) |
| [docs/conventions/tca/navigation/router.md](../../docs/conventions/tca/navigation/router.md) | Router는 전환 상태만 소유한다. 목록 새로고침 effect를 `MainShellRouterFeature`에 두지 않고, 생명주기 계기를 소유한 App `AppRootFeature`가 Domain을 직접 호출한다 |
| [docs/conventions/tca/action/source.md](../../docs/conventions/tca/action/source.md), [action/naming.md](../../docs/conventions/tca/action/naming.md) | 생명주기 사건은 `view` 그룹의 관찰형 이름(`applicationEnteredBackground`), 스트림 사건은 `effect` 그룹(`generationOutcomeArrived`)으로 둔다 |
| [docs/conventions/tca/effect/reducer.md](../../docs/conventions/tca/effect/reducer.md) | Action 분기는 연관값 한 단계씩 helper로 나누고 `default`를 쓰지 않는다. Reducer에서 `Task`를 만들거나 UseCase를 직접 호출하지 않고 Effect로 호출한다. 오류를 무시하지 않으므로 새로고침 결과를 `learningProjectsRefreshFinished(error:)`로 받아 "State 변경 없음" 분기를 명시한다(`try?` 금지) |
| [docs/conventions/tca/effect/writing.md](../../docs/conventions/tca/effect/writing.md), [effect/cancellation.md](../../docs/conventions/tca/effect/cancellation.md) | 새로고침은 `cancelInFlight` 허용 대상이다. 장기 관찰(`outcomeArrivals`)은 안정적인 cancellation ID를 둔다. `any Error` 대신 `ProjectError?`를 Action에 담고 알 수 없는 오류는 fallback case로 바꾼다. 자동 갱신 실패는 State를 바꾸지 않는다(FR-006) |
| [docs/conventions/tca/state/request-identity.md](../../docs/conventions/tca/state/request-identity.md), [state/shape.md](../../docs/conventions/tca/state/shape.md) | 취소만으로 늦은 응답이 반영되지 않는다고 가정하지 않는다. 요청 세대는 `Project` actor가 보존하고 일치하는 응답만 반영한다. 백그라운드 경유 여부는 두 값뿐이므로 `Bool`로 둔다 |
| [docs/conventions/naming.md](../../docs/conventions/naming.md) ([operation.md](../../docs/conventions/naming/operation.md), [boundary-value.md](../../docs/conventions/naming/boundary-value.md)) | 연산 이름은 실제 효과(진행 중 요청 대체)와 관찰/조회 차이를 드러낸다. 스트림 원소가 무엇의 식별자인지 이름으로 식별할 수 있어야 한다 |
| [docs/conventions/test.md](../../docs/conventions/test.md) ([dependency-isolation.md](../../docs/conventions/test/dependency-isolation.md)) | Swift Testing과 한국어 동작 문장 테스트 이름. Test Double은 소유 패키지 프로토콜을 구현해 initializer로 주입하고 반환·실패·대기와 호출 기록만 제공한다. 동시 호출 기록은 `actor` 안에 둔다 |
| [docs/conventions/tca/effect/testing.md](../../docs/conventions/tca/effect/testing.md) | `TestStore`로 계기 입력을 `send`, Effect 결과를 `receive`한다. 교체된 요청의 결과가 반영되지 않음을 검증한다. 장기 관찰 Effect는 테스트 더블 스트림을 끝낸 뒤 `finish()`한다 |
| [docs/conventions/view/preview.md](../../docs/conventions/view/preview.md), [file-vocabulary/preview-type.md](../../docs/conventions/file-vocabulary/preview-type.md) | `ShareRegistrationPreviewSupport`는 기존 자리(`Feature/ShareRegistration/Previews/`)를 유지하고 Reducer 없는 State 구성으로만 바꾼다 |
| [docs/conventions/file-vocabulary/test-file-name.md](../../docs/conventions/file-vocabulary/test-file-name.md) | 새 App 테스트 파일은 동작 범위 이름(`AppRootFeatureLearningProjectsRefreshTests.swift`)을 쓴다 |
| [docs/conventions/abstraction/protocol-criteria.md](../../docs/conventions/abstraction/protocol-criteria.md) | 새 프로토콜을 만들지 않는다. 두 연산은 패키지 경계를 넘는 기존 UseCase 계약(근거 A)에 메서드로 추가한다 |
| [docs/conventions/directory-file.md](../../docs/conventions/directory-file.md), [file-vocabulary.md](../../docs/conventions/file-vocabulary.md) | 파일 하나에 타입 하나. 새 타입 파일은 기존 형태 폴더(`UseCases/`, `Reducers/`, `TestDoubles/`)에만 둔다. 새 형태 폴더를 만들지 않는다 |

## 프로젝트 구조

### 문서(이 기능)

```text
specs/046-project-list-refresh/
├── spec.md                 # 기능 명세
├── plan.md                 # 이 파일
├── research.md             # 0단계 산출물
├── data-model.md           # 1단계 산출물
├── quickstart.md           # 1단계 산출물
├── contracts/
│   ├── domain-contracts.md                  # Domain 공개 API(이관 + 목록 갱신 추가)
│   ├── app-lifecycle-refresh.md             # AppRoot 계기 판정 계약(신규)
│   └── remote-notification-delivery.md      # 원격 알림 전달 경로(이관, 구현됨)
├── device-verification.md  # 실기기 검증 기록(작업에서 보강)
├── checklists/requirements.md
└── tasks.md                # /speckit-tasks 산출물(이 명령이 만들지 않음)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/
├── Domain/
│   ├── Project/UseCases/
│   │   ├── ProjectUseCase.swift                 # refreshReplacingInFlightRequest() 요구사항 추가
│   │   └── Project.swift                        # 요청 대체·대체된 호출자 처리
│   ├── ProjectGeneration/UseCases/
│   │   ├── ProjectGenerationUseCase.swift       # outcomeArrivals() 요구사항 추가
│   │   └── ProjectGeneration.swift              # 결과 수신 시 도착 알림 방출
│   └── Tests/
│       ├── Project/TestDoubles/StubProjectRepository.swift       # 요청별 대기·취소 지원
│       ├── Project/UseCases/ProjectTests.swift
│       └── ProjectGeneration/UseCases/ProjectGenerationTests.swift
├── Feature/
│   ├── ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift  # Reducer 없는 프리뷰로 전환
│   └── Tests/
│       ├── Home/TestDoubles/ProjectUseCaseMock.swift
│       ├── ProjectDetail/TestDoubles/ProjectUseCaseDetailStub.swift
│       ├── ProjectRegistration/TestDoubles/ProjectGenerationUseCaseStub.swift
│       └── ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift
└── App/
    ├── GitIt/
    │   ├── GitItApp.swift                       # .background 전환 전달
    │   ├── Reducers/AppRootFeature.swift        # 계기 판정과 목록 새로고침
    │   └── Screens/AppRootView.swift            # 프리뷰 Noop 적합 타입 갱신
    └── Tests/GitIt/
        ├── Reducers/AppRootFeatureTests.swift                        # 기존 활성화 목록 갱신 테스트 이전
        ├── Reducers/AppRootFeatureLearningProjectsRefreshTests.swift # 신규
        └── TestDoubles/
            ├── ProjectUseCaseMock.swift
            └── ProjectGenerationUseCaseMock.swift
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 그대로 쓴다. 새 target, 새 형태 폴더, manifest 변경은 없다.
Composition, Data, Infrastructure, UI는 변경하지 않는다. `ProjectGeneration`과 `Project`의 생성자 인자가
바뀌지 않으므로 Composition 조립 코드도 바뀌지 않는다.

## 실행 단위

위상 순서는 [아키텍처 문서 3.1](../../docs/architecture.md)의 의존성 표(App → Feature → Domain)를 따른다. 단위 1·2는
Domain 관심사가 서로 달라 의존하지 않는다. 결과 도착 알림을 먼저 두는 것은 단위 3(App)이 두 연산을 모두 호출하기 전에
Domain 변경을 작은 순서로 쌓기 위한 선택이며, 둘의 순서를 바꿔도 된다.

| 순서 | 단위 | 종류 | 목적 | 분리 불가 근거 / 순서 근거 | 통합 검증 |
|---|---|---|---|---|---|
| 1 | 생성 결과 도착 알림 | integration (Domain → Feature → App) | `ProjectGenerationUseCase.outcomeArrivals()` 추가와 중복 도착 억제 | 프로토콜 요구사항을 추가하면 모든 적합 타입이 같은 커밋에서 바뀌어야 compile된다. `ShareRegistrationPreviewSupport`는 메서드를 덧붙이지 않고 적합 타입을 제거해 compile시킨다([research L9](./research.md#l9-컨벤션과-기존-관행의-충돌)) | `compile` |
| 2 | 대체 새로고침 | integration (Domain → Feature → App) | `ProjectUseCase.refreshReplacingInFlightRequest()` 추가와 대체된 호출자 처리 | 단위 1과 같은 이유 | `compile` |
| 3 | 생명주기·결과 도착 계기 판정 | App (+ 패키지 밖 명세 산출물 1개) | `AppRootFeature`·`GitItApp` 계기 판정과 테스트, `device-verification.md` 칸 추가 | 단위 1·2의 연산을 호출하므로 마지막 코드 단위다. `device-verification.md`는 패키지에 속하지 않으므로 그 칸이 검증하는 동작(App 계기 판정)을 구현하는 이 단위에 배정한다 | `compile` |
| — | 전체 완료 검증 | `[no-write]` | `build`·`compile`·`test`, 시나리오별 수용 기준 확인 | 파일을 바꾸지 않는 검증만 둔다. 단위 3의 마지막 커밋 단위에 배정한다 | `build`, `compile`, `test` |

### 단위별 파일(단위 1~3은 `sources/Projects/` 기준)

| 단위 | 패키지 | 파일 |
|---|---|---|
| 1 | Domain | `Domain/ProjectGeneration/UseCases/ProjectGenerationUseCase.swift`, `Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`, `Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift` |
| 1 | Feature | `Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`, `Feature/Tests/ProjectRegistration/TestDoubles/ProjectGenerationUseCaseStub.swift`, `Feature/Tests/ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift` |
| 1 | App | `App/GitIt/Screens/AppRootView.swift`, `App/Tests/GitIt/TestDoubles/ProjectGenerationUseCaseMock.swift` |
| 2 | Domain | `Domain/Project/UseCases/ProjectUseCase.swift`, `Domain/Project/UseCases/Project.swift`, `Domain/Tests/Project/TestDoubles/StubProjectRepository.swift`, `Domain/Tests/Project/UseCases/ProjectTests.swift` |
| 2 | Feature | `Feature/Tests/Home/TestDoubles/ProjectUseCaseMock.swift`, `Feature/Tests/ProjectDetail/TestDoubles/ProjectUseCaseDetailStub.swift` |
| 2 | App | `App/GitIt/Screens/AppRootView.swift`, `App/Tests/GitIt/TestDoubles/ProjectUseCaseMock.swift` |
| 3 | App | `App/GitIt/GitItApp.swift`, `App/GitIt/Reducers/AppRootFeature.swift`, `App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`, `App/Tests/GitIt/Reducers/AppRootFeatureLearningProjectsRefreshTests.swift`(신규), `App/Tests/GitIt/TestDoubles/ProjectUseCaseMock.swift`, `App/Tests/GitIt/TestDoubles/ProjectGenerationUseCaseMock.swift` |
| 3 | 패키지 밖(명세 산출물) | `specs/046-project-list-refresh/device-verification.md`(저장소 루트 기준) |

단위 3의 App 테스트 더블은 단위 1·2에서 추가한 요구사항에 호출 기록과 도착 스트림 제어를 더하는 변경이다. 단위 1·2에서는
compile에 필요한 최소 구현만 둔다.

## 복잡성 추적

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| 단위 1에서 `Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`의 적합 타입 3개 제거 | 기존 파일이 [feature.md 제약조건](../../docs/package-rules/feature.md)("Domain의 UseCase·contract 프로토콜을 Feature 안에서 구현해서는 안 됩니다")을 위반하고, `ProjectGenerationUseCase` 요구사항 추가로 이 파일을 반드시 수정해야 한다 | 위반 적합 타입에 메서드만 더하는 것은 기존 관행을 컨벤션보다 앞세우는 것이다(Constitution 원칙 11). 별도 선행 단위로 두면 Feature가 Domain보다 먼저 바뀌어 원칙 7의 위상 순서와 어긋나므로, 이 파일을 바꿔야 하는 integration unit 안에서 처리한다 |
| 두 UseCase 프로토콜 변경을 integration unit으로 구현 | 프로토콜 요구사항 추가는 모든 적합 타입이 같은 커밋에 있어야 compile된다 | 기본 구현을 프로토콜 extension에 두면 테스트 더블이 새 연산을 기록하지 못하고 누락이 컴파일 오류로 드러나지 않는다 |

## 추가 계획(2026-09-28): 알림 누락 뒤 앱 아이콘 복귀 복구

### 요약

1. **알림 센터 반영(FR-023~FR-025)**: 회원 앱 활성화 때 이미 호출되는 `ProjectGeneration.synchronize()`가 끝에
   `GenerationOutcomeRepository.deliveredOutcomes()`를 읽어 기존 `finish` 경로로 반영하고, 도착 알림은 방출하지 않는다.
   알림 센터 읽기는 Infrastructure(`DeliveredNotificationClient`) → Data(`DeliveredRemoteMessageReader`) → Composition
   어댑터(기존 DTO 파서로 파싱) 순서로 전달한다([research D1~D3](./research.md#3부-알림-누락-뒤-앱-아이콘-복귀-복구-2026-09-28-추가)).
2. **목록 기반 완료 판정(FR-026)**: `Project`가 현재 세대로 반영한 페이지의 식별자를 `projectsListed`로 알리고,
   `ConcernUseCaseAssembly`가 이를 `ProjectGenerationUseCase.completeGenerations(of:)`로 연결한다. 진행 중 기록만 완료로 바꾸고
   로컬 알림은 보내지 않는다([research D4·D5](./research.md#d4-목록-응답으로-완료를-판정하는-위치)).
3. App `AppRootFeature`, Feature 동작은 바뀌지 않는다. `ProjectGenerationUseCase` 요구사항 추가로 적합 타입(App 프리뷰·테스트
   더블, Feature 테스트 더블)만 갱신한다.

### 기술 맥락 변경

- **변경 패키지**: Infrastructure(`InfrastructurePushMessaging`), Data(`DataNotification`), Domain(`DomainProjectGeneration`,
  `DomainProject`), Composition(`CompositionLearningProject`, `CompositionApp`), 적합 타입 갱신으로 Feature·App.
- **manifest 변경**: 없음. CompositionLearningProject → DataNotification → InfrastructurePushMessaging 의존이 이미 있다.
- **제약**: 폴링·서버 변경 없음(FR-020). 알림 센터 알림을 지우지 않음(FR-024). 미해결 `NEEDS CLARIFICATION` 없음.

### 헌법 점검(추가분)

| 원칙 | 점검 | 결과 |
|---|---|---|
| 1. 명시적인 경계 | UNUserNotificationCenter는 Infrastructure에만, Data는 역할 계약과 Factory로 감싸고, Composition이 Data→Domain 변환, 관심사 간 연결은 Composition 클로저(`projectDeleted` 선례). 새 의존 방향 없음 | 통과 |
| 2. 상태와 데이터 안전성 | 판정 상태는 `ProjectGeneration`·`Project` actor 내부. 대체된 목록 응답은 완료 판정에 쓰지 않음 | 통과 |
| 3. 검증 가능한 변경 | 단위마다 compile, 마지막에 build·compile·test. Infrastructure 구현은 실기기 검증 항목으로 남김 | 통과 |
| 5. 수정 경로 | 이 명령은 계획 산출물만 수정했다 | 통과 |
| 7. 위험 기반 실행 단위 | 아래 실행 단위 4~7, 프로토콜 요구사항 추가는 integration unit | 통과 |
| 10·11. 네이밍·컨벤션 | [research D6](./research.md#d6-새-공개-이름), 아래 적용 컨벤션 | 통과 |

### 적용 컨벤션(추가분)

| 문서 | 제약 |
| --- | --- |
| [docs/package-rules/infrastructure.md](../../docs/package-rules/infrastructure.md) | 플랫폼 타입(`UNNotification`)을 밖으로 노출하지 않고 프로젝트 소유 모델(`DeliveredRemoteNotification`)로 반환. Data·Domain 의미(생성 결과)를 이름에 넣지 않음 |
| [docs/package-rules/data.md](../../docs/package-rules/data.md) | 기술 이름 없는 역할 계약 `DeliveredRemoteMessageReader`와 `Factories/` 진입점 공개. Data 테스트는 Infrastructure 역할 더블 주입 |
| [docs/package-rules/composition.md](../../docs/package-rules/composition.md) | Data→Domain 변환과 관심사 간 연결은 어댑터·Assembly에서. 선택 인자 + Factory 기본값(기존 `reminderNotifier` 선례) |
| [docs/package-rules/domain.md](../../docs/package-rules/domain.md) | 관심사 타깃끼리 import 금지, 연결은 init 클로저. 새 연산은 기존 계약의 메서드 |
| [docs/conventions/test.md](../../docs/conventions/test.md) | Swift Testing, 한국어 동작 문장, Test Double은 initializer 주입 |
| [docs/conventions/directory-file.md](../../docs/conventions/directory-file.md) | 파일 하나에 타입 하나, 기존 형태 폴더(`Clients/`, `Models/`, `Contracts/`, `Factories/`, `TestDoubles/`)만 사용 |

### 실행 단위(추가분)

위상 순서: Infrastructure → Data → Domain → Composition → Feature → App.

| 순서 | 단위 | 종류 | 목적 | 분리 불가 근거 | 통합 검증 |
|---|---|---|---|---|---|
| 4 | 알림 센터 원격 알림 조회 | Infrastructure | `DeliveredNotificationClient`, 구현, 모델 | 단일 패키지 | `compile` |
| 5 | 전달된 원격 메시지 읽기 | Data | 역할 계약·모델·client·Factory와 테스트 | 단일 패키지 | `compile` |
| 6 | 알림 센터 결과 동기화 | integration (Domain → Composition) | `deliveredOutcomes()` 추가, `synchronize()` 반영, 어댑터·Assembly 연결 | 프로토콜 요구사항 추가 시 적합 타입(Domain 테스트 더블, Composition 어댑터)이 같은 커밋에 있어야 compile된다 | `compile` |
| 7 | 목록 기반 완료 판정 | integration (Domain → Composition → Feature → App) | `completeGenerations(of:)`, `Project.projectsListed`, Assembly 연결, 적합 타입 갱신 | `ProjectGenerationUseCase` 요구사항과 `Project.init` 인자 추가는 모든 적합 타입·생성 지점이 같은 커밋에 있어야 compile된다 | `compile`, 마지막에 `build`·`compile`·`test` |

### 단위별 파일(추가분, `sources/Projects/` 기준)

| 단위 | 패키지 | 파일 |
|---|---|---|
| 4 | Infrastructure | `Infrastructure/PushMessaging/Remote/Clients/DeliveredNotificationClient.swift`(신규), `Infrastructure/PushMessaging/Remote/Clients/NotificationCenterDeliveredNotificationClient.swift`(신규), `Infrastructure/PushMessaging/Remote/Models/DeliveredRemoteNotification.swift`(신규) |
| 5 | Data | `Data/Notification/Contracts/DeliveredRemoteMessageReader.swift`(신규), `Data/Notification/Models/DeliveredRemoteMessage.swift`(신규), `Data/Notification/Clients/DeliveredRemoteMessageClient.swift`(신규), `Data/Notification/Factories/NotificationFactory.swift`, `Data/Tests/Notification/Clients/DeliveredRemoteMessageClientTests.swift`(신규), `Data/Tests/Notification/TestDoubles/StubDeliveredNotificationClient.swift`(신규) |
| 6 | Domain | `Domain/ProjectGeneration/Contracts/GenerationOutcomeRepository.swift`, `Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`, `Domain/Tests/ProjectGeneration/TestDoubles/StubGenerationOutcomeRepository.swift`, `Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift` |
| 6 | Composition | `Composition/LearningProject/Adapters/GenerationOutcomeRepositoryAdapter.swift`, `Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`, `Composition/App/Assemblies/ConcernUseCaseAssembly.swift`, `Composition/Tests/LearningProject/Adapters/GenerationOutcomeRepositoryAdapterTests.swift` |
| 7 | Domain | `Domain/ProjectGeneration/UseCases/ProjectGenerationUseCase.swift`, `Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`, `Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift`, `Domain/Project/UseCases/Project.swift`, `Domain/Tests/Project/UseCases/ProjectTests.swift` |
| 7 | Composition | `Composition/App/Assemblies/ConcernUseCaseAssembly.swift` |
| 7 | Feature | `Feature/Tests/ProjectRegistration/TestDoubles/ProjectGenerationUseCaseStub.swift`, `Feature/Tests/ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift` |
| 7 | App | `App/GitIt/Screens/AppRootView.swift`, `App/Tests/GitIt/TestDoubles/ProjectGenerationUseCaseMock.swift` |

적합 타입 목록은 구현 시 `: ProjectGenerationUseCase`, `GenerationOutcomeRepository`, `Project(` 검색으로 다시 확인하고,
누락된 파일이 있으면 해당 단위에 포함한다.
