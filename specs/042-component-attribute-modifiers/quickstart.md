# 빠른 시작: 전환 검증 절차

**계획**: [plan.md](./plan.md) | **계약**: [contracts/component-init-contracts.md](./contracts/component-init-contracts.md)

이 문서는 실행 단위(U1~U10)마다, 그리고 마지막에 전환이 명세를 만족하는지 확인하는 절차다. 구현
방법은 담지 않는다.

## 0. 준비

```sh
cd "$(git rev-parse --show-toplevel)"
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

- workspace가 없으면 `sources`에서 `tuist generate`를 먼저 실행한다.
- 빌드 실행기의 세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 순차 실행한다.
- 기본 destination은 `platform=iOS Simulator,name=iPhone 17 Pro`다.

## 1. 단위마다 실행하는 검증

1. `"$project_build_runner" compile`이 통과한다. UI 공개 API 변경과 Feature 호출부 전환이 같은
   단위에 있어야 통과한다.
2. 테스트 파일을 바꾼 단위는 `"$project_build_runner" test`까지 통과한다.
3. 그 단위의 컴포넌트에 대해 아래 조회 결과가 0줄이다(§2).
4. 호출부 diff에서 전환 전후 값이 같은지 대조한다(§3).
5. 그 단위 컴포넌트의 `#Preview`와, 그 컴포넌트를 쓰는 Feature 화면 프리뷰를 연다. 전환 전과 같은
   레이아웃·토큰·색인지 확인한다(SC-004).

## 2. 초기화 계약 조회

아래 명령은 `rg`(ripgrep)를 사용한다.

### 2.1 시각 속성 인자가 남지 않음(SC-001)

전환 전 인자 이름이 호출부나 선언에 남았는지 찾는다. 결과가 0줄이어야 한다.

```sh
rg -n --glob '*.swift' --glob '!**/Derived/**' \
  -e 'StyledText\([^)]*\b(style|color|alignment):' \
  -e '(ActionButton|FeedbackActionButton|TagBadge|IconGlassButton)\([^)]*\b(style|size):' \
  -e 'LabeledCard\([^)]*\bstyle:' \
  -e 'IconPlainButton\([^)]*\b(tintColor|backgroundColor):' \
  -e 'LabeledProgressBar\([^)]*\bvalueColor:' \
  -e '(SelectionCard|SelectionCardList)\([^)]*\bstyle:' \
  -e 'HomeProjectCard\([^)]*\bvariant:' \
  -e 'ScreenContainer\(\s*background:' \
  -e 'OverlayContainer\(\s*screenBackground:' \
  -e 'ContinuousProgressBar\([^)]*\bheight:' \
  sources/Projects
```

여러 줄에 걸친 호출은 위 패턴이 놓칠 수 있다. 그래서 최종 확인은 각 컴포넌트 파일의 `public init`
시그니처를 [contracts](./contracts/component-init-contracts.md) §2·§3과 대조한다.

### 2.2 표시 값 모델만 받음(SC-008)

```sh
# 대상 컴포넌트마다 public init의 첫 인자가 displayModel인지 확인한다
rg -n -A2 'public init\(' sources/Projects/UI/Component

# Feature State·Reducer가 DisplayModel을 참조하지 않는다(0줄이어야 함)
rg -n 'DisplayModel' sources/Projects/Feature --glob '*Feature.swift' --glob '**/ViewModels/**'
```

### 2.3 계약 메서드 이름이 하나뿐임(SC-002·SC-005)

```sh
rg -n 'func (style|size|textStyle|foregroundColorToken|backgroundColorToken)\(' sources/Projects/UI/Component sources/Projects/Feature
rg -n '^public protocol' sources/Projects/UI/Component/Contracts
```

속성 종류마다 메서드 이름은 하나다. 다섯 계약 외에 다른 시각 속성 선언 메서드가 없어야 한다.

### 2.4 상태 `Binding`(SC-009)

