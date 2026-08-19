# 006-final-uxui-screens 문제 해결 기록

**대상 기능**: `006-final-uxui-screens`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260819-001: Figma MCP 호출 한도로 `최종 UXUI` 페이지 조회 실패 (재발)

**기록일**: 2026-08-19
**상태**: 환경 제약
**발생 단계**: `$speckit-specify` — Figma 화면 목록과 레이아웃·색 상수 조사
**관련 항목**: `specs/006-final-uxui-screens/spec.md` FR-003, FR-004, FR-007, FR-015

### 증상

Figma 파일 `mCRt0ejmzI4EFW3UnC9Bzb`의 `최종 UXUI` 페이지를 조회하려는 호출이 모두 실패했다. `get_metadata`(fileKey만 지정, 페이지 목록 조회)와 `get_screenshot`(nodeId `86:761`)이 동일하게 `You've reached the Figma MCP tool call limit on the Starter plan.` 오류를 반환했다.

### 영향

`최종 UXUI` 페이지의 화면 프레임 목록을 열거하지 못해 이 기능의 구현 대상 화면 수와 이름을 확정할 수 없었다. 사용자가 명시한 핵심 제약인 "Figma의 padding/spacing 상수를 그대로 사용"과 "컬러값을 완전히 동일하게 적용"의 목표값도 확보하지 못했다. 이 상태에서 저장소의 현재 구현값을 Figma 확정값으로 승격하면 순환 검증이 되어 디자인 불일치를 검출할 수 없다.

### 근거

- `whoami`: 성공했고 `Git-it 디자인`(Full seat)과 `GIT-IT-FIGMA-MCP`(View seat)를 포함한 소속 플랜을 반환했다. 인증 실패가 아니라 호출 한도 문제임을 구분하는 근거다.
- `get_metadata(fileKey: mCRt0ejmzI4EFW3UnC9Bzb)`: Starter plan MCP call limit 오류를 반환했다.
- `get_screenshot(fileKey: mCRt0ejmzI4EFW3UnC9Bzb, nodeId: 86:761, maxDimension: 2048)`: 같은 오류를 반환했다.
- `nc -z 127.0.0.1 3845`: 실패했다. Figma Desktop의 Dev Mode 로컬 MCP 서버가 열려 있지 않아 원격 한도를 우회할 경로가 없었다.
- `pgrep -lf Figma`: Figma Desktop(`126.7.10`) 프로세스는 실행 중이었다. 앱 미실행이 원인이 아니다.
- `specs/005-figma-layout-audit/trouble-shooting.md:7` `TS-20260819-001`: 같은 날 같은 원인의 선행 기록이 존재한다.

### 원인

현재 Figma 계정이 사용하는 플랜(Starter)의 MCP 호출 한도에 도달한 외부 환경 제약이다. 저장소 코드나 Spec Kit 설정의 문제가 아니다. 로컬 Dev Mode MCP 서버가 비활성 상태여서 대체 조회 경로도 없었다.

### 조치

Figma 조회 없이 확정할 수 있는 범위만 명세에 반영했다. 화면 목록은 열거하지 않고 "`최종 UXUI` 페이지의 모든 프레임"이라는 범위 정의만 고정했으며, 여백·색 확정값은 채우지 않았다. 값 확보 수단을 FR-015의 `[NEEDS CLARIFICATION]`으로 남기고, 의존성 섹션에 조회 실패 사실과 그로 인해 채울 수 없는 요구사항 번호를 명시했다. 한도 회복을 기다리거나 플랜을 변경하는 조치는 사용자 결정이 필요해 수행하지 않았다.

### 검증

- `get_metadata`, `get_screenshot` 재호출: 실패. 두 번째 호출도 동일한 한도 오류를 반환해 일시적 오류가 아님을 확인했다.
- `specs/006-final-uxui-screens/checklists/requirements.md` 검토: `[NEEDS CLARIFICATION]` 미해소 항목과 차단 요인이 기록되어 있고, 조회하지 못한 값이 확정값으로 기재되지 않았음을 확인했다.
- Figma 확정값을 사용하는 검증(FR-008 자동 검증): 미실행. 목표값이 없어 실행 조건을 만들 수 없다.

### 재발 방지

Figma MCP 호출 전에 `whoami`로 인증과 한도를 구분하고, 한도 오류가 나오면 다음 순서로 판정한다. 첫째, 로컬 Dev Mode MCP 서버(`127.0.0.1:3845`) 개방 여부를 확인한다. 둘째, 두 경로 모두 막히면 Figma 기반 값이 필요한 산출물을 완료로 보고하지 않고 미확정 범위를 명시한다. 셋째, 현재 구현값을 Figma 목표값으로 승격하지 않는다.

### 연결

