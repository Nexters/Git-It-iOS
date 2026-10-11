# 구현 계획: Domain·Data·Infrastructure 설계 점검과 문서·네이밍 교정

**Git-flow 유형**: `feature`

**브랜치**: `feature/domain-data-infra-design-review`

**날짜**: 2026-09-17 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/035-domain-data-infra-design-review/spec.md`의 기능 명세

## 요약

세 패키지의 프로덕션·테스트 target과 README를 기준 문서와 명세 035의 패키지 관심사
원칙(FR-017·FR-020)에 대조해, 발견 항목을 `docs/review/domain-data-infra-design-review.md`에
`DOC`(문서 교정)·`RN`(rename)·`DS`(후속 설계 변경)·`OK`(위반 아님) 네 종류로 기록한다.
[research.md](./research.md) 3절이 실측한 초안은 문서 교정 9건, rename 후보 19건, 후속 설계
변경 9건이다. 문서 교정은 아키텍처 문서에 결정 기록 `D-ARCH-004`를 정본으로 두고 패키지
규칙·네이밍·어휘표가 참조하게 한다. rename은 선언 소유 패키지와 참조 패키지를 묶은
integration unit으로 진행해 각 commit이 compile되게 한다. 관심사 중복 쌍과 구조 변경은
기록만 남긴다.

## 기술 맥락

**언어/버전**: Swift 6, Tuist manifest, 마크다운 문서

**주요 의존성**: 없음(외부 패키지 추가·제거 없음, FR-013)

**저장소**: 해당 없음. Keychain·UserDefaults key 문자열은 불변(FR-010)

**테스트**: 기존 Swift Testing target(`DomainAuthenticationTests` 등 11개). 테스트 변경은
이름 치환에 한정(SC-004)

**대상 플랫폼**: iOS 26 Simulator(iPhone 17 Pro), macOS 개발 환경

**프로젝트 유형**: Tuist 멀티 패키지 iOS 앱의 문서·이름 교정

**성능 목표**: 해당 없음

**제약 조건**: 동작·시그니처·의존 방향·저장 값 불변, Composition·Feature·App은 참조 갱신만,
`specs/`·`docs/spec-kit`·`docs/retrospective`·기존 `docs/review` 문서는 수정하지 않음,
프로토콜 추가·제거 없음(기준선 47 유지)

**규모/범위**: 프로덕션 파일 Domain 114·Data 93·Infrastructure 43, 규칙 문서 8개, README 2개,
rename 참조 파일 약 50개(Data 31·Composition 7·docs 10 + Domain 계약 참조)

## 명세와의 해석 차이

1. **target rename(FR-009a)**: 실측 결과 규칙을 위반하는 target 이름이 없어 이번 계획에 target
   rename 단위가 없다(research 3.4). 점검 단계에서 발견되면 U4에 같은 절차로 추가한다.
2. **Data 오류 타입 접두어(RN-01~04)**: Domain에 같은 이름의 오류가 있어 구분 문맥이 필요하다.
   패키지 접두어 대신 오류가 분류하는 대상을 드러내는 이름을 쓴다.
3. **Data 형태 폴더 `Codings/`·`Layouts/`·`Migrations/`(DOC-08·DS-09)**: 어휘표에 Data 행을
   추가하는 문서 교정으로 해소하고, 폴더 재배치는 후속으로 둔다. 어휘표 자체가 "표에 없는
   형태를 추가하려면 같은 PR에서 이 표를 갱신"을 허용한다.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1 명시적 경계 | 통과 | 의존 방향·Tuist 선언 불변(FR-013, SC-005·SC-006) |
| 2 상태·데이터 안전성 | 통과 | 저장 key·전송 필드 불변(FR-010) |
| 3 검증 가능한 변경 | 통과 | 각 단위 빌드·테스트, 전체 검증은 quickstart 명령. 아키텍처 문서는 구조 결정(D-ARCH-004) 기록에 한해 갱신 |
| 4·5 스킬별 수정 경로 | 통과 | 이 계획은 plan·research·data-model·quickstart·contracts만 작성. 구현 파일은 `tasks.md`가 파일 단위로 명시. `docs/**`는 파일 단위 명시 필요 |
| 6 한국어 산출물 | 통과 | 모든 산출물 한국어 |
| 7 위험 기반 실행 단위 | 통과 | 아래 실행 단위 표. rename은 분리 불가 근거를 가진 integration unit |
| 8 Git-flow | 통과 | `feature/domain-data-infra-design-review` 생성 확인 |
| 9 세션 지식 기록 | 해당 없음 | 기록 조건 미충족 |
| 10 책임 기반 네이밍 | 통과 | rename은 설계 변경과 분리(FR-007), 후속 항목은 별도 명세 |

**브랜치 네임스페이스**: `feature/` 사용, 이 개정 후 생성.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정한다.

**세션 지식 기록**: Constitution 원칙 9의 문턱을 충족하는 사건 없음.

**Git 실행 직렬화**: 같은 checkout에서 변경 체인은 하나만 실행한다.

**커밋 단위 구현**: 아래 실행 단위 하나가 커밋 하나 이상이다. rename 단위는 소유 패키지와
참조 패키지를 한 commit에 담는다.

**책임 기반 네이밍**: rename 대상과 방향은 research 3.2. 구체 이름은 구현 단위가 정하되
패키지 접두어·기술 용어·저장 매체 용어를 쓰지 않는다.

**실행 단위 진행**: 아래 표. 위상 순서는 Domain → Data → Composition → Feature/App이며
Infrastructure는 코드 변경이 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/035-domain-data-infra-design-review/
├── plan.md              # 이 파일
├── research.md          # 실측 목록과 결정
├── data-model.md        # 발견 항목 구조
├── quickstart.md        # 검증 명령
├── contracts/
│   └── review-record.md # 점검 결과 문서 형식
└── tasks.md             # /speckit-tasks 산출물
```

### 변경 파일(저장소 루트)

```text
docs/
├── architecture.md                                  # 2장 Domain·Data·Infra 설명, 3.3 예시, 9장 D-ARCH-004
├── package-rules/{domain,data,infrastructure}.md    # FR-017 참조, DOC-01·03·05
├── conventions/naming.md                            # 4장 표 Data 행(DOC-06)
├── conventions/abstraction/structure-baseline.md    # rename 이름 갱신(DOC-07), 누락 계약 2개 추가(DOC-09)
├── conventions/abstraction/{protocol-criteria,test-double-injection}.md  # HTTPProjectRemote 참조
├── conventions/file-vocabulary/shape-vocabulary.md  # Data 행 추가(DOC-08)
├── release/guideline-5-1-1-appeal.md                # LearningProjectHTTPExecutor 참조
└── review/
    ├── README.md                                    # 목록에 추가
    └── domain-data-infra-design-review.md           # 신규: 점검 결과

sources/Projects/
├── Domain/
│   ├── Authentication/README.md                     # DOC-04, RN 이름
│   ├── Authentication/Contracts/{StoredSession,SharedSessionMarker}Repository.swift   # RN-17·18
│   ├── LearningProject/Contracts/{PendingGenerationReminderStore,GenerationReminderRegistry,
│   │   NotificationAuthorizationGateway,ExternalRepositoryURLParser,GenerationStateRepository}.swift  # RN-12~16
│   ├── LearningProject/UseCases/**                  # 위 계약 참조
│   └── Tests/**                                     # 이름 치환
├── Data/
│   ├── {Authentication,Member,LearningProject,ExternalRepository}/Errors/Data*Error.swift  # RN-01~04
│   ├── */Remotes/HTTP*Remote.swift, LearningProjectHTTPExecutor.swift                    # RN-05~09
│   ├── Authentication/{Codings,Migrations,Layouts,Stores}/*Keychain*.swift               # RN-10
│   └── Tests/**                                     # 이름 치환
├── Composition/
│   ├── */Adapters/*.swift, */Assemblies/*.swift     # 참조 갱신, Adapter 파일 이름
│   └── Tests/**
├── Feature/**                                       # ExternalRepositoryURLParser 참조 3파일(App은 참조 없음)
└── Infrastructure/Authentication/README.md          # 참조 이름 확인(변경 없을 수 있음)
```

**구조 결정**: 새 폴더·target을 만들지 않는다. rename으로 파일 이름이 바뀌면 같은 형태 폴더
안에서 `git mv`한다. 점검 결과 문서만 신규 파일이다.

## 실행 단위

| 단위 | 패키지·책임 | 내용 | 검증 | 분리 불가 근거 |
| --- | --- | --- | --- | --- |
| U1 점검 | `docs/review` (문서) | 세 패키지 전수 점검, `domain-data-infra-design-review.md` 초안(모든 항목·판정 조건·근거), `README.md` 목록 추가 | 시나리오 1 명령, SC-001·SC-007 항목 존재 | 단일 |
| U2 문서 교정 | `docs/` + Domain README | DOC-01~06·08 해소, D-ARCH-004 기록(FR-017·FR-020·명확화 5·6 판정 기준의 단일 정본, 3.3 예시는 공개 initializer 시그니처를 싣지 않음). DOC-07(기준선)·DOC-09(기준선 누락 계약)는 U3 뒤 이름 갱신·추가 | 시나리오 2 명령, 문서 링크 대상 존재 | 단일(문서). Domain README(DOC-04)는 코드 변경 없어 같은 단위 |
| U3 Domain rename | Domain + Composition + Feature (integration unit) | RN-12~18 계약·연산 rename, Adapter 파일 이름·Assembly·Feature 참조 갱신, 테스트 치환 | Domain·Composition·Feature scheme 테스트, 옛 이름 0건 | Domain 계약 이름을 바꾸면 Composition Adapter 채택 선언이 즉시 깨진다. Feature는 `ExternalRepositoryURLParser`를 직접 참조(3파일) |
| U4 Data rename | Data + Composition (integration unit) | RN-01~10 타입·파일 rename, Assembly·Adapter 참조 갱신, 테스트 치환, Keychain key 불변 확인 | Data·Composition scheme 테스트, 시나리오 3 저장 값 diff | Data 공개 타입 이름을 바꾸면 Composition Assembly 생성 코드가 깨진다 |
| U5 마무리 | `docs/` + 점검 결과 | DOC-07 기준선 이름 갱신, 점검 결과 `RN-*` 새 이름·상태·2.5 검증 표 기입, 옛 이름 전수 검색, 의존성 검사, 전체 build·compile·test(사용자 실행), after_implement 포맷 훅 | quickstart 전체 검증 | 단일 |

U1과 U2는 코드에 독립적이라 순서를 바꿔도 되지만, U2가 U1의 DOC 항목 ID를 인용하므로 U1을
먼저 둔다. U3·U4는 서로 독립이며 위상 순서(Domain 먼저)를 따른다. U3·U4가 점검 결과의 RN
항목 수를 바꾸면(점검에서 추가 발견) 같은 단위에서 표를 갱신한다.

## 복잡성 추적

위반 없음. Domain·Data rename을 Composition과 묶는 것은 Constitution 원칙 7이 허용하는
"분리하면 compile되지 않는 공개 API 이전"이다.
