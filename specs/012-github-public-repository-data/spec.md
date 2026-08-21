# 기능 명세: GitHub Public Repository Data 계약 구현

**Git-flow 유형**: `feature`

**기능 브랜치**: `미생성 (예정: feature/github-public-repository-data)`

**생성일**: 2026-08-21

**상태**: 초안

**입력**: 사용자 설명: "해당 엔드포인트에 대한 Data 모듈을 구현"

**참조 문서**: [GitHub Public Repository 조회 — 서비스 필요 데이터 구현 명세](../../GitHub%20Public%20Repository%20%EC%A1%B0%ED%9A%8C%20%E2%80%94%20%EC%84%9C%EB%B9%84%EC%8A%A4%20%ED%95%84%EC%9A%94%20%EB%8D%B0%EC%9D%B4%ED%84%B0%20%EA%B5%AC%ED%98%84%20%EB%AA%85%EC%84%B8.md)
(문서 ID: `U02-GITHUB-REPOSITORY-LOOKUP`, 대상 API: `GET https://api.github.com/repos/{owner}/{repo}`)

## 명확화

### 세션 2026-08-21

- 질문: 이번 Data 기능이 HTTP 상태와 기술 오류를 Data 오류로 매핑하는 구현까지 포함하는가? → 답변: 포함하지 않는다. Data는 요청·DTO·오류 계약만 구현하고 실제 매핑과 상태별 매핑 테스트는 후속 Composition 범위로 둔다.
- 질문: 이번 Data 기능은 Repository 조회 실패를 몇 가지 오류로 구분하는가? → 답변: 네트워크 연결 실패만 `offline`으로 구분하고, GitHub 404를 포함한 나머지 실패는 모두 `other`로 통일한다. `owner`/`repo` 추출 실패는 upstream Domain의 `invalidURLFormat`으로 유지한다.
- 질문: method·path·header 요청 계약은 어느 경계가 소유하는가? → 답변: Data가 구체 HTTP 클라이언트 타입에 의존하지 않는 기술 중립적 요청 명세로 소유하고, Composition이 이를 실제 HTTP 요청으로 변환한다.

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - Public Repository 최소 데이터를 안전하게 소비한다 (우선순위: P1)

Data 패키지를 소비하는 Composition 개발자는 조회 가능한 GitHub Public Repository의 응답에서
프로젝트 등록과 표시에 필요한 canonical URL, 소유자 이미지, Star 수, 기술 스택만 받을 수
있어야 한다. GitHub 전체 Repository schema가 변경되거나 사용하지 않는 필드가 추가되어도 이
최소 데이터 계약은 영향을 받지 않아야 한다.

**주요 행위자**: Data 패키지를 소비해 GitHub 연동 Adapter를 조립하는 개발자

**우선순위 이유**: 최소 응답 계약이 없으면 상위 계층이 Repository 등록에 필요한 값을 안정적으로
얻을 수 없고 외부 API의 불필요한 schema에 결합된다.

**독립 테스트**: GitHub 응답 fixture를 `GitHubRepositoryResponseDTO`로 디코딩해 네 필드가
정확히 보존되고, 사용하지 않는 추가 필드가 있어도 결과가 같음을 확인하면 독립적으로 검증할 수
있다.

**수용 시나리오**:

1. **전제** `html_url`, `owner.avatar_url`, `stargazers_count`, `topics`가 포함된 성공
   응답, **실행** Data 응답 계약으로 디코딩, **결과** 각 값이 `htmlURL`,
   `ownerAvatarURL`, `starCount`, `topics`에 손실 없이 보존된다.
2. **전제** `owner.avatar_url`이 `null`이고 `topics`가 비어 있는 성공 응답, **실행**
   디코딩, **결과** 이미지 값은 없음으로 보존되고 빈 기술 스택과 함께 조회가 성공한다.
3. **전제** 서비스가 사용하지 않는 GitHub 응답 필드가 추가된 성공 응답, **실행** 디코딩,
   **결과** 추가 필드는 무시되고 네 개의 서비스 필요 데이터는 동일하게 반환된다.

