# 저장소를 새로 내려받은 뒤 필요한 초기화 명령을 한곳에서 제공합니다.
# 정책을 다시 정의하지 않고 각 기능의 공개 bin/ 명령만 순서대로 호출합니다.

PATHS_SH := ./tools/repository-paths/bin/repository-paths.sh
IOS_ROOT := $(shell $(PATHS_SH) GIT_IT_IOS_ROOT)
HOOKS_ROOT := $(shell $(PATHS_SH) GIT_IT_HOOKS_ROOT)
SWIFT_FORMAT_RUNNER := $(shell $(PATHS_SH) GIT_IT_SWIFT_FORMAT_RUNNER)
PROJECT_SETUP_RUNNER := $(shell $(PATHS_SH) GIT_IT_PROJECT_SETUP_RUNNER)

.DEFAULT_GOAL := help

.PHONY: help init tuist clean hooks format verify-tools

help: ## 사용 가능한 명령을 표시합니다
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  make %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: tuist hooks ## Tuist·Git 훅·에이전트 링크·VS Code workspace를 초기화합니다
	$(PROJECT_SETUP_RUNNER) developer-tools

tuist: ## iOS 프로젝트의 Tuist package를 설치·생성하고 루트에 워크스페이스 심볼릭 링크를 만듭니다
	cd $(IOS_ROOT) && tuist install && tuist generate
	$(PROJECT_SETUP_RUNNER) workspace-link

clean: ## Tuist의 로컬 캐시와 아티팩트를 정리합니다
	cd $(IOS_ROOT) && tuist clean

hooks: ## Git local core.hooksPath와 훅 실행 권한을 설정합니다
	$(HOOKS_ROOT)/hook-management/bin/install.sh

format: ## 프로젝트 전체 Swift 소스를 포맷합니다
	$(SWIFT_FORMAT_RUNNER) format

verify-tools: ## 셸 스크립트 검증에 필요한 ShellCheck·shfmt를 준비합니다
	./tools/script-verification/bin/prepare-tools.sh
