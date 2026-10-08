# 검증 가이드: 값을 더하지 않는 계층과 간접 참조 제거

이 문서는 구현이 명세를 충족하는지 확인하는 절차를 정의한다. 구현 코드는 담지 않는다.

## 사전 준비

```sh
cd sources
tuist generate --no-open
```

파일을 추가·삭제했으면 매번 다시 실행한다. `DerivedData/PreCommit/Build/Products`가 읽기 전용이 되어 Firebase modulemap 복사가 실패하면 `chmod -R u+w DerivedData/PreCommit/Build/Products`로 풀고 다시 빌드한다.

## 기준선 측정 (구현 시작 전 1회)

```sh
find sources/Projects -name "*.swift" -not -path "*/Tests/*" | wc -l
find sources/Projects -name "*.swift" -not -path "*/Tests/*" -print0 | xargs -0 grep -hE "^[[:space:]]*(public )?protocol " | wc -l
find sources/Projects/Data -path "*Contracts*" -name "*.swift" -not -path "*/Tests/*" | wc -l
find sources/Projects/Data -path "*/Tests/*" -name "*.swift" -print0 | xargs -0 grep -hE "#expect|#require" | wc -l
grep -rhoE "case \.[a-zA-Z]+" sources/Projects/Composition/Adapter/Adapters/*.swift | wc -l
```

다섯 값을 기록한다. 마지막 값은 어댑터의 오류 재매핑을 포함한 `case` 분기 총수이며, FR-008의 감소를 상대 비교로 확인하는 용도다.

## 시나리오별 검증

### 시나리오 1 — 프로토콜 생성 기준

1. `docs/conventions/README.md`의 표에서 프로토콜 생성 기준 항목을 찾는다.
2. 링크를 따라가 근거 A·B와 배제 규칙, 배제 시 대안이 모두 적혀 있는지 확인한다.
3. 아래 목록의 프로덕션 프로토콜을 하나씩 근거 A 또는 B에 대응시킨다. 대응되지 않는 항목이 남으면 실패다.

```sh
find sources/Projects -name "*.swift" -not -path "*/Tests/*" -print0 \
  | xargs -0 grep -nE "^[[:space:]]*(public )?protocol "
```

**기대 결과**: 남은 프로토콜 전부가 두 근거 중 하나에 대응되고, 그 대응이 기준선 문서에 기록되어 있다.

### 시나리오 2 — Data 계약 제거

```sh
find sources/Projects/Data -path "*Contracts*" -name "*.swift" -not -path "*/Tests/*" | sort
```

**기대 결과**: 목록에 `AuthenticationRemote`, `ExternalRepositoryRemote`, `AnswerRemote`, `BookmarkRemote`, `LearningSetRemote`, `ProjectRemote`, `QuizGenerationRemote`, `MemberRemote`, `PolicyConsentStore`가 없다. `GenerationStateStore`와 `QuizGenerationOutcomeSource`는 남아 있다.

```sh
grep -rn "AuthenticationRemote\|ExternalRepositoryRemote\|AnswerRemote\|BookmarkRemote\|LearningSetRemote\|ProjectRemote\|QuizGenerationRemote\|MemberRemote\|PolicyConsentStore" sources/Projects --include="*.swift"
```

**기대 결과**: `HTTP*Remote`·`LocalPolicyConsentStore` 같은 구체 타입 이름의 일부로 나타나는 경우 외에 프로토콜 이름 자체의 참조가 없다.

검증 항목 수가 줄지 않았는지 확인한다.

```sh
find sources/Projects/Data -path "*/Tests/*" -name "*.swift" -print0 | xargs -0 grep -hE "#expect|#require" | wc -l
```

**기대 결과**: 기준선 값 이상이다.

### 시나리오 3 — 오류 중복 정리

```sh
grep -rhoE "case \.[a-zA-Z]+" sources/Projects/Composition/Adapter/Adapters/*.swift | wc -l
```

**기대 결과**: 기준선 값보다 작다.

```sh
grep -rn "DataAuthenticationError\|DataLearningProjectError\|DataMemberError\|DataExternalRepositoryError" sources/Projects/Domain --include="*.swift"
```

**기대 결과**: 결과가 없다. Domain이 Data 오류 타입을 참조하지 않는다.

## 패키지별 테스트

```sh
cd sources
xcodebuild test -workspace GitIt.xcworkspace -scheme Data -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath DerivedData/PreCommit
xcodebuild test -workspace GitIt.xcworkspace -scheme Composition -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath DerivedData/PreCommit
```

## 전체 검증

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

**기대 결과**: 이 명세 적용 전에 통과하던 테스트가 모두 그대로 통과한다. 적용 전부터 실패하던 항목이 있으면 그 목록을 명시하고 변동이 없음을 확인한다.

## 수동 회귀

계약 제거는 동작을 바꾸지 않아야 한다. 아래 세 흐름을 실기기 또는 시뮬레이터에서 확인한다.

| 흐름 | 확인 |
| --- | --- |
| 로그인 | Apple 로그인으로 세션이 만들어지고 메인 화면에 진입한다 |
| 프로젝트 등록 | GitHub 저장소 URL로 등록이 시작되고 생성 진행 화면이 뜬다 |
| 약관 동의 | 최초 실행에서 약관 목록이 뜨고 동의 후 다시 묻지 않는다 |

## 기준선 기록 (구현 완료 후)

기준선 측정의 다섯 명령을 다시 실행해 적용 후 값을 얻고, 적용 전후 값과 남은 프로토콜별 존치 근거를 기준선 문서에 기록한다.