---

### 시나리오 2 - GitHub 요청과 인증 경계를 분리한다 (우선순위: P1)

Data 패키지를 소비하는 연동 개발자는 파싱이 끝난 `owner`와 `repo`로 Data가 제공하는 기술
중립적 GitHub Public Repository 요청 명세를 얻을 수 있어야 하며, 이 명세에는 Git-It 또는
Apple 인증 정보가 포함되지 않아야 한다. 구체 HTTP 요청 생성과 전송은 Composition이 맡는다.

**주요 행위자**: Data↔Infrastructure Adapter를 구현하거나 검토하는 개발자

**우선순위 이유**: 서로 다른 서비스의 credential이 GitHub로 전송되면 보안 경계를 위반하며,
요청 계약이 불명확하면 실제 endpoint와 다른 요청을 만들 수 있다.

**독립 테스트**: 대표 `owner`/`repo` 입력으로 생성되는 기술 중립적 요청 명세의 method, path,
필수 헤더와 `Authorization` 부재를 확인하면 구체 HTTP 클라이언트나 실제 네트워크 없이 전체
경계를 검증할 수 있다.

**수용 시나리오**:

1. **전제** `owner = "facebook"`, `repo = "react"`, **실행** Repository 조회 요청 계약을
   확인, **결과** method는 `GET`이고 path는 `/repos/facebook/react`이다.
2. **전제** GitHub Public Repository 조회 요청, **실행** 헤더 확인, **결과**
   `Accept: application/vnd.github+json`과 `X-GitHub-Api-Version: 2022-11-28`가 존재한다.
3. **전제** Git-It access token, refresh token 또는 Apple identity token이 존재하는 실행
   환경, **실행** GitHub 요청 계약 확인, **결과** `Authorization` 및 해당 credential 값은
   요청에 포함되지 않는다.

---

### 시나리오 3 - 조회 실패를 상위 계층이 처리할 수 있게 구분한다 (우선순위: P2)

Data 패키지를 소비하는 개발자는 네트워크 연결 실패와 그 밖의 실패를 구분해 받고, 실패
응답이 등록 가능한 Repository 데이터로 오인되지 않게 해야 한다.

**주요 행위자**: Composition Adapter와 오류 정책을 구현하는 개발자

**우선순위 이유**: 오류 원인의 최소 구분은 상위 계층이 오프라인 안내와 등록 불가 상태를
올바르게 선택하고 성공 데이터 생성을 차단하는 근거가 된다.

**독립 테스트**: Data 오류 계약이 `offline`과 `other`를 서로 다른 케이스로 제공하고, 오류를
던지는 Remote 테스트 대역에서 성공 DTO가 반환되지 않음을 확인하면 독립적으로 검증할 수 있다.
HTTP 상태와 기술 오류의 실제 매핑은 후속 Composition 테스트에서 검증한다.

**수용 시나리오**:

1. **전제** 외부 연동 계층이 연결 실패를 `offline`으로 전달, **실행** Data Remote 계약의
   실패 결과 확인, **결과** `offline`이 보존되고 성공 DTO는 반환되지 않는다.
2. **전제** 외부 연동 계층이 GitHub 404 또는 그 밖의 비연결 실패를 `other`로 전달,
   **실행** Data Remote 계약의 실패 결과 확인, **결과** `other`가 보존되고 성공 DTO는
   반환되지 않는다.

---

### 예외·경계 사례

- `topics`가 누락되거나 `null`이면 빈 배열로 처리하고 Repository 조회는 성공해야 한다.
- `owner.avatar_url`이 누락되거나 `null`이면 이미지 값만 없음으로 처리하고 나머지 응답은
  보존해야 한다.
- `stargazers_count`가 0이면 유효한 값 0으로 보존해야 하며 누락과 혼동하지 않아야 한다.
- `html_url` 또는 `stargazers_count`가 누락되거나 타입이 계약과 다르면 성공 DTO를 만들지
  않고 디코딩 실패로 처리해야 한다.
