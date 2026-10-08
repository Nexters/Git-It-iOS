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
- `docs/spec-kit/005-figma-layout-audit/trouble-shooting.md:7` `TS-20260819-001`: 같은 날 같은 원인의 선행 기록이 존재한다.

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

선행: `docs/spec-kit/005-figma-layout-audit/trouble-shooting.md` `TS-20260819-001`(같은 원인, 컴포넌트 조사 단계). 후속: 이 파일의 `TS-20260819-002`(같은 세션에서 발생한 디자인 자산 접근 제약).

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

선행: 이 파일의 `TS-20260819-001`, `docs/spec-kit/005-figma-layout-audit/trouble-shooting.md` `TS-20260819-001`. 후속: 이 파일의 `TS-20260819-004`.

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
**관련 항목**: `docs/spec-kit/006-final-uxui-screens/trouble-shooting.md`의
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

## TS-20260819-010: Composition 테스트 scheme과 작업 소유 경로 불일치

**기록일**: 2026-08-19

**상태**: 미해결

**발생 단계**: `$speckit-implement` Composition 패키지 `T016`~`T028` 사전 검증

**관련 항목**: `T016`, `T020`, `T027`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

### 증상

`CompositionTests` target은 존재하지만 공유 `Composition` scheme의 test action에 연결되지
않아 project build runner가 해당 테스트를 실행 대상으로 선택할 수 없다. 직접 target test
실행과 build-only test products 실행도 scheme 또는 `build-for-testing` 산출물이 없어 실제
테스트 실행으로 이어지지 않았다.

### 영향

`T017`~`T019`의 Red와 `T027`의 Green 테스트를 실제 실행했다는 근거를 만들 수 없다.
scheme 연결을 소유하는 `ProjectName.swift`는 현재 Composition 작업의 허용 수정 경로에 없기
때문에 `$speckit-implement`로 임의 수정할 수도 없다. 따라서 Composition 구현과 커밋을
시작하지 않고 작업 목록 보정 단계에서 중단했다.

### 근거

- `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`: Composition scheme이
  `.module(name: "Composition")`만 사용하고 `testTarget`을 전달하지 않는다.
- 생성된 `Composition.xcscheme`: `<Testables>`가 비어 있다.
- `tools/githooks/project-build/core/workspace.sh`: `<TestableReference`가 있는 공유
  scheme만 testable 대상으로 판정한다.
- `xcodebuild test -project ... -target CompositionTests -destination ...`: scheme을
  지정해야 한다는 오류와 함께 종료 코드 65를 반환했다.
- `xcodebuild test-without-building -testProductsPath ...`: test products `Info.plist`가
  없고 `build-for-testing`을 다시 실행하라는 오류와 함께 종료 코드 66을 반환했다.
- 현재 `tasks.md`의 Composition 소유 경로와 `T016`~`T026`에는
  `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`가 없다.

### 원인

확정 원인은 Tuist 선언에서 `CompositionTests` target을 만들었지만 `Composition` 공유
scheme의 test action에는 연결하지 않은 상태와, 그 연결 파일을 Composition 작업에 배정하지
않은 `tasks.md`가 함께 존재하는 것이다. runner는 의도대로 test action이 비어 있는 scheme을
제외하므로 runner 자체 오동작은 아니다.

### 조치

- 생성 scheme XML, `ProjectName.swift`와 project build runner의 testable scheme 판정 코드를
  대조했다.
- source를 수정하지 않는 직접 target test와 test products 실행 대안을 격리된
  `/private/tmp` 경로에서 확인했지만 실제 테스트 실행 대안으로 성립하지 않았다.
- 허용 범위를 우회해 `ProjectName.swift` 또는 생성 scheme을 수정하지 않았고 Composition
  구현 파일도 생성하지 않았다.
- `$speckit-tasks`로 `ProjectName.swift`의 Composition scheme 구획을 정확히 하나의
  Composition 작업에 배정하는 보정은 미실행 상태다.

### 검증

- `git status --short --branch`: 기록 전 구현 변경이 없는 깨끗한 작업 트리를 확인했다.
- `rg`로 생성 scheme의 `<Testables>`가 비어 있고 runner가 `<TestableReference`를 검사하는
  것을 확인했다.
- `CompositionTests` 실제 test 실행: 미실행. test action 연결이 없어 차단됨.
- `T016`~`T028` 구현 및 커밋: 미실행.

### 재발 방지

새 test target 작업을 생성할 때 target 선언뿐 아니라 공유 scheme의 `testTarget` 연결과 그
파일의 패키지 소유 작업을 함께 배정한다. Red 테스트를 작성하기 전 생성 scheme의
`<TestableReference>`와 runner의 testable scheme 목록을 확인하며, 누락되면 구현 스킬의
허용 범위를 넓혀 우회하지 않고 `$speckit-tasks`로 작업 목록을 먼저 보정한다.

### 연결

선행: `TS-20260819-009`. 후속: 없음.

## TS-20260819-011: Composition 테스트 scheme 차단 해소와 검증 환경 재시도

**기록일**: 2026-08-19

**상태**: 해결

**발생 단계**: `$speckit-tasks` 작업 보정 및 `$speckit-implement` Composition 패키지
`T016`~`T028`

**관련 항목**: `TS-20260819-010`, `T016`~`T028`, `a60ebd2`, `380c4b4`,
`24d5068`

### 증상

선행 기록의 `CompositionTests` scheme 연결 누락을 보정한 뒤 Red·Green 검증을 재개했다.
이 과정에서 sandbox 안의 `make tuist`가 Tuist 사용자 세션 디렉터리 쓰기 권한으로 실패했고,
전체 변경 파일 lint도 SwiftPM·Clang 사용자 캐시 접근 제한으로 실패했다. 권한이 허용된
환경에서 lint를 다시 실행하자 `CompositionModuleName.swift`의 기존 마지막 인자 쉼표 누락
1건이 실제 형식 오류로 구분되어 검출됐다.

### 영향

scheme 차단이 해소되기 전에는 Composition 테스트 실행 증거를 만들 수 없었고, 이후의 권한
실패를 제품 코드 또는 형식 오류로 오판할 수 있었다. 쉼표 오류를 교정하지 않으면 변경 파일
전체 lint와 커밋 훅을 통과할 수 없었다.

### 근거

- `a60ebd2`: Composition 소유 경로에 `ProjectName.swift` 작업을 추가하고 scheme 전용 직접
  `xcodebuild` 검증으로 `tasks.md`를 보정했다.
- 생성된 `sources/Projects/Composition/Composition.xcodeproj/xcshareddata/xcschemes/Composition.xcscheme`:
  `CompositionTests`의 `<TestableReference>`와 `BlueprintName`을 확인했다.
- Red `xcodebuild test`: `Cannot find type 'SampleDeleteLearningProject' in scope`로 종료 코드
  65를 반환해 환경이 아닌 구현 계약 부재 실패임을 확인했다.
- sandbox `make tuist`: `/Users/jerry/.local/state/tuist/sessions/...`에 대한
  `Permission denied`로 중단됐다.
- sandbox Swift lint: `/Users/jerry/.cache/clang/ModuleCache`에 대한
  `Operation not permitted`로 중단됐다.
- 권한 허용 환경 Swift lint: `CompositionModuleName.swift:45:1`의 `trailingCommas` 1건을
  보고했다.

### 원인

선행 차단의 확정 원인은 `Composition` scheme에 `CompositionTests` test action이 없고 이를
수정할 파일이 작업 소유 경로에도 없던 것이다. 추가 실패의 원인은 sandbox가 Tuist와 SwiftPM,
Clang의 사용자 상태·캐시 경로 쓰기를 허용하지 않은 환경 제약이다. 형식 실패의 확정 원인은
이번에 수정한 `CompositionModuleName.swift`의 다중 인자 `.project` 호출 마지막 인자에 저장소
규칙이 요구하는 쉼표가 없던 것이다.

