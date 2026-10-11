# 기능 명세: UC01~UC20 전체 UseCase end-to-end 구현

**Git-flow 유형**: `feature`

**기능 브랜치**: `미생성 (예정: feature/all-usecases-implementation)`

**생성일**: 2026-08-22

**상태**: 초안

**코드 기준**: `Nexters/Git-It-iOS develop@bdb095b5416207982c53f2ccb083373d6b42edb7`

**API source 기준**: `Nexters/Git-it-Server main@8641bc961cac7dfbf0079cdbec020c65da8ccff1`

**배포 OpenAPI**: 미확보

**선행 정본**: `private/CONVENTION-BASELINE.md` (패키지 책임·의존 방향·Domain UseCase 컨벤션·Data/Composition/Feature/App 경계·세션 401 refresh 규칙·네이밍·Tuist target·테스트 CI 요구사항의 정합 기준)

**입력**: 사용자 설명: "private/spec.md 문서 내용을 기반으로 014-all-usecases-implementation 기능 명세를 작성/갱신합니다. private/CONVENTION-BASELINE.md를 선행 정본으로 사용해 패키지 책임, 의존 방향, Domain UseCase 컨벤션, Data/Composition/Feature/App 경계, 세션·401·refresh 규칙, 네이밍, Tuist target, 테스트·CI 요구사항을 정합합니다. 코드 기준은 develop@bdb095b5416207982c53f2ccb083373d6b42edb7이며, UC01~UC20 전체 UseCase의 Domain 계약부터 App root 도달까지 end-to-end 구현을 다루는 기능 명세를 specs/014-all-usecases-implementation/spec.md에 작성합니다."

---

## 배경

현재 저장소는 일부 UseCase의 Domain·Data·Composition 기반을 갖췄지만 Feature production 구현과 App root 연결이 없어, 사용자가 실제로 호출할 수 있는 제품 UseCase가 하나도 없다. `private/CONVENTION-BASELINE.md`는 패키지 경계와 객체 수명 재해석을 방지하기 위해 이 명세보다 선행하는 정본이며, 두 문서가 충돌하면 CONVENTION-BASELINE.md를 따른다. 본 명세는 "파일 또는 Protocol 존재"가 아니라 다음 end-to-end 경로 완성을 기준으로 UC01~UC20을 구현한다.

```text
승인된 제품 의미
→ Domain UseCase Protocol·모델·오류
→ Infrastructure 기술 API
→ Data concrete Remote·DTO·Endpoint
→ CompositionAdapter mapping·live graph
→ Feature State·Action·Effect·View
→ App root·route·lifecycle
→ package test·App test·CI gate
```

## 명확화

### 세션 2026-08-22

- 질문: `private/spec.md`, `private/CONVENTION-BASELINE.md`는 `.gitignore`(`private/**`)로 커밋되지 않는데, UC01~UC20 상세 카탈로그와 컨벤션 규칙 원문을 이 명세가 참조만 하도록 둘지, 커밋 대상 경로로 복사할지? → 답변: A — 원문을 `specs/014-all-usecases-implementation/` 아래 커밋 대상 파일로 복사해 참조 무결성을 보존한다.

**적용**: UC01~UC20 Protocol·입출력·오류 매핑의 상세 정의(`private/spec.md` 7장)와 패키지·의존·네이밍·테스트 컨벤션 원문(`private/CONVENTION-BASELINE.md`)은 `/speckit-plan` 단계에서 `specs/014-all-usecases-implementation/contracts/usecase-catalog.md`(UC 카탈로그)와 `specs/014-all-usecases-implementation/research.md`(컨벤션 정합 근거)로 복사해 커밋 대상으로 만든다. 이 문서(`spec.md`)의 `private/` 참조는 원본 출처 표시로만 유지하고, 구현·계획 단계는 커밋된 사본을 정본으로 사용한다.

### 해석 우선순위

1. `private/CONVENTION-BASELINE.md` (패키지·의존·컨벤션 정본; 커밋 사본은 `research.md` 참고)
2. `decision-log.md`
3. `common-spec.md`, U01~U08
4. 배포 OpenAPI artifact (미확보)
5. 고정 서버 source contract (`Git-it-Server main@8641bc9...`)
6. Figma 직접 근거
7. 현재 iOS source(`develop@bdb095b...`)
8. 과거 감사·구현 계획

