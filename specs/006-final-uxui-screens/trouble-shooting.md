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

## TS-20260819-005: 정합성 검색 패턴의 백틱이 셸 명령 치환으로 해석됨

**기록일**: 2026-08-19
**상태**: 해결
**발생 단계**: `$speckit-plan` — 계획 산출물 정합성 검색
**관련 항목**: `specs/006-final-uxui-screens/plan.md`, `research.md`, `contracts/**`

### 증상

`rg` 검색식을 큰따옴표로 감싼 셸 명령 안에 Markdown 인라인 코드용 백틱을 포함하자
zsh가 백틱 내부의 `보류`를 명령 치환으로 해석해 `zsh:1: command not found: 보류`를
출력했다. 뒤의 `rg`는 실행됐지만 원래 의도한 검색 패턴이 보존되지 않아 결과를 검증
근거로 사용할 수 없었다.

### 영향

파일 변경이나 데이터 손상은 없었다. 다만 공유 Mock, 그라데이션 방향 보류와 오래된 기준선
문구가 제거됐는지 확인하는 정합성 검색을 다시 실행해야 했다.

### 근거

- 첫 정합성 검색: `zsh:1: command not found: 보류`를 출력했다.
- 같은 시점의 Git 상태: 계획 산출물만 변경·추가된 상태였고 셸 명령은 읽기 전용 `rg`였다.

### 원인

큰따옴표 안의 백틱은 문자열 문자가 아니라 zsh의 명령 치환 구문이다. Markdown 표현을
검색식에 그대로 넣으면서 셸 인용 규칙을 적용하지 않은 것이 확정 원인이다.

### 조치

검색식에서 백틱을 제거하고 정규식을 작은따옴표로 감싸 같은 대상 경로를 다시 검색했다.
이후 셸 명령의 검색 패턴에는 실행 의미가 있는 백틱을 넣지 않는다.

### 검증

- 수정한 `rg` 명령: 성공. 남은 일치는 `research.md`에서 기각한 대안으로 언급한
  `DomainTestDouble` 한 건뿐이었고, 제거 대상인 실제 계획 문구는 남아 있지 않았다.
- 파일 손상 여부: 읽기 전용 검색이므로 변경 없음. 최종 `git diff --check`는 계획 단계
  종료 시 실행한다.

### 재발 방지

셸 검색 패턴은 작은따옴표로 감싸고, Markdown 백틱 자체가 판정에 필요하지 않으면 검색식에서
제거한다. 백틱이 반드시 필요하면 셸을 거치지 않는 도구나 안전한 고정 문자열 인자를 쓴다.

### 연결

선행·후속 문제 ID 없음.

## TS-20260819-007: 동일 파일 delete/add를 한 패치에 넣어 작업 목록 교체 실패

**기록일**: 2026-08-19
**상태**: 해결
**발생 단계**: `$speckit-tasks` — `tasks.md` 전체 재생성
**관련 항목**: `specs/006-final-uxui-screens/tasks.md`

### 증상

기존 `tasks.md`를 전체 교체하기 위해 하나의 `apply_patch` 입력에 같은 파일의
`Delete File`과 `Add File` 연산을 함께 넣자 `apply_patch verification failed: invalid
patch: multiple operations target .../tasks.md`로 거부됐다.

### 영향

패치는 검증 단계에서 거부되어 기존 파일은 그대로 보존됐고 부분 적용은 없었다. 작업 목록
재생성만 일시 중단됐다.

### 근거

- 첫 `apply_patch`: 동일 절대 경로를 delete/add 두 연산의 대상으로 지정했고 위 검증 오류를
  반환했다.
- 분리한 `Delete File`과 `Add File`: 각각 성공했다.
- 재생성 후 형식 검사: 작업 90개, ID `T001`~`T090` 순차, 체크리스트 형식 90/90 유효.

### 원인

`apply_patch`는 한 patch set에서 같은 파일을 대상으로 한 복수 연산을 허용하지 않는다.
전체 교체 의도와 무관하게 delete/add를 서로 다른 patch set으로 분리해야 한다.

### 조치

첫 패치가 파일을 바꾸지 않았음을 확인한 뒤 삭제와 추가를 두 개의 원자적 `apply_patch`
호출로 분리했다. 새 파일을 추가한 즉시 작업 수, ID 연속성과 체크리스트 형식을 검사했다.

### 검증

- `awk` ID 검사: `task-count:90`, 순서 오류 0건.
- 체크리스트 정규식 검사: `total=90 valid=90`.
- 파일 변경 작업의 경로 검사: `sources/`로 시작하는 저장소 상대 경로가 없는 작업 0건.

### 재발 방지

파일 전체 교체가 필요하면 동일 patch set에서 delete/add를 결합하지 않는다. 가능하면
`Update File` 단일 연산을 쓰고, 전체 삭제·재생성이 더 명확할 때는 삭제 성공 뒤 추가를
별도 patch set으로 적용한 후 즉시 존재·형식·내용 검증을 실행한다.

### 연결

