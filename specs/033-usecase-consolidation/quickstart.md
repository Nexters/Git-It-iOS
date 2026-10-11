# 빠른 시작: Domain UseCase 분해 기준 확정과 통합

## 전제

`sources`에서 workspace가 생성되어 있어야 한다. 없으면 `make tuist`를 먼저 실행한다.

## 기준선 측정

적용 전에 실행해 값을 `tasks.md`의 "기준선 기록" 절에 남긴다.

```sh
# 프로덕션 UseCase 파일 수
find sources/Projects/Domain -path '*UseCases*' -name '*.swift' -not -path '*/Tests/*' | wc -l

# UseCase 프로토콜 수
git ls-files 'sources/Projects/Domain/**/UseCases/**/*.swift' | xargs grep -l '^public protocol' | wc -l

# MainShellRouterFeature Domain 의존성 파라미터 수
sed -n '/public init(/,/) {/p' sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift | grep -c 'UseCase\|URLParser'

# AppComposition Domain 의존성 공개 개수
grep -c 'public let [a-zA-Z]*: any .*UseCase' sources/Projects/Composition/App/Assemblies/AppComposition.swift
```

## 시나리오별 검증

### 시나리오 1 — 분해 기준을 문서에서 확인할 수 있다

```sh
grep -n '분해 기준' docs/package-rules/domain.md
```

**기대 결과**: 독립 타입으로 둘 두 조건(판단·조율·보상·동시성 제어 수행, 둘 이상의 계약
조합)이 검증 가능한 문장으로 적혀 있다.

```sh
git ls-files 'sources/Projects/Domain/**/UseCases/**/*.swift' | xargs grep -l '^public protocol'
```

**기대 결과**: 목록의 모든 항목이 [data-model.md](./data-model.md) 2.1의 독립 유지 목록
또는 신설 통합 계약 둘 중 하나다.

### 시나리오 2 — 변경 연산의 순서 보장이 계약 안에 있다

```sh
grep -rn 'MutationSerializer' sources/Projects --include='*.swift'
```

**기대 결과**: 결과가 없다.

```sh
cd sources
xcodebuild test -workspace GitIt.xcworkspace -scheme Domain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath DerivedData/PreCommit
```

**기대 결과**: 회원 정보 변경과 북마크 변경의 동시 호출 순서 보장 테스트가 통합 계약
기준으로 통과한다.

### 시나리오 3 — 주입 배관이 줄어든다

```sh
sed -n '/public init(/,/) {/p' sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift | grep -c 'UseCase'
grep -c 'public let [a-zA-Z]*: any .*UseCase' sources/Projects/Composition/App/Assemblies/AppComposition.swift
```

**기대 결과**: 각각 10 이하, 17 이하.

```sh
grep -rn 'LearningLibraryUseCase\|MemberAccountUseCase' sources/Projects/Feature --include='*.swift' | grep -v 'Router'
```

**기대 결과**: 결과가 없다. 통합 계약은 Router까지만 쓰고 말단 화면 Feature에는 전달하지
않는다([research.md](./research.md) 8절).

### 시나리오 4 — 사라진 타입의 흔적이 없다

```sh
grep -rn 'VerifyAccessTokenUseCase\|RegisterMemberDeviceUseCase\|FetchLearningProjectDetailUseCase\|DeleteLearningProjectUseCase\|FetchLearningSetUseCase\|FetchBookmarkedQuestionsUseCase\|FetchMemberProfileUseCase\|UpdateMemberPositionUseCase\|UpdateMemberCareerLevelUseCase\|CompleteCurationUseCase' sources/Projects --include='*.swift'
```

**기대 결과**: 결과가 없다.

```sh
find sources/Projects/Domain -path '*UseCases*' -type d -empty
```

**기대 결과**: 결과가 없다.

## 패키지별 테스트

```sh
cd sources
for scheme in Domain Composition Feature AppTests; do
  xcodebuild test -workspace GitIt.xcworkspace -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -derivedDataPath DerivedData/PreCommit
done
```

`Feature`와 `AppTests`에는 이 명세 시작 전부터 존재하는 실패가 있다. 판정 기준은 그 목록이
늘지 않는 것이다.

## 전체 검증

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

**기대 결과**: `build` 9/9, `compile` 7/7 성공. `test`는 시도 7 중 성공 5 실패 2로 이 명세
시작 전과 같다.

## 수동 회귀

사용자 관찰 동작이 바뀌지 않았음을 확인한다.

1. **프로젝트 상세와 삭제** — 프로젝트 목록에서 상세로 들어가고, 삭제한 뒤 목록에서 사라지는지
   확인한다.
2. **학습 세트 풀이** — 세트에 들어가 객관식과 주관식을 제출하고 결과가 반영되는지 확인한다.
3. **북마크 토글** — 같은 문제의 북마크를 빠르게 두 번 눌러 최종 상태가 마지막 입력과 같은지
   확인한다.
4. **회원 정보 변경** — 설정에서 직군과 연차를 연속으로 바꾸고 프로필에 마지막 값이 반영되는지
   확인한다.
5. **온보딩 큐레이션** — 신규 로그인 후 직군·연차 선택을 완료하면 메인으로 진입하는지 확인한다.
