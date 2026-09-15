# 구현 계획: Composition에 들어온 정책·저장·기동 책임을 소유 패키지로 되돌리기

**Git-flow 유형**: `feature`

**브랜치**: `feature/composition-responsibility`

**날짜**: 2026-09-16 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/032-composition-responsibility/spec.md`의 기능 명세

## 요약

Composition에 들어와 있는 세 가지 책임을 소유 패키지로 되돌린다. 저장 스키마와 직렬화는 각
Data 모듈로, 세션 유효성 판정·기기 등록·리마인드 정책은 Domain으로, 기동 순서와 알림 문구는
App으로 옮긴다. App Group 좌표와 외부 라이브러리 은닉은 Infrastructure가 맡는다. Composition에는
Domain 계약과 Data·Infrastructure 구현을 잇는 Adapter와 조립만 남는다.

저장 값의 형식과 키는 바꾸지 않는다. 키가 바뀌면 기존 사용자의 로그인이 끊기므로, 이동 대상
저장소마다 고정 문자열로 키를 확인하는 테스트를 소유 패키지에 둔다.

기술 판단의 근거는 [research.md](./research.md), 이동 대상과 불변 좌표는
[data-model.md](./data-model.md), 경계 계약 변경은 [contracts/README.md](./contracts/README.md),
검증 절차는 [quickstart.md](./quickstart.md)에 있다.

## 기술 맥락

**언어/버전**: Swift 5 (`SWIFT_VERSION` 5.0), Swift Concurrency 사용

**주요 의존성**: The Composable Architecture, Firebase Messaging(Infrastructure 뒤로 숨김),
`KeychainStore`·`UserDefaultsStore`(Infrastructure), `UNUserNotificationCenter`(Infrastructure)

**저장소**: 기존 Keychain·UserDefaults 키와 네임스페이스를 그대로 사용한다. 값의 인코딩 형식도
바꾸지 않는다

**테스트**: Swift Testing. 테스트 함수 이름은 한국어 동작 문장
([테스트 컨벤션](../../docs/conventions/test.md))

**대상 플랫폼**: iOS 26.0 이상

**프로젝트 유형**: 모바일 앱 (Tuist 멀티 패키지)

**성능 목표**: 별도 목표 없음. 런타임 동작과 기동 순서를 바꾸지 않는다

**제약 조건**:

- Domain↔Data 경계 구조를 바꾸지 않는다. Adapter는 Composition에 남는다
- Feature는 단일 target을 유지한다
- Keychain·UserDefaults 키와 네임스페이스 문자열을 바꾸지 않는다
- 새 target을 만들지 않는다
- 기동 시 수행되는 작업과 그 순서가 변경 전후 같아야 한다
- 사용자에게 표시되는 문자열이 Composition·Domain에 남지 않아야 한다

**규모/범위**: 7개 패키지 중 5개(Composition, Domain, Data, Infrastructure, App). 이동 대상
파일 11개, 영향 조립 파일 4개

## 명세와의 해석 차이

**SC-002**를 이 계획은 **"Composition이 Infrastructure 저장 API로 직접 읽고 쓰는 지점 0개,
저장 스키마를 정의하는 지점 0개"**로 읽는다. 명세 문장은 "생성하거나 읽고 쓰는 지점이 0개"지만,
[아키텍처 3.5](../../docs/architecture.md)가 Composition을 "Data가 Infrastructure 기술 API 위에서
소유하는 concrete 구현을 실행 환경에 맞게 선택해 객체 생성 순서와 수명을 결정"하는 경계로
정의한다. 조립 시점의 인스턴스 생성까지 금지하면 조립 경계가 할 일이 없어지고, 테스트가 격리된
저장소를 주입할 지점도 사라진다. 근거와 검토한 대안은 [research.md](./research.md) 1절에 있다.

명세 본문은 이 계획이 수정하지 않는다. 이 해석이 받아들여지지 않으면 `/speckit-clarify`로
SC-002를 고친 뒤 계획을 다시 맞춘다.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1. 명시적인 경계 | 통과 | 모든 이동이 아키텍처 3.1의 허용 방향 안에서 일어난다. App→Domain, Data→Infrastructure만 쓰고 새 방향을 만들지 않는다 |
| 2. 상태와 데이터 안전성 | 통과 | 저장 좌표와 인코딩을 고정하고 키 보존 테스트로 증명한다. 소유 패키지만 바뀐다 |
| 3. 검증 가능한 변경 | 통과 | [quickstart.md](./quickstart.md)가 기준선·시나리오별 검증과 기존 설치 상태 수동 회귀를 정의한다 |
| 4. 스킬별 수정 경로 | 통과 | 이 단계는 계획 산출물만 작성한다. 구현 파일 경로는 `tasks.md`가 소유한다 |
| 5. Spec-Kit 범위 | 통과 | `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 작성했다 |
| 6. 한국어 산출물 | 통과 | 모든 산출물을 한국어로 작성했다. 식별자와 키 문자열은 원문 유지 |
| 7. 위험 기반 실행 단위 | 통과 | 아래 실행 단위에 위상 순서와 불가분 근거를 기록했다 |
| 8. Git-flow 네임스페이스 | 통과 | `feature/composition-responsibility`를 생성해 사용 중이다 |
| 9. 세션 지식 기록 | 해당 없음 | 반복되는 사건이나 여러 세션에서 종합한 해석이 아직 없다 |
| 10. 책임 기반 네이밍 | 통과 | 새 이름은 책임을 드러내도록 짓는다. `DeviceIdentifierRepository`처럼 무엇을 소유하는지 이름에 담는다 |

