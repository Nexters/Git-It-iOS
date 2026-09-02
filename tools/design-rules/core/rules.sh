# 디자인 규격의 금지 패턴을 정의하는 순수 규칙 표입니다. 외부 상태를 읽지 않습니다.

# 검사할 규칙 이름을 고정 순서로 제공합니다.
design_rules_names() {
	printf '%s\n' \
		fixed-width \
		canvas-constant \
		hardcoded-metric \
		component-state \
		component-margin \
		component-haptic \
		vertical-fill \
		dynamic-type
}

# 규칙 하나의 위반 설명을 제공합니다.
design_rules_description() (
	design_rules_name=$1
	case "$design_rules_name" in
	fixed-width) printf '고정 폭은 허용 목록에 등록된 곳에만 둡니다\n' ;;
	canvas-constant) printf '정본 캔버스 고정값을 레이아웃 차원으로 쓰지 않습니다\n' ;;
	hardcoded-metric) printf '토큰으로 대체할 수 있는 수치를 직접 적지 않습니다\n' ;;
	component-state) printf '컴포넌트는 표시 상태를 보관하지 않습니다\n' ;;
	component-margin) printf '컴포넌트는 화면 좌우 여백을 붙이지 않습니다\n' ;;
	component-haptic) printf '컴포넌트는 햅틱을 발생시키지 않습니다\n' ;;
	vertical-fill) printf '세로 채움은 허용 목록에 등록된 곳에만 둡니다\n' ;;
	dynamic-type) printf 'Dynamic Type 대응 API를 쓰지 않습니다\n' ;;
	*) return 2 ;;
	esac
)

# 규칙 하나가 검사할 소스 루트의 상대 위치를 제공합니다.
design_rules_scan_subpath() (
	design_rules_name=$1
	case "$design_rules_name" in
	dynamic-type) printf 'UI\n' ;;
	*) printf 'UI/Component\n' ;;
	esac
)

# 규칙 하나의 rg 패턴을 제공합니다.
design_rules_pattern() (
	design_rules_name=$1
	case "$design_rules_name" in
	fixed-width)
		printf '%s\n' '\.frame\(width:'
		;;
	canvas-constant)
		# 폭·높이 차원에 쓰인 정본 고정값만 잡습니다. safe area 입력과 그림자 blur 같은
		# 다른 의미의 같은 숫자는 위반이 아닙니다.
		printf '%s\n' '\b(width|height|maxWidth|maxHeight|minWidth|minHeight):\s*(103|154|34|127|53)\b'
		;;
	hardcoded-metric)
		# 간격 토큰과 같은 값을 직접 적은 곳만 잡습니다. 0은 토큰이 아니므로 제외됩니다.
		printf '%s\n' '\bspacing:\s*(4|6|8|12|14|18|20)\b|\.padding\([^)]*,\s*(4|6|8|12|14|18|20)\)|\.padding\((4|6|8|12|14|18|20)\)'
		;;
	component-state)
		printf '%s\n' '@State\b'
		;;
	component-margin)
		printf '%s\n' 'LayoutToken\.margin|designSystemScreenMargin\('
		;;
	component-haptic)
		printf '%s\n' 'FeedbackGenerator|sensoryFeedback'
		;;
	vertical-fill)
		printf '%s\n' '\.frame\(maxHeight: \.infinity\)'
		;;
	dynamic-type)
		printf '%s\n' 'dynamicTypeSize|ScaledMetric|relativeTo:|UIFontMetrics'
		;;
	*) return 2 ;;
	esac
)

# 규칙 하나의 허용 목록 파일 이름을 제공합니다. 예외가 없으면 빈 값입니다.
design_rules_allow_file() (
	design_rules_name=$1
	case "$design_rules_name" in
	fixed-width) printf 'allowed-fixed-width\n' ;;
	vertical-fill) printf 'allowed-vertical-fill\n' ;;
	*) printf '\n' ;;
	esac
)

# 규칙 하나가 경로로 면제하는 대상인지 판정합니다.
design_rules_path_exempt() (
	design_rules_name=$1
	design_rules_path=$2
	case "$design_rules_name:$design_rules_path" in
	# 화면 좌우 여백은 ScreenContainer 하나가 소유합니다.
	component-margin:*/Scaffolds/ScreenContainer/*) return 0 ;;
	# 스플래시 연출은 타이핑 진행 상태를 자기 안에서 진행시킵니다.
	component-state:*/Displays/SplashView.swift) return 0 ;;
	component-state:*/Displays/LaunchLogo.swift) return 0 ;;
	# 시트는 자기 좌우 여백과 스크롤 높이를 직접 관리하는 표시 방식을 씁니다.
	component-margin:*/Overlays/SheetSurface/*) return 0 ;;
	component-state:*/Overlays/SheetSurface/*) return 0 ;;
	# 수치 상수 선언 파일은 값을 모으는 곳이므로 검사 대상이 아닙니다.
	hardcoded-metric:*+Constant.swift) return 0 ;;
	*) return 1 ;;
	esac
)
