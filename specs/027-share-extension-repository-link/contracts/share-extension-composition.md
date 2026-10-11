# 계약: Extension 조립 루트

**대상 명세**: [spec.md](../spec.md) · **조사**: [research.md](../research.md)

`CompositionShareExtension` target이 노출하는 공개 경계다. Extension target은 이 타입 하나만
조립에 사용하고 Domain·Data·Infrastructure를 직접 조립하지 않는다.

## 공개 표면

| 이름 | 형태 | 설명 |
|---|---|---|
| `ShareExtensionComposition` | struct | Extension 조립 루트 |
| `ShareExtensionComposition.Environment` | struct | `apiBaseURL`, `externalRepositoryBaseURL` |
| `ShareExtensionComposition.live(_:)` | static factory | 실제 구현 조립 |
| `parseRepositoryLink` | `any ExternalRepositoryURLParser` | 네트워크 없는 로컬 URL 판정(FR-003) |
| `fetchExternalRepository` | `any FetchExternalRepositoryUseCase` | 저장소 조회(FR-004a) |
| `createLearningProject` | `any CreateLearningProjectUseCase` | 프로젝트 등록(FR-012) |
| `resolveSessionAvailability` | `@Sendable () async -> SessionAvailability` | 세션·이전 상태 판정(FR-006, FR-011a) |
| `isNotificationAuthorized` | `@Sendable () async -> Bool` | 알림 권한 조회만 수행(FR-016b) |
| `enqueueGenerationReminder` | `@Sendable (String) async -> Void` | 리마인더 대기 목록 기록(FR-016a) |

## 조립 규칙

- 세션 갱신 사용 사례를 조립하지 않는다. HTTP 경로에는 저장된 접근 토큰을 그대로 돌려주는
  정적 `accessTokenProvider`만 주입한다(FR-007, R9).
- 알림 권한은 조회 경로만 노출한다. 권한 요청 경로를 공개 표면에 두지 않는다(FR-016b).
- `InfrastructurePushMessaging`(원격 푸시·Firebase)을 의존하지 않는다(FR-027, R1).
- `Environment`의 URL은 호출자가 자기 번들 구성에서 읽어 전달한다(R7).
- 로컬 판정은 Domain 계약 `ExternalRepositoryURLParser`를 그대로 노출한다. 화면은 Domain
  계약만 참조하고 Data의 파서 구현을 직접 알지 않는다.

## 본 앱 조립 루트와의 관계

| 대상 | target | 원격 푸시 의존 |
|---|---|---|
| 본 앱 조립 루트 `AppComposition` | `CompositionApp` | 있음 |
| 공유 조립 요소(Assembly·Adapter·Coding) | `CompositionAdapter` | 없음 |
| Extension 조립 루트 | `CompositionShareExtension` | 없음 |
