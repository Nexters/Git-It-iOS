# 조사: 생성 상태 관측 단일화와 무효 스트림 제거

**날짜**: 2026-09-15 | **명세**: [spec.md](./spec.md)

## 1. Apple 자격 증명 관측이 동작하지 않는 원인

- **결정**: `authorizationChanges()` 계열을 제거하고 앱 활성 전환 시점의 1회 조회로 대체한다.
- **근거**: `AppleCredentialStateProvider`에서 값을 흘리는 유일한 진입점은 `receiveRevocation(for:)`이고 호출처가 테스트 1곳뿐이다(`Infrastructure/Tests/Authentication/AppleAuthentication/Providers/AppleCredentialStateProviderTests.swift:17`). 프로덕션 조립(`AuthenticationAssembly`)에 호출 경로가 없어 스트림이 값을 내지 않는다. `ASAuthorizationAppleIDProvider`는 상태 조회 API(`getCredentialState(forUserID:)`)를 이미 제공하고 `authorizationStatus()`가 이를 사용하므로, 조회 기반 대체에 새 플랫폼 연동이 필요 없다.
- **검토한 대안**:
  - `ASAuthorizationAppleIDProvider.credentialRevokedNotification` 구독으로 스트림을 실제로 살린다 — 알림은 앱이 실행 중일 때만 오고 백그라운드 취소를 놓친다. 활성 전환 조회가 같은 보장을 더 적은 코드로 준다.
  - 스트림만 제거하고 대체하지 않는다 — 문서에 기술된 "취소 시 세션 정리" 보장이 사라진다. 명세 FR-006이 이를 금지한다.

## 2. 재인증 판정의 반환 값 설계

- **결정**: 새 UseCase는 Domain이 이미 소유한 `AuthorizationStatus`(`.authorized` / `.reauthenticationRequired` / `.temporarilyUnavailable`)를 그대로 반환하고, `.reauthenticationRequired`일 때만 세션을 정리한다. 기존 `AuthenticationOutcome`과 `AuthenticationOutcomes`는 제거한다.
- **근거**: 기존 `AuthenticationOutcomes`는 `.authorized`일 때 `loginSessionRepository.restore()`를 호출해 세션을 복원한다. 이를 활성 전환마다 수행하면 포그라운드 진입 때마다 네트워크 호출이 생겨 명세에 없는 동작 변화가 발생한다. 상태만 반환하면 명세 FR-006·FR-007을 정확히 충족하면서 부작용이 없다.
- **검토한 대안**: `AuthenticationOutcome`을 유지해 1회 호출로 바꾼다 — 복원 부작용이 따라오고, `LoggedInUser`를 실어 나를 이유가 없어졌다.

## 3. 구독 시점 독립성을 얻는 방법

- **결정**: 최신 상태를 보유하는 Domain actor를 두고, 관측 시작 시 현재 상태를 먼저 1회 전달한 뒤 이후 변경을 전달한다.
- **근거**: `AsyncStream`은 구독 이후 값만 전달한다. 현재 코드는 이를 우회하려고 `QuizGenerationProgressFeature`가 생성 요청 **전에** 미리 구독하고(`QuizGenerationProgress/QuizGenerationProgressFeature.swift:187`), `HomeFeature`는 놓친 이벤트를 별도 저장소로 보완한다. 상태 보유 + 초기 1회 전달이 두 우회를 동시에 제거한다.
- **검토한 대안**:
  - `AsyncStream`에 버퍼링 정책을 지정한다 — 버퍼는 구독 이후 생성된 값에만 적용되며 구독 이전 값을 복원하지 못한다.
  - 각 관측자가 구독 직후 별도 조회를 한 번 한다 — 조회와 스트림 사이의 틈에서 값이 유실되고, 모든 관측자가 같은 조합 규칙을 반복 구현해야 한다.

## 4. 진행 상태와 등록 상태의 통합 가능성

- **결정**: `GenerationProgress`(projectID 기준)와 `RepositoryCreationState`(정규화한 저장소 URL 기준)를 하나의 생성 기록 집합으로 통합한다.
- **근거**: 둘 다 "생성 요청이 진행 중"이라는 같은 사실을 다른 키로 표현한다. 등록 요청 시점에는 projectID가 없어 URL이 필요하고, 등록 응답 후에는 projectID가 부여된다. 한 기록이 두 키를 모두 갖게 하면 `CreateLearningProject`의 중복 방지, `FetchLearningProjects`의 진행 중 항목 필터, 진행 화면의 대기 시간 계산이 하나의 정본을 공유한다.
- **검토한 대안**: 두 저장소를 유지한 채 관측만 통합한다 — 명세 FR-002가 금지한다. 정합성 보장 지점이 여전히 없다.

## 5. 기존 저장 값의 이관

- **결정**: 통합 상태는 새 단일 키에 저장하고, 최초 로드 시 기존 두 키(`com.nexters.hytime.gitit.generationProgress` 네임스페이스의 진행 정보, 공유 저장소의 등록 상태 키)를 읽어 병합한 뒤 기존 키를 제거하는 1회 이관을 수행한다.
- **근거**: 이관 없이 키를 바꾸면 앱 업데이트 시점에 진행 중이던 생성이 목록 필터와 대기 시간 계산에서 사라진다. 이관은 Data가 소유한다.
- **검토한 대안**: 기존 두 키를 그대로 쓰며 읽을 때만 합친다 — 저장 정본이 둘로 남아 FR-002를 충족하지 못한다.

## 6. 종료된 생성 기록의 보관

- **결정**: 완료·실패 기록을 즉시 제거하지 않고 기존 `GenerationWaitPolicy.retentionLimit`(3,600초) 동안 보관한 뒤 정리한다.
- **근거**: 관측을 늦게 시작한 관측자가 완료를 보려면 종료 사실이 상태에 남아 있어야 한다. 보관 기간을 새로 정하지 않고 이미 존재하는 보존 한도를 재사용하면 대기·만료 동작의 기준이 하나로 유지된다.
- **검토한 대안**: 완료 즉시 제거하고 별도의 "최근 완료" 목록을 둔다 — 정본이 다시 둘로 나뉜다.

## 7. 기기 토큰 갱신 전달 수단

- **결정**: 값 없는 `AsyncStream<Void>` 대신 갱신 시 호출되는 통지 수단으로 바꾸고, 필수 의존성으로 만든다.
- **근거**: 갱신은 값이 없고 빈도가 낮은 단발 신호다. 현재 `AppRootFeature.init`의 기본값 `{ AsyncStream { $0.finish() } }`는 주입 누락을 런타임에 조용히 흡수해 기기 등록 실패를 감춘다. [Feature 패키지 규칙](../../docs/package-rules/feature.md)은 필수 의존성에 live 기본값을 주는 것을 금지한다.
- **검토한 대안**: 스트림을 유지하고 기본값만 제거한다 — FR-008의 표현 방식 요구를 충족하지 못한다.

## 8. 관측 해제 누락

- **결정**: 관측자 목록을 보유하는 모든 타입이 종료 시 자신의 목록에서 해당 관측을 제거하도록 하고, 반복 등록·해제 후 목록 크기가 증가하지 않음을 테스트로 고정한다.
- **근거**: `AppleCredentialStateProvider.changes()`는 continuation을 배열에 추가만 하고 제거하지 않는다. `PushQuizGenerationOutcomeSource`는 제거하므로, 규칙을 새 통합 관측 대상에 선적용해야 같은 결함이 재도입되지 않는다.
- **검토한 대안**: 약한 참조로 자동 정리한다 — continuation은 값 타입이라 적용할 수 없다.