- `topics`의 값과 순서는 GitHub가 반환한 그대로 보존해야 한다.
- 동일 응답에 `id`, `full_name`, `language`, `license` 등 사용하지 않는 필드가 포함되어도
  디코딩 결과에 영향을 주지 않아야 한다.
- URL 형식 오류는 upstream Domain UseCase가 API 호출 전에 판별하므로 Data 조회 계약은
  파싱된 `owner`와 `repo`만 받으며 `invalidURLFormat`을 생성하지 않는다.

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: `DataLearningProject`는 upstream에서 파싱된 `owner`와 `repo`를 입력받아
  GitHub Public Repository 메타데이터 조회를 표현하는 Data 소유 계약을 제공해야 한다.
- **FR-002**: 조회 요청 계약은 구체 HTTP 클라이언트 타입에 의존하지 않는 기술 중립적 명세로
  `GET https://api.github.com/repos/{owner}/{repo}`와 `Accept: application/vnd.github+json`,
  `X-GitHub-Api-Version: 2022-11-28`를 정확히 표현해야 한다.
- **FR-003**: GitHub 조회 요청에는 `Authorization` 헤더, Git-It access token, Git-It
  refresh token, Apple identity token을 포함하지 않아야 한다.
- **FR-004**: `GitHubRepositoryResponseDTO`의 서비스 소비 데이터는 `htmlURL: String`,
  `ownerAvatarURL: String?`, `starCount: Int`, `topics: [String]` 네 필드로 제한해야 한다.
- **FR-005**: 응답 계약은 `html_url → htmlURL`, `owner.avatar_url → ownerAvatarURL`,
  `stargazers_count → starCount`, `topics → topics`를 손실 없이 보존해야 한다.
- **FR-006**: `owner.avatar_url`이 누락되거나 `null`이어도 응답 디코딩이 성공하고
  `ownerAvatarURL`은 `nil`이어야 한다.
- **FR-007**: `topics`가 누락되거나 `null`이면 빈 배열로 처리하고, 값이 있으면 반환 순서를
  유지해야 한다.
- **FR-008**: 필수 데이터인 `html_url` 또는 `stargazers_count`가 누락되거나 호환되지 않는
  타입이면 성공 DTO를 생성하지 않아야 한다.
- **FR-009**: 응답에 서비스가 소비하지 않는 추가 JSON 필드가 존재해도 디코딩은 성공해야 하며,
  그 필드를 Data 공개 모델에 전달하지 않아야 한다.
- **FR-010**: `full_name`과 `language`는 현재 서비스에서 소비하지 않으므로
  `GitHubRepositoryResponseDTO`의 공개 저장 데이터에 포함하지 않아야 한다.
- **FR-011**: Repository 조회 실패는 Data 경계에서 `offline`과 `other`로 구분할 수 있어야
  하며, URL 형식 오류는 이 오류 계약에 포함하지 않아야 한다.
- **FR-012**: Data 오류 계약에서 `offline`은 네트워크 연결 실패만 의미하고, `other`는
  GitHub HTTP 404·403·5xx와 필수 응답 디코딩 실패를 포함한 나머지 모든 실패를 의미해야
  한다. HTTP 상태와 기술 오류를 이 값으로 실제 변환하는 책임은 포함하지 않아야 한다.
- **FR-013**: 실패 경로에서는 등록 가능한 성공 DTO를 생성하거나 반환하지 않아야 한다.
- **FR-014**: Data 구현은 Domain 모델을 참조하거나 `ExternalRepository`로 변환하지 않아야
  하며, 기술 중립적 요청 명세를 구체 HTTP 요청으로 변환하거나 전송하는 구현 및
  Data↔Infrastructure Adapter를 소유하지 않아야 한다.
- **FR-015**: Data target은 프로젝트 내부 패키지나 외부 라이브러리의 구체 API에 의존하지
  않고 독립적으로 빌드·테스트할 수 있어야 한다.
