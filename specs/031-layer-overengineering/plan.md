# 구현 계획: 값을 더하지 않는 계층과 간접 참조 제거

**Git-flow 유형**: `feature`

**브랜치**: `feature/layer-overengineering`

**날짜**: 2026-09-16 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/031-layer-overengineering/spec.md`의 기능 명세

## 요약

프로토콜을 두는 근거를 두 가지로 한정해 공통 컨벤션에 기록하고, 그 기준에 어긋나는 Data 계약 9개를 제거한다. 제거한 자리는 Composition 어댑터가 Data 구체 타입을 직접 받아 대신한다. 계약 테스트가 보장하던 항목은 구현 테스트로 옮기고 계약 하나마다 대조표를 남긴다. 이어서 Data 오류와 Domain 오류가 항등으로 대응하는 구간을 정리해 어댑터의 재매핑 분기를 줄이고, 마지막으로 파일 수·프로토콜 수와 남은 프로토콜별 존치 근거를 기준선으로 기록한다.

기술 판단의 근거는 [research.md](./research.md), 대상 목록과 전이 형태는 [data-model.md](./data-model.md), 경계 계약 변경은 [contracts/README.md](./contracts/README.md), 검증 절차는 [quickstart.md](./quickstart.md)에 있다.

## 기술 맥락

**언어/버전**: Swift 5 (`SWIFT_VERSION` 5.0), Swift Concurrency 사용

**주요 의존성**: The Composable Architecture, URLSession 기반 `HTTPClient`(Infrastructure), `UserDefaultsStore`(Infrastructure)

**저장소**: 변경하지 않는다. 기존 Keychain·UserDefaults 키를 그대로 사용한다

**테스트**: Swift Testing. 테스트 함수 이름은 한국어 동작 문장 ([테스트 컨벤션](../../docs/conventions/test.md))

**대상 플랫폼**: iOS 26.0 이상

**프로젝트 유형**: 모바일 앱 (Tuist 멀티 패키지)

**성능 목표**: 별도 목표 없음. 런타임 동작을 바꾸지 않는다

**제약 조건**:

- Domain↔Data 경계 구조(Domain 계약 ← Composition Adapter → Data API)를 변경하지 않는다
- Feature는 단일 target을 유지한다
- 서버 API 응답 스키마와 HTTP 상태·오류 코드 매핑을 바꾸지 않는다
- `GenerationStateStore`와 `QuizGenerationOutcomeSource`는 대상에서 제외한다
- Data 테스트의 총 검증 항목 수가 줄어서는 안 된다
- Domain 공개 API가 Data 오류 타입을 노출해서는 안 된다

**규모/범위**: 7개 패키지 중 2개(Data, Composition)와 공통 문서. 제거 대상 계약 9개, 영향 어댑터 8개, 계약 테스트 파일 9개

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1. 명시적인 경계 | 통과 | 경계를 넘지 않는 계약만 제거한다. Composition → Data 의존 방향은 그대로이며 새 참조 방향을 만들지 않는다 |
| 2. 상태와 데이터 안전성 | 통과 | 소유권과 수명이 바뀌는 지점이 없다. 참조 타입 표기만 바뀐다 |
| 3. 검증 가능한 변경 | 통과 | [quickstart.md](./quickstart.md)가 기준선 측정과 시나리오별 검증을 정의한다. 보장 항목 대조표를 요구한다 |
| 4. 스킬별 수정 경로 | 통과 | 이 단계는 계획 산출물만 작성한다. 구현 파일 경로는 `tasks.md`가 소유한다 |
| 5. Spec-Kit 범위 | 통과 | `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 작성했다 |
| 6. 한국어 산출물 | 통과 | 모든 산출물을 한국어로 작성했다. 식별자와 명령어는 원문 유지 |
| 7. 위험 기반 실행 단위 | 통과 | 아래 실행 단위에 위상 순서와 불가분 근거를 기록했다 |
| 8. Git-flow 네임스페이스 | 통과 | `feature/layer-overengineering`을 생성해 사용 중이다 |
| 9. 세션 지식 기록 | 해당 없음 | 반복되는 사건이나 여러 세션에서 종합한 해석이 아직 없다 |
| 10. 책임 기반 네이밍 | 통과 | 새 이름을 만들지 않는다. 기존 구체 타입 이름을 그대로 쓴다 |

**1단계 설계 후 재점검**: 통과. 설계가 새 패키지나 새 의존 방향을 만들지 않으며 복잡성 추적 대상 위반이 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/031-layer-overengineering/
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
docs/conventions/
├── README.md                    # 문서 표에 항목 추가
├── abstraction.md               # 새 인덱스
└── abstraction/                 # 새 규칙 문서와 기준선

sources/Projects/
├── Data/
│   ├── Authentication/Contracts/      # 계약 제거
│   ├── ExternalRepository/Contracts/  # 계약 제거
│   ├── LearningProject/Contracts/     # 계약 5개 제거, 2개 유지
│   ├── LegalConsent/Contracts/        # 계약 제거
│   ├── Member/Contracts/              # 계약 제거
│   ├── */Errors/                      # 오류 case 정리
│   └── Tests/**/Contracts/            # 계약 테스트 제거, 보장 이관
└── Composition/
    ├── Adapter/Adapters/              # 초기화 인자 타입 교체, 재매핑 축소
    └── Tests/Adapter/Adapters/        # HTTPTransport 스텁 기반으로 재구성
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 유지한다. 새 target도 새 패키지 의존성도 추가하지 않는다. `docs/conventions/abstraction/` 디렉터리 하나가 새로 생긴다.

## 실행 단위