### 조치

- `$speckit-tasks`로 `ProjectName.swift`를 독립 `T017`에 배정하고 이후 작업 ID를 연속으로
  이동했으며, `T021`과 `T028`을 직접 격리 `xcodebuild` 검증으로 교정했다.
- `ProjectName.swift`의 Composition scheme에 `testTarget: "CompositionTests"`를 연결했다.
- Tuist 생성과 Swift lint는 같은 명령을 필요한 권한이 허용된 환경에서 다시 실행했다.
- `CompositionModuleName.swift`의 `path: "../Composition"` 뒤에 마지막 인자 쉼표를 추가했다.
- Red 실패 확인 뒤 actor 저장소, 두 Domain Protocol 구현, `AppComposition`과 13개 테스트를
  구현하고 두 기능 커밋으로 분리했다.

### 검증

- `make tuist`: 권한 허용 환경에서 성공했고 생성 scheme의 `CompositionTests`
  `<TestableReference>`를 확인했다.
- 격리된 `xcodebuild build -workspace sources/GitIt.xcworkspace -scheme Composition`:
  종료 코드 0.
- 별도 격리 경로의 `xcodebuild test`: 종료 코드 0.
- `xcrun xcresulttool get test-results summary`: 총 13개 중 통과 13, 실패 0, 건너뜀 0,
  결과 `Passed`.
- 변경 Swift 파일 저장소 lint: 형식 교정 뒤 0 violation.
- 정적 검색: Composition production의 `FetchLearningProjectsMock`,
  `DeleteLearningProjectMock`, `FeatureTests`, `Mock` 참조 0건이며 `live()`와 두 표본 구체
  구현 선택 파일은 `AppComposition.swift` 한 곳이다.
- `380c4b4`, `24d5068`: 두 커밋 모두 pre-commit 스크립트 회귀 검증을 통과했다.

### 재발 방지

새 test target을 추가하는 작업은 target, 공유 scheme test action과 정확한 소유 경로를 함께
배정한다. 단일 scheme의 Red·Green은 runner가 scheme 인자를 지원하기 전까지 서로 다른 임시
Derived Data를 지정한 직접 `xcodebuild`로 실행한다. Tuist·Swift lint가 사용자 상태 또는 캐시
권한으로 실패하면 제품 실패와 분리해 같은 명령을 필요한 권한으로 재실행하고, 그 결과에서
나온 실제 형식 오류를 별도로 교정한다.

### 연결

선행: `TS-20260819-010`. 후속: 없음.

## TS-20260819-012: UI 검증 명령과 기존 회귀 테스트의 작업 배정 누락

**기록일**: 2026-08-19

**상태**: 해결

**발생 단계**: `$speckit-implement` UI 패키지 `T030`~`T056` 사전 검증

**관련 항목**: `T035`, `T054`, `76ce6cb`, `804959e`

### 증상

초기 `T054`는 action 하나만 받는 project build runner에 scheme 인자를 함께 전달하도록 적혀
있어 실행할 수 없었다. 또한 `ActionButton.Size.small == 40`을 기대하는 기존
`LayoutConstantContractTests.swift`가 새 LG·MD·SM 계약과 충돌했지만, 그 파일은 최초 UI
작업에 배정되지 않았다.

### 영향

원문 그대로는 UI package 세 scheme을 서로 격리해 검증할 수 없고, 새 Red 테스트를 통과시켜도
작업 범위 밖의 기존 회귀 테스트가 Green을 막는다. 구현 스킬이 임의로 runner 인터페이스나
미배정 테스트를 수정하면 작업 소유 경계를 위반하게 된다.

### 근거

- project build runner는 공개 입력으로 action 하나만 허용하며 scheme 인자를 받지 않는다.
- `LayoutConstantContractTests.swift`는 기존 `ActionButton.Size.small.surfaceHeight == 40`을
  단언했다.
- `76ce6cb`은 `T054`를 scheme별 직접 `xcodebuild build`·`xcodebuild test`와 격리된
  `-derivedDataPath`로 교정했다.
- `804959e`는 기존 회귀 파일을 독립 `T035`에 배정하고 이후 작업 번호를 연속으로 이동했다.

### 원인

작업 생성 시 저장소 runner의 실제 인자 계약과 기존 UIComponent 테스트 인벤토리를 함께
대조하지 않아, 실행할 수 없는 검증 명령과 누락된 회귀 파일 소유 범위가 만들어졌다.

### 조치

- UI 구현 전에 `tasks.md`만 두 작업 단위로 먼저 보정하고 각각 문서 커밋으로 고정했다.
- 기존 회귀 기대를 LG 54pt·MD 40pt·SM 36pt 계단으로 교정하는 작업을 명시했다.
- 최종 검증은 `DesignSystem`, `UIComponent`, `UIComponentLayout`마다 별도 임시 Derived Data를
  사용하는 직접 `xcodebuild`로 수행했다.

### 검증

- 작업 ID가 `T001`~`T092`까지 중복과 누락 없이 연속임을 확인했다.
- `make tuist`가 성공했다.
- 세 scheme의 독립 build가 모두 종료 코드 0을 반환했다.
- xcresult 요약은 `DesignSystem` 31/31, `UIComponent` 14/14,
  `UIComponentLayout` 15/15 통과를 반환했다.

### 재발 방지

패키지 검증 작업을 생성할 때 runner의 실제 usage를 먼저 실행해 action·scheme 입력을 확인한다.
기준선 변경은 신규 테스트만 검색하지 않고 같은 public API를 참조하는 기존 테스트를 `rg`로
전량 찾아 정확한 수정 파일을 작업 소유 경로에 함께 배정한다.

### 연결

선행: `TS-20260819-011`. 후속: 없음.

## TS-20260819-013: UI 렌더 계약 하네스의 좌표·픽셀 판독 오탐

**기록일**: 2026-08-19

**상태**: 해결

**발생 단계**: `$speckit-implement` UI 패키지 `T039`~`T055` Red·Green 검증

**관련 항목**: `T039`~`T055`, `04ea419`, `5005549`

### 증상

실제 컴포넌트 값을 교정한 뒤에도 UI 테스트가 단계별로 서로 다른 실패를 보고했다. 상위
accessibility identifier가 자식 identifier를 가렸고, 기본 ProjectRow fixture의 긴 제목이
최대 Dynamic Type 스트레스 조건과 섞였다. screenshot crop 뒤 Y축을 한 번 더 뒤집었으며,
같은 RGB의 모든 픽셀을 하나의 bounds로 합쳐 우연히 일치한 단일 픽셀까지 측정했다. 캡슐과
라운드 사각형의 strict RGB 경계는 안티앨리어싱 때문에 실제 폭과 반경도 축소·과대평가했다.

정적 리뷰에서는 `ActionMenu`의 외부 `minHeight`가 명시된 아래 9pt 외에 21pt 빈 공간을
추가하고, ProjectRow의 26pt 강제가 `TagBadge` 고유 높이를 overflow시키는 문제도 발견했다.

### 영향

제품 구현 실패와 테스트 하네스 오탐을 구분하지 않으면 Figma 확정값을 오탐에 맞춰 바꾸거나,
Dynamic Type 콘텐츠를 clip하고도 Green으로 오판할 수 있었다. `swiftc -parse`만으로는 한때
누락된 `return`도 검출하지 못해 실제 target typecheck가 별도로 필요했다.

### 근거

- 최초 visual Red: 기존 회귀를 포함해 7개 실패·4개 통과, identifier 보정 뒤 3개 실패·8개
  통과.
