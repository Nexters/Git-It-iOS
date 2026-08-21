# 구현 계획: GitHub Public Repository Data 계약

**Git-flow 유형**: `feature`

**브랜치**: `feature/github-public-repository-data`

**날짜**: 2026-08-21 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/012-github-public-repository-data/spec.md`의 기능 명세

## 요약

기존 `DataLearningProject` target의 placeholder를 GitHub Public Repository 조회에 필요한
Data 소유 계약으로 교체한다. `owner`와 `repo`로 고정 요청 값을 만드는
`GitHubRepositoryRequest`, 네 필드만 디코딩하는 `GitHubRepositoryResponseDTO`, 조회 능력을
표현하는 `ExternalRepositoryRemote`, `offline`과 `other`를 구분하는
`DataExternalRepositoryError`를 추가한다. 실제 HTTP 요청 변환·전송과 기술 오류 매핑은
Composition 후속 범위로 유지한다.

## 기술 맥락

**언어/버전**: Swift 5 언어 모드(`SWIFT_VERSION: 5.0`), Swift Concurrency·`Sendable`

**주요 의존성**: production은 Swift Standard Library만 사용한다. 테스트 fixture 디코딩은
Apple `Foundation.JSONDecoder`와 Swift Testing을 사용한다.

**저장소**: N/A — 캐시·영속화 없음

**테스트**: Swift Testing(`@Suite`, `@Test`, `#expect`, `#require`), Data 공유 scheme의
`DataLearningProjectTests`

**대상 플랫폼**: iOS 26.0 이상

**프로젝트 유형**: Tuist 기반 iOS 멀티 패키지 앱의 독립 Data 모듈

**성능 목표**: N/A — 네트워크 전송을 구현하지 않는 불변 요청 값·DTO·오류·프로토콜 계약

**제약 조건**: GitHub 인증 정보와 Git-It/Apple credential 미포함, Domain·Infrastructure 타입
참조 금지, 외부 라이브러리 구체 API 금지, 실제 HTTP 오류 매핑·재시도·로깅 제외

**규모/범위**: production target 1개, production 계약 타입 4개, 대응 계약 테스트 4개 묶음,
기존 production/test placeholder 제거

## 헌법 점검

*게이트: 0단계 조사 전에 통과했으며 1단계 설계 후 다시 점검한다.*

- **명시적인 경계**: Data가 외부 서비스 요청·응답과 필요한 기술 능력만 소유한다.
  Domain 모델 변환과 HTTPClient 연결은 Composition에 남긴다. 통과.
- **상태와 데이터 안전성**: 값 타입은 불변·`Sendable`로 두고 credential 필드와
  `Authorization` 헤더를 생성 경로에서 배제한다. 통과.
- **검증 가능한 변경**: 요청 불변조건, 부분 디코딩, 필수·선택 필드와 지정된 오류의 전달을
  독립 Swift Testing으로 고정하고 실제 기술 오류 매핑은 측정 대상에서 제외한다. 통과.
- **허용 수정 경로**: 계획 단계는 이 기능의 `plan.md`, `research.md`, `data-model.md`,
  `quickstart.md`, `contracts/**`만 수정한다. 통과.
- **패키지 진행**: 적용 패키지는 `Data` 하나뿐이다. 구현·검증·결과 보고 후 종료하며 다음
  패키지 파일은 이 명세에서 변경하지 않는다. 통과.
- **책임 기반 네이밍**: GitHub 고정 명칭은 요청·wire DTO에만 유지한다.
  `DataExternalRepositoryError`의 `Data` 문맥은 Composition에서 동명의 Domain 오류와
  구분하기 위한 실제 충돌 문맥이다. 통과.
- **브랜치 네임스페이스**: 현재 브랜치 `feature/github-public-repository-data`가 정책을
  충족한다. 통과.

게이트 위반과 정당화가 필요한 예외는 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/012-github-public-repository-data/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── github-public-repository-data.md
└── tasks.md                              # /speckit-tasks 산출물
```

### 소스 코드(저장소 루트)

```text
sources/Projects/Data/
├── LearningProject/
│   ├── Contracts/
│   │   └── ExternalRepositoryRemote.swift
│   ├── DTOs/
│   │   └── GitHubRepositoryResponseDTO.swift
│   ├── Errors/
│   │   └── DataExternalRepositoryError.swift
│   └── Requests/
│       └── GitHubRepositoryRequest.swift
└── Tests/LearningProject/
    ├── Contracts/
    │   └── ExternalRepositoryRemoteContractTests.swift
    ├── DTOs/
    │   └── GitHubRepositoryResponseDTOTests.swift
    ├── Errors/
    │   └── DataExternalRepositoryErrorTests.swift
    └── Requests/
        └── GitHubRepositoryRequestTests.swift