[아키텍처 3.1](../../docs/architecture.md)의 의존성 표에 따른 위상 순서다. `Data`는 `Infrastructure` 뒤, `Composition`은 `Domain`·`Data`·`Infrastructure` 뒤에 온다. 이 명세에서 `Domain`과 `Infrastructure`는 바뀌지 않는다.

| 단위 | 패키지 | 목적 | 분리 가능성 |
| --- | --- | --- | --- |
| U1 | 문서 | 프로토콜 생성 기준 확정과 문서화 | 단일 문서군. 코드에 의존하지 않는다 |
| **I1** | Data + Composition | Authentication·LegalConsent 계약 제거 | **불가분**. 아래 근거 참조 |
| **I2** | Data + Composition | ExternalRepository 계약 제거 | **불가분**. 같은 근거 |
| **I3** | Data + Composition | Member 계약 제거 | **불가분**. 같은 근거 |
| **I4** | Data + Composition | LearningProject 계약 5개 제거 | **불가분**. 같은 근거 |
| **I5** | Data + Composition | 오류 case 중복 정리 | **불가분**. 아래 근거 참조 |
| U2 | 문서 | 구조 기준선 기록 | 단일 문서. 모든 코드 단위 완료 후 |

### I1~I4를 다중 패키지 단위로 두는 근거

Data가 계약을 제거하면 그 계약을 초기화 인자 타입으로 쓰는 Composition 어댑터가 같은 순간 컴파일 실패한다. 어댑터의 인자 타입을 먼저 바꾸면 이번에는 조립이 구체 타입을 넘기는데 계약이 아직 남아 타입 불일치가 난다. 어느 쪽도 중간 상태를 만들 수 없다.

각 단위는 다음을 함께 바꾼다.

- Data — 계약 파일 제거, 구체 타입의 공개 범위 확인, 계약 테스트 제거와 구현 테스트 보강, 계약 전용 테스트 더블 제거
- Composition — 어댑터 초기화 인자 타입 교체, 어댑터 테스트를 `HTTPTransport` 스텁 기반으로 재구성

**모듈 단위로 쪼갠 이유**: 네 단위는 서로 독립이다. `AuthenticationRemote`를 지워도 `MemberRemote`를 쓰는 코드는 영향을 받지 않는다. 모듈별로 나누면 리뷰 단위가 작아지고 실패 시 되돌릴 범위도 좁다. 근거 문서의 작업 순서 제안(Authentication → ExternalRepository → Member → LearningProject)을 그대로 따른다.

**LegalConsent를 I1에 붙인 이유**: `PolicyConsentStore`는 `AuthenticationAssembly`가 조립한다. 같은 조립 파일을 두 단위가 나눠 건드리면 충돌 지점이 생긴다.

### I5를 다중 패키지 단위로 두는 근거

Data 오류의 case를 지우면 그 case를 `switch`하는 Composition 어댑터가 즉시 컴파일 실패한다. Swift의 `switch` 완전성 검사가 두 변경을 같은 커밋에 묶는다.

**통합 검증**: I1~I5 각각의 완료 시점에 `Data`와 `Composition` 테스트 scheme을 실행한다. 두 패키지를 함께 확인하지 않으면 계약 제거가 조립까지 도달했는지 알 수 없다.

**대안 검토**: 계약을 `@available(*, deprecated)`로 표시한 뒤 한 릴리스 뒤에 제거하는 2단계 분할이 가능하다. 그러나 이 계약들은 저장소 안에서만 쓰이고 외부 소비자가 없어 유예 기간이 보호하는 대상이 없다. 중간 상태를 유지하는 비용만 남는다고 판단해 불가분 단위로 둔다.

### 패키지에 속하지 않는 파일

| 파일 | 배정 단위 | 근거 |
| --- | --- | --- |
| `docs/conventions/README.md` | U1 | 새 문서를 표에 등록하는 변경이며 기준 문서화와 같은 목적이다 |
| `docs/conventions/abstraction.md`, `docs/conventions/abstraction/**` | U1, U2 | 기준은 U1이, 기준선 수치는 U2가 소유한다. 두 단위가 같은 디렉터리의 서로 다른 파일을 다룬다 |
| `sources/Tuist/ProjectDescriptionHelpers/**` | 변경 없음 | 새 target도 새 패키지 의존성도 없다 |
| `docs/review/layer-overengineering-requirements.md` | 변경 없음 | 근거 문서이며 이 명세가 수정하지 않는다 |

## 검증 계획

- U1은 문서만 바꾸므로 빌드가 필요 없다. 문서 구조 규칙([컨벤션 공통 원칙](../../docs/conventions/common/document-structure.md))에 맞는지 확인한다.
- I1~I5는 각각 `Data`와 `Composition` 테스트 scheme으로 집중 검증한다.
- I4 완료 후 전체 `build` → `compile` → `test`를 순차 실행한다. LearningProject는 참조 지점이 가장 많아 여기서 전체를 한 번 확인한다.
- U2 직전에 전체 `build` → `compile` → `test`를 다시 실행하고 결과를 기록한다.
- 보장 항목 대조표를 남긴다. 제거한 계약 테스트가 보장하던 항목이 어느 구현 테스트로 옮겨졌는지 1:1로 기록하고, 옮길 곳이 없는 항목은 제거 근거를 적는다.
- Data 테스트의 검증 항목 수를 I1 시작 전과 U2 직전에 세어 비교한다.
- 수동 회귀 3종(로그인, 프로젝트 등록, 약관 동의)은 [quickstart.md](./quickstart.md)의 절차를 따른다.

## 복잡성 추적

> 헌법 점검에서 정당화해야 하는 위반이 없다. 이 섹션은 비어 있다.
