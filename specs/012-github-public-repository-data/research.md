# 조사: GitHub Public Repository Data 계약

**날짜**: 2026-08-21 | **명세**: [spec.md](./spec.md)

## 결정 1: 명세가 고정한 GitHub Repository endpoint와 API version을 명시적으로 보존한다

- **결정**: 요청 계약은 `https://api.github.com`, `GET`, `/repos/{owner}/{repo}`,
  `Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`을 고정값으로
  제공한다. `Authorization`은 포함하지 않는다.
- **근거**: GitHub 공식 [Get a repository 문서](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#get-a-repository)는
  공개 리소스 조회가 인증 없이 가능하고 해당 path와 Accept 값을 안내한다. 공식
  [API Versions 문서](https://docs.github.com/en/rest/about-the-rest-api/api-versions)는
  `X-GitHub-Api-Version`으로 버전을 지정하도록 하며, 2026-08-21 현재 `2022-11-28`을
  2028-03-10까지 지원한다고 명시한다. 이는 spec.md FR-002~003의 고정 계약과 일치한다.
- **검토한 대안**: 최신 `2026-03-10`으로 갱신 — 이번 명세가 `2022-11-28`을 명시했고 버전
  전환에 따른 응답 호환성 검증은 별도 변경이므로 기각한다. GitHub token 추가 — Public
  Repository 전용 보안 경계를 위반하므로 기각한다.

## 결정 2: unauthenticated rate limit은 요청 모델에 정책을 추가하지 않고 `other` 범주로 남긴다

- **결정**: 요청 계약에 token, retry, throttle 또는 rate-limit 상태를 추가하지 않는다. 후속
  Composition Adapter가 rate limit 실패를 `other`로 분류하며, 이 기능은 그 매핑을 구현하거나
  검증하지 않는다.
- **근거**: GitHub 공식 [REST API rate limits 문서](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)는
  unauthenticated 요청을 IP 기준 시간당 60회로 제한한다. 하지만 이번 Data 범위는 전송과
  상태 매핑을 구현하지 않으며 spec.md가 재시도·로깅 정책을 범위 밖으로 정했다.
- **검토한 대안**: 인증을 추가해 한도를 높임 — credential 미전송 요구와 충돌한다. Data에
  재시도 정책 추가 — 실제 HTTP 실행 책임이 없어 배치할 수 없다.

## 결정 3: `GitHubRepositoryRequest`가 완성된 기술 중립 요청 값을 불변으로 소유한다

- **결정**: public 생성자는 `owner`와 `repository`만 받고 `scheme`, `host`, `method`, `path`,
  `headers`를 고정해 만든다. 각 값은 Swift Standard Library 타입(`String`,
  `[String: String]`)으로 공개하며 `Equatable`, `Sendable`을 채택한다. arbitrary header를
  받는 생성자는 제공하지 않는다.
- **근거**: Data가 endpoint 전체를 소유한다는 명확화 결과를 표현하면서도
  Infrastructure의 `URL`, `HTTPRequest`, `HTTPMethod`, `HTTPHeaders`를 참조하지 않아 독립
  경계를 유지한다. 생성 경로를 제한하면 `Authorization`이나 Git-It/Apple credential이
  섞이는 잘못된 상태를 만들 수 없다.
- **검토한 대안**: absolute URL 하나만 제공 — scheme·host·path를 각각 검증하는 명세 기준을
  약화한다. Infrastructure HTTP 타입 재사용 — Data→Infrastructure 의존 금지. base URL을
  Composition에서 주입 — 명확화 답변과 충돌한다.

## 결정 4: `GitHubRepositoryResponseDTO`는 읽기 전용 부분 `Decodable` 모델로 둔다

- **결정**: DTO는 `Decodable`, `Equatable`, `Sendable`을 채택하고 `htmlURL`,
  `ownerAvatarURL`, `starCount`, `topics`만 공개한다. custom `init(from:)`에서 필수 `owner`
  nested container를 먼저 요구하고 `avatar_url`은 `decodeIfPresent`, `topics`는
  `decodeIfPresent ?? []`로 처리한다. 공개 memberwise initializer는 Test Double과 상위
  Adapter가 값을 구성할 수 있게 유지한다.
- **근거**: Swift `Decodable`은 선언하지 않은 추가 키를 무시하므로 전체 GitHub schema를
  복제할 필요가 없다. required nested container는 `owner` 누락·`null`을 실패시키고, 그
  내부 optional key만 `nil`로 허용해 명확화 답변 B를 그대로 표현한다.
- **검토한 대안**: `Codable` 채택 — 응답을 GitHub wire 형식으로 다시 인코딩할 요구가 없어
  불필요하다. `OwnerDTO`를 public 타입으로 노출 — 서비스가 소비하지 않는 중간 wire 구조가
  공개 API에 남으므로 기각한다. `full_name`·`language` 유지 — FR-010과 충돌한다.

## 결정 5: Remote 계약은 기존 경계명과 표준 `throws`를 유지한다

- **결정**: `ExternalRepositoryRemote: Sendable`이
  `repository(_ request: GitHubRepositoryRequest) async throws -> GitHubRepositoryResponseDTO`
  하나만 제공한다. 현재 기능은 `DataExternalRepositoryError.offline`과 `.other`의 의미와 Test
  Double을 통한 손실 없는 전달을 계약으로 고정한다.
- **근거**: `ExternalRepositoryRemote`는 과거 007/008 설계와 Composition Adapter 계약에서
  사용된 Data 경계명이며 현재 Domain의 외부 Repository 조회 책임과 연결된다. 기존 Data
  계약(`LoginSessionRemote`)도 표준 `throws`를 사용한다. 실제 기술 오류를 두 케이스로
  변환하는 구현은 Composition 범위이므로 이 기능은 오류 타입과 Test Double 계약만 제공한다.
- **검토한 대안**: typed throws — 기존 Data 계약 및 007의 표준 throws 결정과 달라지고 현재
  명세가 요구하지 않는다. `GitHubRepositoryRemote`로 rename — 기존 후속 Adapter 계약과의
  불필요한 이름 단절을 만들므로 기각한다.

## 결정 6: `DataExternalRepositoryError` 이름은 실제 계층 간 충돌을 구분하는 문맥으로 유지한다

- **결정**: `CaseIterable`, `Equatable`, `Error`, `Sendable`인 연관값 없는 `offline`, `other`
  열거로 둔다.
- **근거**: Composition은 Domain의 `ExternalRepositoryError`와 Data 오류를 동시에 다루므로
  `Data`는 단순 소속 표시가 아니라 두 경계를 구분하는 실제 문맥이다. 명세의 핵심 엔터티와
  기존 007/008 계약도 이 이름을 사용한다.
- **검토한 대안**: `ExternalRepositoryError` — Composition에서 Domain 타입과 충돌한다.
  `GitHubRepositoryError` — 오류 의미를 공급자 wire 상태에 과도하게 결합하고 명세의 Data
  경계명을 변경하므로 기각한다.

## 결정 7: 기존 Data target·scheme을 재사용하고 placeholder만 교체한다

- **결정**: production은 `sources/Projects/Data/LearningProject/`, 테스트는
  `sources/Projects/Data/Tests/LearningProject/`에 둔다. 기존 placeholder 두 파일을 제거하고
  `DataModuleName`, `ProjectName.Data` scheme과 `Project.swift`는 수정하지 않는다.
- **근거**: 현재 manifest가 `DataLearningProject`와 `DataLearningProjectTests`를 각각 위
  source root에 연결하고 Data 공유 scheme의 build/test action에도 포함한다. 새 target이나
  공용 구성 변경 없이 독립 빌드·테스트 조건을 이미 충족한다.
- **검토한 대안**: 새 target 또는 target 이름을 반복한 폴더 생성 — 기존 sourceDirectory
  규칙과 테스트 컨벤션을 위반하고 중복 구성을 만든다.

## 결정 8: 테스트는 네 계약 묶음으로 분리하고 실제 네트워크를 호출하지 않는다

- **결정**: Request, DTO, Error, Remote별 Swift Testing 파일을 둔다. JSON fixture는 테스트에
  포함하고 `Foundation.JSONDecoder`로 디코딩한다. Remote는 actor Probe/Test Double로 호출,
  반환, 두 오류 경로와 성공 DTO 미반환을 검증한다.
- **근거**: Data 패키지 규칙은 외부 기술 기능을 Test Double로 대체하고 target을 독립 실행할
  것을 요구한다. 이 기능에는 HTTP Adapter가 없으므로 live GitHub 호출은 Data 계약의 검증
  범위를 넘어선다.
- **검토한 대안**: live API 통합 테스트 — rate limit·네트워크 상태에 따라 비결정적이고
  credential 금지 경계를 검증하는 수단으로 부적절하다.

## 결정 9: 포맷과 패키지 검증을 완료한 뒤 전체 읽기 전용 검증을 실행한다

- **결정**: 정확한 구현 allowlist의 변경 Swift 파일을 `GIT_IT_SWIFT_FORMAT_RUNNER`로 먼저
  포맷한다. 그 뒤 Data 공유 scheme을 `sources/DerivedData/Feature012`에서 집중 검증하고 결과를
  보고한 다음, 공개 project build runner의 전체 build chain을 실행한다. 전체 검증 전후 Git
  추적 파일 상태가 같아야 완료로 판정한다.
- **근거**: 빌드 중 Swift Style 플러그인이 포맷을 적용할 수 있으므로 명시적 포맷을 앞세워
  전체 검증의 변경 가능성을 제거해야 한다. 별도 DerivedData는 Data 집중 검증과 저장소 전체
  `sources/DerivedData/PreCommit` chain의 산출물을 분리한다.
- **검토한 대안**: 전체 build chain을 Data 결과 보고 전에 실행 — 마지막 패키지 완료 뒤에만
  전체 읽기 전용 검증을 허용하는 Constitution과 충돌한다. destination 고정 —
  `GIT_IT_TEST_DESTINATION`을 사용하는 저장소 검증 규칙과 불일치하므로 기각한다.
