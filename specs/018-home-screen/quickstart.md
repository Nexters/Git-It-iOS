# 빠른 시작: 홈 화면과 MainShell 4탭 통합

## 1. 사전 확인

```sh
git branch --show-current
git status --short
tools/spec-kit/bin/resolve-feature.sh --json
tools/spec-kit/bin/validate.sh
```

기대 브랜치는 `feature/home-screen`, 활성 명세는 `specs/018-home-screen`이다. 기존 사용자
변경은 보존하고 구현 단위의 정확한 파일만 수정·stage한다.

## 2. 구현 순서

1. **UI**: `HomeProjectCard`의 색과 회전 책임을 분리하고 본문·재생 콜백을
   독립 계약으로 추가한다.
2. **Feature**: `HomeFeature`, `HomeScreen`, `HomeCardScrollLayout`, Preview·Test Double을
   추가하고 MainShell에 네 탭과 Home Scope를 연결한다.
3. **App**: MainShell의 Home intent를 명시적 no-op으로 수신하고 route 불변을 테스트한다.

각 단계를 끝낼 때 해당 패키지의 변경 파일과 검증 결과를 확인한 뒤 다음 단계로
진행한다. 현재 의존 구조는 다중 패키지 integration unit을 필요로 하지 않는다.

## 3. 생성과 자동 검증

```sh
make tuist

project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile-unit
"$project_build_runner" test-unit
```

- `build`는 공유 scheme의 production Debug build다.
- `compile-unit`는 unit test scheme의 build-for-testing이다.
- `test-unit`는 앞서 생성한 제품을 사용하는 test-without-building이다.
- 세 결과를 하나의 “테스트 통과”로 합치지 않고 각각 보고한다.
- `make tuist`와 검증 실행 전후 `git status --short`를 비교해 추적 소스·문서·index가
  의도치 않게 변하지 않았는지 확인한다.

## 4. 집중 자동 검증 항목

### UI

- `HomeProjectCard.Variant(index:)`의 Domain 순서 기반 3색 순환.
- `currentSetLabel`이 파싱·손실 없이 표시 계약에 전달됨.
- 본문·재생 콜백의 배타성, disabled 학습, 44pt 터치 계약.
- variant가 rotation을 소유하지 않음.

### Feature

- 최초 task의 profile/project 각 1회 조회와 탭 복귀 시 0회 추가 조회.
- 프로필·프로젝트 독립 성공·실패 조합과 프로필만 재시도.
- request ID가 다른 stale 응답의 변경 0건.
- empty와 project failure의 동일 표시 분기, profile failure의 헤더 내 retry.
- 네 탭 순서·Home 기본·`showAllProjectsTapped` 전이·로그아웃 초기화.
- Domain ID의 등록·상세·학습 delegate payload와 무효한 학습 ID의 delegate 0회.
- `P0/P1/P2`, 중간점, clamp의 각도 오차 `±0.5°`.

### App

- Home delegate가 AppRoot route·destination을 변경하지 않음.
- sign-out, account deletion, session invalidation, reset 후 MainShell 재진입이 Home으로 시작함.

## 5. Preview와 수동 검증

`Home/Previews/`의 다음 상태를 iPhone 17 Pro 기준으로 실행한다.

- `Project Present - 1465:19015`
- `Project Absent - 1542:19610`
- `Loading`
- `Project Failure as Empty - 1542:19610`
- `Profile Failure`

수동 체크:

1. Figma의 색·타이포·자산·간격과 기존 DesignSystem token 대응을 확인한다. 차이는 수정하거나
   사용자가 명시적으로 승인하고 검증 결과·PR에 차이·근거·영향·미검증 범위를 기록한다.
2. 카드를 천천히 이동해 앵커 각도·선형 보간·색 고정을 확인한다.
3. 빠른 drag 후 관성 감속과 `P0 ± 1pt` 스냅을 확인한다.
4. 카드 본문과 재생 control에서 시작해 SwiftUI `ScrollView`가 scroll로 인식한 접촉이
   intent를 발생시키지 않는지 확인한다.
5. VoiceOver로 프로필·CTA·전체 보기·본문·재생·네 탭과 선택 상태를 구분한다.
6. iOS 26 `DynamicTypeSize` 전체 12단계(`xSmall`~`accessibility5`)와 긴 이름·기술 스택·세트
   제목에서 핵심 동작을 사용한다.

## 6. 완료 판정

- `tools/spec-kit/bin/validate.sh`가 통과한다.
- build, test compile, test execution 결과가 각각 기록된다.
- Home production Feature source의 Data·Infrastructure·Composition import, `@Dependency` 기반
  Use Case 조회와 새 Avatar Backend·Domain 계약이 각각 0건임을 정적 검사로 확인한다.
- Figma·스냅·drag·VoiceOver·Dynamic Type 수동 항목의 실행 여부와 결과가
  실제 수행 사실대로 구분된다.
- 미승인 Figma 차이가 하나라도 남으면 완료로 판정하지 않는다.
- 구현하지 않은 등록·ProjectDetail·Quiz destination을 완료로 보고하지 않는다.
