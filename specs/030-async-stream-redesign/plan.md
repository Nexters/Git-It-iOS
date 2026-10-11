# 구현 계획: 생성 상태 관측 단일화와 무효 스트림 제거

**Git-flow 유형**: `feature`

**브랜치**: `feature/async-stream-redesign`

**날짜**: 2026-09-15 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/030-async-stream-redesign/spec.md`의 기능 명세

## 요약

프로덕션에서 값을 전달하지 않는 Apple 자격 증명 관측 경로를 제거하고 앱 활성 전환 시점의 1회 확인으로 대체한다. 값 없는 연속 전달로 표현된 기기 토큰 갱신 신호를 통지 수단으로 바꾼다. 진행 정보와 등록 상태로 나뉘어 있던 생성 상태를 하나의 기록 집합으로 통합하고, 최신 상태를 보유하는 Domain 관측 대상이 관측 시작 시 현재 상태를 먼저 전달하도록 한다. 이로써 구독 순서에 의존하던 호출 규약과 보상 저장소 두 개가 사라진다.

기술 접근의 근거는 [research.md](./research.md), 값 구조는 [data-model.md](./data-model.md), 경계 계약 변경은 [contracts/README.md](./contracts/README.md)에 있다.

## 기술 맥락

**언어/버전**: Swift 5 (`SWIFT_VERSION` 5.0), Swift Concurrency 사용

**주요 의존성**: The Composable Architecture, Firebase Messaging(Infrastructure 내부), AuthenticationServices, UserNotifications

**저장소**: 앱과 공유 확장이 함께 읽는 `UserDefaults` 공유 저장소, Keychain(이 명세에서 변경하지 않음)

**테스트**: Swift Testing. 테스트 함수 이름은 한국어 동작 문장 ([테스트 컨벤션](../../docs/conventions/test.md))

**대상 플랫폼**: iOS 26.0 이상

**프로젝트 유형**: 모바일 앱 (Tuist 멀티 패키지)

**성능 목표**: 별도 목표 없음. 앱 활성 전환 시 추가 네트워크 호출을 발생시키지 않는다

**제약 조건**:

- Domain↔Data 경계 구조(Domain 계약 ← Composition Adapter → Data API)를 변경하지 않는다
- Feature는 단일 target을 유지한다
- 푸시 페이로드 스키마를 변경하지 않는다
- Keychain과 세션 관련 저장 키를 변경하지 않는다
- 생성 상태 저장 키는 변경하되 기존 값을 1회 이관한다

**규모/범위**: 7개 패키지 중 6개(UI 제외) 변경. 영향 파일 약 40개

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1. 명시적인 경계 | 통과 | 새 계약은 모두 Domain이 소유하고 구현은 Data·Composition에 둔다. 의존성 표를 벗어나는 참조를 만들지 않는다 |
| 2. 상태와 데이터 안전성 | 통과 | 생성 상태의 소유자를 Domain actor 하나로 명시한다. 관측 취소 경로를 계약에 포함한다 (FR-010) |
| 3. 검증 가능한 변경 | 통과 | [quickstart.md](./quickstart.md)가 검증 절차를 정의한다. 보장 항목 대조표를 요구한다 |
| 4. 스킬별 수정 경로 | 통과 | 이 단계는 계획 산출물만 작성한다. 구현 파일 경로는 `tasks.md`가 소유한다 |
| 5. Spec-Kit 범위 | 통과 | `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 작성했다 |
| 6. 한국어 산출물 | 통과 | 모든 산출물을 한국어로 작성했다. 식별자와 명령어는 원문 유지 |
| 7. 위험 기반 실행 단위 | 통과 | 아래 실행 단위에 위상 순서와 불가분 근거를 기록했다 |
| 8. Git-flow 네임스페이스 | 통과 | `feature/async-stream-redesign`을 생성해 사용 중이다 |
| 9. 세션 지식 기록 | 해당 없음 | 반복되는 사건이나 여러 세션에서 종합한 해석이 아직 없다 |
| 10. 책임 기반 네이밍 | 통과 | 새 이름은 소유 책임을 드러내며 일괄 접두어를 적용하지 않는다. 세부 기준은 [네이밍 컨벤션](../../docs/conventions/naming.md) |

