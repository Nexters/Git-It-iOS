# 구현 계획: Git-It Server API 전체 Data 패키지 구현

**Git-flow 유형**: `feature`

**브랜치**: `feature/server-data-api`

**날짜**: 2026-08-21 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/011-server-data-api/spec.md`의 기능 명세

**참고**: 이 템플릿은 `/speckit-plan`이 채운다. 스킬 정의에는 실행 흐름이 설명되어 있다.

## 요약

참조 문서 SPEC-DATA-API-001이 정의한 iOS 제품 범위의 서버 API 19개 operation(Auth 2,
Project 11, Member 6)을 Data 패키지에 구현한다. 각 도메인은 독립 target
(`DataAuthentication`, `DataLearningProject`, `DataMember`와 대응 Tests target)으로
분리하고, `Contracts`/`DTOs`/`Errors`/`Models`/`Endpoints`/`Remotes` 폴더 구조를 세 도메인에
동일하게 적용한다. Data 패키지는 프로젝트 내부 다른 패키지에 의존하지 않으므로(아키텍처
문서 3.1) production network adapter 연결은 이 기능의 범위 밖이며, Composition 계층에서
후속 작업으로 처리한다.

조사 결과 기존 `DataAuthentication` target은 이전 스펙(001-apple-social-login,
003-http-client 계열)에서 만든 `LoginSessionRemote`/`RefreshRequestDTO`/
`DataAuthenticationError` 등 refresh/revoke 세션 관리 계약을 이미 보유하고 있으며, 이는
FR-012(refresh/revoke 계열 operation 추정 구현 금지)와 정면으로 충돌한다. `DataLearningProject`
target은 이전 구현이 이미 제거되어(`adce9e3` 커밋) placeholder만 남아 있다. 이 계획은 두
불일치를 조사 단계에서 확정하고, 실제 파일 변경은 `/speckit-tasks`가 생성하는 작업에서
수행한다.

## 기술 맥락

**언어/버전**: Swift 6 (Swift Testing 사용, iOS 26.0+ 대상)

**주요 의존성**: Swift Standard Library, `Foundation`(`JSONDecoder`/`JSONEncoder`,
ISO-8601 `DateFormatter`). Data 패키지는 프로젝트 내부 다른 패키지(Domain·Infrastructure
등)에 의존하지 않는다(아키텍처 문서 3.1, `Data → —`).

**저장소**: N/A — 이 기능은 네트워크 API 계약(DTO·Remote 프로토콜)만 다루며 영속 저장소를
포함하지 않는다.

**테스트**: Swift Testing(`@Suite`/`@Test`/`#expect`/`#require`)을 기본으로 사용하고,
XCTest는 이 기능에서 필요하지 않다([테스트 컨벤션](../../docs/conventions/test.md)).

**대상 플랫폼**: iOS 26.0+ (Tuist 멀티 패키지, `DataAuthentication`/`DataLearningProject`/
`DataMember`와 각 Tests target)

**프로젝트 유형**: 모바일 앱의 Data 계층 라이브러리 패키지(iOS 클라이언트 내부 모듈)

**성능 목표**: 명세에 별도 지정된 지연시간·처리량 목표 없음 — DTO 인코딩/디코딩과 오류
매핑이 각 operation당 O(응답 크기)로 동작하면 충분하다.

**제약 조건**: FR-016에 따라 production target에는 test fixture·Mock을 포함하지 않는다.
FR-014에 따라 Apple ID Token/Access Token/Refresh Token/Authorization header 원문을
로그·debug description에 노출하지 않는다.

**규모/범위**: Auth 2 + Project 11 + Member 6 = 19 operation, 3개 production target과 3개
Tests target.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

**브랜치 네임스페이스**: `feature/server-data-api`는 `/speckit-specify` 실행 시
`before_specify` 훅이 없어 미생성 상태로 기록되었고, 이후 사용자 지시로 별도 세션에서
`git checkout -b feature/server-data-api`로 실제 생성되었다. 이 계획은 이미 생성된 브랜치를
소급 변경하지 않고 실제 브랜치명을 그대로 사용한다. **PASS**

**허용 수정 경로**: 이 단계는 `specs/011-server-data-api/plan.md`, `research.md`,
`data-model.md`, `quickstart.md`, `contracts/**`만 생성·수정한다. 구현 파일 경로는 여기
"프로젝트 구조"에 기록하고 `/speckit-tasks`가 `tasks.md`로 옮긴다. **PASS**

**세션 지식 기록**: 이 단계에서 실행 오류나 실패는 발생하지 않았다. 기존
`DataAuthentication` 코드와 SPEC-DATA-API-001의 불일치는 계획 단계의 조사 결과이며
`research.md`에 결정으로 기록한다(트러블슈팅·암묵지 기록 대상 아님). **PASS**

