# 역할별 소유 범위

[Git It iOS UIComponent 컨벤션](../ui-component.md)의 규칙 문서입니다.

| 폴더 | 소유하는 책임 | 소유하지 않는 것 |
| --- | --- | --- |
| `Scaffolds/` | 화면 배경·안전 영역·상하단 고정 영역·탭 구조·흐름 스택 | 담기는 콘텐츠의 의미 |
| `Overlays/` | 겹쳐 뜨는 표면의 배치·표시 전환·닫기 신호 | 표면 안에 놓이는 화면 흐름 |
| `Controls/` | 사용자 입력 수집과 조작 결과 전달 | 입력값의 업무적 해석 |
| `CollectionItems/` | 한 항목의 요약 표시와 항목 단위 동작 | 목록의 정렬·페이지네이션 |
| `Indicators/` | 진행·완료·부재 상태의 시각 표현 | 상태를 만들어 내는 로직 |
| `Displays/` | 텍스트·이미지·본문의 토큰 기반 렌더링 | 표시할 값의 결정 |

검토 전용 UI의 표현 예외는 [View 컨벤션 — 표현 계층](../view/debug-component.md)이
소유하며, 그 UI는 `UIComponentPreviewApp` target에 둡니다.
