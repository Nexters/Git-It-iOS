# 고정 lock의 artifact를 명시적으로 준비하는 외부 어댑터입니다.

verification_platform_detect() (
	verification_uname_system=$(uname -s)
	verification_uname_machine=$(uname -m)
	case "$verification_uname_system:$verification_uname_machine" in
	Darwin:arm64) printf 'darwin-arm64\n' ;;
	Darwin:x86_64) printf 'darwin-x86_64\n' ;;
	*) return 2 ;;
	esac
)

verification_lock_read() (
	: "${VERIFICATION_SUITE_ROOT:?}"
	: "${VERIFICATION_WORK:?}"
	verification_lock_platform=${VERIFICATION_PLATFORM:-$(verification_platform_detect)} || return 2
	verification_lock_source="$VERIFICATION_SUITE_ROOT/dependencies/tools.lock"
	verification_lock_selected="$VERIFICATION_WORK/selected.lock"
	[ -f "$verification_lock_source" ] || return 2
	: >"$verification_lock_selected"
	while IFS='|' read -r verification_name verification_version verification_platform \
		verification_artifact verification_url verification_sha verification_archive verification_binary; do
		case "$verification_name" in '' | \#*) continue ;; esac
		if [ "$verification_platform" = "$verification_lock_platform" ]; then
			printf '%s|%s|%s|%s|%s|%s|%s|%s\n' \
				"$verification_name" "$verification_version" "$verification_platform" \
				"$verification_artifact" "$verification_url" "$verification_sha" \
				"$verification_archive" "$verification_binary" >>"$verification_lock_selected"
		fi
	done <"$verification_lock_source"
	[ "$(wc -l <"$verification_lock_selected" | tr -d ' ')" -eq 2 ]
)

verification_artifacts_fetch() (
	verification_fetch_selected="$VERIFICATION_WORK/selected.lock"
	verification_fetch_directory="$VERIFICATION_WORK/downloads"
	mkdir -p "$verification_fetch_directory" || return 2
	while IFS='|' read -r verification_name verification_version verification_platform \
		verification_artifact verification_url verification_sha verification_archive verification_binary; do
		verification_fetch_target="$verification_fetch_directory/$verification_artifact"
		if [ -n "${VERIFICATION_FIXTURE_ARTIFACTS:-}" ]; then
			cp "$VERIFICATION_FIXTURE_ARTIFACTS/$verification_artifact" "$verification_fetch_target" || return 1
		else
			command -v curl >/dev/null 2>&1 || return 2
			curl -fL --retry 3 --output "$verification_fetch_target" "$verification_url" || return 1
		fi
	done <"$verification_fetch_selected"
)

verification_artifacts_check() (
	verification_check_selected="$VERIFICATION_WORK/selected.lock"
	verification_check_prepared="$VERIFICATION_WORK/prepared"
	mkdir -p "$verification_check_prepared" || return 2
	while IFS='|' read -r verification_name verification_version verification_platform \
		verification_artifact verification_url verification_sha verification_archive verification_binary; do
		verification_check_download="$VERIFICATION_WORK/downloads/$verification_artifact"
		verification_check_actual=$(shasum -a 256 "$verification_check_download" | awk '{print $1}') || return 2
		[ "$verification_check_actual" = "$verification_sha" ] || return 1

		case "$verification_archive" in
		binary)
			cp "$verification_check_download" "$verification_check_prepared/$verification_name" || return 2
			;;
		tar.xz)
			verification_check_unpack="$VERIFICATION_WORK/unpack-$verification_name"
			mkdir -p "$verification_check_unpack" || return 2
			tar -xJf "$verification_check_download" -C "$verification_check_unpack" || return 1
			cp "$verification_check_unpack/$verification_binary" "$verification_check_prepared/$verification_name" || return 1
			;;
		*) return 2 ;;
		esac
		chmod +x "$verification_check_prepared/$verification_name" || return 2

		case "$verification_name" in
		shellcheck)
			verification_check_version=$("$verification_check_prepared/$verification_name" --version | sed -n 's/^version: //p') || return 1
			;;
		shfmt)
			verification_check_version=$("$verification_check_prepared/$verification_name" --version) || return 1
			verification_check_version=${verification_check_version#v}
			;;
		*) return 2 ;;
		esac
		[ "$verification_check_version" = "$verification_version" ] || return 1
	done <"$verification_check_selected"
)

verification_artifacts_place() (
	verification_place_build="$VERIFICATION_SUITE_ROOT/.build"
	verification_place_stage="$verification_place_build/.install.$$"
	verification_place_backup="$verification_place_build/.previous.$$"
	mkdir -p "$verification_place_stage/bin" "$verification_place_stage/artifacts" || return 2
	while IFS='|' read -r verification_name verification_version verification_platform \
		verification_artifact verification_url verification_sha verification_archive verification_binary; do
		cp "$VERIFICATION_WORK/prepared/$verification_name" "$verification_place_stage/bin/$verification_name" || return 2
		cp "$VERIFICATION_WORK/downloads/$verification_artifact" "$verification_place_stage/artifacts/$verification_artifact" || return 2
	done <"$VERIFICATION_WORK/selected.lock"

	if [ -d "$verification_place_build/bin" ] || [ -d "$verification_place_build/artifacts" ]; then
		mkdir -p "$verification_place_backup" || return 2
		[ ! -d "$verification_place_build/bin" ] || mv "$verification_place_build/bin" "$verification_place_backup/bin"
		[ ! -d "$verification_place_build/artifacts" ] || mv "$verification_place_build/artifacts" "$verification_place_backup/artifacts"
	fi
	if mv "$verification_place_stage/bin" "$verification_place_build/bin" &&
		mv "$verification_place_stage/artifacts" "$verification_place_build/artifacts"; then
		rm -rf "$verification_place_stage" "$verification_place_backup"
		return 0
	fi

	rm -rf "${verification_place_build:?}/bin" "${verification_place_build:?}/artifacts"
	[ ! -d "$verification_place_backup/bin" ] || mv "$verification_place_backup/bin" "$verification_place_build/bin"
	[ ! -d "$verification_place_backup/artifacts" ] || mv "$verification_place_backup/artifacts" "$verification_place_build/artifacts"
	rm -rf "$verification_place_stage" "$verification_place_backup"
	return 1
)
