# 빠른 시작: 프로젝트 등록·학습 세트 생성 흐름 검증

## 사전 준비

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
```

workspace가 없으면 `sources`에서 `tuist generate`를 먼저 실행한다. Firebase 콘솔에
등록된 iOS 앱의 `GoogleService-Info.plist`가 `App/GitIt` 리소스에 포함돼 있어야
`FirebaseApp.configure()`가 성공한다(이미 있다면 이 기능은 그것을 재사용하고, 없다면
구현 단위에서 배치 위치를 확정한다).

## 자동화 검증

```sh
"$project_build_runner" compile
"$project_build_runner" test
```

아래 테스트가 통과해야 한다(정확한 파일 경로는 `tasks.md`가 확정).

- `ProjectRegistrationFeatureTests`: 시나리오 1·2·3·4의 State 전이·delegate 출력
- `HomeFeatureTests`: FCM 관찰 Effect 시작 1회, `reloadRequested` 1회 재조회
- `AppRootFeatureTests`: 등록 흐름 표시·종료·Home 복귀
- `LearningProjectGenerationOutcomeRepositoryAdapterTests`: DTO→Domain 변환

## 수동 검증 시나리오 (Simulator 또는 실기기)

FCM silent push와 실제 UIApplicationDelegate 콜백은 XCTest로 결정적으로 재현하기
어려우므로 다음 경로를 Simulator에서 직접 확인한다.

1. **등록 흐름 진입**: Home에서 `지금 불러오기` 탭 → 등록 화면(Figma `986:13739`
   계열)이 전체 화면으로 표시되고 MainShell 탭 바가 보이지 않는지 확인한다. 등록 흐름이
   표시된 상태에서 MainShell의 다른 탭을 탭해도 전환되지 않는지 확인한다(SC-015).
2. **레포 검증**: 유효한 GitHub URL 입력 → 검증 → 레포 확인 화면(`737:10890`)
   전환을 확인한다. 무효한 URL로 재시도해 실패 상태가 재시도만 가능한지 확인한다.
3. **이해도 선택·제출**: `QuizLevel` 3종 선택 각각에 대해 선택 상태 표시를 확인하고
   제출한다.
4. **생성 진행 화면**: 제출 성공 직후 5단계 체크리스트(`737:10800`)가 정적으로
   표시되고, 이 화면에 머무는 동안 Xcode Console이나 서버 로그로 폴링 요청이
   발생하지 않는지 확인한다(SC-010).
5. **`홈에서 기다리기` 경로**: CTA 탭 → 알림 옵션 시트(`824:12149`) 표시 → 수락 또는
   거절 → Home으로 복귀하고 프로젝트 목록이 정확히 1회 재조회되는지 네트워크 로그로
   확인한다.
6. **FCM 완료 경로**: 진행 화면에 머무른 채로, 테스트용 FCM 콘솔이나 백엔드
   트리거로 해당 `projectID`의 완료 payload를 전송한다. 앱이 알림 권한을 거부한
   상태에서도 화면이 완료로 전이되고 Home으로 복귀하는지 확인한다(권한 무관 동작,
   명확화 세션 결정).
7. **FCM 실패 경로**: 동일하게 실패 payload를 전송해 재시도 가능한 단일 실패
   상태가 표시되는지 확인하고, 재시도가 동일 입력으로 `createLearningProject`를
   다시 호출하는지 확인한다.
8. **Home 단독 수신**: 5의 경로로 먼저 Home에 복귀한 뒤, 같은 `projectID`의 완료
   payload를 전송해 Home 목록의 해당 항목 상태가 갱신되는지 확인한다.
9. **중복 payload**: 6 또는 9의 payload를 두 번 연속 전송해 상태 반영이 중복되지
   않는지 확인한다(SC-016).
10. **취소 경로**: 등록 흐름 도중(제출 전) 뒤로 가기로 흐름을 닫고 Home 상태에
    부작용이 없는지 확인한다(SC-014).
11. **접근성**: VoiceOver를 켠 채 1~5를 반복하고, Dynamic Type을 `accessibility5`로
    올려 각 화면의 핵심 조작이 잘리지 않는지 확인한다(SC-012/SC-013).

## 참고

- 정확한 화면 픽셀 값과 UIComponent 재사용 여부는 이 문서가 아니라 구현 단위에서
  `.agents/skills/implement-figma-ui`로 Figma node를 직접 조회해 검증한다.
- 이 문서는 `/speckit-tasks`가 검증 작업을 세분화할 때의 참고 자료이며, 완전한
  자동화 테스트 목록이나 구현 코드를 포함하지 않는다.