선행·후속 문제 ID 없음.

## TS-20260819-006: 읽기 전용 `use_figma`에서 노드 스크린샷 호출 실패

**기록일**: 2026-08-19
**상태**: 해결
**발생 단계**: `$speckit-plan` — edge dim 그라데이션 방향 확인
**관련 항목**: `research.md` R-05, `contracts/design-token-alignment.md`,
`contracts/reference-screen-layout.md`

### 증상

Figma Rectangle `1216:16397`, `1216:16399`의 렌더 방향을 시각 확인하기 위해
`node.screenshot()`을 호출했으나 `Error: in screenshot: Can't call "screenshot" in
read-only mode`로 실패했다.

### 영향

Figma 파일은 변경되지 않았고 다른 조회도 중단되지 않았다. 스크린샷에 의존한 방향 판정은
할 수 없었으므로 원시 fill 행렬과 실제 참조 화면의 컴포넌트 변형을 직접 조회하는 방법으로
검증 경로를 바꿔야 했다.

### 근거

- `use_figma`의 `node.screenshot({ scale: 2, contentsOnly: true })`: 읽기 전용 모드 오류.
- 하위 fill 조회: `top dim` Rectangle `1216:16441`과 `bottom dim` Rectangle
  `1216:16399`의 `GRADIENT_LINEAR`, 정지점과 `gradientTransform`을 반환했다.
- 참조 화면 6개 조회: 모두 상단 `Property 1=문제풀이용`과 하단 `bottom dim` 인스턴스를
  사용했다.

### 원인

현재 `use_figma` 실행 모드는 읽기 전용이며 이 모드에서는 추가 렌더 작업인
`node.screenshot()`이 허용되지 않는다. 노드나 파일 내용의 문제가 아니다.

### 조치

스크린샷 호출을 반복하지 않고 각 컴포넌트의 최소 하위 트리에서 gradient fill을 조회했다.
Figma Plugin API의 위→아래 기준 행렬과 실측 `gradientTransform`을 대조해 상단은 아래→위,
하단은 위→아래로 확정하고 원시 행렬과 정지점을 계약에 기록했다.

### 검증

- gradient fill 조회: 성공. 상단 행렬
  `[[0, -1, 1], [12.2160425, 0, -5.6080213]]`, 하단 행렬
  `[[0, 1, 0], [-9.6313915, 0, 5.3156958]]`을 확보했다.
- 참조 화면 상태 노드 6개 인스턴스 조회: 성공. 여섯 화면이 모두 같은 방향 근거를
  사용함을 확인했다.

### 재발 방지

읽기 전용 `use_figma`에서는 노드 시각 캡처를 시도하지 않고 `fills`, `gradientStops`,
`gradientTransform`과 실제 instance의 variant를 우선 조회한다. 이미지가 반드시 필요하면
읽기 전용 캡처를 지원하는 별도 도구의 가용성을 먼저 확인한다.

### 연결

선행·후속 문제 ID 없음.

## TS-20260819-008: 공통 patch anchor로 후속 기록이 파일 중간에 삽입됨

**기록일**: 2026-08-19
**상태**: 완화
**발생 단계**: `$speckit-troubleshooting` — `TS-20260819-007` append
**관련 항목**: `specs/006-final-uxui-screens/trouble-shooting.md`의
`TS-20260819-006`, `TS-20260819-007`

### 증상

`TS-20260819-007`을 파일 끝에 추가하려고 했으나 patch context로 여러 항목에 반복되는
`선행·후속 문제 ID 없음.` 문장만 사용해, 실제로는 `TS-20260819-005` 뒤이자 기존
`TS-20260819-006` 앞에 삽입됐다. 그 결과 heading 순서가 `005 → 007 → 006`이 됐다.

### 영향

기존 항목의 문장과 바이트는 삭제·수정되지 않았고 `TS-20260819-007`의 사실 내용도
유효하다. 다만 append-only 파일의 물리적 순서가 ID 순서와 어긋났으며, 이를 바로잡기 위해
기존 항목을 이동하면 append-only 보존 원칙을 다시 위반하게 된다.

### 근거

- `rg -n '^## TS-' trouble-shooting.md`: `TS-20260819-007`이 232행,
  `TS-20260819-006`이 283행에 있음을 반환했다.
- patch 적용 전후 기존 항목 삭제·수정: 없음. 새 블록 삽입만 발생했다.

### 원인

파일 끝에만 존재하는 문맥을 확인하지 않고 여러 항목에서 반복되는 연결 문장을 patch
anchor로 사용했다. `apply_patch`가 첫 일치 위치를 선택한 것이 확정 원인이다.

### 조치

append-only 원칙을 지키기 위해 `TS-20260819-007`을 이동하거나 삭제하지 않았다. 대신
현재 오류를 설명하는 이 후속 항목을 `TS-20260819-006`의 고유한 마지막 문맥 뒤, 실제 파일
끝에 추가했다.

### 검증