- 첫 Green 전체 실행: 15개 중 13개 통과, ProjectRow 162pt와 Sheet grabber 상대 좌표 실패.
- fixture·crop 보정 뒤: ProjectRow 151.333pt, grabber strict 폭 57.333pt.
- 잘못된 Y 반전·전역 union 경로에서는 thumbnail 60pt를 100pt, grabber top 5pt를
  50.718pt로 오판했다.
- 첫 전체 픽셀 보정 실행은 15개 중 13개 통과했고 progress fill 208pt를 207.333pt,
  `tag.radius` 8pt를 9.7pt로 읽었다.
- 최종 `/private/tmp/GitIt-006-T054-UIComponentLayout.xcresult`는 15개 전부 통과했다.

### 원인

- SwiftUI accessibility container의 상위 identifier가 결합된 자식 식별자를 덮었다.
- 기본 크기와 최대 Dynamic Type fixture가 서로 다른 검증 목적을 공유했다.
- upright screenshot에 불필요한 CGContext Y flip을 적용했고, RGB bounds가 연결 영역을
  구분하지 않았다.
- strict 단색 픽셀만 도형 경계로 취급해 캡슐 edge와 라운드 corner의 subpixel coverage를
  버렸다.
- `ActionMenu`는 126pt surface에서 위 8pt·아래 9pt를 뺀 109pt를 항목에 배분하지 않았고,
  ProjectRow의 150pt는 Dynamic Type 계약상 고정 높이가 아니라 최소 높이인데 26pt 세부 영역을
  강제했다.

### 조치

- 하위 실제 컴포넌트 identifier를 덮는 그룹 identifier를 제거하고 offscreen element를 찾는
  `reveal` 경로를 추가했다.
- 기본 fixture는 한 줄 문자열, 최대 Dynamic Type fixture는 긴 전체 접근성 문자열로 분리했다.
- app screenshot을 element frame으로 crop한 뒤 추가 Y flip을 제거하고, 4-connected component
  중 주 geometry marker만 선택했다.
- 캡슐은 좌우 1px 안티앨리어싱 edge를 복원하고, Tag는 marker/background RGB projection의
  50% coverage 교차점을 인접 pixel center 사이에서 보간해 반경을 추정했다. 이 RGB 허용치는
  geometry 탐색에만 쓰며 색 정합 근거로 사용하지 않는다.
- `ActionMenu`는 항목 2개에 54.5pt씩 배분해 8 + 54.5×2 + 9 = 126pt를 실제 frame으로 만들고,
  항목이 늘면 최소 44pt를 보존하며 surface를 확장한다.
- ProjectRow는 `TagBadge`를 압축하지 않고 150pt·94pt 최소 높이와 방향별 padding을 유지하며,
  렌더 테스트가 실제 12pt·12pt 간격과 아래 18pt를 판정하도록 했다.
- `xcodebuild build-for-testing`과 실제 UI test로 parse 외 typecheck·실행을 확인했다.

### 검증

- SheetSurface·ProjectRow·ActionMenu 선택 테스트 3/3 통과.
- progress 0%·65%·100%와 Tag radius 선택 테스트 2/2 통과.
- 전체 `UIComponentLayout` 15/15 통과, 실패·건너뜀 0.
- `UIComponent` 14/14 통과로 `ActionMenu` 2·3항목 높이 계산과 신규 공개 계약을 확인했다.
- 변경 Swift 파일 전체 저장소 formatter lint 0 violation, `git diff --check` 통과.
- 토큰 밖 색 리터럴과 의미 있는 body 직접 여백 수치 검색은 각각 0건이다.

### 재발 방지

렌더 테스트는 접근성 식별자가 실제 자식에 남는지 Red 단계에서 먼저 확인한다. 색상 bounds는
전역 union 대신 연결 영역을 사용하고, anti-aliased shape의 geometry는 coverage contour를
subpixel로 복원한다. `swiftc -parse` 성공을 target typecheck로 간주하지 않는다. 고정 크기와
최소 크기를 구분하고, 명시된 inset은 외부 min frame이 아니라 자식 frame의 실제 상대 좌표로
검증한다.

### 연결

선행: `TS-20260819-012`. 후속: 없음.

## TS-20260819-014: Feature 검증 명령과 source directory 준비 순서 불일치

**기록일**: 2026-08-19
**상태**: 해결
**발생 단계**: `$speckit-implement` Feature 패키지 T057~T065 Red·Green 검증
**관련 항목**: T057, T064, `sources/Projects/Feature/Presentation/**`,
`specs/006-final-uxui-screens/quickstart.md`

### 증상

Feature target을 `Presentation` source directory로 전환한 직후 해당 디렉터리가 아직 없어 첫
`make tuist`가 실패했다. 디렉터리를 만든 뒤에는 작업과 quickstart가 제시한
`project_build_runner test Feature`가 runner의 실제 인자 계약과 맞지 않아
`ACTION 한 개가 필요합니다`로 실패했다. 기본 destination의 이름 기반 simulator 항목도 데이터
디렉터리가 없어 사용할 수 없었다.

### 영향

T064 Red 검증과 Feature Green 검증을 계획에 적힌 명령 그대로 실행할 수 없었다. source 생성,
workspace 재생성과 scheme별 직접 `xcodebuild` 순서로 검증 경로를 교정해야 했다.

### 근거

- 첫 `make tuist`: `Presentation` source directory 부재로 project generation 실패.
- `project_build_runner test Feature`: `ACTION 한 개가 필요합니다`를 반환해 현재 runner가 scheme
  인자를 받지 않음을 확인했다.
- `xcrun simctl list devices available`: 이름 기반 `iPhone 17 Pro` 대신 정상 데이터가 있는
  `default`와 이 세션에서 만든 `GitItFeatureTests` UUID를 확인했다.

### 원인

source directory를 선언하는 T057과 실제 source를 만드는 T065 사이에 생성 명령을 실행했으며,
작업·quickstart의 scheme 인자 예시가 현재 runner의 action-only 계약과 달랐다. simulator 이름은
현재 설치 상태를 보장하는 안정적인 식별자가 아니었다.

### 조치

T065가 소유한 정확한 `Presentation/Screens/LearningProjectList` 경로를 먼저 만든 뒤
`make tuist`를 다시 실행했다. scheme별 검증은 quickstart의 fallback에 따라
`sources/GitIt.xcworkspace`와 격리 `-derivedDataPath`, 확인된 simulator UUID를 사용하는 직접
`xcodebuild`로 전환했다.

### 검증

- `make tuist`: 재실행 성공.
- `xcodebuild build -workspace sources/GitIt.xcworkspace -scheme Feature ...`: 성공.
- runner의 scheme별 실행: 미지원 상태를 확인했으므로 재시도하지 않았다.

### 재발 방지

source directory 전환 task는 최소 source 경로가 생긴 뒤 Tuist를 생성한다. scheme별 검증 task를
작성하거나 실행하기 전에 runner usage를 확인하고, 미지원이면 처음부터 workspace 직접 실행과
격리 Derived Data를 사용한다. destination은 실행 직전 `simctl`로 유효한 UUID를 확인한다.

### 연결

선행: `TS-20260819-012`. 후속: `TS-20260819-015`.

## TS-20260819-015: FeatureTests가 LocalStatusKit 메타데이터 실현 중 부트스트랩 충돌

**기록일**: 2026-08-19
**상태**: 환경 제약
**발생 단계**: `$speckit-implement` Feature 패키지 T068 검증
**관련 항목**: T061~T063, T065~T068,
`sources/Projects/Feature/FeatureTests/LearningProjectList/**`

### 증상

최종 Feature source와 test bundle은 `build-for-testing`까지 성공했지만 격리 simulator에서
`test-without-building`을 실행하면 테스트 본문에 진입하지 못하고 약 75초 뒤 `Early unexpected
exit`로 종료됐다. crash report는 Apple 내부 `LocalStatusKit`의
`PublishStatusInvocation` class metadata를 XCTest가 전체 class 목록에서 실현하는 중
`EXC_BAD_ACCESS (SIGSEGV)`가 발생했음을 보여 준다.

