# 조사: 레포지토리 생성 상태관리 Repository

이 기능 명세에는 남은 [NEEDS CLARIFICATION] 표식이 없다(명확화 세션에서 모두 해소).
아래는 계획 단계에서 확인이 필요했던 기술 결정 사항이다.

## 결정 1: "생성 중" 상태를 어느 계층·형태로 구현하는가

- **결정**: Domain에 `RepositoryCreationStateRepository` 계약을 두고, 실제 구현은 Composition의
  단일 in-memory `actor`(`RepositoryCreationStateRepositoryAdapter`)로 둔다. Data 패키지는 관여하지
  않는다.
- **근거**: FR-008에 따라 상태는 영속화하지 않고 프로세스 메모리에만 유지하면 되므로, 서버
  DTO나 로컬 저장소(UserDefaults 등)가 필요한 `GenerationProgressRepository`류와 달리 Data
  계층 없이 Composition만으로 충분하다. `actor`는 Swift 동시성 안전성을 보장하면서 기존
  `GenerationCompletionReminderCoordinator`가 이미 증명한 패턴(actor + `observeGenerationOutcomes`
  구독)과 일치해 검토 비용이 낮다.
- **검토한 대안**:
  - Data 계층에 로컬 저장소(UserDefaults)를 두는 방안 — FR-008(영속화하지 않음) 및 가정과
    충돌해 기각.
  - Domain UseCase 내부에 static/전역 상태로 두는 방안 — Constitution 원칙 2(상태 소유자·수명
    범위 명시)와 `@Dependency`/전역 mutable container 금지 컨벤션에 위배되어 기각.

## 결정 2: 레포지토리 동일성 판별과 필터링 키

- **결정**: 생성 시작 시점에는 정규화된 `githubRepoURL`(트림, 소문자 변환, 끝 슬래시 제거)을
  식별자로 사용해 중복을 판별한다. `register()` 성공 응답으로 `projectID`를 얻으면 같은 상태
  레코드에 `projectID`를 연결해, 이후 `FetchLearningProjects`의 필터링(서버가 돌려주는
  `LearningProjectSummary.projectID` 기준)과 `GenerationOutcome.projectID` 기준 해제 신호 모두와
  매칭한다.
- **근거**: `LearningProjectSummary`에는 `githubRepoURL`이 없고 `projectID`만 있어(조사 결과,
  `sources/Projects/Domain/LearningProject/Models/LearningProject/LearningProjectSummary.swift`),
  목록 필터링은 `projectID` 기준일 수밖에 없다. 반면 생성 시작 시점에는 아직 `projectID`가
  없으므로 `githubRepoURL`이 유일한 키다. 하나의 레코드가 두 식별자를 모두 보관하는 것이
  가장 단순한 매칭 방법이다.
- **검토한 대안**: 서버 등록 API가 `githubRepoURL`을 목록 응답에 포함하도록 확장하는 방안 —
  Data/서버 계약 변경이 필요해 이 기능의 범위(클라이언트 상태 관리)를 벗어나 기각.

## 결정 3: 생성 완료/실패 신호 연결 방식

- **결정**: 새 Composition actor가 기존 `ObserveGenerationOutcomesUseCase` 스트림을 직접
  구독해 `GenerationOutcome.status`(`.completed`/`.failed`)를 수신하면 해당 `projectID`의
  "생성 중" 상태를 해제한다. 구독 시작은 App 부트스트랩에서 기존
  `GenerationCompletionReminderCoordinator.start(observeGenerationOutcomes:)`가 호출되는 지점
  (`sources/Projects/Composition/App/Assemblies/AppComposition.swift`)과 동일한 자리에 추가한다.
- **근거**: 이미 검증된 배선 지점을 재사용하면 새로운 서버 API·폴링을 도입하지 않고(가정에
  명시된 제약) 기존 인프라를 그대로 활용할 수 있다.
- **검토한 대안**: `CreateLearningProject` UseCase가 자체적으로 결과를 기다리는 방안 — 등록
  요청과 생성 완료 사이의 시간(정상 흐름에서 FCM + 300~500초 지연)이 길어 UseCase 호출을
  그만큼 붙잡아 둘 수 없어 기각.

## 결정 4: 신호 유실 안전장치(15분 타임아웃) 구현 방식

- **결정**: 별도 백그라운드 타이머·Task를 두지 않고, 상태를 조회하는 시점(`isCreating`,
  `activeProjectIDs`, 새 `beginCreation` 호출 시 중복 검사)마다 기록 시각(`recordedAt`)이
  900초를 초과한 레코드를 함께 정리(lazy expiry)한다.
- **근거**: 요구되는 것은 "다음 조회 시점에는 더 이상 막지 않는다"이지, 정확히 900초 뒤에
  즉시 반응하는 실시간 타이머가 아니다. Lazy expiry는 별도 Task 생명주기 관리, 취소, 앱
  종료 시 정리 문제를 없애 Constitution 원칙 2(비동기 작업의 오류·취소 경로 처리)의 부담을
  줄인다.
- **검토한 대안**: `Task.sleep` 기반 만료 타이머를 레코드마다 예약하는 방안 — 다수의 취소
  가능한 Task를 관리해야 해 복잡도가 늘고, 이 기능의 저빈도·소규모 상태에는 이득이 적어
  기각.

## 결정 5: 오류 표현

- **결정**: 기존 `LearningProjectError` enum에 새 case(예: `duplicateCreationInProgress`)를
  추가해 사용한다. 새 오류 타입을 별도로 만들지 않는다.
- **근거**: `CreateLearningProjectUseCase.callAsFunction`은 이미 `LearningProjectRepository`가
  던지는 `LearningProjectError`를 그대로 전파하는 구조라, 같은 오류 타입에 case를 추가하는
  편이 호출부(Feature 계층)의 기존 `switch`/에러 매핑 로직과 자연스럽게 맞물린다.
- **검토한 대안**: `CreateLearningProjectUseCase` 전용 새 오류 타입 도입 — 호출부가 두 종류의
  오류를 모두 처리해야 해 불필요한 복잡도를 추가하므로 기각.
