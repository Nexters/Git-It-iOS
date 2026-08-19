# 데이터 모델: UI 레이아웃 검증

## 레이아웃 계약 항목

| 필드 | 형식 | 규칙 |
| --- | --- | --- |
| `component` | 문자열 | Figma와 코드에서 식별 가능한 컴포넌트 이름 |
| `variant` | 문자열 | 크기·스타일·상태 조합을 독립적으로 식별 |
| `property` | 열거 값 | `width`, `height`, `spacing`, `padding`, `cornerRadius`, `touchWidth`, `touchHeight`, `adaptive` |
| `targetValue` | 수치 또는 조건 | 고정값은 pt, 적응형은 검증 조건으로 기록 |
| `tolerance` | 수치 | 기본 `0.5pt`; 화면 실측은 항목별 명시 |
| `evidenceLevel` | `A`, `B`, `C` | Figma 직접 확인, 저장소의 Figma 실측 명시, 현재 코드 기준선 |
| `source` | 문자열 | Figma 영역 또는 저장소 상대 경로 |
| `testIdentifier` | 문자열 | XCUITest에서 안정적으로 찾는 식별자 |
| `status` | 열거 값 | `confirmed`, `baseline`, `excluded`, `mismatch`, `passing` |

### 검증 규칙

- `A` 또는 `B` 항목만 디자인 일치의 강제 목표값으로 사용한다.
- `C` 항목은 회귀 기준선으로 기록할 수 있지만 Figma 확정값이라고 보고하지 않는다.
- 고정 수치는 `abs(actual - target) <= tolerance`일 때 통과한다.
- `adaptive` 항목은 텍스트 잘림 없음, 화면 경계 침범 없음과 최소 터치 영역을 검증한다.

## 검증 대상 변형

| 필드 | 형식 | 규칙 |
| --- | --- | --- |
| `id` | 문자열 | 앱과 UI 테스트에서 동일하게 사용하는 안정 식별자 |
| `component` | 문자열 | 소유 컴포넌트 |
| `size` | 선택 열거 값 | 컴포넌트가 지원하는 이름 있는 크기만 허용 |
| `style` | 선택 열거 값 | 시각 스타일 |
| `state` | 선택 열거 값 | 기본, 누름, 비활성, 오류 등 |
| `expectedContracts` | 계약 ID 목록 | 변형이 충족해야 하는 레이아웃 계약 |

## 렌더링 측정 결과

| 필드 | 형식 | 규칙 |
| --- | --- | --- |
| `contractID` | 문자열 | 대응 레이아웃 계약 |
| `actualValue` | 수치 또는 관찰 결과 | XCUITest가 측정한 프레임 또는 조건 |
| `difference` | 수치 | 고정값일 때 실제값과 목표값의 절대 차이 |
| `passed` | Bool | 계약 충족 여부 |
| `diagnostic` | 문자열 | 실패 시 컴포넌트·변형·기대값·실제값 포함 |

### 상태 전이

```text
baseline/confirmed → mismatch(실패 테스트) → passing(구현 교정 후 동일 테스트 성공)
excluded → excluded(근거 또는 플랫폼 소유권이 바뀌기 전까지 유지)
```
