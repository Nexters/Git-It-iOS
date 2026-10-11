# 계약: Extension 화면 동작

**대상 명세**: [spec.md](../spec.md) · **데이터 모델**: [data-model.md](../data-model.md)

## 진입 계약

| 항목 | 값 |
|---|---|
| Extension 유형 | Share Extension |
| 활성화 규칙 | web URL 1건(FR-001) |
| 보조 수신 | URL 항목이 없을 때만 텍스트 항목을 URL로 변환 시도(FR-002) |
| 항목이 여러 개일 때 | 저장소로 판정 가능한 첫 항목을 사용한다 |

## 화면 계약

- 상태와 허용 동작은 [data-model.md](../data-model.md)의 `ShareRegistrationState` 표를 정본으로
  한다.
- 색상·타이포그래피·컴포넌트는 `DesignSystem`·`UIComponent`만 사용한다(FR-022). Extension
  전용 색상 값이나 폰트를 새로 정의하지 않는다.
- 호스트 앱 위에 카드로 표시하고 배경에 호스트 앱이 비치게 한다(FR-023).
- 화면 간 이동(push·모달 중첩)을 두지 않는다(FR-019).
- 종료는 항상 Extension 컨텍스트 완료 요청으로 처리해 호스트 앱 상태를 바꾸지 않는다(FR-024).
- 본 앱을 여는 동작을 제공하지 않는다(FR-025). `appLaunchRequired` 상태도 안내 문구만 제공한다.

## 진단 로그 계약

| 항목 | 값 |
|---|---|
| subsystem | `com.nexters.hytime.gitit` |
| category | `ShareExtension` |
| 기록 대상 | 상태 전이, URL 판정 실패 사유, 세션 판정 결과, 조회·등록 실패 사유 |
| 금지 대상 | 접근 토큰, 원본 URL 전체, 사용자 식별자 등 개인정보(FR-031) |
| 전송 | 없음. 기기 내 기록만 유지한다(FR-031) |
