# Tuist <패키지>ModuleName.swift에서 모듈, target 블록과 의존성 선언을 읽는 어댑터입니다.
#
# modules: <모듈><TAB><패키지><TAB><파일><TAB><줄>
# targets: <target><TAB><패키지><TAB><파일><TAB><줄>
# declarations: <target><TAB><from|target|production><TAB><대상 패키지><TAB><대상 모듈><TAB><파일><TAB><줄>

package_dependencies_collect_manifest() (
	pd_manifest=$1
	pd_package=$2
	pd_work=$3
	awk \
		-v package="$pd_package" \
		-v modules="$pd_work/modules" \
		-v targets="$pd_work/targets" \
		-v declarations="$pd_work/declarations" '
		function start(name) {
			current = name
			printf "%s\t%s\t%s\t%d\n", name, package, FILENAME, FNR >> targets
		}
		function declare(kind, target_package, module) {
			if (current == "") return
			printf "%s\t%s\t%s\t%s\t%s\t%d\n", current, kind, target_package, module, FILENAME, FNR >> declarations
		}
		# "name: <패키지>ModuleName.<모듈>.rawValue"에서 패키지와 모듈을 꺼냅니다.
		function named(text) {
			sub(/^.*name:[ \t]*/, "", text)
			named_package = text
			sub(/ModuleName[.].*/, "", named_package)
			named_module = text
			sub(/^[A-Za-z]+ModuleName[.]/, "", named_module)
			sub(/[.]rawValue.*/, "", named_module)
		}
		BEGIN {
			enum_pattern = "^(public |internal |fileprivate |private )?enum " package "ModuleName([ \t:{]|$)"
			own_name = "^[ \t]*name:[ \t]*" package "ModuleName[.][A-Za-z_][A-Za-z0-9_]*[.]rawValue"
			inline_module = "[.](module|testModule)[(][ \t]*name:[ \t]*" package "ModuleName[.][A-Za-z_][A-Za-z0-9_]*[.]rawValue"
			any_name = "^[ \t]*name:[ \t]*[A-Za-z]+ModuleName[.][A-Za-z_][A-Za-z0-9_]*[.]rawValue"
			inline_target = "[.]target[(][ \t]*name:[ \t]*[A-Za-z]+ModuleName[.][A-Za-z_][A-Za-z0-9_]*[.]rawValue"
			from_call = "[.]from(App|Composition|Feature|Domain|Data|Infrastructure|UI)[(][.][A-Za-z_][A-Za-z0-9_]*[)]"
		}
		/^[ \t]*\/\// { next }
		# 1. 모듈 enum의 case를 모읍니다.
		$0 ~ enum_pattern { in_enum = 1; next }
		in_enum && /^}/ { in_enum = 0; next }
		in_enum {
			if ($0 ~ /^[ \t]*case[ \t]+/) {
				cases = $0
				sub(/^[ \t]*case[ \t]+/, "", cases)
				sub(/\/\/.*$/, "", cases)
				total = split(cases, parts, ",")
				for (i = 1; i <= total; i++) {
					name = parts[i]
					sub(/=.*/, "", name)
					gsub(/[ \t]/, "", name)
					if (name ~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
						printf "%s\t%s\t%s\t%d\n", name, package, FILENAME, FNR >> modules
					}
				}
			}
			next
		}
		# 최상위 선언이 끝나면 현재 target 블록도 끝납니다.
		/^}/ { in_switch = 0; current = ""; open_module = 0; open_target = 0; next }
		/var target[ \t]*:[ \t]*Target/ { in_switch = 1; current = ""; next }
		{
			line = $0
			# 2. target 블록 시작: switch의 case 또는 배열의 .module(name:)
			if (in_switch && line ~ /^[ \t]*case[ \t]+[.][A-Za-z_][A-Za-z0-9_]*[ \t]*:/) {
				name = line
				sub(/^[ \t]*case[ \t]+[.]/, "", name)
				sub(/[ \t]*:.*/, "", name)
				start(name)
				open_module = 0
				open_target = 0
				next
			}
			if (open_module && line ~ own_name) {
				named(line)
				start(named_module)
				open_module = 0
				next
			}
			if (match(line, inline_module)) {
				named(substr(line, RSTART, RLENGTH))
				start(named_module)
			}
			# 3. 여러 줄 .target( name: … ) 선언을 닫습니다.
			if (open_target) {
				if (line ~ any_name) {
					named(line)
					declare(open_production ? "production" : "target", named_package, named_module)
				}
				open_target = 0
				if (line ~ any_name) next
			}
			production = line ~ /productionTarget:/
			rest = line
			while (match(rest, inline_target)) {
				named(substr(rest, RSTART, RLENGTH))
				declare(production ? "production" : "target", named_package, named_module)
				production = 0
				rest = substr(rest, RSTART + RLENGTH)
			}
			rest = line
			while (match(rest, from_call)) {
				token = substr(rest, RSTART, RLENGTH)
				target_package = token
				sub(/^[.]from/, "", target_package)
				sub(/[(].*/, "", target_package)
				module = token
				sub(/^[^(]*[(][.]/, "", module)
				sub(/[)]$/, "", module)
				declare(production ? "production" : "from", target_package, module)
				production = 0
				rest = substr(rest, RSTART + RLENGTH)
			}
			open_module = line ~ /[.](module|testModule)[(][ \t]*$/
			if (line ~ /[.]target[(][ \t]*$/) {
				open_target = 1
				open_production = line ~ /productionTarget:/
			}
		}
	' "$pd_manifest"
)