### 영향

Reducer·View와 세 테스트 파일은 컴파일됐고 Feature production build도 성공했지만, 상태 전이와
Effect 취소·오류 경로의 실행 검증을 완료할 수 없다. 따라서 T068·T069는 완료 처리할 수 없고,
검증되지 않은 변경을 커밋하지 않은 채 Feature 패키지에서 중단해야 한다.

### 근거

- `xcodebuild build-for-testing ... -scheme Feature ...`: 성공하고
  `Feature_iphonesimulator26.5-arm64.xctestrun`을 생성했다.
- `xcodebuild test-without-building -xctestrun ... -destination
  'platform=iOS Simulator,id=47B1E0AE-11C1-495B-BCE8-EE9C3E255104'`: 종료 코드 65,
  `The test runner crashed while preparing to run tests`.
- `/Users/jerry/Library/Logs/DiagnosticReports/xctest-2026-08-19-220431.ips`:
  `PublishStatusInvocation` → `realizeAllClasses()` → `objc_copyClassList` →
  `+[XCTestCase(RuntimeUtilities) allSubclasses]` 순서에서 `EXC_BAD_ACCESS`.
- 같은 격리 simulator에서 기존 `DesignSystem` xctestrun은 종료 코드 0으로 통과했다.

### 원인

확정된 직접 원인은 XCTest 부트스트랩이 Apple 내부 `LocalStatusKit` class metadata를 실현하는
과정의 메모리 접근 오류다. Feature 의존 그래프가 이 Apple framework를 로드하게 만드는 세부
조건과 Xcode·iOS 26.5 runtime 중 어느 구성요소의 결함인지는 확인 중이다. 테스트 assertion이나
Reducer 실행 실패는 테스트 본문에 진입하지 않아 원인으로 확인되지 않았다.

### 조치

기본 simulator, 이 세션의 새 simulator, scheme 실행과 생성된 `.xctestrun` 직접 실행으로 재현
경로를 분리했다. 통과한 DesignSystem과 `.xctestrun`의 Main Thread Checker 주입 조건을 비교해
동일함을 확인했으므로 진단 옵션을 임의로 끄지 않았다. Apple 공식 문서·포럼에서 해당 crash의
확정 우회를 찾지 못해 product·Tuist 설정을 추측으로 변경하지 않았다.

### 검증

- Feature production `xcodebuild build`: 성공.
- Feature `build-for-testing`: 성공, 테스트 source typecheck 완료.
- Feature `.xctestrun` 직접 실행: 실패, 테스트 0건 실행 전 동일 crash.
- 새 simulator에서 DesignSystem `.xctestrun`: 성공. simulator 전체 고장과는 구분됨.
- Feature 상태 전이 assertion: 미실행. XCTest 부트스트랩 충돌로 테스트 본문에 도달하지 못함.

### 재발 방지

동일한 `PublishStatusInvocation`·`objc_copyClassList` stack이면 product assertion 실패로 분류하지
않고 crash report와 테스트 실행 건수를 먼저 확인한다. Xcode 또는 simulator runtime 변경 뒤
Feature `.xctestrun`을 다시 실행해 환경 상태 변화를 확인하고, 테스트가 실제로 시작되기 전에는
T068을 완료로 표시하지 않는다.

### 연결

선행: `TS-20260819-014`. 후속: 없음.

## TS-20260819-016: FeatureTests LocalStatusKit 부트스트랩 충돌 재발

**기록일**: 2026-08-19
**상태**: 환경 제약
**발생 단계**: `$speckit-implement` Feature 패키지 T068 재검증
**관련 항목**: T068, `TS-20260819-015`,
`sources/Projects/Feature/FeatureTests/LearningProjectList/**`

### 증상

Feature 구현을 보존한 채 최신 workspace와 새로운 격리 Derived Data로 T068을 다시 실행했지만,
테스트 본문 0건 상태에서 `Early unexpected exit`가 재발했다. 이번 실행도 XCTest가
`LocalStatusKit`의 `PublishStatusInvocation` class metadata를 실현하는 중 같은 주소에서
`EXC_BAD_ACCESS (SIGSEGV)`로 종료됐다.

### 영향

Feature production build와 test bundle 컴파일은 다시 성공했지만 상태 전이, Effect 취소·오류
경로와 로컬 Mock 호출 검증은 여전히 실행되지 않았다. 따라서 T068·T069 완료 표시와 Feature
단위 커밋을 진행할 수 없다.

### 근거

- `make tuist`: 성공해 현재 source 기준 workspace를 생성했다.
- `xcodebuild build ... -scheme Feature ... -derivedDataPath
  /private/tmp/GitIt-006-T068-Feature-Retry`: 종료 코드 0.
- 같은 경로의 `xcodebuild build-for-testing`: 종료 코드 0,
  `Feature_iphonesimulator26.5-arm64.xctestrun` 생성.
- `xcodebuild test-without-building -xctestrun ... -destination
  'platform=iOS Simulator,id=FF975095-E0FC-434D-89E9-E3EBA19EB913'`: 종료 코드 65,
  25.5초 뒤 test runner bootstrap crash.
- `/Users/jerry/Library/Logs/DiagnosticReports/xctest-2026-08-19-221415.ips`:
  `KERN_INVALID_ADDRESS at 0x000000000bad4007`, `PublishStatusInvocation` →
  `realizeAllClasses()` → `objc_copyClassList` →
  `+[XCTestCase(RuntimeUtilities) allSubclasses]` 순서가 `TS-20260819-015`와 일치했다.

### 원인

확정된 직접 원인은 `TS-20260819-015`와 동일한 Apple 내부 `LocalStatusKit` metadata 실현
오류다. 새 Derived Data와 workspace 재생성으로도 재발해 stale project·Feature build cache가
직접 원인일 가능성은 낮아졌다. Feature 의존 그래프와 iOS 26.5 runtime 사이의 세부 유발 조건은
확인 중이다.

### 조치

추적 source를 수정하지 않고 Tuist 재생성, 격리 production build, 격리 test bundle 컴파일과
현재 부팅된 simulator UUID를 사용한 직접 `.xctestrun` 실행으로 다시 분리 검증했다. crash
stack이 동일해 product·Tuist 설정을 추측으로 바꾸지 않았고 T068을 미완료로 유지했다.

### 검증

- Feature production build: 성공.
- Feature test source typecheck와 링크: 성공.
- Feature 테스트 실행: 실패, 테스트 본문 0건.
- production의 Mock·`@Dependency`·Service Locator·Composition 참조: 정적 검색 0건.
- 다른 test target 의존성: `FeatureTests`가 Feature·TCA·DomainLearningProject만 참조함을 확인.

### 재발 방지

같은 runtime에서 Derived Data만 바꾼 반복 실행은 복구 판정 근거로 삼지 않는다. Xcode 또는 iOS
Simulator runtime이 변경된 뒤 crash stack과 실제 테스트 실행 건수를 다시 확인하고, 본문 실행이
시작되기 전에는 T068과 커밋을 완료하지 않는다.

### 연결

선행: `TS-20260819-015`. 후속: 없음.

## TS-20260819-017: Feature build 뒤 완료된 UI 파일에 Preview가 자동 추가됨

**기록일**: 2026-08-19
**상태**: 완화
**발생 단계**: `$speckit-implement` Feature 패키지 T068 build 검증
**관련 항목**: T068,
`sources/Projects/UI/UIComponentLayoutHarness/LayoutContractCatalog.swift`

### 증상

세션 시작 Git 상태에는 없던 `LayoutContractCatalog.swift` 변경이 Feature production build와
`build-for-testing` 뒤 나타났다. 변경 내용은 파일 끝에 `LayoutContractCatalog()`를 표시하는
`#Preview` 블록 4줄이 추가된 것이었다.