현재 iOS 코드가 요구사항과 충돌하면 코드를 정본으로 승격하지 않는다.

---

## 범위

### 포함

- UC01~UC20 Domain UseCase Protocol과 concrete 구현, 필요한 Domain 모델·오류·Repository 계약
- Data concrete Remote와 인증 header·request·response·오류 변환
- CompositionAdapter의 DTO→Domain 및 Data→Domain 오류 mapping과 Assembly(Authentication/ExternalRepository/LearningProject/Member)·App composition root
- U01~U08 Feature production 구현과 App navigation 연결
- SessionRecord, local legal acceptance, refresh single-flight 의미
- Tuist target·scheme·test target 정비
- UIComponent ViewModel 제거 기준 준수와 누락 component 구현
- App launch, route 도달성, unit/UI test와 CI release gate

### 제외

- 서버 refresh/revoke endpoint·DTO의 임의 설계
- generation status polling·terminal 완료 UI
- private GitHub Repository 인증
- 오프라인 제출 큐와 로컬 북마크/답변 동기화
- 다중 기기 관리 UI
- 승인되지 않은 약관·개인정보 production 문안
- 서버 endpoint 설계 품질 평가
- 프로필 사진·nickname·email 편집
- automatic essay grading

---

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - Domain 계약을 UC01~UC20까지 완비한다 (우선순위: P1)

Domain 개발자와 Feature 개발자가 UC01~UC20 전체에 대응하는 `XxxUseCase` Protocol과 concrete `Xxx` 구현을 갖게 되어, 서버 계약(nullable ID, raw status, 오류 의미)을 손실 없이 Feature에 전달할 수 있다.

**주요 행위자**: Domain 개발자, Feature 개발자

**우선순위 이유**: 이후 모든 계층(Data·Composition·Feature·App)이 Domain Protocol을 기준으로 조립되므로, Domain 계약 완비가 다른 시나리오의 선행 조건이다.

**독립 테스트**: Domain target만 빌드·테스트해 Protocol/concrete 대응과 모델 불변식을 검증할 수 있으며, 서버 nullability·raw status·오류 의미가 보존됨을 독립적으로 확인할 수 있다.

**수용 시나리오**:

1. **전제** UC06~UC10과 UC15~UC20 Domain 계약이 없다, **실행** `specs/014-all-usecases-implementation/contracts/usecase-catalog.md`(계획 단계에서 `private/spec.md` 7장 원문을 복사해 생성)의 UC01~UC20 정본 카탈로그를 구현한다, **결과** UC01~UC20 모두 대응 `XxxUseCase` Protocol과 concrete `Xxx`가 존재한다.
2. **전제** Protocol signature를 검사한다, **실행** import·입출력 타입을 확인한다, **결과** DTO·HTTP·Infrastructure·SwiftUI·TCA 타입 참조가 0건이다.
3. **전제** 서버가 nullable ID와 raw status를 반환한다, **실행** Domain mapping을 수행한다, **결과** optional과 raw value가 손실되지 않는다.
4. **전제** 서버가 오류를 반환한다, **실행** UseCase를 호출한다, **결과** 401·project/set/question/member unavailable·temporary failure가 서로 구분된 Domain 오류로 표현된다.

---

### 시나리오 2 - Data가 모든 API operation의 실행 가능한 Remote를 제공한다 (우선순위: P1)

Data·Infrastructure 개발자가 UC06~UC10, UC15~UC20에 필요한 concrete HTTP Remote를 완비해, 보호 API에는 매 요청 시점의 access token이 실리고 GitHub public API에는 Git-It token이 실리지 않는 상태를 만든다.

**주요 행위자**: Data 개발자, Infrastructure 개발자

**우선순위 이유**: Domain 계약이 실행 가능해지려면 실제 네트워크 계층이 있어야 하며, 인증 header 누락은 보안·정합성 결함으로 직결된다.

