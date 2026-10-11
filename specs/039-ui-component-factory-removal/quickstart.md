# 검증 가이드: UIComponent 정적 팩토리 제거

**기능**: [spec.md](./spec.md) | **계약**: [contracts/component-creation-api.md](./contracts/component-creation-api.md)

각 작업 단위가 끝날 때와 기능 전체가 끝날 때 무엇을 실행해 무엇을 확인하는지 정리한다.

## 전제

```sh
cd sources && tuist generate
```

workspace가 이미 있으면 생략한다. 아래 명령은 저장소 루트에서 실행한다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

## 1. 작업 단위마다 (컴포넌트 하나 전환 직후)

### 1.1 컴파일

```sh
"$project_build_runner" compile
```

**기대**: 성공. 실패하면 그 컴포넌트의 호출부 전환이 끝나지 않은 것이다. UI의 팩토리 제거와
Feature 호출부 수정이 같은 커밋에 들어가야 한다(FR-006).

### 1.2 팩토리 잔존 확인

전환한 컴포넌트 이름으로 실행한다.

```sh
grep -rn "public static func" sources/Projects/UI/Component/<경로>/<컴포넌트>.swift
```

**기대**: 출력 없음.

```sh
grep -rnE "<컴포넌트>\.(팩토리이름1|팩토리이름2)\b" sources/Projects/UI sources/Projects/Feature
```

**기대**: 출력 없음. 프리뷰와 테스트 파일도 포함해 남지 않아야 한다(FR-007).

## 2. 표현 불변 확인

`UIComponentPreviewApp` target으로 전환한 컴포넌트의 프리뷰를 열어 변형·크기·상태별 렌더링이
전환 전과 같은지 확인한다. 프리뷰는 모든 시각 변형을 포함해야 한다
([View 컨벤션 — 프리뷰](../../docs/conventions/view/preview.md)).

**기대**: 색·크기·간격·타이포그래피가 전환 전과 동일(FR-005, SC-003). `StyledText`는 자간·
행간·폰트·정렬까지 확인한다.

## 3. 기능 전체 완료 시

```sh
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

**기대**: 세 명령 모두 성공(FR-008, SC-004). 세 명령은 순차 실행을 전제로
`sources/DerivedData/PreCommit`을 공유한다.

### 3.1 여섯 컴포넌트 전체 팩토리 0개

```sh
grep -rn "public static func" \
  sources/Projects/UI/Component/Controls/ActionButton.swift \
  sources/Projects/UI/Component/Controls/IconGlassButton.swift \
  sources/Projects/UI/Component/Displays/TagBadge.swift \
  sources/Projects/UI/Component/Displays/LabeledCard.swift \
  sources/Projects/UI/Component/Displays/StyledText.swift \
  sources/Projects/UI/Component/Overlays/ScreenEdgeScrim.swift
```

**기대**: 출력 없음(SC-001).

### 3.2 대상 아닌 선언이 그대로인지

```sh
grep -n "tabColor" sources/Projects/UI/Component/Scaffolds/TabShell/TabShellItem.swift
grep -n "resizable" sources/Projects/UI/Component/Displays/ResourceImage.swift
```

**기대**: 둘 다 그대로 존재(FR-009).

## 4. 컨벤션 개정 확인

```sh
grep -rn "팩토리" docs/conventions/
```

**기대**: 팩토리 정의를 요구하거나 전제하는 문장이 남지 않는다(FR-004b, SC-006). 남는 언급은
`component-init.md`의 금지 서술 한 건뿐이다. 개정 대상 문서와 삭제 대상
`view/factory-criteria.md`는 [spec.md](./spec.md)의 FR-004a가 열거한다.

```sh
grep -rn "factory-criteria" docs/
```

**기대**: 삭제한 문서를 가리키는 링크가 남지 않는다(FR-004b-2). `docs/conventions/view.md`
§3.3 절과 그 링크가 삭제됐는지 확인한다.

```sh
grep -rn "view\.md#3-공개-생성-경로" docs/
grep -n "^### 3\." docs/conventions/view.md
```

**기대**: 첫 명령은 `docs/package-rules/ui.md`, `docs/conventions/ui-component.md`,
`docs/conventions/ui-component/public-contract.md` 세 건을 그대로 반환하고, 그 앵커가 살아
있다(FR-004b-1). 둘째 명령은 §3.1·§3.2·§3.4·§3.5를 반환한다 — §3.3만 사라지고 나머지 번호는
그대로여야 한다(FR-004b-3).

`docs/retrospective/`의 언급은 과거 기록이므로 개정 대상이 아니다.

### 4.1 문서만으로 판정 가능한지

```sh
grep -n "init\|팩토리" docs/conventions/view/component-init.md
```

**기대**: §4 첫 명령의 남은 `팩토리` 언급이 금지 서술뿐이고, `component-init.md`가 공개 생성
경로를 단수로 규정하며 호출 예시가 모두 초기화 호출이다(SC-006a).

## 5. 커밋 전

pre-commit 훅이 셸 회귀·Swift 포맷·디자인 규칙·패키지 의존성 검사를 순서대로 실행한다.
훅을 우회하지 않는다(`--no-verify` 금지). 포맷 결과가 staged 파일과 다르면 변경 파일을 다시
stage한다.