**1단계 설계 후 재점검**: 통과. 새 패키지나 새 의존 방향이 없고, 복잡성 추적 대상 위반이 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/032-composition-responsibility/
├── plan.md              # 이 파일
├── research.md          # 0단계 산출물
├── data-model.md        # 1단계 산출물
├── quickstart.md        # 1단계 산출물
├── contracts/README.md  # 1단계 산출물
├── checklists/
│   └── requirements.md  # 명세 품질 체크리스트
└── tasks.md             # 2단계 산출물(/speckit-tasks)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/
├── Infrastructure/
│   ├── Storage/                  # App Group 공유 UserDefaults 생성
│   ├── Authentication/           # 공유·레거시 KeychainStore 생성
│   └── PushMessaging/            # 푸시 클라이언트 생성 진입점, AppDelegate 은닉
├── Domain/
│   ├── Authentication/           # SessionAvailability, 세션 유효성 판정
│   ├── Member/                   # deviceID 계약, 기기 등록 UseCase
│   └── LearningProject/          # 리마인드 정책, 예약 계약
├── Data/
│   ├── Authentication/           # 세션 Coding·Layout·Migration, 상태 마커
│   ├── Member/                   # deviceID 저장 구현
│   └── LearningProject/          # 대기 리마인드 저장
├── Composition/
│   ├── Adapter/Adapters/         # 새 Domain 계약의 Adapter 추가
│   ├── Adapter/Assemblies/       # 조립 인자 교체
│   ├── App/Assemblies/           # bootstrap 해체, 조각 공개
│   └── (제거) Codings/ Layouts/ Migrations/ Resolvers/ Models/
└── App/
    ├── GitIt/                    # 기동 절차 소유 타입, 알림 문구
    └── ShareExtension/           # SessionAvailability 참조 경로 변경
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 유지한다. 새 target도 새 패키지 의존성도 추가하지
않는다. Composition에서 폴더 5개가 사라지고 Data·Domain·Infrastructure에 파일이 늘어난다.

## 실행 단위

[아키텍처 3.1](../../docs/architecture.md)의 의존성 표에 따른 위상 순서다. `Infrastructure`가
가장 아래, `Data`는 그 뒤, `Domain`은 독립, `Composition`은 셋 뒤, `App`이 마지막이다.

| 단위 | 패키지 | 목적 | 분리 가능성 |
| --- | --- | --- | --- |
| **I1** | Infrastructure + Composition | 외부 라이브러리 직접 사용 제거 | **불가분**. 아래 근거 참조 |
| **I2** | Infrastructure + Data + Composition | 저장 스키마·직렬화 이동 | **불가분**. 아래 근거 참조 |
| **I3** | Domain + Composition + App | 세션 유효성 판정 이동 | **불가분**. 아래 근거 참조 |
| **I4** | Domain + Data + Composition + App | 기기 등록 UseCase 승격 | **불가분**. 아래 근거 참조 |
| **I5** | Domain + Composition + App | 리마인드 정책과 문구 이동 | **불가분**. 아래 근거 참조 |
| **I6** | Composition + App | 기동 순서 이동 | **불가분**. 아래 근거 참조 |
| U1 | 문서 | 이동 결과와 남은 책임 기록 | 단일 문서. 모든 코드 단위 완료 후 |

### I1을 다중 패키지 단위로 두는 근거

`AppComposition`이 `FirebaseMessagingPushClient()`를 직접 부르고 `PushNotificationAppDelegate`가
`FirebaseMessagingAppDelegate` 별칭이다. Infrastructure가 대체 진입점을 공개하기 전에 호출을
지우면 조립이 컴파일되지 않고, 진입점만 만들고 호출을 남기면 외부 타입 이름이 그대로 남는다.

**먼저 두는 이유**: 범위가 가장 작고 다른 단위가 만드는 파일에 의존하지 않는다. 근거 문서의
작업 순서 제안과 같다.

### I2를 다중 패키지 단위로 두는 근거