**독립 테스트**: Infrastructure stub transport를 주입해 request·header·body·response·오류를 검증할 수 있다.

**수용 시나리오**:

1. **전제** set/answer/bookmark/member는 Protocol·Endpoint만 있다, **실행** concrete HTTP Remote를 추가한다, **결과** UC06~UC10·UC15~UC20의 서버 호출이 실제 실행 가능하다.
2. **전제** Git-It 보호 operation을 호출한다, **실행** request를 캡처한다, **결과** 현재 access token의 Bearer header가 포함된다.
3. **전제** GitHub public lookup을 호출한다, **실행** request를 캡처한다, **결과** Git-It Bearer token이 포함되지 않는다.
4. **전제** 서버가 401/404/500 또는 invalid payload를 반환한다, **실행** Remote를 호출한다, **결과** Data 오류가 status·server code 의미를 보존한다.

---

### 시나리오 3 - CompositionAdapter가 전체 live graph를 조립한다 (우선순위: P1)

App·Composition 개발자가 하나의 App composition root에서 UC01~UC20 중 외부 capability가 확보된 UseCase 전부를 Domain Protocol 타입으로 노출하고, 공유 session·transport 수명을 보장한다.

**주요 행위자**: App 개발자, Composition 개발자

**우선순위 이유**: Feature와 App이 소비할 UseCase 표면과 공유 수명이 이 단계에서 확정되지 않으면 이후 계층이 서로 다른 세션 상태를 사용하는 정합성 결함이 발생한다.

**독립 테스트**: in-memory Keychain/transport를 사용해 graph 생성과 protocol-typed public surface를 검증할 수 있다.

**수용 시나리오**:

1. **전제** environment와 shared session store가 있다, **실행** App composition root를 생성한다, **결과** UC01~UC20 중 외부 capability가 확보된 UseCase가 Domain Protocol 타입으로 노출된다.
2. **전제** refresh/revoke capability가 없다, **실행** production graph를 검증한다, **결과** 임의 endpoint 없이 release blocker가 명시된다.
3. **전제** 동일 app graph에서 여러 보호 Remote를 생성한다, **실행** token과 transport identity를 확인한다, **결과** 동일 session source·공유 transport를 사용한다.
4. **전제** Adapter mapping을 실행한다, **실행** nullable ID·raw status·set progress·bookmark IDs를 변환한다, **결과** 의미 손실이 0건이다.

---

### 시나리오 4 - U01~U08 Feature가 UseCase Protocol만 소비한다 (우선순위: P2)

Feature 개발자가 U01~U08 각 화면에서 initializer로 주입된 Domain UseCase Protocol만 호출하도록 구현해, Data·Infrastructure·Composition에 대한 직접 의존과 production `@Dependency` 조회를 제거한다.

**주요 행위자**: Feature 개발자

**우선순위 이유**: Domain·Data·Composition 계약이 먼저 안정돼야 Feature가 재작업 없이 UseCase를 소비할 수 있다.

**독립 테스트**: FeatureTests의 local Test Double과 TCA TestStore만으로 reducer를 실행해 상태·오류·delegate·동시성 처리를 검증할 수 있다.

**수용 시나리오**:

1. **전제** Feature source가 placeholder다, **실행** U01~U08 reducer/view를 구현한다, **결과** 각 화면이 해당 UC를 호출하고 상태·오류·delegate를 표현한다.
2. **전제** Feature dependency를 검사한다, **실행** import와 initializer를 확인한다, **결과** Data·Infrastructure·Composition import와 production `@Dependency`가 0건이다.
3. **전제** 늦은 response·중복 mutation·Task cancellation이 발생한다, **실행** reducer test를 수행한다, **결과** 현재 state와 서버 정본을 훼손하지 않는다.
4. **전제** 401이 발생한다, **실행** Feature가 delegate를 출력한다, **결과** Root session flow로 수렴한다.

---

### 시나리오 5 - App이 root·navigation·lifecycle을 연결한다 (우선순위: P2)

App 개발자가 composition root, session restore, U01~U08 route를 연결해 사용자가 실제로 도달 가능한 제품 진입점을 완성한다.