**Git 실행 직렬화**: 이 단계는 파일 시스템 조사와 문서 작성만 수행하며 동시에 실행 중인
다른 Git index 변경 체인이 없다. **PASS**

**책임 기반 네이밍**: 신규 `DataMember` target과 재작성 대상 `DataAuthentication` 계약은
[네이밍 컨벤션](../../docs/conventions/naming.md) 4절의 Data 패키지 문맥(획득·저장·캐시·
동기화 책임, DTO·기술 계약)을 따르고 서버 schema 고정 명칭(`APIResponseDTO`,
`FieldErrorDTO` 필드명 등)은 원문을 보존한다. 상세 이름은 `data-model.md`와
`contracts/`에서 확정한다. **PASS**

**패키지 진행**: 이 명세는 Data 패키지만 변경한다. `Domain → Data → Infrastructure →
Composition → UI → Feature → App` 순서 중 Data 이외 패키지는 해당 사항이 없어 건너뛴다.
Data 패키지 내부에서는 3개 독립 target(Authentication/LearningProject/Member)을 각각 하나의
구현 단위로 순차 진행하며, 순서는 기존 코드 충돌 해소가 필요한 Authentication을 먼저,
LearningProject, Member 순으로 `tasks.md`에서 확정한다(각 target 완료·검증·사용자 승인 후
다음 target 진행). **PASS**

## 프로젝트 구조

### 문서(이 기능)

```text
specs/011-server-data-api/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md         # 1단계 산출물(/speckit-plan)
├── quickstart.md         # 1단계 산출물(/speckit-plan)
├── contracts/            # 1단계 산출물(/speckit-plan)
└── tasks.md              # 2단계 산출물(/speckit-tasks, /speckit-plan이 생성하지 않음)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/Data/
├── Authentication/
│   ├── Contracts/     # AuthenticationRemote(appleLogin, verifyAccessToken)
│   ├── DTOs/          # AppleLoginRequestDTO, LoginResponseDTO, 공통 Envelope/Error DTO
│   ├── Errors/        # DataAuthenticationError(FR-006 매핑 중 Auth 범위)
│   ├── Models/        # (필요 시) Auth 도메인 전용 Data 모델
│   ├── Endpoints/      # HTTP method/path/query/body 계약(참조 문서 AUTH-XX)
│   └── Remotes/        # AuthenticationRemote 구현이 사용할 계약 조립
│
├── LearningProject/
│   ├── Contracts/      # LearningProjectRemote(11개 operation)
│   ├── DTOs/           # Register/List/Detail/Status/Set/Answer/Bookmark DTO
│   ├── Errors/         # DataLearningProjectError(FR-006 매핑 중 Project 범위)
│   ├── Models/
│   ├── Endpoints/       # 참조 문서 PROJECT-XX
│   └── Remotes/
│
├── Member/              # 신규 생성
│   ├── Contracts/       # MemberRemote(6개 operation)
│   ├── DTOs/
│   ├── Errors/          # DataMemberError(FR-006 매핑 중 Member 범위)
│   ├── Models/
│   ├── Endpoints/        # 참조 문서 MEMBER-XX
│   └── Remotes/
│
└── Tests/
    ├── Authentication/
    ├── LearningProject/
    └── Member/          # 신규 생성
```

Tuist target: `DataAuthentication`/`DataAuthenticationTests`,
`DataLearningProject`/`DataLearningProjectTests`, `DataMember`/`DataMemberTests`
([Project.swift](../../sources/Projects/Data/Project.swift)에서 target 선언).

**구조 결정**: 참조 문서 SPEC-DATA-API-001의 3절(Data 모듈)이 명시한 3개 도메인×6개
역할 폴더 구조를 그대로 채택한다. `DataLearningProject`는 기존 placeholder를 대체하고,
`DataMember`는 신규 생성하며, `DataAuthentication`은 기존 refresh/revoke 세션 계약을
제거하고 참조 문서 AUTH-01/AUTH-02 계약으로 재작성한다(근거: `research.md` 결정 1, 2).

## 1단계 설계 후 헌법 재점검

`research.md`·`data-model.md`·`contracts/`·`quickstart.md` 작성 후에도 새 최상위 패키지나
패키지 간 의존성 변경은 도입하지 않았다(결정 3·4에서 공유 target 신설을 기각). 세 도메인
target은 서로 독립적으로 유지되며 패키지 진행 게이트("Data 패키지 내부에서 Authentication
→ LearningProject → Member 순차 진행")도 그대로 유효하다. **모든 게이트 PASS 유지.**

## 복잡성 추적

> **헌법 점검에서 정당화해야 하는 위반이 있을 때만 작성한다**

없음 — 모든 게이트가 PASS다.
