# 구현 계획: 관심사별 Domain UseCase 재설계와 호출부 전환

**Git-flow 유형**: `feature`

**브랜치**: `feature/domain-usecase-redesign`

**날짜**: 2026-09-18 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/037-domain-usecase-redesign/spec.md`의 기능 명세

## 요약

Domain UseCase 20개와 세 Domain 타깃을 관심사별 UseCase 7개·타깃 7개와 식별자 기반 타깃 `DomainIdentifier`로 재구성하고,
Data에 요청 인증 정보 구성요소를 두어 만료·401 시 로그아웃하며, Composition·Feature·App 호출부를 새 API로 옮긴다.
전환은 **새 타깃을 나란히 추가 → 하위 패키지가 새 UseCase를 추가 조립 → 관심사 묶음별 호출부 전환 → 옛 선언 제거** 순서로
진행해 각 커밋 단위가 독립적으로 compile되게 한다([research R-01](./research.md#r-01-전환-순서--추가-후-전환-마지막에-제거)).

## 기술 맥락

**언어/버전**: Swift 6 컴파일러, Swift 5 언어 모드(typed throws 미사용)

**주요 의존성**: SwiftUI, The Composable Architecture(Feature·App), Tuist 멀티 프로젝트, Swift Testing

**저장소**: 보안 저장소(로그인 기록·Apple 식별자), App Group UserDefaults(생성 대기 기록·공유 로그인 표시·약관 동의) — 형식 변경 없음

**테스트**: Swift Testing. Domain은 테스트 대역으로 계약을 대체, Data는 인메모리 저장소·기록 전송, Feature는 TCA `TestStore`

**대상 플랫폼**: iOS 26.0+ 앱과 Share Extension

**프로젝트 유형**: 모바일 앱(멀티 패키지)

**성능 목표**: 목록 필터 재적용은 서버 재요청 없이 수행. 목록 첫 로드와 새로고침이 동시에 호출돼도 서버 요청 1회

**제약 조건**: 코드 주석은 `// MARK:`만, 파일당 타입 1개, 공개 이름 규칙(D-ARCH-004·원칙 10), Domain은 프로젝트 내부 패키지에 의존하지 않음(같은 패키지의 `DomainIdentifier` 제외)

**규모/범위**: Domain 소스·테스트 약 170개 파일 교체, Data Remote 6개·알림 계약, Composition 어댑터 약 20개·조립 7개, Feature Reducer 약 27개와 테스트·프리뷰, App 루트·확장 앱

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1 명시적인 경계 | 통과 | 관심사 타깃 간 import 없음, `DomainIdentifier`만 예외로 규칙 문서에 기록(FR-008). 의존성은 Tuist에 명시, 순환 없음 |
| 2 상태와 데이터 안전성 | 통과 | 공유 상태 소유자: `Account`(로그인 상태), `Project`(목록), `ProjectGeneration`(생성 상태), `RequestCredentialProvider`(인증 정보). 모두 앱 수명 인스턴스 1개. 비동기 오류는 동작이 던지고 스트림은 마지막 성공 상태 유지 |
| 3 검증 가능한 변경 | 조건부 통과 | 단위 검증은 `swiftc -typecheck`(Domain), 의존성 검사 스크립트, 정적 검색으로 수행한다. 프로젝트 `build`·`compile`·`test` 실행기는 사용자 지시에 따라 사용자가 실행하며, 미실행 범위를 보고한다 |
| 4·5 스킬별 수정 경로 | 통과 | 이 계획은 산출물만 수정. 구현 파일은 `tasks.md`에 정확한 경로로 기록 |
| 6 한국어 산출물 | 통과 | |
| 7 위험 기반 실행 단위 | 통과 | 아래 실행 단위 표. 다중 패키지 단위마다 분리 불가 근거 기록 |
| 8 Git-flow 브랜치 | 통과 | `feature/domain-usecase-redesign` 생성 확인 |
| 9 세션 지식 기록 | 해당 없음 | |
| 10 책임 기반 네이밍 | 통과 | 세션·토큰 이름을 Domain에서 제거, 저장소 연산 이름 제거. 네이밍 변경과 동작 변경(요청 인증·실패 알림·목록 공유)은 같은 기능 범위이나 커밋 단위를 분리 |

