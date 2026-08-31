# Home 카드 스크롤 계약

## 1. 좌표계

- 좌표는 수평 ScrollView viewport의 선행 축을 기준으로 한다.
- `P0`는 최초 선행 카드의 중심, `P1`·`P2`는 동일한 `cardStride`로 이어진
  후속 중심 좌표다.
- 앵커는 현재 데이터 index가 아니라 최초 레이아웃의 화면 좌표다.

```text
P0 = leadingInset + cardWidth / 2
P1 = P0 + cardWidth + spacing
P2 = P1 + cardWidth + spacing
```

`leadingInset`, `cardWidth`, `spacing`의 실제 값은 Figma node와 기존 DesignSystem token을
구현 시 대조해 확정하며 이 계약이 임의 숫자를 추정하지 않는다.

## 2. 각도 함수

```text
A0 = 0°, A1 = +16°, A2 = -12°

x <= P0: A0
P0 < x < P1: lerp(A0, A1, (x - P0) / (P1 - P0))
P1 <= x < P2: lerp(A1, A2, (x - P1) / (P2 - P1))
x >= P2: A2
```

함수는 연속이며 앵커 오차는 `±0.5°` 이하다. index, ID, 색 variant는 입력이
아니다.

## 3. 색 variant

```text
variant = Domain 조회 순서 index % 3
0 → purple, 1 → lightBlue, 2 → darkBlue
```

- variant는 해당 `LearningProjectSummary`가 Home State에 표시되는 동안 변하지 않는다.
- 카드가 `P0`, `P1`, `P2`를 지나도 색은 바뀌지 않고 각도만 바뀌다.

## 4. 스냅과 가시성

- `LazyHStack.scrollTargetLayout()`과 `viewAligned(anchor: .leading)`를 사용한다.
- 사용자가 손을 떼면 관성 감속 후 가장 가까운 카드의 선행 엣지가
  target으로 정렬되고 그 카드 중심은 `P0 ± 1pt`에 위치한다.
- 자동 순환, 사용자 재정렬, 추가 페이지 로딩은 제공하지 않는다.
- 카드 1개는 `P0/0°`, 2개는 `P0/0°`·`P1/+16°`로 배치한다.

## 5. 입력 우선순위

입력은 임의 거리 임계값을 추가하지 않고 SwiftUI `ScrollView`의 플랫폼 scroll gesture
인식 결과로 tap과 scroll을 구분한다.

| 입력 | 결과 |
|---|---|
| 카드 본문 tap | ProjectDetail intent 정확히 1회 |
| 재생 control tap | 유효한 ID의 학습 intent 정확히 1회 |
| 본문에서 시작해 플랫폼이 scroll로 인식한 접촉 | 스크롤만 발생, 두 intent 0회 |
| 재생 control에서 시작해 플랫폼이 scroll로 인식한 접촉 | 스크롤만 발생, 두 intent 0회 |

크고 반투명한 drag-capturing overlay를 카드 위에 올려 접근성과 Button 입력을 차단하지
않는다. 플랫폼 ScrollView의 pan 인식과 카드 내 형제 control로 중재한다.

## 6. 검증

- 순수 함수 테스트: 세 앵커, 두 중간점, 양쪽 clamp, 연속성.
- 레이아웃 검증: 1·2·3개 이상 카드, `P0 ± 1pt`, 색 고정.
- 상호작 검증: 본문 tap, 재생 tap, 두 영역에서 시작한 drag.
- 접근성 검증: 두 control의 구분 가능한 label·trait, disabled 학습 상태, 44pt 영역.
