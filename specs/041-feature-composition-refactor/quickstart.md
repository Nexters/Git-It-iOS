# 빠른 시작: 검증 절차

**기능**: [spec.md](./spec.md) · **계획**: [plan.md](./plan.md)

이 문서는 각 작업 단위와 최종 상태를 검증하는 방법이다. 구현 세부는 `tasks.md`와 구현 단계가
소유한다.

## 사전 조건

- 브랜치 `feature/feature-composition-refactor`가 checkout되어 있다.
- workspace가 있다. 없으면 `make tuist`로 만든다.
- 테스트 destination 기본값은 `platform=iOS Simulator,name=iPhone 17 Pro`이다. 다른 기기를 쓰려면
  `GIT_IT_TEST_DESTINATION`을 지정한다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

## 1. 단위별 검증

각 단위(U1~U11)를 커밋하기 전에 순서대로 실행한다. 세 명령은 `sources/DerivedData/PreCommit`을
공유하므로 병렬로 실행하지 않는다.

```sh
"$project_build_runner" compile   # 모든 단위
"$project_build_runner" test      # 테스트를 옮기거나 추가한 단위
```

**기대 결과**

- compile과 test가 모두 성공한다. 실패하면 구성·컴파일·테스트·Simulator 환경 중 어디서 실패했는지
  구분해 기록한다([테스트 실행 기록](../../docs/conventions/test/execution-record.md)).
- 테스트를 옮긴 단위는 [research.md §6](./research.md#6-단언-이관-대응표-sc-011)에 대응표 행을 채운다.
  이관 전 `@Test` 하나마다 이관 뒤 위치가 있다.

## 2. 단위별 구조 점검 (리뷰 대조)

자동 검사가 없으므로 다음 조회 결과를 리뷰에서 대조한다(FR-020, FR-022). 명령은 읽기 전용이다.

```sh
cd sources/Projects/Feature
# 공용 디렉터리가 흐름 디렉터리 타입을 참조하지 않는가 (SC-010)
grep -rnE 'HomeFeature|SettingsFeature|TutorialFeature|MainShellRouter|ProjectListFeature|ProjectDetailFeature' Shared/
# 공용 Reducers에 View가 없는가 (SC-015)
grep -rn ': View' Shared/Reducers/
# @Shared·@Dependency를 쓰지 않는가 (FR-012, FR-026)
grep -rnE '@Shared|@Dependency' --include='*.swift' . | grep -v '/Derived/'
```

**기대 결과**: 세 명령 모두 출력이 없다.

화면 디렉터리 간 참조(SC-010)는 [research.md §3.7](./research.md#37-전체-분류-리팩토링-완료-후-예정-sc-007)의
분류표를 기준으로 리뷰어가 확인한다. 각 화면 폴더의 파일이 다른 화면 폴더의 타입을 참조하지
않는지 본다.

## 3. 최종 검증 (U12)

```sh
"$project_build_runner" build     # 모든 공유 scheme Debug 빌드 (SC-005)
"$project_build_runner" compile   # build-for-testing
"$project_build_runner" test      # test-without-building
```

**기대 결과**

- 세 명령이 모두 성공한다(SC-005).
- Feature 테스트가 모두 통과한다. 이관 대응표에 빈 행이 없다(SC-002, SC-011).
- 분류표의 39개 Reducer가 모두 하나의 분류에 속한다(SC-007).
- `docs/conventions/tca/feature.md`가 분해 기준을 싣고 `docs/conventions/tca/feature/classification.md`를
  링크한다. 분류 문서에는 최종 분류, 제외 사유(E1~E8)와 동작 차이 목록(research §4)이 있다(SC-009).
- 동작 차이는 research §4의 "의도한 차이" 항목에 한정되며, 각 항목을 고정하는 테스트가 있다(SC-002).

## 4. 셸 스크립트

이 기능은 셸 스크립트를 변경하지 않는다. `tools/**`의 스크립트 검증은 실행 대상이 아니다.