**주요 행위자**: App 개발자

**우선순위 이유**: Feature가 완성돼도 App root 연결이 없으면 사용자에게 도달 불가능한 코드로 남는다.

**독립 테스트**: App test에서 fake composition을 주입해 launch/root/route 도달성을 검증할 수 있다.

**수용 시나리오**:

1. **전제** 앱이 시작된다, **실행** composition root와 session restore를 실행한다, **결과** U01 또는 U03으로 결정적으로 분기한다.
2. **전제** U01 인증·약관·curation이 완료된다, **실행** delegate를 처리한다, **결과** U02 또는 U03으로 이동한다.
3. **전제** MainShell을 사용한다, **실행** 탭 전환·route·logout을 수행한다, **결과** 인증 session 동안 탭 state가 유지되고 logout에서 폐기된다.
4. **전제** 앱을 실행한다, **실행** source와 화면을 검사한다, **결과** `Hello, world!`, preview-only root, sample store 참조가 0건이다.

---

### 시나리오 6 - 검증이 merge와 release를 실제로 차단한다 (우선순위: P2)

리뷰어와 릴리스 담당자가 CI required job이 global flag로 조용히 skip되지 않고, integration blocker가 열린 상태에서 production release가 진행되지 않음을 신뢰할 수 있다.

**주요 행위자**: 리뷰어, 릴리스 담당자

**우선순위 이유**: 앞선 시나리오들이 코드로 완성돼도, 검증이 우회 가능하면 merge-ready·release-ready 판정 자체를 신뢰할 수 없다.

**독립 테스트**: CI policy test와 workflow run으로 required job의 skip/failure 처리 결과를 검증할 수 있다.

**수용 시나리오**:

1. **전제** Swift 또는 project config가 변경됐다, **실행** PR CI가 실행된다, **결과** lint/build/unit/App/UI 검증이 global flag 때문에 생략되지 않는다.
2. **전제** required job이 실패 또는 비정상 skip된다, **실행** gate를 평가한다, **결과** merge-ready가 아니다.
3. **전제** deployed OpenAPI, legal, environment, refresh/revoke blocker가 열린 상태다, **실행** release validation을 수행한다, **결과** production release가 차단된다.

---

### 예외·경계 사례

- Domain Protocol이 요구하는 concrete Data Remote가 아직 없을 때 해당 UC는 "구조 완료"와 "production 차단"을 구분해 표시하며, 미구현 상태를 제품 완료로 보고하지 않는다.
- refresh/revoke 서버 capability(`INT-API-001`)가 확보되지 않은 상태에서 401이 반복되면 세션은 종료 방향으로 수렴하고, 임의 refresh path나 fake success를 만들지 않는다.
- optional `nextSetID`/`nextQuestionID`가 서버에서 null로 오면 빈 문자열이나 임의 UUID로 치환하지 않고 nil을 그대로 Feature까지 전달한다.
- registration `requestStatus`가 서버에 정의되지 않은 새 raw 값을 반환하면 임의의 알려진 상태로 매핑하지 않고 raw string을 그대로 보존한다.
- 동일 question에 대한 answer 제출과 bookmark 토글이 동시에 발생하면 같은 대상 mutation을 직렬화해 경쟁 조건을 방지한다.
- CI에서 문서-only 변경이 아닌데 required job 전체가 global validation flag 때문에 skip되면, gate는 skip을 성공으로 취급하지 않고 실패로 판정한다.

---

## 요구사항 *(필수)*

### 기능 요구사항 — Domain·모델

