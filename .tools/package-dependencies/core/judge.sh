# 수집한 레코드로 일관성 오류와 의존성 위반을 판정합니다. 파일을 읽고 결과 파일만 씁니다.
#
# errors: <종류><TAB><파일><TAB><줄><TAB><이유>
# violations: <파일><TAB><줄><TAB><규칙><TAB><이유>

package_dependencies_judge() (
	pd_work=$1
	pd_projects=$2
	pd_architecture=$3
	awk -F '\t' \
		-v allowed_file="$pd_work/allowed" \
		-v table_file="$pd_work/table" \
		-v modules_file="$pd_work/modules" \
		-v targets_file="$pd_work/targets" \
		-v declarations_file="$pd_work/declarations" \
		-v roots_file="$pd_work/roots" \
		-v files_file="$pd_work/files" \
		-v imports_file="$pd_work/imports" \
		-v errors="$pd_work/errors" \
		-v violations="$pd_work/violations" \
		-v projects="$pd_projects" \
		-v architecture="$pd_architecture" '
		function fail(kind, file, line, reason) {
			printf "%s\t%s\t%d\t%s\n", kind, file, line, reason >> errors
		}
		function violate(file, line, rule, reason) {
			printf "%s\t%d\t%s\t%s\n", file, line, rule, reason >> violations
		}
		function allows(package, target_package) {
			return package == target_package || index(" " allowed[package] " ", " " target_package " ") > 0
		}
		function shown(list) {
			if (list == "") return "없음"
			gsub(/ /, ", ", list)
			return list
		}
		function declared(target, module) {
			if (module == target || ((target, module) in declares)) return 1
			if (target in production) {
				if (module == production[target] || ((production[target], module) in declares)) return 1
			}
			return 0
		}
		FILENAME == allowed_file { allowed[$1] = $2; allowed_line[$1] = $3; next }
		FILENAME == table_file { table[$1] = $2; table_line[$1] = $3; next }
		FILENAME == modules_file {
			if ($1 in module_package) {
				fail("module-duplicate", $3, $4, "모듈 " $1 ": " module_package[$1] ", " $2 " 패키지가 함께 선언함")
			} else {
				module_package[$1] = $2
			}
			next
		}
		FILENAME == targets_file {
			if ($1 in target_package) {
				fail("target-duplicate", $3, $4, "target " $1 ": 블록이 두 번 이상 있음")
			} else {
				target_package[$1] = $2
				target_count++
				target_file[$1] = $3
				target_line[$1] = $4
			}
			next
		}
		FILENAME == declarations_file {
			count++
			declaration_target[count] = $1
			declaration_kind[count] = $2
			declaration_package[count] = $3
			declaration_module[count] = $4
			declaration_file[count] = $5
			declaration_line[count] = $6
			next
		}
		FILENAME == roots_file { root[$1] = $2; root_line[$1] = $3; next }
		FILENAME == files_file { file_count++; files[file_count] = $0; next }
		FILENAME == imports_file {
			import_count++
			import_file[import_count] = $1
			import_line[import_count] = $2
			import_module[import_count] = $3
			next
		}
		END {
			# 1. 표와 설정의 대응
			for (package in allowed) {
				if (!(package in table)) {
					violate(architecture, table_line["__section__"], "table-mismatch", package ": 표에 없음 / 설정 " shown(allowed[package]))
				} else if (table[package] != allowed[package]) {
					violate(architecture, table_line[package], "table-mismatch", package ": 표 " shown(table[package]) " / 설정 " shown(allowed[package]))
				}
			}
			for (package in table) {
				if (package != "__section__" && !(package in allowed)) {
					violate(architecture, table_line[package], "table-mismatch", package ": 표 " shown(table[package]) " / 설정에 없음")
				}
			}

			# 2. manifest 자기 일관성
			for (module in module_package) {
				if (!(module in target_package)) fail("target-missing", "Tuist manifest", 0, "모듈 " module ": target 블록 없음")
			}
			for (target in target_package) {
				if (!(target in module_package)) {
					fail("target-unknown", target_file[target], target_line[target], "target " target ": 모듈 enum에 없음")
				}
			}
			for (i = 1; i <= count; i++) {
				module = declaration_module[i]
				if (!(module in module_package) || module_package[module] != declaration_package[i]) {
					fail("declaration-mismatch", declaration_file[i], declaration_line[i], declaration_package[i] " 패키지에 모듈 " module " 없음")
					continue
				}
				declares[declaration_target[i], module] = 1
				if (declaration_kind[i] == "production") production[declaration_target[i]] = module
			}

			# 3. source root 일관성
			for (target in target_package) {
				if (!(target in root)) fail("source-root-missing", "config/source-roots", 0, "target " target ": config/source-roots에 루트 없음")
			}
			for (target in root) {
				if (!(target in target_package)) {
					fail("source-root-unknown", "config/source-roots", root_line[target], "target " target ": manifest에 없음")
				} else if (root[target] != target_package[target] && index(root[target], target_package[target] "/") != 1) {
					fail("source-root-package", "config/source-roots", root_line[target], "target " target ": 루트 " root[target] ", " target_package[target] " 패키지 밖")
				}
			}

			# 4. 파일을 가장 긴 루트의 target에 대응시킵니다.
			prefix = projects "/"
			for (i = 1; i <= file_count; i++) {
				file = files[i]
				relative = index(file, prefix) == 1 ? substr(file, length(prefix) + 1) : file
				best = ""
				best_length = -1
				for (target in root) {
					if (index(relative, root[target] "/") == 1 && length(root[target]) > best_length) {
						best = target
						best_length = length(root[target])
					}
				}
				if (best == "") fail("source-unmapped", file, 0, "어느 target 루트에도 속하지 않는 Swift 파일")
				owner[file] = best
			}

			# 5. manifest 선언의 패키지 조합
			for (i = 1; i <= count; i++) {
				target = declaration_target[i]
				if (declaration_kind[i] == "target" || !(target in target_package)) continue
				package = target_package[target]
				if (!allows(package, declaration_package[i])) {
					violate(declaration_file[i], declaration_line[i], "manifest-package", \
						target " target이 " declaration_package[i] " 패키지 모듈 " declaration_module[i] " 의존 선언: " package " 허용 " shown(allowed[package]))
				}
			}

			# 6. import의 패키지 조합과 target 선언
			for (i = 1; i <= import_count; i++) {
				module = import_module[i]
				target = owner[import_file[i]]
				if (!(module in module_package) || target == "") continue
				package = target_package[target]
				imported_package = module_package[module]
				if (!allows(package, imported_package)) {
					violate(import_file[i], import_line[i], "import-package", \
						target " target(" package ")에서 " imported_package " 패키지 모듈 " module " import: " package " 허용 " shown(allowed[package]))
				} else if (!declared(target, module)) {
					violate(import_file[i], import_line[i], "import-undeclared", target " target manifest에 " module " 선언 없음")
				}
			}
			printf "%d\t%d\n", target_count, file_count > (errors ".summary")
		}
	' "$pd_work/allowed" "$pd_work/table" "$pd_work/modules" "$pd_work/targets" \
		"$pd_work/declarations" "$pd_work/roots" "$pd_work/files" "$pd_work/imports"
)