선행: `specs/005-figma-layout-audit/trouble-shooting.md` `TS-20260819-001`(같은 원인, 컴포넌트 조사 단계). 후속: 이 파일의 `TS-20260819-002`(같은 세션에서 발생한 디자인 자산 접근 제약).

## TS-20260819-002: 사용자 제공 로컬 디자인 자산 경로 읽기 거부

**기록일**: 2026-08-19
**상태**: 환경 제약
**발생 단계**: `$speckit-specify` — 사용자 첨부 디자인 자산 확인
**관련 항목**: `specs/006-final-uxui-screens/spec.md` 가정 섹션, 의존성 섹션

### 증상

사용자가 요청과 함께 첨부한 디자인 자산 경로 `/Users/jerry/Downloads/Safari/animation & logo/`의 파일을 어떤 도구로도 읽을 수 없었다. 디렉터리 목록 조회와 개별 파일 읽기가 모두 권한 오류로 실패했다.

### 영향

애니메이션 자산(`Animation_Complete.json`, `Animation_General_Loading.json`, `Animation_Notification.json`, `Animation_Project_Empty.json`, `Animation_Set Creation_Loading.json`, `Animation_Storage_Empty.json`), 레벨·지식 일러스트 SVG 7종, 앱 아이콘 SVG와 스플래시 미리보기 HTML의 실제 내용을 확인하지 못했다. 자산 형식, 크기, 색 정의와 필요한 렌더링 방식(예: Lottie 의존성 도입 여부)을 이 단계에서 판단할 수 없었다.

### 근거

- `ls -la "/Users/jerry/Downloads/Safari/animation & logo/"`: `Operation not permitted`을 반환하고 종료 코드 `1`로 끝났다.
- Read 도구로 `/Users/jerry/Downloads/Safari/animation & logo/Illust_Levels_Beginner.svg` 읽기: `EPERM: operation not permitted, open ...`을 반환했다.
- 파일명 자체는 사용자 요청 메시지에 포함되어 있어 목록만 확인할 수 있었다. 내용은 확인하지 못했다.

### 원인

macOS가 `~/Downloads`에 적용하는 접근 권한 정책으로 현재 실행 환경에 읽기 권한이 없다. 경로 오타나 파일 부재가 아니다. 두 개의 서로 다른 도구가 같은 오류를 반환한 점이 이를 뒷받침한다.

### 조치

자산 내용을 추측해 명세에 반영하지 않았다. 사용자가 전달한 파일명만으로 식별 가능한 범위를 명세의 가정 섹션에 기록하고, 접근 권한 확보 또는 저장소가 읽을 수 있는 위치로의 이동을 계획 단계 진입 전 선행 조건으로 명시했다. 애니메이션 재생 방식 결정은 이 명세에서 내리지 않고 보류했다.

### 검증

- Bash `ls`와 Read 도구 두 경로 모두 실패: 확인함. 단일 도구의 문제가 아님을 구분했다.
- 자산 내용 기반 판단(형식, 크기, 색): 미실행. 읽기 권한이 없어 실행 조건을 만들 수 없다.

### 재발 방지

사용자가 `~/Downloads`, `~/Desktop`, `~/Documents` 아래 경로의 파일을 첨부하면 내용 기반 판단을 시작하기 전에 읽기 가능 여부를 먼저 확인한다. 읽지 못하면 파일명에서 유추한 내용을 확인된 사실로 기록하지 않고, 저장소 안으로 옮기도록 요청한다.

### 연결

선행: 이 파일의 `TS-20260819-001`(같은 세션의 디자인 원천 접근 제약). 후속: 없음.

## TS-20260819-003: Figma MCP 조회 복구 (TS-20260819-001 상태 변화)

**기록일**: 2026-08-19
**상태**: 해결
**발생 단계**: `$speckit-specify` — 사용자 요청에 따른 Figma 연결 재확인
**관련 항목**: 이 파일의 `TS-20260819-001`, `specs/006-final-uxui-screens/spec.md` FR-015

### 증상

`TS-20260819-001`에서 호출 한도 오류를 반환하던 Figma MCP 조회가 재시도 시 정상 응답했다. 한도 오류는 더 이상 재현되지 않았다.

### 영향

`최종 UXUI`의 화면 목록과 디자인 원천을 확보해 명세의 최대 차단 요인이 해소됐다. `TS-20260819-001`의 `환경 제약` 상태는 이 항목으로 갱신된다(원래 항목은 이력으로 보존).

### 근거