### 영향

완료·승인된 UI 패키지 파일이 Feature 허용 경로 밖에서 바뀌어 그대로 두면 패키지 승인 게이트와
정확한 task write scope를 위반한다. Feature 변경 커밋에 섞이면 변경 소유권도 잘못 기록된다.

### 근거

- T068 시작 `git status --short`: UIComponentLayoutHarness 변경 없음.
- Feature build·`build-for-testing` 뒤 `git status --short`:
  `M sources/Projects/UI/UIComponentLayoutHarness/LayoutContractCatalog.swift` 발생.
- 해당 파일 diff: 기존 닫는 괄호 뒤 `#Preview { LayoutContractCatalog() }`만 추가됨.

### 원인

Feature build 과정에서 실행된 저장소의 Swift Style `FormatSwift` build plugin 이후 변경이
발생한 것은 확인했다. plugin 내부의 어떤 규칙이 Preview를 추가했는지는 확인 중이며, 사용자가
직접 수정한 증거는 세션 중 관찰되지 않았다.

### 조치

Feature 허용 범위 밖 변경을 즉시 분리해 추가된 Preview 블록만 역패치했다. 기존 UI 파일의 다른
내용과 Feature 작업 파일은 변경하지 않았다. 원인 규칙 수정은 현재 task가 소유하지 않으므로
수행하지 않았다.

### 검증

- 역패치 뒤 `git diff -- sources/Projects/UI/UIComponentLayoutHarness/LayoutContractCatalog.swift`:
  출력 0건.
- T068 재실행: 미실행. 재실행하면 동일 부수효과가 생길 수 있고 T068 자체가 이미
  `TS-20260819-016`의 bootstrap crash로 중단됨.

### 재발 방지

Swift build 뒤에는 검증 대상 파일뿐 아니라 `git status --short`를 다시 확인해 build plugin의
추적 파일 변경을 분리한다. 완료된 선행 패키지 파일이 바뀌면 후속 커밋에 포함하지 말고 시작
상태와 diff를 대조해 이번 실행이 만든 변경만 복구한다.

### 연결

선행: `TS-20260819-016`. 후속: 없음.

## TS-20260819-018: FeatureTests LocalStatusKit 부트스트랩 충돌 3차 재발

**기록일**: 2026-08-19
**상태**: 환경 제약
**발생 단계**: `$speckit-implement` Feature 패키지 T068 재검증
**관련 항목**: T068, `TS-20260819-015`, `TS-20260819-016`,
`sources/Projects/Feature/FeatureTests/LearningProjectList/**`

### 증상

현재 source로 workspace를 다시 생성하고 Feature production build와 test bundle 컴파일을
성공시킨 뒤, 데이터 디렉터리가 존재하는 iOS 26.5 simulator에서 테스트를 실행했지만 약
75초 뒤 테스트 본문에 진입하지 못한 채 `Early unexpected exit`가 다시 발생했다. 최신 crash
report도 XCTest가 `LocalStatusKit`의 `PublishStatusInvocation` metadata를 실현하는 중 같은
주소에서 `EXC_BAD_ACCESS (SIGSEGV)`로 종료됐음을 보여 준다.

### 영향

Feature source와 테스트 자산은 컴파일·링크됐지만 상태 전이, Effect 취소·오류 경로와 로컬
Mock 호출 assertion은 실행되지 않았다. 따라서 T068·T069를 완료 표시하거나 App 패키지로
진행할 수 없다.

### 근거

- `make tuist`: 현재 source 기준 workspace 생성 성공.
- `xcodebuild build -workspace sources/GitIt.xcworkspace -scheme Feature -destination
  'platform=iOS Simulator,id=6CA6AEA3-FD6C-4549-A261-A29C6B0372C4' -derivedDataPath
  /private/tmp/GitIt-006-T068-Feature-20260819-2348`: production build 성공.
- `xcodebuild test ... -destination
  'platform=iOS Simulator,id=FF975095-E0FC-434D-89E9-E3EBA19EB913'`: 종료 코드 65,
  `Early unexpected exit`, 약 75.8초 뒤 bootstrap 종료.
- `/private/tmp/GitIt-006-T068-Feature-20260819-2350.xcresult`: `FeatureTests`의 제품 테스트
  통과 0건, bootstrap 오류 1건.
- `/Users/jerry/Library/Logs/DiagnosticReports/xctest-2026-08-19-235117.ips`:
  `KERN_INVALID_ADDRESS at 0x000000000bad4007`, `PublishStatusInvocation` →
  `realizeAllClasses()` → `objc_copyClassList` →
  `+[XCTestCase(RuntimeUtilities) allSubclasses]` 순서에서 충돌.

### 원인

확정된 직접 원인은 `TS-20260819-015`·`TS-20260819-016`과 동일한 Apple 내부
`LocalStatusKit` class metadata 실현 오류다. 현재 workspace, 격리 Derived Data와 실제 데이터가
존재하는 simulator에서도 재발해 stale project, Feature 컴파일 캐시와 simulator 데이터 부재는
이 실행의 직접 원인이 아니다. Feature 의존 그래프와 Xcode 26.6·iOS 26.5 runtime 사이의 세부
유발 조건은 확인 중이다.

### 조치

runner가 scheme 인자를 받지 않는 기존 `TS-20260819-014`의 제약에 따라 직접 `xcodebuild`로
전환했다. `simctl list` 결과만 신뢰하지 않고 simulator 데이터 디렉터리 존재 여부를 확인해
`default` UUID로 재실행했으며, product·Tuist 설정은 추측으로 변경하지 않았다.

### 검증

- Feature production build: 성공.
- Feature test source typecheck와 test bundle 링크: 성공.
- Feature 테스트 본문: 미실행. XCTest suite 구성 단계에서 충돌.
- T068 상태 전이·Effect·Mock assertion: 미검증.

### 재발 방지

`simctl list devices available` 출력과 실제 simulator 데이터 디렉터리 존재 여부를 함께 확인한다.
같은 `0x000000000bad4007`·`PublishStatusInvocation` stack이면 assertion 실패로 분류하지 않고
Xcode 또는 iOS runtime 변경 뒤 실제 테스트 본문 실행 건수를 다시 확인한다.

### 연결

선행: `TS-20260819-015`, `TS-20260819-016`. 후속: 없음.

## TS-20260820-001: macOS awk 캡처 배열 문법 비호환

**기록일**: 2026-08-20
**상태**: 해결
**발생 단계**: `$speckit-analyze` 요구사항·작업 수 집계
**관련 항목**: `specs/006-final-uxui-screens/spec.md`,
`specs/006-final-uxui-screens/tasks.md`

### 증상

FR·SC 식별자 수를 집계하려고 `awk`의 `match`에 세 번째 캡처 배열 인자를 전달하자
`awk: syntax error`로 종료되어 해당 명령의 FR·SC 집계값이 각각 0으로 출력됐다.

### 영향

첫 집계 명령의 요구사항 수를 분석 지표로 사용할 수 없었다. 명세·계획·작업·소스 파일은
변경되지 않았고, 문서 연결성 판단은 대체 집계가 끝날 때까지 보류했다.

### 근거

- `awk 'match($0, /.../, m) { ... }' specs/006-final-uxui-screens/spec.md`:
  `awk: syntax error at source line 1`로 실패했다.
- `rg -o '\*\*FR-[0-9]{3}\*\*' ... | wc -l`과 대응 SC 명령: FR 29개,
  SC 21개를 정상 집계했다.
- `awk '/^- \\[[ xX]\\] T[0-9]+/{n++} END{print n}' .../tasks.md`: 작업 92개를
  정상 집계했다.

### 원인

