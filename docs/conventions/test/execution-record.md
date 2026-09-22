# 실행 결과와 기록

[Git It iOS 테스트 컨벤션](../test.md)의 규칙 문서입니다.

테스트 컴파일과 테스트 실행은 서로 다른 검증 단계입니다.

```sh
project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" compile
"$project_build_runner" test
```

- `compile`의 성공은 `build-for-testing`의 컴파일·링크 성공만 의미합니다.
- 테스트 통과는 `test-without-building`에서 테스트 본문이 실행되고 결과가 성공했을 때만
  기록합니다.
- runner launch, preflight 또는 Simulator bootstrap 단계에서 실패해 테스트 본문에
  진입하지 못하면 제품 동작 실패로 단정하지 않습니다. scheme·test target·host 구성과
  Simulator 환경을 분리해 점검하고, 실행되지 않은 테스트를 통과로 기록하지 않습니다.
- PR에는 실제 실행한 명령, 성공·실패 단계, 실행된 테스트 수와 미검증 범위를 구분해
  기록합니다.
