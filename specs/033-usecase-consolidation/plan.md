# 구현 계획: Domain UseCase 분해 기준 확정과 통합

**Git-flow 유형**: `feature`

**브랜치**: `feature/usecase-consolidation`

**날짜**: 2026-09-16 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/033-usecase-consolidation/spec.md`의 기능 명세

## 요약

Domain UseCase를 독립 타입으로 둘 기준을 하나로 정해 `docs/package-rules/domain.md`에
기록하고, 기준을 충족하지 못하는 분해를 모듈별 능력 단위 계약으로 통합한다. 같은 저장소를
변경하는 연산은 하나의 계약으로 묶고 순서 보장을 그 계약 구현 안으로 옮겨 직렬화 전용 타입
두 개를 없앤다. 그 결과 조립과 Router가 다루는 Domain 의존성 개수가 줄어든다.

판정 결과는 독립 유지 18개, 통합 8개 → 2개, 제거 2개다. 근거는
[research.md](./research.md)와 [data-model.md](./data-model.md)에 있다.

## 기술 맥락

**언어/버전**: Swift 6, iOS 26.0 이상

**주요 의존성**: 없음. `DomainAuthentication`, `DomainLearningProject`, `DomainMember`는
프로젝트 내부 패키지에 의존하지 않는다.

**저장소**: 해당 없음. 이 명세는 저장소 계약을 바꾸지 않는다.

**테스트**: Swift Testing. Domain 테스트가 판정과 순서 보장을 소유한다.

**대상 플랫폼**: iOS Simulator (iPhone 17 Pro)

**프로젝트 유형**: Tuist 멀티 패키지 iOS 앱

**성능 목표**: 해당 없음. 사용자 관찰 동작과 네트워크 호출 순서가 바뀌지 않는다.

**제약 조건**: Domain↔Data 경계 구조 현행 유지, 저장소 계약과 Adapter 불변, Feature 단일
target 유지, 사용자 관찰 동작 불변.

**규모/범위**: Domain UseCase 프로토콜 28개와 프로덕션 파일 60개, Composition 조립 4곳,
Router Feature 5개, App 조립·프리뷰 3곳.

## 명세와의 해석 차이

명세의 "수치 목표 조정" 절은 근거 문서의 목표(`MainShellRouterFeature` 5개 이하,
`AppComposition` 12개 이하, UseCase 파일 절반 이하)를 실측 도달 가능값으로 바꿔 적었다.
이 계획은 그 결정을 따르며, 조정된 목표보다 더 줄어드는 값을 산출한다.

| 항목 | 현재 | 명세 목표 | 이 계획 예상 |
| --- | --- | --- | --- |
| UseCase 프로토콜 | 28 | 22 이하 | 20 |
| 프로덕션 UseCase 파일 | 60 | 46 이하 | 42 |
| `MainShellRouterFeature` Domain 의존성 | 14 | 11 이하 | 10 |
| `AppComposition` Domain 의존성 | 25 | 19 이하 | 17 |

## 헌법 점검

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1. 명세 우선 | 통과 | [spec.md](./spec.md)가 먼저 있고 이 계획이 그것을 따른다 |
| 2. 아키텍처 경계 | 통과 | Domain은 계속 프로젝트 내부 패키지에 의존하지 않는다. 의존 방향이 바뀌는 곳이 없다 |
| 3. 예외 기록 | 통과 | 근거 문서 수치와의 차이를 명세와 이 계획에 남겼다 |
| 4. 검증 가능성 | 통과 | SC-001~SC-011이 명령 또는 테스트로 확인된다 |
| 5. 스킬 허용 경로 | 통과 | 이 명령은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 수정한다 |
| 6. 커밋 단위 구현 | 통과 | 아래 실행 단위가 커밋 단위 설계의 근거를 제공한다 |
| 7. 위험 기반 실행 단위 | 통과 | 위상 순서와 불가분 근거를 아래에 기록했다 |
| 8. Git-flow 네임스페이스 | 통과 | `feature/usecase-consolidation`을 생성해 사용 중이다 |
| 9. 세션 지식 기록 | 해당 없음 | 반복 사건이나 여러 세션에서 종합한 해석이 아직 없다 |
| 10. 책임 기반 네이밍 | 통과 | `LearningLibrary`와 `MemberAccount`는 능력을 가리키며 일괄 접두어·접미어를 적용하지 않는다. 기존 `UseCase` 접미어는 이 패키지의 확립된 계약 형태다 |

**1단계 설계 후 재점검**: 통과. 새 패키지나 새 의존 방향이 없고 복잡성 추적 대상 위반이 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/033-usecase-consolidation/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/README.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks 산출물
```

