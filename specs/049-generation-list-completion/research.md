# 조사: 서버 프로젝트 목록에서 확인된 생성 중 프로젝트를 완료로 반영

**날짜**: 2026-10-01 | **명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

기술 맥락에 NEEDS CLARIFICATION은 없었다. 아래는 설계 결정과 그 근거다.

## R1. 두 관심사의 연결 방식(FR-001)

- **결정**: `Project`(목록)가 목록에 반영한 페이지의 프로젝트 식별자를 생성자 주입 클로저
  `projectsListed`로 알리고, Composition `ConcernUseCaseAssembly`가 이를
  `ProjectGeneration.confirmCompletion(of:)`에 연결한다.
- **근거**:
  - Domain 관심사 타깃은 서로 import하지 못한다(`docs/package-rules/domain.md`). 그래서 `Project`가
    `ProjectGeneration`을 직접 부를 수 없다.
  - 같은 두 관심사가 이미 같은 방식으로 연결되어 있다. `Project.delete`가 `projectDeleted` 클로저를 부르고
    Composition이 `projectGeneration.release`에 연결한다(커밋 `78d065c`, 046 FR-022). 새 연결도 그 옆에
    같은 모양으로 둔다.
  - 완료 판정 규칙(어느 기록을 끝낼지)은 `ProjectGeneration`이 소유한다. `Project`는 "이 프로젝트들이
    목록에 있다"는 사실만 알리고, Composition 클로저는 그대로 전달만 한다. Composition 규칙 "비즈니스
    규칙을 Adapter에 두지 않는다"에 맞다.
- **검토한 대안**:
  - App(`AppRootFeature`)이 `project.projects()` 스트림을 관찰해 `confirmCompletion`을 부르는 안:
    Domain 규칙을 App이 구현하게 되어 기각했다(`docs/package-rules/app.md` 제약).
  - `ProjectGeneration`이 목록 스트림을 주입받아 스스로 관찰하는 안: 관심사가 다른 관심사의 모델
    (`ProjectList`)을 알아야 해 기각했다.
  - `projectsListed`에 기본값(no-op)을 두어 U2를 단일 패키지로 나누는 안: production 조립에서 연결을
    빠뜨려도 compile이 통과해 결함이 숨는다. `projectDeleted`·`signedOutEvents`도 기본값이 없다. 기각했다.

## R2. 공개 이름

- **결정**:
  - `Project.init(... projectsListed: @escaping @Sendable ([ProjectID]) async -> Void)`
  - `ProjectGeneration.confirmCompletion(of projectIDs: [ProjectID]) async`
  - `confirmCompletion(of:)`은 `ProjectGenerationUseCase` 프로토콜에 추가하지 않고 actor의 공개
    메서드로만 둔다.
- **근거**:
  - `projectsListed`는 `projectDeleted`와 같은 사건 어휘다. "목록에 반영된 프로젝트"라는 경계 값의 뜻을
    드러낸다(naming §3.5).
  - `confirmCompletion(of:)`은 "목록으로 확인된 완료를 기록에 반영한다"는 실제 효과를 동사·목적어로
    드러낸다(naming §3.3). `finish`·`markCompleted`는 결과 원인을 감춘다.
  - 프로토콜에 넣지 않는 이유: `ProjectGenerationUseCase`는 Feature·App 주입과 Test Double 교체를 위한
    계약이다. `confirmCompletion(of:)`은 Composition 조립 코드가 concrete `ProjectGeneration`으로만 부르고
    Feature·App은 쓰지 않는다. 추상화 컨벤션은 교체 근거가 없는 프로토콜 요구사항을 두지 않는다
    (`docs/conventions/abstraction.md` §2). 프로토콜에 넣으면 App·Feature의 conformer 9개(미리보기 1,
    Test Double 8)에 쓰지 않는 no-op을 추가해야 한다.
- **검토한 대안**: `release`처럼 프로토콜에 추가하는 안. `release`는 78d065c에서 프로토콜에 들어갔지만
  실제 호출자는 Composition 연결 하나뿐이라 같은 상황이었다. 컨벤션이 기존 관행보다 우선하므로 새 메서드는
  프로토콜 밖에 둔다. `release`를 프로토콜에서 빼는 정리는 이 명세 범위 밖이다.

## R3. 중복 반영과 결과 뒤집힘 방지(FR-004, FR-005)

- **결정**: 새 판정 로직을 만들지 않고 기존 `GenerationRecord.finishing(status:at:)`과
  `PendingGenerationRepository.finishGeneration`을 그대로 거친다.
- **근거**:
  - `GenerationRecord.finishing`은 `status == .inProgress`일 때만 전이하고, 이미 완료·실패면 자신을
    그대로 돌려준다. 그래서 목록 확인 뒤 늦게 온 `QUIZ_READY`도, 원격 알림으로 실패한 뒤 온 목록 확인도
    기록을 바꾸지 않는다(시나리오 3).
  - `GenerationState.finishing(projectID:)`은 `projectID`가 같은 기록만 고치므로 식별자가 없는 기록과
    기록에 없는 프로젝트는 영향을 받지 않는다(FR-004).
  - `PendingGenerationRepositoryAdapter.finishGeneration`은 기록이 있으면 `true`를 돌려준다(이미
    끝난 기록도 포함). 그래서 목록 확인으로 완료된 뒤 온 원격 알림은 보존·재시도 대기열에 들어가지 않는다.