- `get_metadata(fileKey: mCRt0ejmzI4EFW3UnC9Bzb)`: 성공. 최상위 페이지 `86:761 📌 서비스 설계`를 반환했다.
- `use_figma` 읽기 전용 스크립트: 성공. `최종 UXUI`가 페이지가 아니라 `📌 서비스 설계` 안의 SECTION(`720:8655`, 자식 70개)임을 확인했다.
- `use_figma` 화면 열거: 기기 크기 프레임 65개(중첩 프레임 4개 제외)를 확인했다.
- `figma.variables.getLocalVariableCollectionsAsync()`: 색 변수 25개만 존재하고 FLOAT(여백·간격) 변수는 0개임을 확인했다.
- `figma.getLocalTextStylesAsync()`: 텍스트 스타일 20종을 확인했다.

### 원인

플랜의 MCP 호출 한도가 시간 경과로 회복된 것으로 보인다. 저장소나 설정 변경은 없었다. 회복 주기는 확인하지 못했다.

### 조치

확보한 화면 목록과 디자인 원천 요약을 `spec.md` 부록에 기록하고, FR-015의 `[NEEDS CLARIFICATION]`을 실제 확보 수단(색은 변수, 텍스트는 스타일, 여백은 프레임 auto-layout 실측)으로 대체했다. 체크리스트의 차단 요인 항목도 해소 상태로 갱신했다.

### 검증

- `spec.md` 부록과 Figma 조회 결과 대조: 화면 프레임 65개와 그룹별 분류가 일치함을 확인했다.
- 여백·색 확정값의 화면별 계약 작성: 미실행. 계획 단계의 작업이다.

### 재발 방지

한도 오류는 영구 차단이 아니라 회복 가능한 제약으로 취급한다. 한도 오류 발생 시 작업을 포기하지 말고 미확정 범위를 명시해 진행한 뒤, 이후 세션에서 재시도해 상태 변화를 새 항목으로 기록한다.

### 연결

선행: 이 파일의 `TS-20260819-001`, `specs/005-figma-layout-audit/trouble-shooting.md` `TS-20260819-001`. 후속: 이 파일의 `TS-20260819-004`.

## TS-20260819-004: `get_metadata` 응답이 전송 한계를 초과해 파싱 실패

**기록일**: 2026-08-19
**상태**: 완화
**발생 단계**: `$speckit-specify` — `최종 UXUI` 구조 조회
**관련 항목**: `specs/006-final-uxui-screens/spec.md` 의존성 섹션

### 증상

`get_metadata`에 `nodeId: 86:761`(페이지 전체)을 지정하면 응답이 도착하기 전에 SSE 파싱이 실패했다. 오류는 `Failed to parse SSE message: Invalid JSON: EOF while parsing a string at line 1 column 187355`였다.

### 영향

페이지·섹션 단위의 구조를 `get_metadata`로 한 번에 읽을 수 없어, 화면 목록 확보 방법을 바꿔야 했다. 이 실패는 호출 한도 오류(`TS-20260819-001`)와 증상이 달라 구분이 필요하다.

### 근거

- `get_metadata(nodeId: 86:761)` 1차 호출: 위 파싱 오류로 실패했다.
- 같은 호출 2차 재시도: 동일한 오류가 **같은 컬럼 번호(187355)** 에서 재현됐다. 일시적 전송 오류가 아니라 응답 크기에 기인함을 뒷받침한다.
- `get_metadata(fileKey만 지정)`: 성공했다. 작은 응답은 문제가 없다.
- `use_figma` 읽기 전용 스크립트로 필요한 필드만 반환: 성공했다.

### 원인

`📌 서비스 설계` 페이지의 하위 트리가 커서 `get_metadata`의 XML 응답이 전송 계층이 처리할 수 있는 크기를 넘었다. 권한이나 한도 문제가 아니다.

### 조치

`get_metadata` 대신 `use_figma`로 읽기 전용 스크립트를 실행해 필요한 필드(`id`, `name`, `type`, 좌표, 크기)만 선택 반환하도록 바꿨다. 섹션 → 그룹 → 화면 순으로 나누어 조회해 각 응답을 작게 유지했다. 근본 원인인 응답 크기 자체는 해소하지 않았으므로 상태는 `완화`다.

### 검증

- `use_figma` 3회 호출(섹션 자식 70개, 그룹 4개 자식, 기기 크기 프레임 65개): 모두 성공했다.
- `get_metadata`로 페이지 전체를 읽는 경로: 여전히 실패. 재시도하지 않는다.

### 재발 방지

큰 Figma 페이지나 섹션은 `get_metadata`로 한 번에 읽지 않는다. 먼저 `get_metadata`를 `nodeId` 없이 호출해 페이지 목록만 얻고, 이후 구조 탐색은 `use_figma` 읽기 전용 스크립트로 필요한 필드만 반환한다. SSE 파싱 오류가 같은 컬럼 번호에서 재현되면 전송 크기 문제로 판정하고 조회 단위를 줄인다.

### 연결

선행: 이 파일의 `TS-20260819-003`. 후속: 없음.