- **FR-014-001**: 시스템은 UC01~UC20 각각에 대해 Domain이 소유한 `Sendable` UseCase Protocol을 제공해야 한다.
- **FR-014-002**: concrete UseCase는 대응 Protocol을 구현하고 Domain Repository Protocol만 의존해야 한다.
- **FR-014-003**: Domain 공개 타입에는 DTO·HTTP·Keychain·Apple SDK·TCA·SwiftUI 타입이 없어야 한다.
- **FR-014-004**: 시스템은 server identifier·배열 순서·nullability를 손실 없이 보존해야 한다.
- **FR-014-005**: 시스템은 `nextSetID?`, `nextQuestionID?`를 빈 문자열로 치환하지 않아야 한다.
- **FR-014-006**: 프로젝트 등록 결과는 `projectID + raw requestStatus + selected quizLevel`을 보존해야 한다.
- **FR-014-007**: 시스템은 registration status를 generation progress/terminal state로 사용하지 않아야 한다.
- **FR-014-008**: 시스템은 member 통계·answer scoring·progress를 클라이언트에서 재계산하지 않아야 한다.
- **FR-014-009**: 시스템은 idToken·accessToken·refreshToken을 사용자 ID로 사용하지 않아야 한다.

### 기능 요구사항 — Data·Infrastructure

- **FR-014-010**: 제품 UC가 사용하는 모든 Data Remote Protocol에는 concrete implementation이 있어야 한다.
- **FR-014-011**: concrete Remote는 필요한 Infrastructure dependency를 Tuist에 명시해야 한다.
- **FR-014-012**: 보호 API request는 매 호출 시점의 access token으로 Authorization header를 구성해야 한다.
- **FR-014-013**: GitHub public request에는 Git-It token을 전달하지 않아야 한다.
- **FR-014-014**: 시스템은 400/401/404/500/transport/decoding/cancellation을 Data 오류에서 구분해야 한다.
- **FR-014-015**: 시스템은 cancellation을 일반 temporary failure로 변환하지 않고 `CancellationError` 의미를 유지해야 한다.
- **FR-014-016**: 시스템은 server message 원문을 Feature/UI에 노출하지 않아야 한다.
- **FR-014-017**: Data는 Domain·Composition·Feature·App·UI를 import하지 않아야 한다.

### 기능 요구사항 — Composition·DI

- **FR-014-018**: App composition root는 process당 정확히 한 번 생성해야 한다.
- **FR-014-019**: Composition public surface는 `any XxxUseCase` 또는 불변 typed bundle만 노출해야 한다.
- **FR-014-020**: Composition은 DTO→Domain과 Data 오류→Domain 오류 변환을 유일한 adapter 경계에서 수행해야 한다.
- **FR-014-021**: session store와 refresh coordinator는 전체 graph에서 공유해야 한다.
- **FR-014-022**: Git-It server Remote들은 동일한 current-token source를 사용해야 한다.
- **FR-014-023**: Composition은 Feature/Store/View를 생성하지 않아야 한다.
- **FR-014-024**: Feature는 Composition object 또는 service locator를 받지 않아야 한다.

### 기능 요구사항 — Feature·App

- **FR-014-025**: 각 Feature는 필요한 UseCase Protocol을 reducer initializer로 명시적으로 받아야 한다.
- **FR-014-026**: Feature production 코드는 `@Dependency`, singleton, global mutable container로 UseCase를 찾지 않아야 한다.
- **FR-014-027**: unauthorized는 delegate로 Root session flow에 전달해야 한다.
- **FR-014-028**: 시스템은 동일 mutation의 병렬 실행을 방지해야 한다.
- **FR-014-029**: read request의 늦은 이전 response는 현재 route state를 덮어쓰지 않아야 한다.
- **FR-014-030**: App은 U01~U08 route payload를 식별자 손실 없이 연결해야 한다.
- **FR-014-031**: MainShell은 selected tab과 탭별 child/navigation state를 소유해야 한다.
- **FR-014-032**: logout/session invalidation에서 보호 child effect와 state를 모두 폐기해야 한다.

### 기능 요구사항 — UI

- **FR-014-033**: UIComponent는 scalar/value, Binding, callback만 공개 입력으로 사용해야 한다.
- **FR-014-034**: UIComponent에는 `ViewModel`, `State`, `Props` wrapper를 추가하지 않아야 한다.
- **FR-014-035**: Feature/Domain/TCA 타입은 UIComponent 공개 API와 구현에 없어야 한다.
- **FR-014-036**: 누락된 Text field, setting row, learning-set row, question/answer component를 의미별 계약으로 구현해야 한다.
- **FR-014-037**: `UIComponentLayoutHarness`를 `UIComponentPreviewApp`으로 교정하고 production App 완료 근거와 분리해야 한다.