```

현재 `sources/Projects/Data/LearningProject/DataLearningProjectPlaceholder.swift`와
`sources/Projects/Data/Tests/LearningProject/DataLearningProjectCompilationTests.swift`는 실제
계약과 테스트로 대체되므로 구현 단계에서 제거한다. `DataModuleName`과 Data 공유 scheme은 이미
`DataLearningProject`/`DataLearningProjectTests`를 연결하므로 Tuist 구성 파일은 변경하지 않는다.

**구조 결정**: 패키지 문맥을 폴더명에 반복하지 않고 기존 `LearningProject` source root 아래를
역할별로 나눈다. production과 test target의 경로는 현재 `DataModuleName.sourceDirectory`와
테스트 컨벤션을 그대로 따른다.

## 0단계: 조사 결과

[research.md](./research.md)에서 다음 결정을 확정했다.

1. GitHub 공식 `GET /repos/{owner}/{repo}`와 명세가 고정한 API version·헤더를 그대로 쓴다.
2. 요청 값은 scheme·host·method·path·headers를 불변으로 만들고 credential 주입 경로를 두지 않는다.
3. 응답 DTO는 `Decodable` 전용 부분 모델이며 필수 `owner` 컨테이너와 선택
   `owner.avatar_url`, 기본값 `[]`인 `topics`를 구분한다.
4. Remote는 표준 `throws`를 유지하고 계약상 `DataExternalRepositoryError`만 전달한다.
5. 기존 target·scheme을 재사용하고 source/test placeholder만 실제 계약으로 교체한다.

미해결 기술 항목은 없다.

## 1단계: 설계와 계약

- [data-model.md](./data-model.md): 요청 값, 응답 DTO, 오류, Remote 관계와 검증 규칙
- [contracts/github-public-repository-data.md](./contracts/github-public-repository-data.md): 공개
  Swift 계약과 테스트 매트릭스
- [quickstart.md](./quickstart.md): 구현 후 build-for-testing과 test-without-building 검증 절차

## 구현 경계와 순서

적용 대상은 `Data(DataLearningProject)` 하나다.

1. 요청·DTO·오류·Remote 계약 테스트를 추가하고 구현 전에 대상 선언 부재로 실패하는 Red
   상태를 확인해 명세의 성공·실패 조건을 고정한다.
2. 네 production 타입을 구현하고 placeholder production/test 파일을 제거한다.
3. `tasks.md`에 정확히 명시된 현재 변경 Swift 파일만 `GIT_IT_SWIFT_FORMAT_RUNNER` 공개
   진입점으로 포맷하고 Git index와 대상 밖 파일이 변경되지 않았음을 확인한다.
4. 금지 의존성·credential 노출을 정적 확인하고 Data 공유 scheme을 별도
   `sources/DerivedData/Feature012`에서 build-for-testing, test-without-building 순서로 검증한다.
   destination은 `GIT_IT_TEST_DESTINATION` 또는 기본 `iPhone 17 Pro`를 사용한다.
5. 변경 파일과 Data 집중 검증 결과를 사용자에게 보고하고 Data 패키지 변경을 종료한다.
6. 보고 직후 작업 트리 기준 상태를 기록하고 저장소 공개 runner의 전체 production build,
   build-for-testing, test-without-building을 순차 실행한 뒤 Git 추적 파일 상태가 동일한지
   확인한다. 다른 패키지 작업은 이 명세에 포함하지 않는다.

## 설계 후 헌법 재점검

- 변경 경로는 `sources/Projects/Data/LearningProject/**`와
  `sources/Projects/Data/Tests/LearningProject/**`의 Data 단일 패키지로 배정 가능하다.
- 프로젝트 내부 패키지·외부 라이브러리 의존성을 추가하지 않는다.
- Domain 변환, HTTPClient 변환·전송, 오류 매핑과 App DI를 설계에 포함하지 않았다.
- 요청 값과 DTO는 불변·`Sendable`이고 테스트는 별도 Data test target에 위치한다.
- 공용 Tuist 구성 파일 변경이 없어 다중 패키지 작업 또는 승인 게이트가 추가되지 않는다.
- 허용된 Swift 파일을 전체 검증 전에 공개 formatter로 정리하고, 전체 검증 전후 작업 트리
  상태가 같아야만 읽기 전용 gate를 통과한 것으로 판정한다.

설계 후에도 모든 gate가 통과하며 복잡성 예외는 없다.
