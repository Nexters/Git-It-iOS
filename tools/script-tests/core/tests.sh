# 스크립트 테스트 파일을 NUL 경계로 수집하고 실행하는 외부 어댑터입니다.

script_tests_collect() (
	script_tests_root=$1
	script_tests_list=$2
	find "$script_tests_root/tools" -type f -path '*/tests/test-*.sh' -print0 >"$script_tests_list"
)

script_tests_execute() (
	script_tests_list=$1
	# 경로를 argv로 복원해 공백, 한글과 개행이 있는 테스트 파일도 안전하게 실행합니다.
	# shellcheck disable=SC2016
	xargs -0 -n 1 /bin/sh -c '
		printf "스크립트 테스트 실행: %s\\n" "$1"
		# CI의 중앙 경로 환경변수가 fixture JSON을 덮어쓰지 않게 격리합니다.
		unset GIT_IT_PATHS_FILE GIT_IT_IOS_ROOT GIT_IT_PROJECTS_ROOT GIT_IT_TUIST_ROOT
		unset GIT_IT_WORKSPACE_PATH GIT_IT_WORKSPACE_LINK_PATH GIT_IT_DERIVED_DATA_PATH
		unset GIT_IT_SWIFT_STYLE_ROOT GIT_IT_HOOKS_ROOT GIT_IT_ARCHITECTURE_PATH
		unset GIT_IT_AGENT_INSTRUCTIONS_PATH GIT_IT_AGENT_SKILLS_ROOT
		unset GIT_IT_CLAUDE_INSTRUCTIONS_LINK_PATH GIT_IT_CLAUDE_SKILLS_LINK_PATH
		unset GIT_IT_VSCODE_WORKSPACE_PATH GIT_IT_SPECS_ROOT GIT_IT_DOCS_ROOT
		unset GIT_IT_SWIFT_FORMAT_RUNNER GIT_IT_PROJECT_BUILD_RUNNER GIT_IT_PROJECT_SETUP_RUNNER
		unset GIT_IT_SCRIPT_TEST_RUNNER GIT_IT_SCRIPT_VERIFICATION_RUNNER
		# Git hook이 주입한 저장소 환경은 fixture 저장소의 git 명령을 오염시킵니다.
		unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY
		unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX
		/bin/sh "$1"
	' script-tests <"$script_tests_list"
)