### 기능 요구사항 — 세션·법적 문서

- **FR-014-038**: login 성공 시 token pair와 `needsCuration`을 보호 저장해야 한다.
- **FR-014-039**: current legal manifest의 required current version acceptance와 curation 성공이 모두 충족돼야 onboarding을 완료해야 한다.
- **FR-014-040**: placeholder legal content/version/null required flag가 production bundle에 있으면 release를 실패시켜야 한다.
- **FR-014-041**: refresh는 전역 single-flight여야 한다.
- **FR-014-042**: 시스템은 refresh 거부와 temporary failure를 구분해야 한다.
- **FR-014-043**: logout은 local clear를 먼저 완료하고 revoke를 best-effort로 수행해야 한다.
- **FR-014-044**: refresh/revoke endpoint가 없는 상태에서 임의 path·DTO를 추가하지 않아야 한다.

### 기능 요구사항 — 패키지·컨벤션 정합 (CONVENTION-BASELINE.md 반영)

- **FR-014-045**: 모든 패키지 의존 방향은 CONVENTION-BASELINE.md 3.1의 의존 그래프를 따라야 하며, Domain·Infrastructure는 서로 및 App/Feature/UI에 의존하지 않아야 한다.
- **FR-014-046**: Data는 concrete Remote(Contracts/DTOs/Endpoints/Errors/Remotes)까지 소유해야 하며, DTO→Domain 변환은 CompositionAdapter가 소유해야 한다.
- **FR-014-047**: 새 Domain UseCase Protocol/concrete 이름은 `<동사><대상>UseCase`/`UseCase` 접미어 제거 규칙을 따라야 한다.
- **FR-014-048**: 표준 약어(ID, URL, HTTP 등)는 식별자 첫 단어가 아니면 전체 대문자, 첫 단어면 전체 소문자로 표기해야 하며 `projectId`, `repositoryUrl` 같은 신규 공개 API 표기를 추가하지 않아야 한다.
- **FR-014-049**: Tuist target 이름과 `sources/Projects/<패키지>/` 폴더 이름은 분리해야 하며, 폴더는 역할만 표현해야 한다.
- **FR-014-050**: 테스트 함수 이름은 한국어 동작 문장으로 작성하고 Swift Testing을 기본으로 사용해야 하며, XCTest는 UI 자동화 등 필요한 경우로 제한해야 한다.

### 핵심 엔터티

- **ExternalRepository / QuizLevel / ProjectRegistrationReceipt**: GitHub 저장소 canonical 정보, 요청한 학습 난이도, 프로젝트 등록 요청의 raw 접수 결과(생성 상태 머신 아님).
- **LearningProjectPage / LearningProjectSummary / LearningProjectDetail / LearningProjectSetProgress**: 학습 프로젝트 목록·요약·상세와 세트별 진행률. optional next set/question ID를 보존한다.
- **LearningSet / Question / QuestionFormat / QuestionSource**: 학습 세트와 문제, 문제 형식·출처. 정답·해설은 제출 전 비공개다.
- **ChoiceAnswerResult / EssayAnswerResult / Rubric**: 객관식·서술형 답변 제출 결과와 평가 기준. correct 여부는 서버 정본만 사용한다.
- **BookmarkState / BookmarkedQuestion / BookmarkedQuestionCollection**: 문제 북마크의 최종 상태와 목록. desired final bool을 서버에 전송하고 응답을 정본으로 반영한다.
- **AuthenticationMethod / AuthenticationOutcome / SessionRecord / SessionTokens / LocalOnboardingState / SessionRefreshOutcome**: 인증 수단, 로그인 결과, 로컬 세션 정본(token pair, `needsCuration`), refresh 결과.
- **LegalDocument / LegalAcceptanceRecord**: 약관·개인정보 문서와 수락 기록. 승인된 버전만 사용한다.
- **MemberProfile / MemberPosition / CareerLevel / LearningStatistics / WeeklyLearningCount / MemberDeviceInfo / MemberError**: 회원 프로필, 개발 분야·수준, 학습 통계, 기기 등록 정보, 회원 관련 오류.
- **Domain 오류 정본**: `invalidRequest`, `unauthorized`, `sessionExpired`, `projectUnavailable`, `learningSetUnavailable`, `questionUnavailable`, `memberUnavailable`, `externalRepositoryUnavailable`, `externalRateLimited`, `authenticationCancelled`, `invalidAuthenticationCallback`, `temporarilyUnavailable`로 구분한다.