사용한 macOS `awk`가 GNU awk 확장인 `match`의 세 번째 캡처 배열 인자를 지원하지 않는데,
지원 여부를 확인하지 않고 해당 문법을 사용했다.

### 조치

식별자 추출을 `rg -o`로, 개수 집계를 `wc -l`로 분리해 다시 실행했다. 실패한 `awk` 결과는
폐기하고 대체 명령의 출력만 분석 지표에 사용했다.

### 검증

- `rg -o` 기반 재집계: 성공, FR 29개·SC 21개.
- POSIX 범위의 단순 `awk` 작업 집계: 성공, T001~T092 총 92개.
- 저장소 산출물 변경: 문제 해결 기록 외 미실행.

### 재발 방지

macOS 기본 `awk`를 사용할 때 `match`의 세 번째 배열 인자 같은 GNU 확장을 사용하지 않는다.
단순 식별자 추출은 `rg -o`, 개수는 `wc -l`을 사용하고, 복합 파싱이 필요하면 먼저 도구
호환성을 확인한다.

### 연결

선행·후속 문제 ID: 없음.

## TS-20260820-002: UIComponent 타깃명과 Component 역할 폴더 혼동

**기록일**: 2026-08-20
**상태**: 해결
**발생 단계**: `$speckit-plan` typography 적용 근거와 소스 경로 조사
**관련 항목**: `specs/006-final-uxui-screens/plan.md`,
`specs/006-final-uxui-screens/tasks.md`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`

### 증상

UIComponent 구현 파일을 찾기 위해
`rg --files sources/Projects/UI/UIComponent/Components`를 실행하자 대상 디렉터리가 없어
명령이 실패했다.

### 영향

첫 탐색에서는 UIComponent의 실제 구현·테스트 경로와 typography 사용처를 확인할 수
없었다. 실패한 탐색 자체는 파일을 변경하지 않았으며, 계획·작업 문서의 경로를 실제
구조와 대조할 때까지 수정 판단을 보류했다.

### 근거

- `rg --files sources/Projects/UI/UIComponent/Components`: `No such file or directory`로
  실패했다.
- `rg --files sources/Projects/UI`: 실제 구현은 `sources/Projects/UI/Component/**`, 레이아웃
  하네스는 `sources/Projects/UI/ComponentLayoutHarness/**`, 테스트는
  `sources/Projects/UI/Tests/**` 아래에 있음을 확인했다.
- `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift:15-26`: 타깃의
  `rawValue`에서 `UI` 접두어와 테스트 접미어를 제거해 역할 폴더를 계산한다.

### 원인

Tuist 타깃 이름 `UIComponent`를 실제 source 역할 폴더 이름과 같다고 가정했다. 저장소는
타깃에는 패키지 문맥을 포함하지만 source·test 폴더에는 역할 이름만 두므로 실제 폴더는
`Component`다.

### 조치

`sources/Projects/UI`에서 범위를 넓혀 파일을 다시 검색하고 `UIModuleName.sourceDirectory`의
계산 규칙을 확인했다. 이후 `spec.md`, `plan.md`, `tasks.md`, `quickstart.md`, 계약 문서와
요구사항 체크리스트의 실행 경로를 현재 역할 폴더 기준으로 맞췄다.

### 검증

- `rg --files sources/Projects/UI | rg 'Component|TextStyleTokenTests'`: 실제 구현·테스트·하네스
  경로 확인에 성공했다.
- `rg 'sources/Projects/UI/(UIComponent|DesignSystemTests|UIComponentTests|UIComponentLayoutHarness|UIComponentUITests)'
  specs/006-final-uxui-screens --glob '!trouble-shooting.md'`: 잔여 경로 0건.
- `git diff --check`: 성공.

### 재발 방지

UI 패키지 경로를 문서화하거나 탐색하기 전에
`sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`의
`sourceDirectory`를 기준으로 타깃 이름과 역할 폴더를 구분한다. 경로를 확신할 수 없으면
먼저 `rg --files sources/Projects/UI`에서 실제 파일을 찾는다.

### 연결

선행·후속 문제 ID: 없음.

## TS-20260820-003: Tuist 재생성 후 Xcode Unique Derived Data에서 외부 의존성 빌드 순환

**기록일**: 2026-08-20
**상태**: 미해결
**발생 단계**: `006-final-uxui-screens` 작업 중 Tuist 재생성 후 Xcode `App` scheme 빌드
**관련 항목**: T082, T091, `sources/Tuist/Package.swift`,
`tools/githooks/project-build/core/xcodebuild.sh`

### 증상

Xcode 26.6에서 `App` scheme을 빌드하자 `UIKitNavigationShim` target의
`Copy Module Map`과 `shim.m` 컴파일 사이에 dependency cycle이 발생했다. 오류의 cycle
point는 제품 framework의 `Modules/module.modulemap`이었고, Xcode는 해당 파일을 생성하는
script phase와 그 파일에 의존하는 Objective-C 컴파일을 하나의 순환으로 판정했다.

같은 Xcode 전역 Derived Data에서는 순환 오류 직전 빌드에서
`ComposableArchitectureMacros produced malformed response`도 발생했다. 두 오류 모두 앱의
동작 코드가 아니라 Tuist가 생성한 외부 의존성 산출물을 가리켰다.

### 영향

`App` scheme 빌드가 제품 source 검증 전에 중단됐다. 이 실패만으로 현재 앱 source,
AppIcon 변경 또는 `swift-navigation` source 결함을 확정할 수 없으며, T082와 T091의 빌드
성공 근거로 사용할 수도 없다.

### 근거

- 첨부 Xcode 오류: `Cycle inside UIKitNavigationShim; building could produce unreliable
  results.`와 `Copy Module Map` → `shim.m` → `module.modulemap` 순환을 보고했다.
- `sources/Tuist/Package.resolved:203-208`: `swift-navigation`은 외부 의존성 버전
  `2.10.3`이며 관련 lock file의 작업 트리 변경은 없었다.
- `sources/Tuist/Package.swift:28-31`: `SwiftNavigation`, `SwiftUINavigation`,
  `UIKitNavigation`, `UIKitNavigationShim`을 framework product로 생성한다.
- 생성된 `swift-navigation.xcodeproj/project.pbxproj`: `UIKitNavigationShim`의 `Sources`
  phase 뒤에 제품 `module.modulemap`을 출력하는 `Copy Module Map` phase가 있다.
- 생성 프로젝트 시각은 2026-08-20 03:48:34, Xcode 전역 Derived Data의 `build.db` 갱신
  시각은 03:49:06, 오류 기록 시각은 03:49:18이었다.
- 같은 전역 Derived Data의 `shim.o`와 `UIKitNavigationShim.framework`은 프로젝트 재생성
  전인 03:21에 정상 생성됐지만, 재생성 뒤에는 갱신되지 않았다.
- Xcode 전역 `IDEBuildLocationStyle`은 `Unique`였다. 이 방식은 project별 경로를 선택하지만
  같은 project의 매 빌드마다 새 경로를 만들지는 않는다.
- `tools/repository-paths/repository-paths.json:7`과
  `tools/githooks/project-build/core/xcodebuild.sh:45-60`: 저장소 runner는 Xcode 전역 경로와
  별도인 `sources/DerivedData/PreCommit` 또는 `TestSchemes/<scheme>`을 명시적으로 사용한다.

### 원인

확정된 직접 원인은 Xcode가 현재 `UIKitNavigationShim` build task graph에서
`module.modulemap` 생성과 `shim.m` 컴파일을 순환으로 판정한 것이다.

프로젝트 재생성 뒤에도 Xcode `Unique` 경로의 이전 외부 의존성 산출물과 XCBuild 증분
그래프가 재사용된 것이 유력한 유발 조건이다. `Unique`와 저장소의 명시적
`-derivedDataPath`가 같은 파일을 사용해 충돌한 것은 아니다. 다만 새 Derived Data에서 같은
빌드를 연속 실행하는 A/B 검증은 아직 수행하지 않았으므로 stale cache를 최종 원인으로
확정하지 않는다.

### 조치

미실행. 다음 순서로 복구한다.

1. 실행 중인 Xcode build와 `xcodebuild`가 없는지 확인하고 Xcode를 종료한다. 열린 상태에서
   `build.db` 또는 제품 디렉터리를 이동하지 않는다.
2. 오류 로그가 가리킨 정확한 전역 Derived Data
   `~/Library/Developer/Xcode/DerivedData/GitIt-dlquessjgjqpujfavwufonmjoixv`만 대상으로
   확인한다. `DerivedData` 상위 디렉터리 전체나 다른 project 경로는 대상에 포함하지 않는다.
3. 즉시 삭제하지 않고 `/private/tmp/GitIt-dlquessjgjqpujfavwufonmjoixv-stale-20260820-001`
   같은 비어 있는 명시 경로로 이동해 rollback 가능하게 보존한다. 원본 존재와 대상 부재를
   먼저 확인하고, 검증 완료 전에는 격리본을 삭제하지 않는다.
4. 전역 캐시와 독립된 새 경로에서 다음 clean build를 실행한다.

   ```sh
   xcodebuild build \
     -workspace sources/GitIt.xcworkspace \
     -scheme App \
     -configuration Debug \
     -destination 'generic/platform=iOS Simulator' \
     -derivedDataPath /private/tmp/GitIt-006-App-UIKitNavigationShim-20260820 \
     -disableAutomaticPackageResolution \
     -jobs 1 \
     CODE_SIGNING_ALLOWED=NO \
     COMPILER_INDEX_STORE_ENABLE=NO
   ```

5. 첫 빌드가 성공하면 같은 명령을 같은 임시 Derived Data 경로로 한 번 더 실행해 증분
   빌드에서도 cycle이 재발하지 않는지 확인한다.
6. 두 번 모두 성공한 뒤 Xcode에서 `sources/GitIt.xcworkspace`를 열고 `App` scheme을 다시
   빌드한다. Xcode `Unique`가 새 전역 Derived Data를 만들게 하며, 새 경로의
   `UIKitNavigationShim` 산출물 시각이 현재 빌드와 일치하는지 확인한다.
7. Xcode 빌드까지 성공한 뒤에만 격리해 둔 이전 Derived Data의 삭제 여부를 결정한다.

새 임시 Derived Data의 첫 빌드에서도 같은 cycle이 발생하면 위 cache 가설은 기각한다. 이때
생성된 `project.pbxproj`를 직접 수정하지 않고, 현재 Xcode·Tuist·`swift-navigation` 조합에서
`UIKitNavigationShim`의 framework product와 `Copy Module Map` phase 순서를 별도 호환성
문제로 조사한다.

### 검증

- 전역 Derived Data 격리 이동: 미실행.
- 새 임시 Derived Data의 첫 clean build: 미실행.
- 같은 임시 경로의 두 번째 incremental build: 미실행.
- 새 Xcode `Unique` 경로의 `App` scheme build: 미실행.
- 해결 판정 기준: 위 세 빌드가 모두 종료 코드 0과 `** BUILD SUCCEEDED **`를 반환하고,
  `UIKitNavigationShim`의 `shim.o`, `module.modulemap`, framework가 각 사용 경로에서 현재
  빌드 시각으로 생성돼야 한다.

### 재발 방지

`Unique`를 매 실행마다 깨끗한 Derived Data를 만드는 설정으로 해석하지 않는다. Tuist
재생성 직후 외부 macro의 `malformed response`, module map cycle 또는 재생성 전 시각의
산출물 재사용이 관찰되면 product source를 수정하기 전에 새 `-derivedDataPath`에서 clean과
incremental 빌드를 차례로 비교한다. 같은 checkout의 `sources/DerivedData/PreCommit`을 쓰는
`build`, `compile`, `test`와 별도 runner 실행은 병렬화하지 않는다.

### 연결

선행·후속 문제 ID: 없음.

## TS-20260820-004: 수렴 코드 범위 경로 불일치와 Tuist 구성 충돌 표식 발견

**기록일**: 2026-08-20
**상태**: 미해결
**발생 단계**: `$speckit-converge` 현재 코드 범위 탐색과 구현 대조
**관련 항목**: T001, T002, T016~T020, T068,
`sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

### 증상

`plan.md`와 `tasks.md`에 기록된 Domain·Composition·Feature·App 구현 경로를 한 번에
`rg --files`로 조회하자 여러 디렉터리가 존재하지 않아 명령이 실패했다. 상위 패키지
디렉터리에서 다시 탐색하던 중 두 Tuist helper에 실제 merge marker가 남아 있고,
`DataModuleName.sourceDirectory`가 추가 enum case를 처리하지 않으며, Composition 테스트의
import 이름이 선언 target 이름과 다른 상태도 확인했다.

### 영향

현재 Tuist helper는 정상적인 프로젝트 생성·빌드 입력으로 사용할 수 없고, Composition
테스트도 선언된 production module을 import하지 않는다. 따라서 T068의 Feature build·test와
후속 App 작업을 신뢰성 있게 실행할 수 없다. `ProjectName.swift`의 충돌 블록은 Domain과
Data 구획을 함께 감싸 Constitution 원칙 7의 단일 패키지 소유권을 즉시 결정할 수 없으므로,
수렴 작업을 `tasks.md`에 추가하는 단계도 보류했다.

### 근거

- `rg --files sources/Projects/Domain/LearningProjectTests ...`: `Domain/LearningProjectTests`,
  `Composition/Composition/LearningProject`, `Feature/FeatureTests/LearningProjectList`,
  `App/ScreenLayoutHarness`, `App/ScreenLayoutUITests`가 없다는 오류로 실패했다.
- `rg --files sources/Projects/Domain sources/Projects/Composition sources/Projects/Feature
  sources/Projects/App`: 실제 테스트·Composition 역할 폴더는 `Tests/LearningProject`,
  `Adepter`, `Tests/Adepter`, `Tests/LearningProjectList`이며 App harness는 아직 존재하지
  않음을 확인했다.
- `rg -n '^(<<<<<<<|=======|>>>>>>>)' sources/Tuist/ProjectDescriptionHelpers ...`:
  `DomainModuleName.swift`와 `ProjectName.swift`에서 merge marker를 확인했다.
- `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`: enum은
  `DataLearningProject`·`DataLearningProjectTests`를 포함하지만 `sourceDirectory` switch는
  두 case를 처리하지 않고, 해당 target 선언은 필수 `sourceDirectory`를 전달하지 않는다.
- `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`와
  `sources/Projects/Composition/Tests/Adepter/LearningProject/*.swift`: 선언 target은
  `CompositionAdepter`인데 테스트 3개는 `Composition`을 import한다.

### 원인

경로 조회 실패의 직접 원인은 계획·작업 문서의 target 중심 경로와 현재 역할 폴더 경로가
일부 패키지에서 일치하지 않는 것이다. Tuist helper의 merge marker, Data switch 누락과
Composition module 불일치가 함께 존재하게 된 변경 과정은 확인하지 않았으며, Git 이력이나
diff를 사용하는 것이 금지된 `$speckit-converge` 범위에서는 원인을 추정하지 않는다.

### 조치

상위 패키지 디렉터리에서 파일 목록을 다시 수집하고 현재 helper·source·test 내용을 직접
대조했다. 기존 미완료 T068~T092로 추적되는 Feature 검증·App 구현·전체 검증은 중복 작업으로
추가하지 않았다. 새 결함은 심각도별로 분류했지만 `ProjectName.swift`의 Domain·Data 소유
경계를 임의로 정하지 않고 `tasks.md` append를 중단했다.

### 검증

- 상위 패키지 기준 `rg --files`: 실제 source·test 파일 목록 수집 성공.
- Tuist helper merge marker 재검색: 2개 Swift 파일에 잔존, 미해결.
- `DataModuleName` switch와 Composition import 정적 대조: 불일치 재확인, 미해결.
- Tuist 생성·build·test: 미실행. 현재 정적 구성 결함과 패키지 소유권 결정이 선행돼야 한다.
- `tasks.md` 수렴 단계 추가: 미실행.

### 재발 방지

수렴 코드 범위는 문서 경로를 그대로 한 번에 조회하기 전에 각 패키지의
`*ModuleName.sourceDirectory`와 `Target.testModule` 경로 계산을 확인한다. 프로젝트 생성이나
build 전에 Swift source의 merge marker, enum switch 완결성과 target 이름↔import 이름을
정적으로 검사한다. 공용 helper의 충돌 블록이 여러 패키지 구획을 함께 감싸면 한 패키지에
임의 배정하지 말고 사용자에게 소유 경계를 먼저 확인한다.

### 연결

선행: `TS-20260820-002`. 후속: 없음.

## TS-20260820-005: Tuist 구성 수렴 작업의 패키지 소유권 확정

**기록일**: 2026-08-20
**상태**: 완화
**발생 단계**: `$speckit-converge` F1~F3 후속 작업 배정
**관련 항목**: `TS-20260820-004`, T093~T102,
`specs/006-final-uxui-screens/tasks.md`

### 증상

`TS-20260820-004`에서 `ProjectName.swift`의 conflict block이 Domain과 Data 구획을 함께
감싸 수렴 작업을 한 패키지에 임의 배정할 수 없어 `tasks.md` append가 중단됐다.

### 영향

Tuist helper와 Composition module 불일치의 수정 작업이 정의되지 않아 T068의 Feature
검증과 후속 App 작업을 재개할 수 없었다.

### 근거

- 사용자 결정(2026-08-20): 현재 브랜치의 Tuist 형태를 적용한다.
- `specs/006-final-uxui-screens/tasks.md`: 현재 브랜치의 명시적 `sourceDirectory`, 역할 중심
  source·test 폴더와 `.package(...)` scheme을 수렴 기준으로 기록한 T093~T102가 존재한다.
- 작업 ID 재검사: T001~T102 총 102개, 중복 0건, 기존 완료 67개를 보존했다.

### 원인

선행 기록의 직접 원인은 공용 helper의 패키지 소유 기준이 미확정이었던 것이다. 사용자가
incoming 암시형 대신 현재 브랜치 Tuist 형태를 정본으로 선택해 작업 배정 기준이 확정됐다.

### 조치

기존 T001~T092를 수정하지 않고 `## 단계 6: 수렴`을 파일 끝에 추가했다. Domain은 conflict
marker와 Domain scheme 복구, Data는 역할 폴더·완결된 `sourceDirectory`·Data scheme 정합,
Composition은 target 이름과 test import 정합을 소유하도록 T093~T102를 패키지 순서와
승인 게이트에 맞춰 배정했다.

### 검증

- 작업 ID·순서 검사: T001~T102 연속, 중복 0건.
- 완료 표시 검사: 기존 완료 67개 유지, 새 미완료 10개 추가.
- 수렴 패키지 순서: Domain → Data → Composition.
- 실제 Tuist helper 수정·프로젝트 생성·build·test: 미실행. T093 이후 구현 책임이다.

### 재발 방지

공용 Tuist helper가 여러 패키지 구획을 함께 감싸면 현재 브랜치의 target/sourceDirectory/scheme
형식을 먼저 확정하고, 패키지별 변경·검증·보고·승인 작업을 분리한다. 수렴 스킬은 소스에
직접 적용하지 않고 append된 작업으로만 인계한다.

### 연결

선행: `TS-20260820-004`. 후속: 없음.

## TS-20260820-006: Data 수렴 검증의 runner 범위와 Simulator 권한 제약

**기록일**: 2026-08-20
**상태**: 환경 제약
**발생 단계**: `$speckit-implement` Data 수렴 T098
**관련 항목**: T098, `tools/githooks/project-build/bin/run.sh`,
`TS-20260819-012`, `TS-20260820-005`

### 증상

T098의 Domain·Data 단일 scheme 검증 방법을 확인하려고 project build runner에 `--help`를
전달하자 `오류[common.invalid-input]: 지원하지 않는 ACTION=--help`로 종료됐다. 이어 sandbox
안에서 `xcrun simctl list devices available`을 실행하자 CoreSimulatorService 연결이 끊기고
사용자 Library의 Simulator 로그 경로 접근이 거부됐다.

### 영향

project build runner의 전체 공유 scheme 검증을 그대로 실행하면 Data 승인 단위 밖의 패키지까지
검증하게 되고, sandbox 안에서는 테스트 destination UUID를 확인할 수 없었다. 두 제약 모두
제품 코드나 Tuist graph의 실패와 혼동할 수 있지만 source 변경을 요구하지 않는다.

### 근거

- `./tools/githooks/project-build/bin/run.sh --help`: action은 `build`, `compile`, `test` 중
  하나만 허용한다는 진단과 함께 종료 코드 2를 반환했다.
- `tools/githooks/project-build/bin/run.sh`: 공개 인자 수를 1개로 제한하고 모든 공유 scheme을
  관찰·실행하며 scheme 필터 인자를 제공하지 않는다.
- sandbox 안 `xcrun simctl list devices available`: `CoreSimulatorService connection became
  invalid`, `Operation not permitted`, `Connection refused`를 반환했다.
- 승인된 외부 `xcrun simctl list devices available`: 부팅된 destination
  `FF975095-E0FC-434D-89E9-E3EBA19EB913`를 확인했다.

### 원인

runner 오류의 확정 원인은 action 하나만 받는 공개 인터페이스에 지원하지 않는 `--help`를
전달한 것이다. T098은 Domain·Data만 순서대로 요구하지만 현재 runner는 scheme 단위 필터를
지원하지 않는다. Simulator 조회 실패의 확정 원인은 sandbox가 CoreSimulatorService와 사용자
Library 로그 경로에 접근하지 못한 환경 권한 제약이다.

### 조치

runner 구현을 읽어 action-only 계약과 전체 scheme 범위를 확인했다. Data 승인 단위를 넘기지
않도록 `Domain`, `Data` 각각에 격리된 `/private/tmp` Derived Data를 만들고 runner와 같은 핵심
옵션의 직접 `xcodebuild`로 `build`, `build-for-testing`, `test-without-building`을 순서대로
실행했다. Simulator 목록과 테스트 실행은 승인된 외부 환경에서 수행했다.

### 검증

- `make tuist`: 성공, 현재 source 기준 workspace 생성 완료.
- `Domain` 직접 `xcodebuild`: build·build-for-testing·test-without-building 성공,
  xcresult 기준 28/28 통과, 실패·건너뜀 0건.
- `Data` 직접 `xcodebuild`: build·build-for-testing·test-without-building 성공,
  xcresult 기준 23/23 통과, 실패·건너뜀 0건.
- 전체 공유 scheme runner 검증: 미실행. 현재 Data 승인 단위 밖이며 T091이 별도로 소유한다.

### 재발 방지

단일 package scheme 검증 전 runner 소스의 공개 인자 계약을 확인하고 `--help` 지원을 가정하지
않는다. scheme 필터가 없는 동안 package 승인 단계는 scheme별 격리 Derived Data와 직접
`xcodebuild`를 사용한다. Simulator destination은 sandbox 실패 시 제품 오류로 분류하지 않고
승인된 `simctl` 조회 결과의 UUID를 명시한다.

### 연결

선행: `TS-20260819-012`, `TS-20260820-005`. 후속: 없음.