**브랜치 네임스페이스**: `feature/` 사용, 명세 단계에서 현재 HEAD(`760e1e3`)로부터 생성.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 수정했다.

**세션 지식 기록**: 원칙 9를 따른다.

**Git 실행 직렬화**: 같은 checkout에서 변경 체인을 하나만 실행한다. 현재 pre-commit 단계는 모두 비활성(`tools/githooks/pre-commit.d/enabled`)이다.

**커밋 단위 구현**: 아래 실행 단위를 기준으로 `/speckit-implement`가 커밋을 설계한다.

**책임 기반 네이밍**: [research R-02](./research.md#r-02-구현-타입-이름), [contracts/domain-api.md](./contracts/domain-api.md).

**실행 단위 진행**: 아래 표. 전환 기간에는 한 파일이 옛 Domain 모듈과 새 Domain 모듈을 함께 import하지 않는다.

**선행 조건 — 기존 미커밋 변경**: 브랜치에 사용자 소유 미커밋 변경 31개 파일이 있고 일부가 이 기능의 수정 대상이다
([research R-13](./research.md#r-13-기존-미커밋-변경)). `/speckit-implement`는 시작 전에 소유권을 확인해야 한다.

## 패키지 위상 순서와 실행 단위

[아키텍처 문서 3.1](../../docs/architecture.md): Domain → 없음, Infrastructure → 없음, Data → Infrastructure,
Composition → Domain·Data, Feature → Domain·UI, App → Feature·Composition·Domain. UI는 변경하지 않는다.

| 단위 | 목적 | 패키지 | 분리 불가 근거 / 비고 | 검증 |
| --- | --- | --- | --- | --- |
| U1 | 새 Domain 타깃 8개와 테스트를 기존 타깃 옆에 추가 | Domain + Tuist 헬퍼 + 의존성 검사 설정 | 타깃 선언(`DomainModuleName`·scheme)과 `source-roots`가 소스 루트와 1:1이어야 검사가 통과 | `swiftc -typecheck`(타깃별), 의존성 검사 스크립트 |
| U2 | 알림 권한 설정 조회 | Infrastructure | 단일 패키지 | 정적 검토, 사용자 compile |
| U3 | 요청 인증 정보 구성요소와 Remote 인자 전환, 알림 설정 조회 전달 | Data + Composition | Remote 공개 init과 `LocalReminderNotifier` 요구사항 변경은 Composition 호출부·테스트 대역과 함께 바뀌어야 compile | 사용자 compile·test |
| U4 | 새 관심사 UseCase 조립과 공개 속성 추가(옛 속성 유지) | Composition + Tuist 헬퍼 | 새 Domain 타깃 의존 선언(매니페스트)과 import가 함께 필요 | 의존성 검사 스크립트, 사용자 compile |
| U5 | Account·UserInfo·AppSetting 호출부 전환 | Feature + App | Router init 변경이 App 루트 호출부와 함께 바뀌어야 compile | 사용자 compile·test |
| U6 | QuizDetail 호출부 전환 | Feature + App | 동일 | 동일 |
| U7 | Project·ProjectGeneration·ExternalRepository 호출부 전환(퀴즈 후 갱신·배너·확장 앱 포함) | Feature + App | 동일. 확장 앱 `ShareViewController`와 `ShareRegistrationFeature` 동시 변경 | 동일 |
| U8 | 옛 UseCase·계약·모델·어댑터·조립·공개 속성·타깃 제거 | Domain + Composition + Feature + App + Tuist 헬퍼 + 의존성 검사 설정 | 옛 타깃 제거는 모든 참조 제거와 같은 커밋이어야 compile | SC-001·002·004·007 정적 검색, 의존성 검사 스크립트 |
| U9 | 규칙 문서 갱신 | 문서 | 파일 단위 | 링크·내용 검토 |
| U10 | 전체 읽기 전용 검증과 포맷 훅 | — | 마지막 단위 | [quickstart.md](./quickstart.md) 1절, 포맷 훅, 사용자 build·compile·test |

U5–U7 사이의 상대 순서는 호출부 의존이 적은 순(Account 계열 → QuizDetail → Project 계열)이다. 전환 중 이름 충돌이 해소되지
않으면 해당 단위들을 하나의 integration unit으로 합친다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/037-domain-usecase-redesign/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── domain-api.md
│   └── integration-surface.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks 산출물
```

### 소스 코드(저장소 루트)

```text
sources/
├── Tuist/ProjectDescriptionHelpers/
│   ├── ProjectName.swift                          # Domain scheme 타깃 목록
│   ├── AllTestsScheme.swift                       # Domain 테스트 타깃 목록
│   └── Projects/
│       ├── DomainModuleName.swift                 # 타깃 8쌍 추가, 옛 3쌍 제거
│       ├── CompositionModuleName.swift            # .fromDomain 전환
│       ├── FeatureModuleName.swift                # .fromDomain 전환
│       └── AppModuleName.swift                    # .fromDomain 전환
└── Projects/
    ├── Domain/
    │   ├── Identifier/Models/                     # ProjectID, QuizSetID, QuizID, ExternalRepositoryURL
    │   ├── Account/{Contracts,Errors,Models,UseCases}/
    │   ├── UserInfo/{Contracts,Errors,Models,UseCases}/
    │   ├── AppSetting/{Contracts,Errors,Models,UseCases}/
    │   ├── ExternalRepository/{Contracts,Errors,Models,UseCases}/
    │   ├── QuizDetail/{Contracts,Errors,Models,UseCases}/
    │   ├── Project/{Contracts,Errors,Models,UseCases}/
    │   ├── ProjectGeneration/{Contracts,Errors,Models,UseCases}/
    │   ├── Tests/<관심사>/{UseCases,Models,TestDoubles}/
    │   └── Authentication/, LearningProject/, Member/, Tests/{Authentication,LearningProject,Member}/   # U8에서 제거
    ├── Infrastructure/LocalNotification/{Clients,Models}/
    ├── Data/
    │   ├── Shared/Models/RequestCredential.swift
    │   ├── Authentication/{Stores,Remotes}/
    │   ├── LearningProject/Remotes/, Member/Remotes/, Notification/{Contracts,Clients,Models}/
    │   └── Tests/{Authentication,LearningProject,Member,Notification}/
    ├── Composition/{Authentication,LearningProject,Member,App,ShareExtension}/{Adapters,Assemblies,Codings}/ + Tests/
    ├── Feature/<흐름>/ + Tests/<흐름>/
    └── App/{GitIt,ShareExtension}/ + Tests/GitIt/
tools/package-dependencies/config/source-roots
docs/package-rules/{domain.md,composition.md}
docs/conventions/directory-file/production-source-root.md
```

**구조 결정**: 기존 멀티 패키지 구조를 유지하고 Domain 패키지 안의 타깃만 관심사 단위로 나눈다. Data·Composition 모듈 구성은
바꾸지 않는다([integration-surface.md](./contracts/integration-surface.md#3-composition)).

## 1단계 설계 후 헌법 재점검

- 원칙 1: `ProjectUseCase`가 생성 상태를 `Set<ProjectID>` 클로저로만 받아 타깃 경계를 지킨다. Composition이 변환한다. 통과.
- 원칙 2: `RequestCredentialProvider`와 `Account` 사이 무효 신호는 멱등 정리로 중복 수신을 허용한다. 통과.
- 원칙 3: 프로젝트 실행기 미실행은 사용자 지시에 따른 것이며 각 단위 보고와 PR에 미검증 범위로 기록한다. 조건부 통과.
- 원칙 10: 구현 이름 예외(`ExternalRepositoryResolver`)의 근거를 research R-02에 기록했다. 통과.

## 복잡성 추적

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
| --- | --- | --- |
| Domain 타깃 간 의존(`DomainIdentifier`) | 여러 관심사가 같은 식별자를 공개 API에 쓰고, 같은 이름의 `typealias`를 타깃마다 두면 함께 import하는 파일에서 모호한 타입 참조가 된다(재설계 결정 27) | 소유 관심사에만 두고 `String` 사용(R2 일관성 저하), 접두어 이름(같은 값에 이름 여럿) |
| 전환 기간 옛·새 API 공존(U1–U7) | 한 번에 교체하면 수백 파일이 한 커밋에서만 compile된다 | 단일 초대형 커밋(리뷰·되돌리기 불가) |
