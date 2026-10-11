# 구현 계획: 서버 프로젝트 목록에서 확인된 생성 중 프로젝트를 완료로 반영

**Git-flow 유형**: `feature`

**브랜치**: `feature/generation-list-completion`

**날짜**: 2026-10-01 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/049-generation-list-completion/spec.md`의 기능 명세

## 요약

서버가 생성 결과 원격 알림을 보내지 않으면 생성 기록이 진행 중으로 남아 홈 잠금·진행 화면·공유 확장
차단이 보관 기한(1시간)까지 풀리지 않는다. 서버 프로젝트 목록에는 생성이 끝난 프로젝트만 나타나므로,
목록 로드에 진행 중 기록의 프로젝트가 포함되면 그 기록을 원격 알림 `QUIZ_READY`와 같은 완료 결과로
반영한다.

구현은 이미 있는 두 Domain 관심사 사이의 연결 방식을 그대로 따른다. `Project`(목록)가 삭제 성공을
`projectDeleted` 클로저로 알리고 Composition이 `ProjectGeneration.release`에 연결한 것과 같은 모양으로,
`Project`가 목록에 반영한 페이지의 프로젝트 식별자를 `projectsListed` 클로저로 알리고 Composition이
`ProjectGeneration.confirmCompletion(of:)`에 연결한다([research R1·R2](./research.md)). 완료 전이
규칙과 중복·뒤집힘 방지는 기존 `GenerationRecord.finishing`이 이미 보장한다([R3](./research.md#r3-중복-반영과-결과-뒤집힘-방지fr-004-fr-005)).

## 기술 맥락

**언어/버전**: Swift 6(typed throws), iOS 26.0 이상

**주요 의존성**: SwiftUI, TCA(The Composable Architecture). 이 변경은 Domain·Composition만 수정하며 새
외부 의존성이 없다.

**저장소**: App Group 공유 `UserDefaults` 계열 키 값 저장소의 생성 기록(`generationState`). 저장 형식은
바꾸지 않는다.

**테스트**: Swift Testing. 빌드 실행기의 `build`·`compile`·`test`를 사용한다.

**대상 플랫폼**: iOS 26.0 이상 앱. 공유 확장은 코드를 바꾸지 않고 공유 저장소 기록으로 효과를 받는다.

**프로젝트 유형**: 모바일 앱(Tuist 멀티 패키지)

**성능 목표**: 해당 없음. 목록 로드 한 번당 페이지 항목 수(20개 내외)와 진행 중 기록 수의 집합 대조다.

**제약 조건**:
- 서버 API·알림 payload를 바꾸지 않고 폴링·새 목록 요청 계기를 추가하지 않는다(FR-008).
- 목록 확인은 목록 갱신 계기(046 FR-002)로 쓰지 않는다(FR-006).
- 목록 확인에 사용자 알림을 두지 않는다(FR-007).
- 원격 알림 반영, 결과 보존·재시도, 만료, 로그아웃, 삭제 해제는 그대로 둔다(FR-009).

**규모/범위**: 운영 파일 3개(Domain 2, Composition 1), 테스트 파일 2개(Domain), 문서 1개(048 spec). 두
패키지(Domain, Composition)와 `specs/048-generation-outcome-payload/spec.md`가 대상이다.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 점검 | 결과 |
|---|---|---|
| 브랜치 네임스페이스 | `feature/generation-list-completion`은 `/speckit-specify`가 2026-10-01에 048 HEAD `238d804`에서 만들었다. | 통과 |
| 허용 수정 경로 | 이 명령은 plan·research·data-model·quickstart·contracts만 만든다. 구현 경로는 아래 "실행 단위"에 기록한다. | 통과 |
| 의존성 방향(architecture.md 7.1) | 새 의존성이 없다. Domain 관심사 타깃(`Project`, `ProjectGeneration`)은 서로 import하지 않고 Composition이 클로저로 연결한다. | 통과 |
| 생성자 주입 | `Project`의 새 클로저 인자는 생성자로 주입한다. 전역 상태나 `@Dependency`를 쓰지 않는다. | 통과 |
| 책임 기반 네이밍(원칙 10) | 새 공개 이름 `projectsListed`·`confirmCompletion(of:)`은 [R2](./research.md#r2-공개-이름)에 근거를 둔다. rename은 없다. | 통과 |
| 위상 순서(원칙 7) | U1 Domain → U2 Domain+Composition → U3 문서. 제거 예외는 쓰지 않는다. | 통과 |
| 커밋 단위 구현 | 3개 단위. 다중 패키지 단위 1개(U2)는 아래에 분리 불가 근거와 통합 검증을 적었다. | 통과 |
| 테스트 컨벤션 | 새 테스트는 Swift Testing과 한국어 동작 문장 이름을 쓰고 Test Double은 initializer로 주입한다. | 통과 |
| 세션 지식 기록(원칙 9) | 서버 알림 누락이 실기기에서 재현되어 목록 경로가 필요해진 경위는 문턱을 넘을 수 있다. 구현 뒤 `speckit-troubleshooting` 사용 여부를 따로 판단하며 계획 산출물로 만들지 않는다. | 해당 시 별도 |

설계 후 재점검 결과, 위 판정은 바뀌지 않았다. 복잡성 추적에 올릴 위반은 없다.

## 적용 컨벤션

| 문서 | 이번 설계에 부과한 제약 |
| --- | --- |
| `docs/architecture.md` | Domain은 Data·Composition을 모른다. 두 관심사의 연결은 Composition이 소유한다. 위상 순서는 Domain → Composition이다. |
| `docs/package-rules/domain.md` | 관심사 타깃은 서로 import하지 않는다. 그래서 `Project`는 `ProjectGeneration`을 부르지 못하고 클로저로 알린다. 완료 판정 규칙(어느 기록을 끝낼지)은 `ProjectGeneration`이 소유한다. 상태를 가진 관심사는 `actor`이며 순서 보장은 구현 내부 상태로 둔다. |
| `docs/package-rules/composition.md` | Composition은 조립과 연결만 한다. `projectsListed` 클로저는 `confirmCompletion(of:)`를 그대로 부르며 비즈니스 판정을 넣지 않는다. 공개 API 인자는 Domain 타입만 쓴다. |
| `docs/conventions/abstraction.md` | 프로토콜은 교체 근거가 있을 때만 둔다. `confirmCompletion(of:)`은 Composition 연결에서만 부르므로 `ProjectGenerationUseCase` 계약에 추가하지 않는다([R2](./research.md#r2-공개-이름)). |
| `docs/conventions/naming.md` §3.3·§3.5 | 동사와 목적어가 실제 효과를 드러낸다. `confirmCompletion(of:)`은 "확인된 완료를 기록에 반영"을, `projectsListed`는 "목록에 반영된 프로젝트"라는 경계 값을 뜻한다. |
| `docs/conventions/test.md` | 새 동작은 Domain 테스트로 검증한다. 클로저 호출은 Fixture의 기록 클로저로 관찰하며 Test Double은 initializer로 주입한다. |
| `docs/conventions/directory-file.md`, `docs/conventions/file-vocabulary.md` | 새 파일·폴더를 만들지 않는다. 기존 UseCase·테스트 파일에 메서드와 테스트를 추가한다. |

## 프로젝트 구조

### 문서(이 기능)

```text
specs/049-generation-list-completion/
├── spec.md
├── plan.md              # 이 파일
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── list-confirmed-completion.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks 산출물
```

### 소스 코드

아래 경로는 모두 `sources/Projects/` 기준이다.

```text
Domain/ProjectGeneration/UseCases/ProjectGeneration.swift     # confirmCompletion(of:) 추가
Domain/Project/UseCases/Project.swift                         # projectsListed 클로저 주입과 호출
Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift
Domain/Tests/Project/UseCases/ProjectTests.swift
Composition/App/Assemblies/ConcernUseCaseAssembly.swift       # 클로저 연결
```

**구조 결정**: 기존 파일만 수정한다. 새 타입·파일·target·manifest 변경이 없으므로 `make tuist` 재생성이
필요 없다.

## 실행 단위

위상 순서는 Domain → Composition이다. 각 단위가 끝나면 `"$project_build_runner" compile`을 실행하고,
마지막 단위에서 `build`·`compile`·`test`를 모두 실행한다.

### U1 — [Feat] 목록 확인으로 진행 중 생성 기록을 완료로 반영 (Domain, 단일 패키지)

- 수정: `Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`
  - `public func confirmCompletion(of projectIDs: [ProjectID]) async` 추가. 규칙은
    [contracts/list-confirmed-completion.md](./contracts/list-confirmed-completion.md)의 판정표를 따른다.
  - `ProjectGenerationUseCase` 계약은 바꾸지 않는다(R2).
- 테스트 수정: `Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift`
- **검증**: `compile`. 판정표의 각 행과 "도착 알림을 방출하지 않는다", "관찰 전에도 저장소에 반영된다"를
  테스트로 검증한다(SC-001·SC-003·SC-004·SC-005의 Domain 부분).

### U2 — [Feat] 목록에 반영한 프로젝트를 생성 기록에 알림 (Domain + Composition, 통합 단위)

- **분리 불가 근거**: `Project.init`에 필수 인자 `projectsListed`를 추가하면 Composition의
  `ConcernUseCaseAssembly`가 같은 커밋에서 인자를 넘겨야 compile된다. 기본값(no-op)을 두는 안은 production
  연결 누락을 숨기므로 기각했다(R1).
- Domain 수정: `Domain/Project/UseCases/Project.swift`
  - `init`에 `projectsListed: @escaping @Sendable ([ProjectID]) async -> Void` 추가(`projectDeleted` 뒤).
  - 첫 페이지 교체와 다음 페이지 추가가 목록에 **반영된** 뒤 그 페이지 항목의 식별자로 클로저를 부른다.
    대체된(epoch 불일치) 응답과 실패한 로드는 부르지 않는다.
- Domain 테스트 수정: `Domain/Tests/Project/UseCases/ProjectTests.swift`
- Composition 수정: `Composition/App/Assemblies/ConcernUseCaseAssembly.swift`
  - `Project(... projectsListed: { await projectGeneration.confirmCompletion(of: $0) })`
- **검증**: `compile`. Project 테스트로 "첫 페이지·다음 페이지 반영 시 알린다", "대체된 응답·실패는 알리지
  않는다"를 검증한다. Composition 연결은 compile과 실기기 검증(quickstart 3)으로 확인한다(R5).

### U3 — [Docs] 048 결과 경로 가정 갱신 (문서, 마지막 단위)

- 수정: `specs/048-generation-outcome-payload/spec.md` 가정 섹션의 "생성 결과는 원격 알림으로만
  들어오므로 …" 문장에 이 명세로 갱신되었다는 표시를 붙인다(FR-010, SC-007). 다른 문장은 바꾸지 않는다.
- **검증**:
  - 전체 `build`·`compile`·`test`와 필수 `after_implement` hook(`speckit.swift-format.run`)을 실행한다.
  - 실기기 확인(SC-001·SC-002)은 [quickstart.md](./quickstart.md)를 따르며, 수행하지 못하면 미검증으로
    기록한다.

## 복잡성 추적

헌법 점검에서 정당화가 필요한 위반이 없다.
