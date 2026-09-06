# 조사: 마이페이지 구현

**입력**: [spec.md](./spec.md)의 기능 요구사항, 기존 소스 조사, `implement-figma-ui` 재조회 결과

> 이 문서는 `/speckit-implement` 착수 중 Figma 재조회로 드러난 사실을 반영해 재작성됐다.
> 최초 버전(단일 `SettingsScreen` + 시트 기반 선택)의 결정 4·5·6은 무효화됐다.

## 1. 화면 구조 — Router + 화면 5개

- **결정**: "마이" 탭은 화면 하나가 아니라 **프로필 화면**(신규 `ProfileFeature`)과
  **설정 화면**(기존 `SettingsFeature` 재사용, 목록/개발 분야 선택/개발 수준 선택/계정
  삭제 확인 4단계)으로 구성하고, 이 둘을 `SettingsRouterFeature`(신규)로 연결한다.
- **근거**: `implement-figma-ui`로 노드 `4393:6038`(Task 개요), `1539:19209`(프로필),
  `1465:19689`(설정), `1535:18281`/`1535:18378`(개발 분야/수준 선택),
  `1636:31714`(계정 삭제)를 직접 조회한 결과, 프로필 화면 우측 상단 설정 아이콘을
  눌러야 설정 화면에 진입하는 별도 여정임을 확인했다. [TCA Navigation 컨벤션
  §2.3](../../docs/conventions/tca/navigation.md#23-router-feature와-화면-전환-소유)의
  "화면이 둘 이상인 흐름은 Router-Feature를 둔다"를 그대로 적용한다.
- **검토한 대안**: 단일 `SettingsScreen`에 프로필 헤더까지 포함하는 최초 계획은
  기각했다 — 실제 디자인과 맞지 않고, 설정 화면만 단독으로 재방문하는 사용자 흐름
  (프로필 화면을 거치지 않고 뒤로가기로 설정에 남는 경우)을 표현할 수 없다.

## 2. Router 내부 구조 — "한 화면 Feature가 여러 단계를 가짐" 패턴

- **결정**: `SettingsRouterFeature.State`는 `profile: ProfileFeature.State`와
  `settings: SettingsFeature.State`를 항상 함께 보유한다. 활성 화면은
  `enum ActiveScreen { case profile; case settings(SettingsStep) }`,
  `enum SettingsStep { case list, positionSelection, careerLevelSelection,
  accountDeletion }`로 표현한다. `SettingsFeature`의 State·Action은 변경하지 않는다 —
  이미 있는 `positionSelected`/`careerLevelSelected`/`deleteAccountTapped` 등을 그대로
  사용하고, "지금 어떤 단계가 보이는지"만 Router가 소유한다.
- **근거**: [TCA Navigation 컨벤션 §2.3](../../docs/conventions/tca/navigation.md#23-router-feature와-화면-전환-소유)의
  "하나의 화면 Feature가 여러 단계를 가지면 세부 화면을 연관값으로 함께 포함하는
  계층형 값"을 그대로 따른 것이다. 개발 분야/개발 수준 선택과 계정 삭제 확인은 모두
  `SettingsFeature`가 이미 가진 데이터(positionMutation 등)만 사용하는 같은 화면
  Feature의 단계이지 독립된 화면 Feature가 아니다.
- **검토한 대안**: 선택·삭제 확인마다 별도 화면 Feature를 새로 만드는 방안은 기각했다
  — 상태(현재 직군/연차, mutation 상태)가 모두 `SettingsFeature`에 이미 있어 중복
  Feature를 만들면 같은 데이터를 두 Reducer가 나눠 갖게 된다.
- **뒤로가기**: `NavigationStack`/`StackState`를 쓰지 않고, `ActiveScreen`을 이전 값으로
  되돌리는 상태 전이로 구현한다(컨벤션 §2.3). 프로필 → 설정 → 개발 분야 선택 방향으로
  진입했다면 뒤로가기는 그 역순으로 `ActiveScreen`을 되돌린다.

## 3. 화면 상태 관리 재사용 여부 — `SettingsFeature`(변경 없음)

- **결정**: `SettingsFeature`는 그대로 재사용한다. 새 Reducer를 만들지 않는다.
- **근거**: 이미 프로필 조회(`profileLoad` — 설정 화면이 개발 분야/수준의 현재 값을
  보여주는 데 사용), 직군·연차 변경, 로그아웃·계정 탈퇴를 실패 처리까지 포함해 구현하고
  있다. `MainShellRouterFeature`도 5개 UseCase 의존성을 이미 App까지 전달한다.
- **검토한 대안**: 없음(최초 조사와 동일한 결론이며 재확인만 했다).

## 4. 신규 `ProfileFeature`

- **결정**: 프로필 화면 전용 `ProfileFeature`를 신규 추가한다. `FetchMemberProfileUseCase`를
  생성자로 주입받아 화면 진입 시 독립적으로 프로필(통계 포함)을 조회한다.
- **근거**: 프로필 화면은 설정 화면과 다른 정보(이름·이메일·직군 배지·연차 배지·통계
  3종·주간 추이)를 보여주며, 설정 화면 재방문 시 프로필을 다시 그릴 필요가 없다.
  Home과 Settings가 이미 각자 독립적으로 `fetchMemberProfile`을 호출하는 이 저장소의
  기존 관행([HomeFeature](../../sources/Projects/Feature/Home/Home/HomeFeature.swift),
  [SettingsFeature](../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift))과
  일치한다.
- **검토한 대안**: `SettingsFeature`가 이미 가진 `profileLoad`를 Router가 두 화면에
  공유하는 방안은 기각했다 — Navigation 컨벤션이 "화면 Feature는 자신의 화면 상태만
  소유한다"를 요구하고, 공유 상태는 어느 화면이 소유자인지 모호해진다.

## 5. 직군·연차 선택 화면 — `SelectionCardList` 재사용

- **결정**: 개발 분야/개발 수준 선택은 시트가 아니라 **전체 화면**이며, 이미 존재하는
  `SelectionCardList`(`.compact` 스타일=직군, 기본 `.detailed` 스타일=연차)로 구현한다.
  온보딩의 [PositionSelectionScreen](../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift)·
  [CareerSelectionScreen](../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift)이
  이미 이 컴포넌트로 동일한 시각 패턴(카드형, 선택 시 파란 테두리)을 구현하고 있고
  Figma 문구도 그대로 일치한다(연차 "입문/주니어/미들/시니어"와 각 설명 문구).
- **근거**: 새 컴포넌트가 필요 없고, 표시 문구(제목·설명·아이콘)는 온보딩 화면의
  `Display` enum과 동일하게 설정 흐름 화면에도 각자 정의한다(§6 참고).
- **검토한 대안**: 온보딩 화면을 그대로 import해 재사용하는 방안은 검토했지만 기각했다
  — 온보딩 화면은 `OnboardingRouterFeature`에 속한 진입 전용 흐름이고, `nextTapped` 등
  온보딩 전용 Action에 결합되어 있어 설정 흐름에서 직접 재사용하면 책임이 섞인다.
  대신 같은 `SelectionCardList` 컴포넌트와 동일한 표시 문구를 설정 흐름 화면에
  독립적으로 구현한다(이 저장소가 이미 `HomeProfileDisplay`·온보딩 두 곳에서 직군·연차
  한글 매핑을 각자 정의하고 있는 기존 관행과 일치).

## 6. 계정 삭제 확인 — 전체 화면

- **결정**: 계정 삭제 확인은 다이얼로그가 아니라 경고 문구 + "회원 탈퇴" 버튼이 있는
  **전체 화면**(`SettingsScreen+AccountDeletionView.swift`)이다.
  `accountAction == .confirmingDeletion` 상태를 그대로 화면 표시 조건으로 쓰고,
  기존 `deleteAccountConfirmed`/`deleteAccountCancelled`(뒤로가기) Action을 그대로
  연결한다.
- **근거**: Figma 노드(`1636:31714`)가 별도 프레임이며 경고 문구가 다이얼로그로 담기에는
  길다.
- **검토한 대안**: 최초 조사의 `confirmationDialog`/`SheetSurface` 결정은 기각한다.

## 7. Domain `LearningStatistics` 필드 교정 (신규 발견)

- **결정**: `LearningStatistics`를 `thisWeekSolvedCount: Int`, `thisMonthSolvedCount: Int`,
  `streakDays: Int`, `weeklyCounts: [WeeklyLearningCount]`로 교정하고,
  `WeeklyLearningCount`를 `dayLabel: String`(예: "월"), `count: Int`로 교정한다.
  Composition의 `MemberRepositoryAdapter.fetchProfile()`이 DTO의 값을 그대로 전달하도록
  수정하고, 날짜 파싱 시도(`dayFormatter`, `weeklyCount(from:)`)를 제거한다.
- **근거**: `https://git-it.kr/v3/api-docs`(OpenAPI 문서)에서 `GET /api/v1/members/me`의
  실제 응답 예시를 직접 조회한 결과 `thisWeekSolvedCount`/`thisMonthSolvedCount`/
  `streakDays`/`weeklyChart`(각 `{dayLabel, count}`)가 이미 존재한다. Data 계층
  ([MemberProfileResponseDTO](../../sources/Projects/Data/Member/DTOs/MemberProfile/MemberProfileResponseDTO.swift),
  [WeeklyChartItemDTO](../../sources/Projects/Data/Member/DTOs/MemberProfile/WeeklyChartItemDTO.swift))는
  이미 이 필드를 올바르게 디코딩하고 있었지만, Composition의 어댑터가
  `totalAnsweredCount: response.thisMonthSolvedCount`(의미 불일치),
  `totalCorrectCount: 0`(항상 0 하드코딩), `weeklyChart`의 `dayLabel`("월" 등)을
  `yyyy-MM-dd` 형식으로 파싱 시도(항상 실패 → `compactMap`이 모두 버림)하고 있어 화면에
  필요한 값을 전혀 전달하지 못하는 상태였다. 서버에 새 필드를 요청할 필요가 없다.
- **영향 범위**: Domain(`LearningStatistics.swift`, `WeeklyLearningCount.swift`),
  Composition(`MemberRepositoryAdapter.swift`와 그 테스트), 호출부
  (`AppRootView.swift`, `HomeScreenPreviews.swift`, Domain 테스트 3개 파일) — 모두
  fixture 구성 변경이며 기능적으로 이 통계를 소비하는 기존 Feature는 없다(Home은
  `statistics`를 사용하지 않는다).
- **검토한 대안**: 이번 기능 범위에서 통계 카드를 "총 풀이/총 정답"으로 축소해
  기존 필드 그대로 쓰는 방안은 기각했다 — Figma와 실제 서버 응답 모두 이미 정확한
  값(이번 주/이번 달/연속 학습)을 제공하므로 축소하면 존재하는 데이터를 버리게 된다.

## 8. "세트 생성 완료 알림" 항목 제외

- **결정**: 설정 화면에 "세트 생성 완료 알림" 행을 구현하지 않는다(spec.md FR-014).
- **근거**: 사용자가 명시적으로 이번 범위에서 제외를 결정했다. 이 항목이 필요로 하는
  Domain 계약(알림 on/off 조회·변경)이 기존 5개 UseCase에 없고, 020-local-reminder-notification
  스펙과의 중복·연계 여부도 확인되지 않았다.
- **검토한 대안**: 없음(사용자 결정).

## 9. Figma 노드 조회 제약(최초 조사, 재확인됨)

- **결정**: 큰 노드/페이지에 대한 `get_metadata`는 SSE 파싱 오류로 실패하므로 사용하지
  않는다. `get_screenshot`으로 대상을 먼저 식별하고, 필요한 하위 노드만 좁혀 조회한다
  (`.agents/skills/implement-figma-ui/references/mcp-playbook.md` §4·§5).
- **근거**: 이번 세션에서 `get_screenshot`은 모든 대상 노드(`4393:6038`, `1539:19209`,
  `1465:19689`, `1535:18378`)에서 정상 동작했다. 문제는 인증이나 연결이 아니라
  `get_metadata`의 응답 크기였다.
