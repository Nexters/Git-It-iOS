# 빠른 검증: Domain·Data·Infrastructure 설계 점검과 문서·네이밍 교정

모든 명령은 저장소 루트에서 실행한다. 항목 구조는 [data-model.md](./data-model.md), 문서 형식은
[contracts/review-record.md](./contracts/review-record.md), 실측 목록은
[research.md](./research.md)를 참고한다.

## 준비

```sh
paths=./tools/repository-paths/bin/repository-paths.sh
build="$("$paths" GIT_IT_PROJECT_BUILD_RUNNER)"
depcheck="$("$paths" GIT_IT_PACKAGE_DEPENDENCY_RUNNER)"
base=b424b27   # 기능 브랜치 생성 시점 commit(research.md). origin/develop는 303커밋 뒤라 merge-base를 쓰지 않는다
```

빌드·테스트(`"$build" build|compile|test`)는 사용자가 직접 실행한다.

## 시나리오 1: 점검 결과를 재현할 수 있다 (S1, SC-001·SC-007)

```sh
review=docs/review/domain-data-infra-design-review.md
grep -cE '^\| (DOC|RN|DS|OK)-[0-9]+ ' "$review"
grep -nE 'AuthenticationOutcome|HTTPUserRemote|Composition Adapter|Data[A-Z][A-Za-z]+Error|APIResponseDTO|HTTPMethod|InfrastructureAuthentication|ExternalRepositoryLocation' "$review"
```

기대: 첫 명령이 항목 수를 출력하고, 둘째 명령이 배경 예시 5건과 `ExternalRepositoryLocation`
쌍을 각각 1행 이상 찾는다. 임의의 항목을 골라 `대상 위치`를 열면 `불일치`가 그대로 보인다.

## 시나리오 2: 규칙 문서가 현재 구조를 설명한다 (S2, SC-010)

```sh
grep -n 'HTTPUserRemote\|UserRemote' docs/architecture.md
grep -n 'Composition의 Adapter\|Composition Adapter가' docs/package-rules/infrastructure.md
grep -n 'AuthenticationOutcome' sources/Projects/Domain/Authentication/README.md
grep -n 'D-ARCH-004' docs/architecture.md
```

기대: 앞 세 명령은 0건, 마지막은 1건 이상. 아키텍처 2장·3.3·9장, 패키지 규칙 3개, 네이밍
4장 표가 FR-017과 같은 결론을 낸다(수용 시나리오 2-3·2-4는 사람이 읽어 확인).

## 시나리오 3: rename이 동작 없이 이름만 바꿨다 (S3, SC-003·SC-004·SC-005·SC-006)

```sh
git grep -nE 'DataAuthenticationError|DataMemberError|DataLearningProjectError|DataExternalRepositoryError|HTTP(Authentication|ExternalRepository|Answer|Bookmark|LearningSet|Project|Member)Remote|LearningProjectHTTPExecutor|SessionRecordKeychainCoding|SessionKeychainMigration|SessionKeychainLayout|AppleIdentityKeychainLayout|AppleIdentityKeychainStore|PendingGenerationReminderStore|GenerationReminderRegistry|NotificationAuthorizationGateway|ExternalRepositoryURLParser|StoredSessionRepository|SharedSessionMarkerRepository' -- sources docs ':!docs/spec-kit' ':!docs/retrospective' ':!docs/review/*-requirements.md'
git diff --stat "$base" -- 'sources/Projects/*/Tests/**' && git diff "$base" -- 'sources/Projects/*/Tests/**' | grep -E '^[-+]' | grep -vE '^(\+\+\+|---)' | grep -vE 'Remote|Error|Keychain|Storage|Store|Registry|Registration|Gateway|Authorization|Parser|Locator|Session|load\(|save\(|currentState\(|record\('
"$depcheck"
git diff --stat "$base" -- sources/Tuist/ProjectDescriptionHelpers/Projects/
git ls-files 'sources/Projects/**/*.swift' | grep -v '/Tests/' | xargs grep -hE '^[[:space:]]*(public )?protocol ' | wc -l
```

기대: 옛 이름은 `docs/review/domain-data-infra-design-review.md`의 옛 이름 열 외 0건, 의존성
검사 위반 0, manifest diff 없음(target rename이 없을 때), 프로토콜 수 47(구조 기준선과 동일).
마지막 명령(SC-004 "변경 전후 동일")은 테스트 diff에서 이름 치환에 해당하지 않는 변경 줄을
출력하며, 기대는 0줄이다. 출력이 있으면 그 줄이 기대값 변경이 아닌지 사람이 확인한다. 옛 이름
목록은 구현 시 확정된 rename 표(`RN-*`)로 갱신한다.

저장·전송 값 불변(FR-010):

```sh
git diff "$base" -- 'sources/Projects/Data/**/Layouts/*.swift' 'sources/Projects/Data/**/Codings/*.swift' | grep -E '^[-+].*(rawValue|= "|case .* = )'
```

기대: 출력이 있으면 그 줄이 key 문자열 변경이 아니라 타입 이름 변경인지 사람이 확인한다.

## 전체 검증(마지막 단위)

1. `"$build" build && "$build" compile && "$build" test` — 사용자 실행.
2. 위 시나리오 1~3 명령.
3. `./tools/script-tests/bin/run.sh`와 `./tools/script-verification/bin/run.sh` — 셸을 바꾸지
   않았으므로 통과 확인만.
4. 점검 결과 문서 2.5 표에 실제 결과를 적는다.