- **FR-016**: 성공, optional 데이터, 추가 필드, 필수 필드 누락, 요청 method/path/header,
  credential 미포함과 두 Data 오류 케이스의 구분을 자동화된 계약 테스트로 검증해야 한다.
  연결 실패, HTTP 404·403·5xx와 기술적 디코딩 실패의 실제 매핑 테스트는 이 기능에 포함하지
  않아야 한다.

### 핵심 엔터티

- **GitHub Public Repository 조회 계약**: 파싱된 `owner`와 `repo`를 받아 GitHub Public
  Repository endpoint의 method·path·header를 기술 중립적 요청 명세로 제공하고 응답 결과를
  Data 경계의 언어로 표현한다.
- **GitHubRepositoryResponseDTO**: canonical Repository URL, optional 소유자 이미지 URL,
  Star 수, 순서가 보존된 topics만 담는 최소 응답 데이터다.
- **DataExternalRepositoryError**: 네트워크 연결 실패를 `offline`, GitHub 404를 포함한
  나머지 실패를 `other`로 구분하는 Data 오류다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: 정상, 이미지 없음, topics 누락·`null`·빈 배열, 추가 필드 포함 fixture의
  디코딩 테스트가 100% 통과하고 네 개의 서비스 필요 필드 값 손실이 0건이다.
- **SC-002**: 구체 HTTP 클라이언트 없이 실행하는 요청 계약 테스트에서 method, path, 두 필수
  헤더가 모두 일치하고 `Authorization` 및 세 종류의 금지 credential이 포함되는 경우가 0건이다.
- **SC-003**: `GitHubRepositoryResponseDTO`의 서비스 소비 데이터가 네 필드로 제한되고,
  `full_name`, `language` 및 기타 미사용 GitHub 필드가 공개 데이터로 노출되는 경우가
  0건이다.
- **SC-004**: Data 오류 계약 테스트에서 `offline`과 `other` 두 케이스를 100% 구분하고,
  각 오류를 던지는 Remote 테스트 대역이 성공 DTO를 반환하는 사례가 0건이다.
- **SC-005**: `DataLearningProject` production target과 test target이 독립적으로 빌드·테스트
  대상에 포함되고, 이 기능의 자동화된 계약 테스트가 모두 통과한다.
- **SC-006**: 새 Data production 코드에서 프로젝트 내부 패키지 import, Domain 모델 참조,
  외부 라이브러리 구체 API 참조가 각각 0건이다.

## 가정

- 참조 문서 `U02-GITHUB-REPOSITORY-LOOKUP`의 endpoint, header와 wire field 계약이 구현
  시점에도 유효하다고 가정한다.
- URL 검증과 `owner`/`repo` 파싱은 기존 Domain `FetchExternalRepository`가 API 호출 전에
  수행하며, Data 계약에는 이미 파싱된 값만 전달된다고 가정한다.
- 유효한 `owner`/`repo`로 조회한 GitHub HTTP 404는 Data와 Domain 모두 `other`로 처리하며,
  URL에서 식별자를 추출하지 못한 경우만 upstream Domain의 `invalidURLFormat`으로 유지한다.
- Public Repository 조회는 인증 없이 수행하며 Private Repository 인증은 지원하지 않는다.
- 캐시, 영속화, 자동 재시도와 로깅 정책은 이번 Data 계약에 추가하지 않는다.

## 범위 밖

- GitHub URL 자동 보정 규칙의 변경(`.git` 제거, trailing path 처리 등)과 Domain
  `FetchExternalRepository` 수정
- `GitHubRepositoryResponseDTO`를 Domain `ExternalRepository`로 변환하는
  Domain↔Data Adapter
- 실제 HTTP 클라이언트로 요청을 전송하고 기술 오류를 Data 오류로 변환하는
  Data↔Infrastructure Adapter, 상태별 오류 매핑 테스트 및 App DI 배선
- Feature/UI의 입력 상태, 오류 문구, 재시도 흐름과 프로젝트 등록 화면
- Private Repository 인증, GitHub GraphQL, Repository 상세·branch·commit·issue·pull
  request 등 추가 API
