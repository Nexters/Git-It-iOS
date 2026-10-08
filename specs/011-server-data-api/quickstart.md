# 빠른 시작: Git-It Server API 전체 Data 패키지 구현 검증

이 문서는 구현 완료 후 spec.md의 수용 시나리오와 성공 기준을 실제로 검증하는 절차다.
DTO·오류 상세는 [data-model.md](./data-model.md)와 [contracts/](./contracts)를,
HTTP method/path는 참조 문서 SPEC-DATA-API-001의 operation ID를 따른다.

## 사전 준비

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

workspace가 없으면 `sources`에서 `tuist generate`를 먼저 실행한다.

## 1. 빌드 검증(SC-007)

```sh
"$project_build_runner" build
```

`DataAuthentication`, `DataLearningProject`, `DataMember` 3개 production target과
`DataAuthenticationTests`, `DataLearningProjectTests`, `DataMemberTests` 3개 Tests
target이 공유 scheme으로 빌드되어야 한다.

## 2. 테스트 컴파일·실행(SC-003, SC-004, SC-005, SC-006)

```sh
"$project_build_runner" compile
"$project_build_runner" test
```

기대 결과:

- 19개 operation 각각의 request/response contract test가 통과한다.
- nullable 필드(예: `nextSetId`/`nextQuestionId`/`myAnswer` nil) fixture decoding이
  실패하지 않는다.
- 알려지지 않은 `QuizGenerationStatusResponseDTO.status` raw value fixture decoding이
  실패하지 않는다.
- `Tests/Authentication/Security`(또는 대응 위치)의 민감 값 노출 검증 테스트가 통과한다.

## 3. Operation completeness 확인(SC-001)

각 target의 Remote 프로토콜(`AuthenticationRemote`/`LearningProjectRemote`/
`MemberRemote`)이 선언한 메서드 수를 합산해 Auth 2 + Project 11 + Member 6 = 19임을
확인하는 completeness test가 다음을 출력해야 한다.

```text
Expected operation count: 19
Actual operation count:   19
Missing operations:       0
Unexpected product APIs:  0
```

Google 로그인은 `excludedOperations`로만 관리하며 unexpected로 판정하지 않는다.

## 4. 제외 대상 검색(SC-002, SC-008)

```sh
grep -rn "GoogleLoginRequestDTO\|googleLogin(\|GoogleLoginEndpoint" sources/Projects/Data
grep -rn "refreshSession\|revokeRefreshToken\|RefreshRequestDTO\|RefreshResponseDTO" sources/Projects/Data
```

두 명령 모두 결과가 0건이어야 한다(문서·`excludedOperations` 표기 제외).

## 5. Production target 순수성 확인(FR-016)

```sh
grep -rln "Mock\|Fixture" sources/Projects/Data/Authentication sources/Projects/Data/LearningProject sources/Projects/Data/Member 2>/dev/null
```

`Tests/` 하위 경로를 제외하고 결과가 없어야 한다.

## 6. 셸 스크립트를 변경한 경우

```sh
./tools/script-tests/bin/run.sh
./tools/script-verification/bin/prepare-tools.sh
./tools/script-verification/bin/run.sh
```

이 기능은 Swift 코드만 변경할 것으로 예상되므로 일반적으로 해당 없음.
