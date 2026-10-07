# 빠른 시작: UI 패키지 디자인 규격 정렬 검증

**기능 브랜치**: `feature/ui-design-spec-alignment`

**날짜**: 2026-09-02

이 문서는 구현 결과를 검증하는 실행 가이드다. 값과 계약의 내용은
[contracts/](./contracts)와 [data-model.md](./data-model.md)를 참조하고 여기서 반복하지 않는다.

## 사전 준비

workspace가 없으면 먼저 생성한다.

```sh
make tuist
```

빌드·테스트 진입점은 저장소 경로 도구에서 읽는다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

기본 테스트 destination은 `platform=iOS Simulator,name=iPhone 17 Pro`이며
`GIT_IT_TEST_DESTINATION`으로 덮어쓴다.

## 1. 토큰 카탈로그 검증 (SC-001 ~ SC-003)

`DesignSystemTests` target이 화면 렌더링 없이 검사한다.

```sh
"$project_build_runner" test
```

**기대 결과**

- `DesignTokenSet.current.validate()`가 빈 배열을 반환한다.
- `BorderToken.all`·`OpacityToken.all`·`EffectToken.all`이 각각 6·6·2개다.
- 빈 배열인 토큰 카테고리가 하나도 없다.
- `EffectToken.sheetElevation.layers`가 2개다.
- 규격이 나열한 토큰 이름이 모두 존재한다.

실패하면 [design-token-catalog.md](./contracts/design-token-catalog.md)의 표와 대조한다.

`TextStyleToken`과 `FontFamilyToken`은 값을 바꾸지 않으므로 기존 값 그대로 통과해야 한다.
이 두 토큰에서 실패가 나면 의도치 않게 건드린 것이다.

## 2. 레이아웃 변수 범위 검증 (SC-004)

같은 테스트 실행에 포함된다. 지원 기기 9종의 입력을 표로 넣어 계산 결과가 규격의 min–max
범위 안에 있는지 검사한다.

| 기기 | 폭 × 높이 | safe area 상/하 |
| --- | --- | --- |
| iPhone SE 3 | 375 × 667 | 20 / 0 |
| iPhone 13 mini | 375 × 812 | 50 / 34 |
| iPhone 16e · 14 · 13 | 390 × 844 | 47 / 34 |
| iPhone 16 · 15 · 15 Pro | 393 × 852 | 59 / 34 |
| iPhone 17 · 17 Pro · 16 Pro | 402 × 874 | 62 / 34 |
| iPhone Air | 420 × 912 | 68 / 34 |
| iPhone 14 Plus · 13 Pro Max | 428 × 926 | 47 / 34 |
| iPhone 16 Plus · 15 Pro Max | 430 × 932 | 59 / 34 |
| iPhone 17 Pro Max · 16 Pro Max | 440 × 956 | 62 / 34 |

**기대 결과**: 양 끝 확인이 특히 중요하다. SE(20/0)에서 `topScrimHeight` = 70,
`tabBarBottomInset` = 24, `contentWidth` = 335, `contentBudget(.plain)` = 505,
`contentBudget(.largeTitle)` = 435, `sheetMaximumHeight` = 631이다. 17 Pro Max에서
`contentWidth` = 400, `gridColumn2` = 194, `contentBudget(.plain)` = 718,
`sheetMaximumHeight` = 878이다. Air(68/34)의 largeTitle에서 `topScrimHeight` = 188이다.

계산식은 [layout-metrics.md](./contracts/layout-metrics.md)를 참조한다.

## 3. 금지 패턴 검사 (SC-005 · SC-006 · SC-011 · SC-014)

```sh
design_rule_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_DESIGN_RULE_RUNNER)
"$design_rule_runner"
```

**기대 결과**: 종료 코드 0. 위반이 있으면 파일·행·규칙 이름을 출력한다.

규칙과 허용 예외는 [design-rule-checks.md](./contracts/design-rule-checks.md)에 있다.
`.frame(width:` 사용처는 착수 시점 56곳이며, 허용 목록에 등록되지 않은 곳이 남으면 실패한다.

검사기 자신의 회귀 테스트는 셸 테스트 러너가 실행한다.

```sh
./tools/script-tests/bin/run.sh
./tools/script-verification/bin/run.sh
```

## 4. 컴포넌트 계약 검증 (SC-007 · SC-009 · SC-010)

`UIComponentTests`가 검사한다. 1번과 같은 명령에 포함된다.

**기대 결과**

- 신설 4종(`Chip` · `PressOverlayStyle` · `BookmarkButton` · `ChoiceResultRow`)의 공개 생성
  경로와 상태별 표현이 규격과 일치한다.
- 조작 가능한 컴포넌트가 모두 44pt 이상의 터치 영역을 갖는다.
- 역할 폴더 6종 각각에 최소 1개의 테스트가 있다. 착수 시점에 `Scaffolds`와 `Displays`가
  0개이므로 이 둘이 새로 필요하다.

## 5. 전체 빌드와 회귀 (SC-012)

```sh
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

**기대 결과**: 세 명령이 모두 성공한다. UI 패키지뿐 아니라 Feature 패키지를 포함한 앱
전체가 컴파일된다. 토큰 공개 구조와 골격 컴포넌트 계약 변경으로 깨진 Feature 호출부가
복구되어 있어야 한다.

세 명령은 순차 실행을 전제로 `sources/DerivedData/PreCommit`을 공유한다. 병렬로 실행하지
않는다.

## 6. PR 본문의 화면 변경 목록 확인 (SC-015)

규격 적용으로 표시가 달라지는 항목이 변경 전후 값과 함께 **PR 본문**에 표로 있는지
확인한다. 저장소에 별도 문서 파일을 만들지 않는다. 최소 다음 세 건이 포함된다.

| 화면 | 값 | 변경 |
| --- | --- | --- |
| 프로젝트 등록 | `TextField` 높이 | 56 → 52 |
| 홈 | 2열 카드 폭 | 154 → `gridColumn2` (161.5 – 194) |
| 전 화면 | 상단 스크림 높이 | 103 고정 → `topScrimHeight` (70 – 188) |

같은 PR 본문에 규격 밖 15종의 유지·이동·삭제 판정과 근거도 함께 적는다(SC-008).

**타이포·폰트 항목은 이 목록에 오르지 않는다.** 현행을 유지하므로 표시가 달라지지 않는다.
명세의 "알려진 차이"에 적힌 두 건(숫자 폰트, 미번들 자산)은 이 기능의 검증 대상이 아니다.

## 7. 시각 확인 (선택)

자동 검증이 잡지 못하는 시각 결과는 Simulator에서 확인한다. 양 끝 기기를 보는 것이 목적이다.

```sh
GIT_IT_TEST_DESTINATION='platform=iOS Simulator,name=iPhone SE (3rd generation)' "$project_build_runner" test
```

SE(최소 폭·최소 높이·홈 인디케이터 없음)와 iPhone 17 Pro Max(최대)에서 스크림·탭바·시트가
어긋나지 않는지 확인한다.

## 실패 시 확인 순서

1. 토큰이 비어 있는가 — `DesignTokenSet.current.validate()`의 반환 목록을 먼저 본다.
2. 참조 무결성 위반인가 — 역할 토큰이 없는 원시 토큰을 가리키는 경우가 가장 흔하다.
3. 정본 고정값이 남았는가 — 금지 패턴 검사의 `canvas-constant` 규칙 출력을 본다.
4. Feature 호출부인가 — UI만 빌드되고 앱 전체가 실패하면 호출부 복구가 남은 것이다.