---

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-014-001**: UC01~UC20 각각에 Domain Protocol, concrete 구현, 대응 테스트가 존재한다.
- **SC-014-002**: 외부 capability가 확보된 UC는 Data concrete Remote와 Composition live wiring을 모두 갖춘다.
- **SC-014-003**: Feature/App 소스에서 Data·Infrastructure·Composition concrete 타입 직접 참조가 0건이다.
- **SC-014-004**: 보호 Git-It request 중 Authorization header가 누락된 사례가 0건이다.
- **SC-014-005**: optional ID를 빈 문자열로 변환하는 코드 경로가 0건이다.
- **SC-014-006**: registration status를 generation state machine으로 사용하는 코드 경로가 0건이다.
- **SC-014-007**: idToken/accessToken을 user ID로 사용하는 코드가 0건이다.
- **SC-014-008**: U01~U08 모든 제품 route가 App root에서 실제로 도달 가능하다.
- **SC-014-009**: production App에 Hello World/preview-only/sample store 참조가 0건이다.
- **SC-014-010**: Feature production dependency 획득 경로가 initializer 외에 0건이다.
- **SC-014-011**: UIComponent에 ViewModel/State/Props wrapper가 0건이다.
- **SC-014-012**: package build·unit·App·UI·lint required CI가 모두 성공한다.
- **SC-014-013**: global validation flag로 인해 required job이 skip된 PR은 merge-ready로 판정되지 않는다.
- **SC-014-014**: integration blocker(INT-API-001/002, INT-LEGAL-001/002, INT-ENV-001)가 열린 상태의 production release가 0건이다.
- **SC-014-015**: CONVENTION-BASELINE.md의 패키지 의존 방향·네이밍·테스트 컨벤션과 충돌하는 신규 코드가 0건이다.

---

## 가정

- `private/spec.md`, `private/CONVENTION-BASELINE.md` 원문은 `/speckit-plan` 단계에서 `specs/014-all-usecases-implementation/contracts/usecase-catalog.md`, `research.md`로 복사돼 커밋 대상이 되며, 이후 모든 단계(계획·작업·구현)는 이 커밋 사본을 정본으로 참조한다. `private/` 원본은 출처 표시로만 남긴다.
- CONVENTION-BASELINE.md가 정한 패키지 책임·의존 방향·객체 수명 규칙은 본 명세의 모든 Phase에서 재해석하지 않고 그대로 적용한다.
- 서버 refresh/revoke endpoint(`INT-API-001`)와 배포 OpenAPI(`INT-API-002`)는 이 명세의 구현 기간 중 확보되지 않을 수 있으며, 그 경우 해당 UC(UC12, UC14)는 "구조 완료 / production 차단"으로 표시하고 임의 endpoint를 설계하지 않는다.
- 약관·개인정보 승인 콘텐츠(`INT-LEGAL-001`), 오픈소스 notice(`INT-LEGAL-002`), production/staging base URL(`INT-ENV-001`)이 확보되지 않으면 관련 release 항목은 차단 상태로 유지한다.
- 코드 기준 SHA(`develop@bdb095b...`)가 구현 착수 시점에 달라지면 source audit를 다시 수행하고 이 문서의 기준 SHA를 갱신한다.
- Phase(Domain → Infrastructure → Data → Composition → UI → Feature → App)별 구현 순서와 승인 게이트는 CONVENTION-BASELINE.md 14장과 private/spec.md 18장의 순서를 그대로 따른다.
- CI의 `GIT_IT_CI_VALIDATION_ENABLED` global flag로 인한 required job skip 허용은 이 명세 범위에서 교정 대상이며, 별도 정책 변경 없이 유지되지 않는다.