### 소스 코드(저장소 루트)

```text
docs/package-rules/domain.md                                   # 분해 기준 기록

sources/Projects/Domain/
├── Authentication/UseCases/VerifyAccessToken/                 # 제거
├── LearningProject/UseCases/
│   ├── LearningLibrary/                                       # 신설
│   ├── FetchLearningProjectDetail/                            # 제거
│   ├── DeleteLearningProject/                                 # 제거
│   ├── FetchLearningSet/                                      # 제거
│   ├── FetchBookmarkedQuestions/                              # 제거
│   └── SetQuestionBookmark/                                   # actor화, Serializer 제거
├── Member/UseCases/
│   ├── MemberAccount/                                         # 신설
│   ├── FetchMemberProfile/                                    # 제거
│   ├── UpdateMemberPosition/                                  # 제거
│   ├── UpdateMemberCareerLevel/                               # 제거
│   ├── CompleteCuration/                                      # 제거
│   ├── RegisterMemberDevice/                                  # 제거
│   ├── RegisterCurrentDevice/                                 # 저장소 직접 주입
│   └── MemberMutationSerializer.swift                         # 제거
└── Tests/                                                     # 대응 테스트 이관

sources/Projects/Composition/
├── Adapter/Assemblies/{AuthenticationAssembly,LearningProjectAssembly,MemberAssembly}.swift
└── App/Assemblies/AppComposition.swift

sources/Projects/Feature/
├── MainShell/Router/MainShellRouterFeature.swift
├── ProjectDetail/Router/ProjectDetailRouterFeature.swift
├── Quiz/Router/QuizRouterFeature.swift
├── Settings/Router/SettingsRouterFeature.swift
└── Onboarding/Router/OnboardingRouterFeature.swift

sources/Projects/App/GitIt/
├── Reducers/AppRootFeature.swift
└── Screens/AppRootView.swift
```

## 실행 단위

[아키텍처 3.1](../../docs/architecture.md)의 의존성 표에 따른 위상 순서다. `Domain`이 가장
아래, `Composition`이 그 뒤, `Feature`와 `App`이 마지막이다.

| 단위 | 패키지 | 목적 | 분리 가능성 |
| --- | --- | --- | --- |
| U1 | 문서 | 분해 기준 확정과 기록 | 단일 문서. 모든 코드 단위보다 먼저 |
| **I1** | Domain + Composition | 소비자 없는 UseCase 2개 제거 | **불가분**. 아래 근거 참조 |
| **I2** | Domain + Composition + Feature + App | 회원 능력 계약 통합과 직렬화 내재화 | **불가분**. 아래 근거 참조 |
| I3 | Domain | 북마크 변경 직렬화 내재화 | 단일 패키지 |
| **I4** | Domain + Composition + Feature + App | 학습 자료 능력 계약 통합 | **불가분**. 아래 근거 참조 |
| U2 | 문서 | 통합 결과와 남은 UseCase 목록 기록 | 단일 문서. 모든 코드 단위 완료 후 |

### U1을 먼저 두는 이유

FR-001의 기준이 I1~I4의 모든 판정 근거다. 기준을 문서에 먼저 고정해야 구현 중 판정이
흔들리지 않고, 구현 순서를 바꿔도 결론이 같다는 것을 확인할 수 있다.

### I1을 다중 패키지 단위로 두는 근거

`VerifyAccessTokenUseCase`를 제거하면 그것을 만들고 공개하는 `AuthenticationAssembly`와
`AppComposition`이 같은 순간 컴파일 실패한다. `RegisterMemberDeviceUseCase`도 마찬가지로
`MemberAssembly`와 `AppComposition`, 그리고 같은 Domain 모듈의 `RegisterCurrentDevice`가
함께 바뀌어야 한다.

