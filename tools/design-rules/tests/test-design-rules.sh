#!/bin/sh
# 디자인 규칙 8종이 위반 fixture에서 실패하고 정상 fixture에서 통과하는지 검사합니다.
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
suite=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
work=$(mktemp -d "${TMPDIR:-/tmp}/design-rules-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM

. "$suite/core/rules.sh"
. "$suite/core/scan.sh"

# 규칙 하나를 fixture 소스에 적용해 위반 수를 센다.
scan_source() {
	scan_rule=$1
	scan_relative=$2
	scan_body=$3
	scan_allow=${4:-}
	scan_case="$work/case"
	rm -rf "$scan_case"
	mkdir -p "$scan_case/$(dirname -- "$scan_relative")"
	printf '%s\n' "$scan_body" >"$scan_case/$scan_relative"
	: >"$work/report"
	design_rules_scan_rule \
		"$scan_rule" \
		"$scan_case" \
		"$scan_allow" \
		"$work/report" \
		"$suite/core"
	wc -l <"$work/report" | tr -d ' '
}

# 위반 fixture는 최소 1건을 보고해야 한다.
expect_violation() {
	[ "$(scan_source "$1" "$2" "$3" "${4:-}")" -ge 1 ] || {
		printf 'FAIL: %s 규칙이 위반 fixture를 잡지 못함\n' "$1" >&2
		exit 1
	}
}

# 정상 fixture는 위반을 보고하지 않아야 한다.
expect_clean() {
	[ "$(scan_source "$1" "$2" "$3" "${4:-}")" -eq 0 ] || {
		printf 'FAIL: %s 규칙이 정상 fixture를 위반으로 판정\n' "$1" >&2
		exit 1
	}
}

# 규칙 이름 목록이 규격의 8종과 일치한다.
[ "$(design_rules_names | wc -l | tr -d ' ')" -eq 8 ] || {
	printf 'FAIL: 규칙 수가 8종이 아님\n' >&2
	exit 1
}

# 1. fixed-width — 허용 목록에 없는 고정 폭은 위반이다.
expect_violation fixed-width 'UI/Component/Controls/Sample.swift' '        .frame(width: 120)'
printf '%s\n' 'UI/Component/Controls/Sample.swift 종횡비가 의미를 갖는 요소' >"$work/allow-width"
expect_clean fixed-width 'UI/Component/Controls/Sample.swift' '        .frame(width: 120)' "$work/allow-width"

# 2. canvas-constant — 레이아웃 차원의 정본 고정값만 위반이다.
expect_violation canvas-constant 'UI/Component/Controls/Sample.swift' '        .frame(height: 34)'
expect_violation canvas-constant 'UI/Component/Controls/Sample.swift' '        .frame(width: 154)'
expect_clean canvas-constant 'UI/Component/Controls/Sample.swift' '            blur: 34,'
expect_clean canvas-constant 'UI/Component/Controls/Sample.swift' '            safeAreaBottom: 34,'

# 3. hardcoded-metric — 토큰 값과 같은 수치를 직접 적으면 위반이다.
expect_violation hardcoded-metric 'UI/Component/Controls/Sample.swift' '        VStack(spacing: 12) {'
expect_clean hardcoded-metric 'UI/Component/Controls/Sample.swift' '        VStack(spacing: 0) {'
expect_clean hardcoded-metric 'UI/Component/Controls/Sample+Constant.swift' '        static let padding: CGFloat = 12'

# 4. component-state — 표시 상태 보관은 예외 없이 위반이다.
expect_violation component-state 'UI/Component/Controls/Sample.swift' '    @State private var isOn = false'
expect_clean component-state 'UI/Component/Controls/Sample.swift' '    let isOn: Bool'

# 5. component-margin — ScreenContainer 밖의 화면 여백 사용은 위반이다.
expect_violation component-margin 'UI/Component/Controls/Sample.swift' '        .designSystemScreenMargin()'
expect_clean component-margin \
	'UI/Component/Scaffolds/ScreenContainer/ScreenContainer.swift' '        .designSystemScreenMargin()'

# 6. component-haptic — 햅틱 발생은 예외 없이 위반이다.
expect_violation component-haptic 'UI/Component/Controls/Sample.swift' '        UIImpactFeedbackGenerator(style: .light).impactOccurred()'
expect_clean component-haptic 'UI/Component/Controls/Sample.swift' '        onTap()'

# 7. vertical-fill — 허용 목록에 없는 세로 채움은 위반이다.
expect_violation vertical-fill 'UI/Component/Controls/Sample.swift' '        .frame(maxHeight: .infinity)'
printf '%s\n' 'UI/Component/Controls/Sample.swift 웹 콘텐츠' >"$work/allow-fill"
expect_clean vertical-fill 'UI/Component/Controls/Sample.swift' '        .frame(maxHeight: .infinity)' "$work/allow-fill"

# 8. dynamic-type — Dynamic Type 대응 API는 예외 없이 위반이다.
expect_violation dynamic-type 'UI/Component/Controls/Sample.swift' '    @ScaledMetric private var size = 12'
expect_clean dynamic-type 'UI/Component/Controls/Sample.swift' '    private let size: CGFloat = 12'

# 프리뷰 스캐폴딩은 검사 대상이 아니다.
expect_clean component-margin 'UI/Component/Controls/Sample.swift' \
	'#Preview("Sample") {
    Sample()
        .designSystemScreenMargin()
}'

printf 'PASS: design rules\n'