**1단계 설계 후 재점검**: 통과. 설계가 새 패키지나 새 의존 방향을 만들지 않으며 복잡성 추적 대상 위반이 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/030-async-stream-redesign/
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
│   ├── Authentication/AppleAuthentication/Providers/   # 자격 증명 변경 전달 제거
│   └── PushMessaging/Remote/Clients/                   # 토큰 갱신 통지 수단
├── Domain/
│   ├── Authentication/Contracts/                       # 자격 증명 변경 관측 계약 제거
│   ├── Authentication/UseCases/                        # 인증 결과 관측 제거, 자격 증명 확인 추가
│   └── LearningProject/
│       ├── Models/LearningProject/                     # 생성 기록·생성 상태
│       ├── Contracts/                                  # 생성 상태 보존 계약, 구 계약 2종 제거
│       └── UseCases/                                   # 생성 추적, 등록·목록 UseCase 연결 변경
├── Data/
│   └── LearningProject/                                # 생성 상태 저장 구현과 1회 이관
├── Composition/
│   ├── Adapter/Adapters/                               # 생성 상태 보존 어댑터로 통합
│   ├── Adapter/Assemblies/                             # 조립 경로 변경
│   ├── Adapter/Factories/                              # 리마인드 신호원 교체
│   └── App/Assemblies/                                 # 노출 의존성 변경
├── Feature/
│   ├── Home/ · ProjectRegistration/ · MainShell/       # 관측 대상 교체
└── App/
    └── GitIt/Reducers/ · Screens/                      # 주입과 Effect 변경
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 유지한다. 새 target을 만들지 않고 새 패키지 의존성도 추가하지 않는다. 변경은 위에 나열한 기존 디렉터리 안에서 끝난다.

## 실행 단위

[아키텍처 3.1](../../docs/architecture.md)의 의존성 표에 따른 위상 순서다. `Infrastructure`와 `Domain`은 서로 의존하지 않아 순서가 자유롭고, `Data`는 `Infrastructure` 뒤, `Composition`은 `Domain`·`Data`·`Infrastructure` 뒤, `Feature`는 `Domain` 뒤, `App`은 모두의 뒤에 온다.

| 단위 | 패키지 | 목적 | 분리 가능성 |
| --- | --- | --- | --- |
| U1 | Infrastructure | 자격 증명 변경 전달 제거, 토큰 갱신 통지 수단 도입 | 단일 패키지 |
| U2 | Domain | 생성 기록·생성 상태 모델과 생성 상태 보존 계약 추가 | 단일 패키지. 추가만 하므로 기존 코드가 깨지지 않는다 |
| U3 | Data | 생성 상태 저장 구현과 기존 두 키의 1회 이관 | 단일 패키지 |
| U4 | Domain | 생성 추적 도입, 등록·목록 UseCase 연결 변경, 구 계약 2종 제거 | 단일 패키지 |
| U5 | Domain | 자격 증명 확인 UseCase 추가, 인증 결과 관측과 자격 증명 변경 관측 계약 제거 | 단일 패키지 |
| **I1** | Composition + Feature + App | U4·U5가 제거한 계약의 사용처를 동시에 교체 | **불가분**. 아래 근거 참조 |

### I1을 다중 패키지 단위로 두는 근거

U4와 U5가 Domain의 공개 계약을 제거하면 그 계약을 참조하는 Composition 조립, Feature 초기화 인자, App 주입이 동시에 컴파일 실패한다. 세 패키지는 각각 다음을 보유한다.

- Composition — 어댑터 통합, 조립 경로, 노출 의존성 목록
- Feature — Router와 화면 Reducer의 초기화 인자
- App — 주입 지점, Effect, 프리뷰 대체 구현

Feature의 초기화 인자는 App이 채우고 그 값은 Composition이 만든다. 어느 한 패키지만 바꾸면 나머지 둘이 빌드되지 않으므로 중간 상태를 만들 수 없다.

**통합 검증**: I1 완료 시점에 `build`, `compile`, `test`를 모두 실행한다. 단위 검증만으로는 세 패키지의 연결을 확인할 수 없다.

**대안 검토**: Domain 계약을 한동안 유지한 채 새 계약을 병행 도입하고 사용처를 하나씩 옮긴 뒤 구 계약을 제거하는 3단계 분할이 가능하다. 그러나 중간 단계에서 생성 상태의 정본이 둘이 되어 명세 FR-002를 위반하는 상태가 저장소에 남는다. 리뷰 단위를 줄이는 이득보다 정합성이 깨진 중간 커밋의 위험이 크다고 판단해 불가분 단위로 둔다.

### 패키지에 속하지 않는 파일

| 파일 | 배정 단위 | 근거 |
| --- | --- | --- |
| `sources/Tuist/ProjectDescriptionHelpers/Projects/*ModuleName.swift` | 변경 없음 | 새 target·새 패키지 의존성이 없다. manifest 변경이 발생하면 해당 패키지 단위에 포함한다 |
| `docs/review/async-stream-redesign-requirements.md` | 변경 없음 | 근거 문서이며 이 명세가 수정하지 않는다 |

## 검증 계획

- U1~U5는 해당 패키지의 테스트 target으로 집중 검증한다.
- I1 완료 후 전체 `build` → `compile` → `test`를 순차 실행한다.
- 보장 항목 대조표를 남긴다. 제거한 테스트가 보장하던 항목이 어느 새 테스트로 옮겨졌는지 1:1로 기록하고, 옮길 곳이 없는 항목은 제거 근거를 적는다.
- 수동 회귀 3종(프로젝트 등록, 홈 목록 갱신, 리마인드 알림)은 [quickstart.md](./quickstart.md)의 절차를 따른다.

## 복잡성 추적

> 헌법 점검에서 정당화해야 하는 위반이 없다. 이 섹션은 비어 있다.
