# 계약: UI `TabShell` 비활성 탭 입력

**기능**: [spec.md](../spec.md) | **조사**: [research.md R5](../research.md#r5-비활성-탭-표현)

## 공개 API 변경

```text
TabShell.init(
    selected: Binding<Item>,
    isEnabled: @escaping (Item) -> Bool = { _ in true },   // 추가
    @ViewBuilder content: @escaping (Item) -> Content,
)
```

- 기존 호출(`TabShell(selected:content:)`)은 그대로 컴파일되고 모든 탭이 활성 상태다.
- `isEnabled(item) == false`인 탭은 탭 막대에서 비활성으로 표시되고 사용자가 선택할 수 없다.
- 선택 거부의 정본은 호출자(Feature Reducer)다. `TabShell`은 표시만 담당하며 Feature State·Action을 알지 못한다
  ([UIComponent 컨벤션](../../../docs/conventions/ui-component.md)).
- 비활성 표시는 시스템 비활성 상태를 사용해 VoiceOver가 비활성임을 안내하게 한다.

## 대체안 적용 시 보장 범위

[research R5](../research.md#r5-비활성-탭-표현)의 대체안 조건 (a)·(b) 중 하나에 해당해 `Tab(value:)` +
`TabContent.disabled(_:)`를 쓰지 않으면 보장 범위가 다음으로 줄어든다.

| 보장 | 기본안 | 대체안 |
| --- | --- | --- |
| 기존 호출 무변경, 기본 전부 활성 | 보장 | 보장 |
| 비활성 탭 시각 구분 | 시스템 비활성 표시 | 아이콘·제목 `grey400` |
| 탭 막대에서 선택 입력 차단 | 보장 | 보장하지 않음 — 호출자 Reducer가 선택을 거부하고 `selectedTab`을 유지 |
| VoiceOver 비활성 안내 | 보장 | 보장하지 않음 |

대체안을 적용하면 그 사실, 해당 조건과 줄어든 보장을 실행 단위 보고와 PR 본문에 남긴다.

## 검증

- UI 단위 테스트: 기본 `isEnabled`는 모든 항목에 `true`를 반환한다.
- 프리뷰: 한 항목을 비활성화한 `TabShell` 프리뷰를 추가한다.
