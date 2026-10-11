# 빠른 시작: 생성 완료 리마인드 알림 검증

이 문서는 구현 완료 후 spec의 수용 시나리오를 실제로 확인하는 절차다. 세부 계약은
[contracts/notification-permission-contracts.md](./contracts/notification-permission-contracts.md),
데이터 표현은 [data-model.md](./data-model.md)를 참고한다.

## 사전 준비

```sh
tuist install && tuist generate  # sources 아래에서 workspace가 없으면 먼저 실행
```

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
```

## 자동화 검증

```sh
"$project_build_runner" test
```

다음 target의 신규·갱신 테스트가 포함되는지 확인한다.

- `DomainLearningProject` Tests: `RequestGenerationReminder`가 stub
  `NotificationAuthorizationGateway`/`GenerationReminderRegistry`로 세 결과(허용/방금 거부/
  이미 거부)에서 등록 호출 여부를 올바르게 분기하는지 검증한다.
- `InfrastructurePushMessaging`: `LocalNotificationClient`/concrete 구현이 컴파일된다
  (별도 테스트 target 없음, 기존 관례).
- `Feature` Tests: `notificationOptionAccepted`가 stub
  `RequestGenerationReminderUseCase`의 반환값(`.authorized`/`.declined`/`.previouslyDenied`)에
  따라 `openNotificationSettings` 호출 여부를 올바르게 분기하는지 검증한다.
- `Composition` Tests(`GenerationCompletionReminderCoordinatorTests`): 등록된 프로젝트의
  완료 신호 수신 시 발송, 미등록·실패·중복 신호에서 미발송을 검증한다.
- `Composition` Tests(`AppCompositionPublicSurfaceTests`): 신규 공개 표면
  `requestGenerationReminder: any RequestGenerationReminderUseCase`의 시그니처를 검증한다.

## 수동 시뮬레이터 검증(시나리오 1, 2)

1. iOS Simulator에서 앱을 최초 실행한다(알림 권한이 `notDetermined`인 상태).
2. 프로젝트 등록 흐름에서 GitHub 레포지토리를 검증하고 생성을 제출한다.
3. 생성 진행 화면에서 `홈에서 기다리기`를 탭해 알림 옵션 시트를 띄운다.
4. `리마인드 알림 설정하기`(수락)를 탭한다.
   - **기대**: iOS 시스템 알림 권한 요청 다이얼로그가 뜬다(시나리오 1-1).
5. 다이얼로그에서 허용을 선택한다.
   - **기대**: 다이얼로그 응답과 무관하게 곧바로 등록 흐름이 닫히고 Home으로 복귀한다.
6. 서버(또는 테스트용 FCM 페이로드 주입 도구)로 같은 프로젝트의 생성 완료 신호를 보낸다.
   - **기대**: Home에 머무는 상태에서도 사용자에게 보이는 로컬 알림이 도착한다(시나리오
     2-2, Home 복귀 후 리마인드 지속).
7. 시스템 설정 앱 > 알림 > (앱 이름)에서 알림을 다시 껐다가, 다른 프로젝트에 대해 같은
   절차(3~4)를 반복해 수락을 탭한다.
   - **기대**: 시스템 다이얼로그 없이 설정 앱의 알림 화면으로 즉시 이동한다(시나리오 1-2,
     이미 거부된 상태).

## 회귀 확인(019 로직 불변)

- 알림 옵션을 거절하거나 시트를 닫아도 기존과 동일하게 등록 흐름이 닫히고 Home으로
  복귀하는지 확인한다(FR-008/시나리오 2-3, 019 FR-014/FR-015 회귀 없음).
- 생성 실패 신호를 수신했을 때 기존 재시도 가능 실패 상태 UI가 그대로 동작하고, 로컬 알림은
  발송되지 않는지 확인한다(시나리오 3).