- `tail`로 `TS-20260819-006`의 마지막 문맥이 실제 EOF임을 확인한 뒤 이 항목을 추가했다.
- heading ID 고유성 검사는 최종 문서 검증에서 실행한다.
- 물리적 heading 순서 교정: 미실행. 기존 기록 이동이 append-only 원칙을 위반하므로
  의도적으로 보존했다.

### 재발 방지

append-only 파일에는 반복되는 짧은 문장을 anchor로 쓰지 않는다. 먼저 `tail`로 EOF의
고유한 3개 이상 문장을 확인하고 그 전체 문맥을 patch anchor로 사용한다. 적용 뒤에는
heading 순서와 파일 tail을 즉시 확인한다.

### 연결

선행: `TS-20260819-007`. 후속: 없음.

## TS-20260819-009: Domain 패키지 검증 명령과 실행 환경 불일치

**상태**: 완화

**발생 작업**: `$speckit-implement` Domain 패키지 `T001`~`T015`

**관련 커밋**: `b812b19`, `f929842`

### 증상

- 새 `LearningProject` source directory가 아직 없을 때 `make tuist`가 source glob을
  찾지 못해 generation 단계에서 실패했다.
- `project-build` runner에 `test DomainLearningProject`를 전달하면 scheme을 받지 않고
  `오류[common.invalid-input]: ACTION 한 개가 필요합니다`로 종료했다.
- 이름 기반 `iPhone 17 Pro` destination은 디스크에서 사라진 simulator UUID를 선택해
  test 실행 단계에서 boot에 실패했다.
- sandbox 안에서는 CoreSimulator service와 SwiftPM cache 접근이 거부되어 사용 가능한
  simulator 조회와 `swift-format` lint가 실패했다.

이 문제들은 구현 계약과 무관하지만 Red 검증과 최종 build/test/lint를 차례로 막아,
환경 또는 도구 인터페이스 실패를 제품 코드 실패로 오판할 위험이 있었다.

### 근거

- 최초 `make tuist`: `invalid source files globs ... LearningProject/** does not exist`.
- `project_build_runner test DomainLearningProject`:
  `오류[common.invalid-input]: ACTION 한 개가 필요합니다`.
- 이름 기반 destination test:
  `Unable to boot device because it cannot be located on disk`.
- sandbox 안 `xcrun simctl list devices available`: CoreSimulator service 연결 실패.
- 사용 가능한 booted UUID `FF975095-E0FC-434D-89E9-E3EBA19EB913`를 지정한 최종
  `xcodebuild build`: `** BUILD SUCCEEDED **`.
- 같은 UUID와 격리된 Derived Data/result bundle을 사용한 최종 test: 2개 suite의 5개
  test가 모두 통과했고 `** TEST SUCCEEDED **`를 반환했다.

### 원인

- Tuist는 target source glob을 평가할 때 해당 directory가 실제로 존재해야 한다.
- 현재 `project-build` runner의 공개 입력은 action 하나만 받으며, 작업 문서에 적힌
  scheme 인자 형태와 일치하지 않는다.
- 이름 기반 destination 해석이 현재 사용할 수 없는 과거 simulator UUID를 선택했다.
- sandbox는 사용자 SwiftPM cache와 CoreSimulator service 접근 권한을 제공하지 않았다.

### 조치

- `T006`의 정확한 허용 경로에 `LearningProjectID.swift`를 먼저 만든 뒤 project를 다시
  생성하고, 아직 구현하지 않은 나머지 모델을 참조하는 test로 Red를 확인했다.
- 대상 scheme 검증은 절대 workspace 경로와 격리된 Derived Data를 지정한
  `xcodebuild`로 실행했다.
- 권한이 필요한 조회를 승인된 환경에서 다시 실행해 사용 가능한 simulator UUID를
  확인하고 build/test destination에 직접 지정했다.
- 동일한 관련 파일 범위의 formatter lint를 승인된 환경에서 다시 실행했다.

### 검증

- Red 단계에서 `LearningProjectID`, `LearningProgress`, `LearningSetMark`,
  `LearningProjectSummary`, `LearningProjectPage` 부재로 compile 실패함을 확인했다.
- 최종 `make tuist`와 `DomainLearningProject` build가 성공했다.
- `DomainLearningProjectTests`의 2개 suite, 5개 test가 모두 통과했다.
- 변경한 Domain/Tuist Swift 파일의 formatter lint가 0 violation으로 통과했다.
- 두 구현 커밋의 pre-commit 회귀 테스트가 모두 통과했다.

### 재발 방지

- 새 source directory를 추가할 때는 해당 task가 허용한 실제 source 파일을 하나 이상
  만든 뒤 `tuist generate`를 실행한다.
- runner가 scheme 인자를 지원하기 전까지 단일 scheme 검증은 격리된 경로를 사용하는
  직접 `xcodebuild`로 수행한다.
- simulator는 사용 가능한 UUID를 확인해 명시하고, sandbox 권한 실패는 제품 실패로
  해석하지 않고 같은 명령을 필요한 권한으로 재실행한다.

### 연결

선행: 없음. 후속: 없음.