```sh
# 제거된 상태 콜백이 남지 않음(0줄이어야 함)
rg -n --glob '*.swift' --glob '!**/Derived/**' \
  -e '(Chip|SelectableSettingRow|BookmarkButton|ChoiceResultRow)\([^)]*\bonTap:' \
  -e 'PolicyAgreementRow\([^)]*\bonToggle:' \
  -e 'SavedQuestionCard\([^)]*\bonBookmarkTap:' \
  -e 'ModalOverlay\([^)]*\bonDismiss:' \
  -e 'SelectionCardList\([^)]*\bonSelect:' \
  -e 'onToggleExpand' \
  sources/Projects

# 상태 Binding에 기본값이 없음(0줄이어야 함)
rg -n 'Binding<[^>]+>\s*=\s*\.constant' sources/Projects/UI/Component

# Feature에 BindableAction·BindingReducer가 새로 생기지 않음(0줄이어야 함)
rg -n 'BindableAction|BindingReducer' sources/Projects/Feature
```

여러 줄 호출은 위 패턴이 놓칠 수 있다. 그래서 대상 컴포넌트의 `public init`을
[contracts](./contracts/component-init-contracts.md) §3.1과 대조한다. Feature Reducer·Action 파일과 Reducer
테스트의 diff가 0줄인지도 `git diff --stat`으로 확인한다.

## 3. 렌더링 동일성 대조(SC-004)

- [research.md](./research.md) §1.2의 명시 호출 수와 전환 뒤 메서드 호출 수를 비교한다. 차이는
  기본값과 같아 생략한 호출부(§4.1 목록)만큼이어야 한다.
- `StyledText` 정렬: 전환 전 `alignment: .center` 55곳에 `.multilineTextAlignment(.center)`가 있어야
  한다. `.multilineTextAlignment`를 가진 상위 컨테이너 안에서 정렬을 넘기지 않던 호출부는
  [research.md](./research.md) §4.2의 조회 결과대로 처리했는지 확인한다.
- 새 기본값을 쓰게 되는 호출부가 전환 전 같은 값을 명시했는지 확인한다. 대상은 `StyledText` `.body1`,
  `LabeledCard` `.neutral`, `HomeProjectCard` `.purple`이다. 다른 값을 명시했던 호출부는 메서드로 같은
  값을 선언해야 한다.
- `SelectionCard` EmptyView 경로가 `.compact`로 그려지는지 `SelectionCardList` `.compact` 목록
  프리뷰로 확인한다.

- 상태 `Binding` 대상 화면에서 탭·토글·닫기 동작이 전환 전과 같은 View Action을 보내는지 호출부
  diff로 대조한다. 비교 대상은 setter가 보내는 Action과 제거된 콜백이 보내던 Action이다. 대상 화면은
  Saved 필터, 약관 동의, 북마크, 삭제 확인 모달, 선택 목록이다([research.md](./research.md) §9.3).

## 4. 계약 단위 테스트(SC-007)

```sh
"$project_build_runner" test
```

`sources/Projects/UI/Tests/Component/Unit/Contracts/`의 테스트가 계약마다 다음을 확인한다.

- 메서드를 호출하지 않으면 기본값이다.
- 메서드가 그 속성만 바꾸고 표시 값·다른 시각 속성을 유지한다(`Mirror`로 저장 프로퍼티 조회).
- 같은 속성을 두 번 선언하면 마지막 값이 남는다.
- 서로 다른 속성의 호출 순서를 바꿔도 결과가 같다.

## 5. 문서 개정 확인(SC-006)

```sh
# 0줄이어야 함
rg -n '표시 상태를 묶는|상태 wrapper|시각 변형은 .*초기화 인자' docs .agents/skills/implement-figma-ui/references
```

그다음 [research.md](./research.md) §7과 명세 FR-016 목록의 문서를 연다. 새 컴포넌트를 가정하고 다음을
판정할 수 있는지 확인한다.
- 시각 속성 선언 방식
- 기본값·호출 순서 제약
- 표시 값 모델 적용 여부와 인자 구분

## 6. 최종 검증(마지막 단위)

```sh
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

세 명령이 모두 통과하고 §2·§5 조회가 0줄이면 SC-001~SC-009를 충족한다. 이어서 필수
`after_implement` 포맷 훅을 실행하고 결과를 다시 확인한 뒤 커밋한다.
