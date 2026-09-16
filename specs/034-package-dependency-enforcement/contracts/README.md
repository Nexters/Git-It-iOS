# 계약: 패키지 의존성 검사 도구

이 기능이 외부에 노출하는 인터페이스는 검사 도구의 명령 계약과 저장소 연동점이다.
Composition 조립 API 변화는 [data-model.md](../data-model.md) 3절에 있다.

## 1. 공개 진입점

| 항목 | 값 |
| --- | --- |
| 경로 키 | `GIT_IT_PACKAGE_DEPENDENCY_RUNNER` |
| 경로 | `tools/package-dependencies/bin/run.sh` |
| 인자 | 없음. 인자가 있으면 종료 코드 2와 `오류[common.invalid-input]` |
| 작업 디렉터리 | 무관. 자기 물리 경로에서 저장소를 해석한다 |
| 읽는 경로 키 | `GIT_IT_PROJECTS_ROOT`, `GIT_IT_TUIST_ROOT`, `GIT_IT_ARCHITECTURE_PATH` |
| 테스트 전용 입력 | `PACKAGE_DEPENDENCIES_CONFIG_DIR`(설정 디렉터리 덮어쓰기), `GIT_IT_PATHS_FILE`(경로 판독기 규약) |
| 외부 명령 | POSIX `sh`, `awk`, `sed`, `grep`, `find`, `sort`, `mktemp`. `rg`와 네트워크를 쓰지 않는다 |
| 부작용 | 호출별 임시 디렉터리만 만들고 종료 시 지운다. 저장소 파일을 쓰지 않는다 |

## 2. 종료 코드와 출력

| 종료 코드 | 의미 | stdout | stderr |
| --- | --- | --- | --- |
| 0 | 위반 없음 | `패키지 의존성 검사 완료: target=<N> 파일=<M> 위반=0` | 없음 |
| 1 | 규칙 위반 | 없음 | 위반 줄 목록 + 요약 오류 |
| 2 | 입력·설정·파싱 오류 | 없음 | `오류[package-dependencies.<종류>]: …` + `조치: …` |

위반 줄 형식(경로는 저장소 루트 기준, 정렬됨):

```text
<경로>:<줄>: [<규칙>] <이유>
```

예:

```text
sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift:31: [manifest-package] Feature target이 Data 패키지 모듈 DataMember를 선언함: Feature 허용 Domain, UI
sources/Projects/App/GitIt/GitItApp.swift:4: [import-undeclared] GitIt target manifest가 DomainMember를 선언하지 않음
docs/architecture.md:66: [table-mismatch] Composition: 표 Domain, Data, Infrastructure / 설정 Domain, Data
```

요약:

```text
오류[package-dependencies.violated]: 위반 <N>건
조치: 위 선언이나 import를 아키텍처 3.1 표가 허용하는 방향으로 고치거나, 표와 config/allowed-dependencies를 함께 바꾸세요
```

규칙과 오류 종류의 정의는 [data-model.md](../data-model.md) 1.8·1.9절이 정본이다.

## 3. 설정 파일

| 파일 | 형식 | 정본 |
| --- | --- | --- |
| `tools/package-dependencies/config/allowed-dependencies` | `<패키지>: <허용 패키지…>` | data-model 1.1 |
| `tools/package-dependencies/config/source-roots` | `<target> <GIT_IT_PROJECTS_ROOT 기준 루트>` | data-model 1.6 |

두 파일 모두 `#` 주석과 빈 줄을 허용한다. target을 추가·이름 변경하면 `source-roots`도 같은
커밋에서 바꿔야 하며, 빠뜨리면 검사가 종료 코드 2로 알려준다.

## 4. 저장소 연동점

| 연동점 | 계약 |
| --- | --- |
| `tools/githooks/pre-commit` | 단계 이름 `package-dependencies`를 허용하고 `script-tests → swift-format → design-rules → package-dependencies → build → compile` 순서로 실행 |
| `tools/githooks/pre-commit.d/package-dependencies.sh` | 인자 없이 `GIT_IT_PACKAGE_DEPENDENCY_RUNNER`를 실행하고 종료 코드를 그대로 전파 |
| `tools/githooks/pre-commit.d/enabled` | 단계 이름을 주석 처리 상태로 등재. 활성화는 명세 범위 밖 |
| `.github/workflows/ci.yml` | `package-dependencies` job. `vars.GIT_IT_CI_VALIDATION_ENABLED == 'true'`면 변경 분류와 무관하게 실행. `gate`의 `needs`와 `gate-evaluate.sh` 인자에 결과 포함 |
| `tools/script-tests/bin/run.sh` | `tools/package-dependencies/tests/test-*.sh`를 자동 수집 |
| `tools/script-verification/bin/run.sh` | `VERIFICATION_SCRIPT_TARGETS`에 `tools/package-dependencies` 포함 |