**먼저 두는 이유**: 범위가 가장 작고 Feature와 App을 건드리지 않는다. I2와 I4가 만드는
파일에 의존하지 않는다.

### I2를 다중 패키지 단위로 두는 근거

`FetchMemberProfileUseCase`, `UpdateMemberPositionUseCase`,
`UpdateMemberCareerLevelUseCase`, `CompleteCurationUseCase` 넷을 `MemberAccountUseCase`
하나로 바꾸면, 그 넷을 받는 `MemberAssembly`, `AppComposition`, `MainShellRouterFeature`,
`SettingsRouterFeature`, `OnboardingRouterFeature`, `AppRootFeature`, `AppRootView`가 같은
순간 컴파일 실패한다. 프로토콜 이전과 참조 갱신을 나눌 수 없다.

`MemberMutationSerializer` 제거도 같은 단위에 둔다. 통합 계약 구현이 직렬화를 내부에
가져가는 순간 그 타입의 유일한 소비자가 사라지기 때문이다.

**I4보다 먼저 두는 이유**: 직렬화 내재화 방식을 먼저 확정하고 검증해야 I3이 같은 방식을
북마크에 적용할 수 있다.

### I3을 단일 패키지 단위로 두는 근거

`SetQuestionBookmark`를 actor로 바꾸고 `QuestionMutationSerializer`를 제거하는 변경은
`SetQuestionBookmarkUseCase` 프로토콜 서명을 바꾸지 않는다. 생성자 인자에서 기본값이 있던
`serializer`가 사라질 뿐이고, 호출부는 그 인자를 넘기지 않으므로 Domain 밖이 바뀌지 않는다.

### I4를 다중 패키지 단위로 두는 근거

`FetchLearningProjectDetailUseCase`, `DeleteLearningProjectUseCase`,
`FetchLearningSetUseCase`, `FetchBookmarkedQuestionsUseCase` 넷을 `LearningLibraryUseCase`
하나로 바꾸면, `LearningProjectAssembly`, `AppComposition`, `MainShellRouterFeature`,
`ProjectDetailRouterFeature`, `QuizRouterFeature`, `AppRootFeature`, `AppRootView`가 같은
순간 컴파일 실패한다.

**마지막에 두는 이유**: 영향 범위가 가장 넓다. I1~I3으로 방식이 검증된 뒤에 적용한다.

### U2를 마지막에 두는 이유

남은 UseCase 목록과 각 항목의 존치 근거는 I1~I4가 끝나야 확정된다.

## 통합 검증

| 단위 | 검증 |
| --- | --- |
| U1 | 문서 링크와 기준 문장의 검증 가능성 |
| I1 | `Domain`·`Composition` scheme 테스트, 제거 대상 grep 0건 |
| I2 | `Domain`·`Composition` scheme 테스트, `AppTests`, `App` scheme 빌드, 회원 변경 순서 보장 테스트 |
| I3 | `Domain` scheme 테스트, 북마크 변경 순서 보장 테스트, `MutationSerializer` grep 0건 |
| I4 | `Domain`·`Composition`·`Feature` scheme 테스트, `AppTests`, `App` scheme 빌드 |
| U2 | 문서에서 시작해 링크만 따라가 각 UseCase의 존치 근거에 도달 |

`Feature` scheme 전체 테스트는 이 명세와 무관한 기존 실패로 약 60분이 걸린다. I4와 전체
완료 검증에서만 실행하고, 그 밖의 단위에서는 영향 scheme만 실행한다.

## 검증 계획

1. 각 단위마다 [quickstart.md](./quickstart.md)의 해당 시나리오 grep과 영향 scheme 테스트를
   실행한다.
2. 모든 코드 단위 완료 후 `build` → `compile` → `test` 전체를 실행하고 scheme별 성공·실패
   목록이 이 명세 시작 전과 같은지 확인한다.
3. 기준선을 다시 재고 [research.md](./research.md) 9절의 예상값과 대조한다.
4. [quickstart.md](./quickstart.md)의 수동 회귀 5종을 확인한다. 실행 주체를 먼저 정한다.