`SharedSessionLayout`은 App Group 좌표와 도메인 키를 한 타입에 담고 있다. 좌표를
Infrastructure로, 키를 각 Data 모듈로 나누는 순간 이 타입을 쓰는 조립 6곳
(`AuthenticationAssembly`, `LearningProjectAssembly`, `AppComposition`,
`ShareExtensionComposition`, `LoginSessionRepositoryAdapter`, `SessionAvailabilityResolver`)이
같은 순간 컴파일 실패한다. `SessionRecordKeychainCoding`도 세 곳이 함께 참조한다.

이 단위가 이 명세에서 가장 크고 위험도 가장 높다. 키 보존 테스트를 이 단위에 집중한다.

**I3보다 먼저 두는 이유**: `SessionAvailabilityResolver`가 `SessionRecordKeychainCoding`과
`SharedSessionStateMarkerCoding`을 쓴다. 저장 타입이 Data로 간 뒤에 판정을 Domain으로 올려야
중간에 Composition을 거쳐 참조하는 상태를 만들지 않는다.

### I3을 다중 패키지 단위로 두는 근거

`SessionAvailability`를 `DomainAuthentication`으로 옮기면 그 타입을 쓰는
`ShareExtensionComposition`(Composition)과 `ShareViewController`(App)가 같은 순간 컴파일
실패한다. 타입 이동과 참조 갱신을 나눌 수 없다.

### I4를 다중 패키지 단위로 두는 근거

deviceID 계약을 Domain에 만들고 구현을 `DataMember`에 두면, 그 둘을 잇는 Adapter와 조립이
Composition에 동시에 필요하다. 앱·OS 버전 주입 때문에 `AppComposition.init` 서명이 바뀌고
App의 호출부가 함께 바뀐다.

### I5를 다중 패키지 단위로 두는 근거

`GenerationCompletionReminderCoordinator`를 Domain 정책과 Composition Adapter로 쪼개는 동시에
표시 문구가 App에서 조립 인자로 들어와야 한다. 셋 중 하나만 먼저 바꾸면 문구가 갈 곳이 없거나
정책이 알림 계약을 부를 수 없다.

### I6을 다중 패키지 단위로 두는 근거

`bootstrap` 클로저를 없애고 조각을 개별 프로퍼티로 공개하는 변경과, App이 그 조각을 순서대로
부르는 변경은 같은 순간에 일어나야 한다. 한쪽만 바꾸면 기동이 아무것도 하지 않거나 컴파일되지
않는다.

**마지막에 두는 이유**: I1~I5가 조각을 정리한 뒤라야 무엇을 공개할지 확정된다.

### 통합 검증

- I1: `Infrastructure`와 `Composition` 테스트 scheme
- I2: `Infrastructure`·`Data`·`Composition` 테스트 scheme. 키 보존 테스트를 함께 확인
- I3~I5: `Domain`·`Data`·`Composition` 테스트 scheme과 `AppTests`
- I6: `Composition`과 `AppTests`, 그리고 전체 `build` → `compile` → `test`

`AppTests`와 `Feature`는 이 브랜치 시작 시점에 이미 실패한다(`AppEntryFeature` 스플래시 게이트
계열, 각각 별도 명세로 분리됨). 실패 목록이 늘지 않았는지로 판정한다.

### 패키지에 속하지 않는 파일

| 파일 | 배정 단위 | 근거 |
| --- | --- | --- |
| `sources/Tuist/ProjectDescriptionHelpers/Projects/*.swift` | 필요한 단위에 개별 배정 | 이동으로 target 의존이 바뀌면 그 단위가 함께 고친다. 새 target은 만들지 않는다 |
| `docs/package-rules/composition.md` | U1 | 이동 후 Composition에 남는 것이 무엇인지 규칙 문서에 반영한다 |
| `docs/review/composition-responsibility-requirements.md` | 변경 없음 | 근거 문서이며 이 명세가 수정하지 않는다 |

## 검증 계획

- 각 단위 완료 시 해당 패키지 테스트 scheme을 함께 실행한다.
- I2 완료 후 키 보존 테스트와 전체 `build` → `compile` → `test`를 실행한다. 저장 좌표가 바뀌면
  기존 사용자의 로그인이 끊기므로 여기서 한 번 전체를 확인한다.
- I6 완료 후 전체 `build` → `compile` → `test`를 다시 실행하고 결과를 기록한다.
- 이동한 정책마다 이동 전 테스트가 보장하던 항목의 이관처를 1:1로 기록한다.
- Composition 프로덕션 줄수와 위반 지표 4종을 적용 전후로 세어 비교한다.
- 기존 설치 상태를 지우지 않은 수동 회귀 3종은 [quickstart.md](./quickstart.md)의 절차를 따른다.

## 복잡성 추적

> 헌법 점검에서 정당화해야 하는 위반이 없다. 이 섹션은 비어 있다.