- **검토한 대안**: `confirmCompletion`이 진행 중 기록만 미리 골라 `finishGeneration`을 부르는 안. 저장소
  갱신 사이의 경쟁을 피하려면 어차피 저장소 안의 `finishing` 가드를 믿어야 하므로, 미리 고르는 것은 호출
  횟수만 줄이는 최적화다. 진행 중 기록의 식별자 집합과 목록 식별자의 교집합에만 부르되, 정확성은
  `finishing` 가드에 맡긴다.

## R4. 목록 확인이 목록 갱신 계기가 되지 않게(FR-006)

- **결정**: `confirmCompletion(of:)`은 `outcomeArrivals()` 스트림에 아무것도 방출하지 않고
  `recentArrivals`에도 기록하지 않는다. 기록 갱신 뒤 `apply`로 `states()`만 방출한다.
- **근거**:
  - 목록 갱신 계기는 `AppRootFeature`가 `outcomeArrivals()`를 관찰해 만든다(046 FR-002). 여기에 방출하면
    목록 로드 → 완료 반영 → 목록 로드가 반복된다.
  - `states()` 방출은 홈 잠금(`AppRootFeature.applyGenerationState`), 생성 진행 화면
    (`QuizGenerationProgressFeature`의 `generationStates`), 공유 확장(`currentState()`로 저장소 읽기)이
    이미 받는 경로다. 그래서 FR-002의 "원격 알림 완료와 같은 결과"가 추가 코드 없이 성립한다.
  - 목록 확인으로 완료된 뒤 늦게 온 `QUIZ_READY`는 `recentArrivals`에 없으므로 기존대로 도착 알림을 방출해
    목록을 한 번 더 갱신한다. 이는 원격 알림이 만든 계기라 FR-006에 어긋나지 않고, 기록은 R3에 따라
    바뀌지 않는다.

## R5. Composition 연결의 검증 범위

- **결정**: `ConcernUseCaseAssembly`의 `projectsListed` 연결은 compile과 실기기 검증으로 확인하고, 별도
  Composition 테스트를 두지 않는다.
- **근거**:
  - 연결은 클로저 한 줄이고 판정 규칙은 모두 Domain 테스트가 검증한다.
  - 기존 `projectDeleted` 연결에도 Composition 테스트가 없다. `AppCompositionTests` 계열은 공개 표면과
    수명만 다룬다.
  - 실기기 검증(quickstart 3)이 연결까지 포함한 끝단 동작을 확인한다.
- **검토한 대안**: `ConcernUseCaseAssembly`를 인메모리 저장소로 조립해 목록 로드 뒤 생성 기록을 읽는
  통합 테스트. 조립에 필요한 인자(원격·인증·저장소)가 많아 얻는 것에 비해 비용이 크다.

## R6. 알림 방식(FR-007)

- **결정**: 목록 확인 경로에는 로컬 알림이나 다른 사용자 알림을 두지 않는다.
- **근거**:
  - 목록 로드는 회원 사용자가 메인 화면 흐름에 있고 앱이 포그라운드일 때만 일어난다(046 FR-001~FR-004).
    그래서 완료가 반영되는 순간 사용자는 화면을 보고 있고, 잠금 해제·진행 화면 전환으로 결과를 안다.
  - 048이 로컬 결과 알림 기능을 모두 제거했다. 이 경로만을 위해 되살릴 이유가 없다.
  - 048 가정 "원격 알림이 아닌 결과 경로가 생기면 그때 알림 방식을 다시 정한다"에 대한 답이 이 결정이며,
    U3에서 048 가정에 표시를 붙인다(FR-010).

## R7. 확인 대상 페이지의 범위

- **결정**: 목록에 **반영된** 페이지의 항목만 알린다. 대체 새로고침으로 버려진 응답(epoch 불일치)과
  실패한 로드는 알리지 않는다. 다음 페이지는 목록에 이미 있어 걸러진 항목을 포함해 그 페이지 항목 전체를
  알린다.
- **근거**:
  - `Project`는 대체된 응답을 목록에 반영하지 않는다(`replaceWithFirstPage`·`appendPage`의 epoch 가드).
    반영하지 않은 응답을 근거로 삼으면 "목록에서 확인된"이라는 명세 문장과 어긋나고, 로그아웃 뒤 늦게
    도착한 이전 세션 응답이 새 세션 기록을 건드릴 수 있다.
  - 다음 페이지에서 이미 목록에 있는 항목을 걸러도 `confirmCompletion`은 멱등이라(R3) 결과가 같다. 걸러진
    항목을 따로 계산하지 않는 편이 단순하다.
- **검토한 대안**: 응답이 오면 반영 여부와 무관하게 알리는 안. 위 이유로 기각했다.

## R8. 실행 단위와 위상 순서

- **결정**: 3개 커밋 단위. U1 Domain(`ProjectGeneration`) → U2 Domain(`Project`)+Composition 통합 →
  U3 문서.
- **근거**:
  - Composition은 Domain에 의존하므로 Domain이 먼저다. U2가 U1의 `confirmCompletion(of:)`을 연결하므로
    U1이 U2보다 앞선다.
  - U2가 통합 단위인 이유는 R1의 기본값 기각 결정이다. `Project.init` 시그니처 변경과 조립 인자 추가는
    같은 커밋이어야 compile된다.
  - U3은 코드와 무관한 문서 정정이며, 전체 검증과 필수 후행 훅을 마지막에 묶는다.
