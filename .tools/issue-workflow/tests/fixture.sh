#!/bin/sh
# 실제 모듈과 규칙 문서를 복사한 격리 저장소와 가짜 gh를 만듭니다.

fixture_create() {
	fixture_source=$1
	fixture_repository=$2
	fixture_bin=$3
	fixture_paths="$fixture_source/.tools/repository-paths/bin/repository-paths.sh"

	mkdir -p "$fixture_repository/.tools" "$fixture_bin"
	cp -R "$fixture_source/.tools/repository-paths" "$fixture_repository/.tools/"
	cp -R "$fixture_source/.tools/issue-workflow" "$fixture_repository/.tools/"

	# 규칙 문서는 공개 경로 키로 찾아 원본 그대로 복사합니다.
	for fixture_key in GIT_IT_WORKFLOW_LANE_DOC GIT_IT_WORKFLOW_LABEL_DOC GIT_IT_ISSUE_TEMPLATE_ROOT; do
		fixture_relative=$("$fixture_paths" "$fixture_key")
		mkdir -p "$fixture_repository/$(dirname -- "$fixture_relative")"
		cp -R "$fixture_source/$fixture_relative" "$fixture_repository/$fixture_relative"
	done

	cat >"$fixture_bin/gh" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$FAKE_GH_LOG"
case "$1 $2" in
'issue view')
	[ "${FAKE_GH_FAIL:-false}" != true ] && [ "${GH_TOKEN:-}" != invalid ] || {
		printf 'HTTP 503\n' >&2
		exit 1
	}
	[ "${FAKE_ISSUE_STATE:-OPEN}" != MISSING ] || {
		printf 'GraphQL: Could not resolve to an issue or pull request with the number of 9.\n' >&2
		exit 1
	}
	case "$*" in
	*'--json labels '*)
		[ "${FAKE_LABELS_FAIL:-false}" != true ] || {
			printf 'HTTP 503\n' >&2
			exit 1
		}
		if [ -f "${FAKE_LABEL_FILE:-/nonexistent}" ]; then
			cat "$FAKE_LABEL_FILE"
			exit 0
		fi
		printf '%s\n' "${FAKE_ISSUE_LABELS:-type: tooling}"
		exit 0
		;;
	*'--json number,title,labels,body '*)
		printf '#%s 목적 문장\n라벨: type: tooling\n\n## 목적\n' "$3"
		exit 0
		;;
	esac
	printf '%s https://github.com/example/repository/%s/9\n' "${FAKE_ISSUE_STATE:-OPEN}" "${FAKE_ISSUE_KIND:-issues}"
	;;
'issue create')
	while [ "$#" -gt 0 ]; do
		if [ "$1" = --body-file ]; then
			cp "$2" "$FAKE_GH_BODY"
		fi
		shift
	done
	printf 'https://github.com/example/repository/issues/7\n'
	;;
'issue develop')
	printf 'github.com/example/repository/tree/branch\n'
	;;
'api repos/'* | 'api --method')
	case "$*" in
	*matching-refs*)
		[ "${FAKE_BRANCHES_FAIL:-false}" != true ] || {
			printf 'HTTP 503\n' >&2
			exit 1
		}
		for fake_branch in ${FAKE_ISSUE_BRANCHES:-}; do
			printf '%s\n' "$fake_branch"
		done
		;;
	*'--method DELETE'*)
		[ "${FAKE_LABEL_REMOVE_FAIL:-false}" != true ] || exit 1
		rm -f "$FAKE_LABEL_FILE"
		;;
	*/labels*)
		[ "${FAKE_LABEL_ADD_FAIL:-false}" != true ] || exit 1
		printf 'status: on-hold\n' >"$FAKE_LABEL_FILE"
		;;
	esac
	;;
esac
EOF
	chmod +x "$fixture_bin/gh"

	# 저장소 안 심볼릭 링크는 원본 경로로 판정해야 합니다.
	fixture_ios_root=$("$fixture_paths" GIT_IT_IOS_ROOT)
	mkdir -p "$fixture_repository/.agents" "$fixture_repository/$fixture_ios_root" "$fixture_repository/docs"
	printf '# Agent\n' >"$fixture_repository/AGENTS.md"
	printf 'App\n' >"$fixture_repository/$fixture_ios_root/App.swift"
	ln -s .agents "$fixture_repository/.claude"
	ln -s AGENTS.md "$fixture_repository/CLAUDE.md"
	printf '.claude\nCLAUDE.md\nignored.txt\n' >"$fixture_repository/.gitignore"

	git -C "$fixture_repository" init -q -b develop
	git -C "$fixture_repository" config user.name issue-workflow-test
	git -C "$fixture_repository" config user.email issue-workflow-test@example.com
	git -C "$fixture_repository" add -A
	git -C "$fixture_repository" commit -qm fixture
}
