# 기능 명세: Onboarding Router 리팩토링

**Git-flow 유형**: `feature`

**기능 브랜치**: `미생성 (예정: feature/onboarding-router-refactor)`

**생성일**: 2026-08-27

**상태**: 초안

**입력**: 사용자 설명: "OnboardingFeature 에 대해 리팩토링이 필요합니다. Feature 는 책임에 따라 분리하고 조합해야합니다. 그리고, 현재 Onboarding 이라는 기능 아래에 너무 많은 기능을 담고 있습니다. Router 패턴을 적용해 Onboarding 화면들을 분리하고, 화면이동에 대해서 추적 가능하도록 TDD 방식으로 리팩토링합니다."

## 명확화

### 세션 2026-08-28

- 질문: Router 패턴이 이번에 처음 도입되는 구조이므로 `docs/conventions/tca.md`에 정식
  섹션으로 문서화하는 것을 이번 범위에 포함할까요, 아니면 Onboarding 코드 리팩토링만
  다루고 문서화는 별도 후속 작업으로 분리할까요? → 답변: 이번 기능 범위에
  `docs/conventions/tca.md`에 Router 패턴(화면 조합, 이동 추적 이벤트)을 정식 섹션으로
  추가하는 것을 포함한다.
- 질문: 이동 추적 대상이 Router가 조합하는 최상위 단위 간 전환으로 한정되는지, 아니면
  단위 내부의 세부 화면 전환까지 포함하는지? → 답변: 사용자가 체감하는 모든 화면
  전환을 추적한다. 최상위 단위는 각각 자신의 내부 세부 화면을 연관값으로 갖는 계층형
  화면 식별자로 표현하고, 그 연관값 변화를 통해 단위 내부 전환도 이동 이벤트로
  추적한다.
- 질문: SC-005의 "가장 큰 단일 Reducer 파일의 크기가 유의미하게 줄어"는 정량 기준이
  없어 검증할 수 없다. 파일 크기(줄 수) 감소를 기준으로 삼을지, 아니면 다른 방식으로
  측정할지? → 답변: 크기 감소는 결과일 뿐 의도한 기준이 아니다. 의도한 기준은 응집도
  관점의 분리이므로, SC-005는 각 화면 Feature Reducer가 자신이 속한 책임 단위의
  Action·상태 전이만 처리하고 다른 책임 단위의 상태를 직접 변경하는 case가 존재하지
  않는다는 응집도 검증 기준으로 대체한다.
- 질문: 세션 복원(인증)이 정말 Onboarding의 책임 범위에 포함되어야 하는가? →
  답변: 아니다. 세션 복원과 "온보딩 진입이 필요한가" 판단은 Onboarding의 책임이 아니라
  앱이 처음 시작할 때 목적지를 정하는 App 최상위 Route(이미 저장소에 존재하는
  `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`)의 책임이다. 이번
  리팩토링 범위는 그 로직을 `AppRootFeature`로 옮기는 것까지 포함하며, Onboarding
  Router는 인증을 제외한 2개 화면 Feature(온보딩 안내, 큐레이션)만 조합한다.
- 질문: Onboarding Router의 화면 값에 "완료" case를 직접 둘 것인가? → 답변: 아니다.
  Router의 화면 값 enum에는 "완료" case를 두지 않는다. Router가 상위(App Root)로
  나가야 하는지는 큐레이션 제출 성공 같은 조건을 관찰하는 별도 하위 Feature가
  판단하며("완료 여부"가 아니라 "Router 전환 여부"를 판단하는 책임), 그 결과를
  `delegate` Action으로 상위에 알린다.
- 질문: Onboarding Router보다 생명주기가 긴 상태(예: App Root가 로그아웃 후 Onboarding
  Router를 새 State로 재생성할 때도 유지돼야 하는 값)를 TCA `@Shared`, `Binding` 또는
  `inout`으로 공유할 수 있는가? → 답변: 아니다. `@Shared`는 key 기반 전역 저장소에
  가까워 이 프로젝트가 이미 금지한 `@Dependency`·전역 mutable container와 같은
  계열이며, `Binding`을 State에 저장하는 것은 `docs/conventions/tca.md` 4.1이 금지하는
  closure 저장과 같은 문제(추적 어려움, `TestStore` 값 비교 불가)를 재도입한다.
  `inout`은 함수 호출 동안만 유효해 State 프로퍼티로 보존할 수 없다. 대신 오래 유지돼야
  하는 값은 그 값의 정본을 가진 계층(App Root 자신의 State, 또는 Keychain·서버 같은
  Domain/Infrastructure 정본)이 소유하고, 하위 Feature는 `delegate` Action으로 상위에
  알리거나 필요할 때 자신의 생성자 주입 UseCase로 정본을 다시 조회한다. App Root가 이미
  `.onboarding(.delegate(.mainShellRequested))`를 받아 자신의 `route`를 갱신하는 것과
  같은 패턴이며 새 메커니즘을 도입하지 않는다.
- 질문: `AppRootFeature`/`AppRootView`의 현재 미완성 부분 중 `mainShellPlaceholder`
  (실제 MainShell 화면 대신 표시되는 `Text("MainShell")`)를 실제 화면으로 교체하는
  것까지 이번 계획 대상에 포함할 것인가? → 답변: 아니다. 확인 결과 `MainShellFeature`는
  아직 화면(View/Screen) 자체가 없어(Reducers·Models만 존재), 이는 Onboarding/App Route
  책임 경계와 무관한 별개의 미완성 작업이다. 이번 범위는 `AppRootFeature`가
  `restoreSession` 호출과 결과에 따라 `route`를 `.mainShell`로 정확히 전환하는 것까지만
  다루고, `mainShellPlaceholder`를 실제 MainShell 화면으로 교체하는 것은 별도 후속
  기능으로 명시적으로 남긴다.

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - App Route와 Onboarding의 책임 경계 재설정 및 화면별 분리 (우선순위: P1)

`OnboardingFeature` 하나가 세션 복원(인증), 튜토리얼·약관 동의·로그인, 포지션·경력
선택까지 전부 담당하는 단일 Reducer(약 500줄)로 되어 있다. 그런데 세션 복원과 "온보딩
진입이 필요한가" 판단은 본래 Onboarding의 책임이 아니라 앱이 처음 시작할 때 목적지를
정하는 App 최상위 Route(`AppRootFeature`)의 책임이다. 개발자가 이 경계를 바로잡아
세션 복원·진입 판단 로직은 `AppRootFeature`로 옮기고, Onboarding은 "이미 온보딩 진입이
필요하다고 판단된 이후"의 흐름만 담당하는 응집도 높은 단위(온보딩 안내, 큐레이션)로
분리해, 각 단위를 독립적으로 이해·수정·테스트할 수 있게 한다.

**주요 행위자**: Git-It iOS 앱을 유지보수하는 개발자

**우선순위 이유**: 책임 경계 재설정과 분리 자체가 이번 리팩토링의 전제 조건이며, 이후
Router 조합과 이동 추적 검증이 이 분리 위에서 이루어진다.

**독립 테스트**: 분리된 각 Feature(`AppRootFeature`, Onboarding Router의 화면
Feature들)의 State·Action·Reducer를 다른 Feature를 몰라도 단위 테스트로 검증할 수
있음을 확인하는 것으로 가치를 확인할 수 있다.

**수용 시나리오**:

1. **전제** 리팩토링 전 `OnboardingFeature`가 세션 복원과 온보딩 화면 로직을 모두
   소유한다, **실행** 개발자가 리팩토링을 완료한다, **결과** 세션 복원과 "온보딩 진입
   필요 여부" 판단은 `AppRootFeature`가 소유하고, Onboarding Router는 온보딩 안내
   (튜토리얼·약관 동의·로그인)와 큐레이션(포지션·경력 선택) 2개 화면 Feature만
   조합한다.
2. **전제** 분리된 하나의 화면 Feature가 존재한다, **실행** 개발자가 그 Feature만 단위
   테스트를 실행한다, **결과** 다른 화면 Feature나 `AppRootFeature`의 State·Action
   타입을 import하거나 목(mock)으로 준비하지 않고도 테스트가 통과한다.

---

### 시나리오 2 - App Root의 진입 판단과 Router를 통한 화면 조합 (우선순위: P1)

`AppRootFeature`는 세션 복원과 회원 프로필 완료 여부에 따라 MainShell로 바로 이동할지,
Onboarding Router에 진입시킬지, 그리고 Onboarding Router에 진입시킨다면 처음(온보딩
안내)부터 시작할지 큐레이션부터 바로 시작할지를 판단한다. Onboarding Router는 그렇게
결정된 시작 지점부터, 리팩토링 이전과 동일한 사용자 흐름(온보딩 안내 → 큐레이션 →
완료)을 재현한다.

**주요 행위자**: Git-It iOS 앱을 유지보수하는 개발자, 그리고 이 흐름을 실제로 사용하는
최종 사용자

**우선순위 이유**: 진입 판단과 화면 조합이 실제 사용자 흐름을 깨뜨리면 리팩토링의
의미가 없으므로, 분리와 동등하게 최우선이다.

**독립 테스트**: `AppRootFeature`의 상태 전이 테스트만으로 "미인증 → 온보딩 안내부터
시작", "인증+프로필 미완료 → 큐레이션부터 시작", "인증+프로필 완료 → MainShell 직행"을
확인할 수 있고, Onboarding Router의 상태 전이 테스트만으로 "온보딩 안내 완료 → 큐레이션
→ 완료(App Root로 위임)"라는 대표 여정이 기존과 동일한 순서로 전환됨을 확인할 수 있다.

**수용 시나리오**:

1. **전제** 세션 복원이 인증되지 않은 상태로 끝난다, **실행** `AppRootFeature`가 이
   결과를 처리한다, **결과** Onboarding Router에 진입하며 튜토리얼 1페이지부터
   시작한다(리팩토링 이전과 동일).
2. **전제** 세션 복원이 인증됐고 회원 프로필에 포지션·경력 정보가 없다, **실행**
   `AppRootFeature`가 이 결과를 처리한다, **결과** Onboarding Router에 진입하며
   큐레이션(포지션 선택)부터 바로 시작한다.
3. **전제** 사용자가 온보딩 안내에서 약관에 동의하고 로그인에 성공했으며 포지션·경력
   정보가 없다, **실행** Onboarding Router가 로그인 완료 이벤트를 처리한다, **결과**
   큐레이션(포지션 선택)으로 전환된다.
4. **전제** 사용자가 포지션 선택 화면에서 뒤로 가기를 실행한다, **실행** Onboarding
   Router가 로그아웃 Effect 완료를 처리한다, **결과** 온보딩 안내(튜토리얼 3페이지)로
   되돌아가고 큐레이션 선택 상태가 초기화된다.
5. **전제** 큐레이션 제출이 성공한다, **실행** Router 하위의 전환 판단 Feature가 이
   조건을 감지한다, **결과** Onboarding Router가 `delegate(mainShellRequested)`를
   상위(App Root)로 올리고, App Root가 MainShell로 전환한다.

---

### 시나리오 3 - 테스트로 검증 가능한 화면 이동 추적 (우선순위: P2)

Onboarding Router로 화면 전환이 조합되면서 화면 전환이 여러 곳에 흩어져 발생할 수
있다. 개발자가 온보딩 여정의 회귀를 안전하게 검증하려면, 어떤 화면에서 어떤 화면으로
전환되었는지를 테스트 코드로 직접 확인할 수 있어야 한다. Onboarding Router는 화면
전환이 발생할 때마다 전환 이전 화면·이후 화면·전환을 유발한 액션을 담은 이벤트를
남긴다.

**주요 행위자**: Git-It iOS 앱을 유지보수하는 개발자

**우선순위 이유**: 이동 추적은 App Route/Onboarding 경계 재설정과 화면 조합이 끝난
뒤에 그 위에서 검증 가능성을 더하는 요구사항이므로 시나리오 1·2보다 우선순위가 낮다.

**독립 테스트**: Onboarding Router 테스트에서 특정 액션을 보낸 뒤 화면 이동 이벤트
목록을 조회해 전환 이전·이후 화면이 기대한 값과 일치하는지 어서션(assert)하는 것만으로
검증할 수 있다. 실제 analytics·로깅 인프라 연동, 그리고 `AppRootFeature`의 자체 Route
전환은 이번 이동 추적 범위에 포함하지 않는다.

**수용 시나리오**:

1. **전제** Onboarding Router가 튜토리얼 화면에 있다, **실행** 사용자가 로그인 완료
   후 약관 동의가 필요해 약관 동의 화면으로 전환된다, **결과** 테스트가 "튜토리얼 →
   약관 동의" 전환 이벤트를 조회해 발생 여부와 순서를 확인할 수 있다. 두 화면 모두
   "온보딩 안내"라는 같은 최상위 단위에 속하므로, 이 이벤트는 최상위 단위는 그대로 두고
   그 연관값(내부 세부 화면)만 바뀐 전환으로 기록된다.
2. **전제** 온보딩 여정 중 화면 전환이 N번 발생한다, **실행** 테스트가 전체 이동 이벤트
   목록을 조회한다, **결과** 기록된 이벤트 수와 순서가 실제 발생한 전환 횟수·순서(최상위
   단위 간 전환과 단위 내부 세부 화면 전환을 모두 포함)와 정확히 일치한다.

---

### 예외·경계 사례

- 화면 Feature 내부에서 상태가 바뀌지만 Onboarding Router가 관리하는 화면이 바뀌지
  않는 경우(예: 포지션 선택 화면에서 포지션 값만 바뀌는 경우), 이동 추적 이벤트가
  발생하지 않아야 한다.
- 로그인 취소·재시도 가능한 실패처럼 화면이 바뀌지 않고 상태만 바뀌는 인증 실패
  케이스에서는 이동 추적 이벤트가 남지 않아야 한다.
- 세션 복원 실패 후 재시도(`restoreError` 유지 등)는 이제 `AppRootFeature`의 책임이며,
  이번 리팩토링의 이동 추적 요구사항(FR 대상은 Onboarding Router) 범위 밖이다.
  `AppRootFeature`는 자신의 상태 전이를 TDD로 작성된 테스트로 검증하되, 화면 이동
  이벤트 형태로 남길 필요는 없다.
- `requestID` 기반 오래된 비동기 응답 무시 로직처럼 기존 경쟁 상태(race condition)
  방지 동작은 `AppRootFeature`(세션 복원·프로필 조회)와 Onboarding Router(로그인,
  큐레이션 제출) 양쪽에서 리팩토링 이후에도 동일하게 유지되어야 한다.
- Onboarding Router와 그 하위 Feature, 그리고 `AppRootFeature` 사이에서 Router보다 긴
  생명주기가 필요한 값이 발견되면, 그 값은 발견한 시점에 자식 Feature의 State에
  두는 대신 소유권을 가진 상위(App Root 자신의 State 또는 Domain/Infrastructure 정본)로
  옮기고 `delegate` Action으로 전달해야 한다.

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: 시스템은 세션 복원과 "온보딩 진입이 필요한가" 판단 책임을 Onboarding에서
  제거하고, 이미 App 최상위 Route를 소유하고 있는 `AppRootFeature`
  (`sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
  `sources/Projects/App/GitIt/Screens/AppRootView.swift`)로 옮겨야 한다.
- **FR-002**: `AppRootFeature`는 세션 복원 결과와 회원 프로필 완료 여부(포지션·경력
  보유 여부)에 따라 MainShell로 바로 이동할지, Onboarding Router에 진입시킬지, 그리고
  진입시킨다면 온보딩 안내부터 시작할지 큐레이션부터 시작할지를 결정해야 한다. 이
  분기는 리팩토링 전 `OnboardingFeature`가 `restoreSessionFinished`·
  `memberProfileFetchFinished`에서 수행하던 판단과 동일한 결과를 내야 한다.
- **FR-003**: Onboarding Router는 인증(세션 복원)을 제외한 2개 화면 Feature — 온보딩
  안내(튜토리얼·약관 동의·로그인), 큐레이션(포지션·경력 선택) — 를 조합해야 한다.
- **FR-004**: 분리된 각 화면 Feature는 다른 화면 Feature나 `AppRootFeature`의
  State·Action 타입을 직접 참조하지 않고 독립적으로 컴파일·테스트되어야 한다.
- **FR-005**: Onboarding Router의 화면 값에는 "완료" case를 두지 않는다. Router가
  상위(App Root)로 나가야 하는지는 큐레이션 제출 성공 등 조건을 관찰하는 별도 하위
  Feature가 "Router 전환 여부"를 판단해야 하며, 그 판단 결과를 `delegate` Action으로
  상위에 알려야 한다.
- **FR-006**: Onboarding Router는 관리 중인 화면이 실제로 전환될 때마다 전환 이전
  화면, 전환 이후 화면, 전환을 유발한 액션을 식별할 수 있는 이동 이벤트를 생성해야
  하며, 이 이벤트는 프로덕션 analytics 인프라 연동 없이 단위 테스트에서 직접
  조회·검증할 수 있어야 한다. 화면 값은 온보딩 안내·큐레이션이라는 최상위 단위를
  나타내는 연관값 enum으로 표현하고, "온보딩 안내"처럼 내부에 튜토리얼·약관
  동의·로그인 같은 세부 화면을 가진 단위는 그 세부 화면을 자신의 연관값으로 함께
  표현해, 최상위 단위 간 전환뿐 아니라 같은 단위 안에서 연관값만 바뀌는 세부 화면
  전환도 이동 이벤트로 남아야 한다.
- **FR-007**: 화면 상태만 바뀌고 Onboarding Router가 관리하는 화면이 바뀌지 않는
  액션에서는 이동 이벤트가 발생하지 않아야 한다.
- **FR-008**: 리팩토링 전 `OnboardingFeature`가 다루던 모든 수용 시나리오는 리팩토링
  후에도 동일한 결과를 내야 하며, 세션 복원·재시도 관련 시나리오는 `AppRootFeature`
  테스트로, 튜토리얼·약관 동의·로그인·큐레이션 관련 시나리오(정상 흐름, 로그인
  취소·재시도 가능한 실패, 큐레이션 제출 실패, 포지션 선택 화면에서 뒤로 가기에 따른
  로그아웃)는 Onboarding Router·화면 Feature 테스트로 재현되어야 한다.
- **FR-009**: `AppRootFeature`와 각 화면 Feature, Onboarding Router의 상태 전이 및
  이동 추적 동작은 TDD로 작성된 테스트로 검증되어야 하며, 리팩토링 이전에 존재하던
  온보딩 테스트가 다루던 수용 시나리오는 새 구조에서도 동등한 커버리지로 재현되어야
  한다.
- **FR-010**: 시스템과 앱 조립(Composition) 계층의 통합 지점은 이번 리팩토링으로 인해
  최종 사용자에게 보이는 화면 동작이나 앱 시작 흐름이 달라지지 않아야 한다.
- **FR-011**: 이번 리팩토링으로 Router 패턴이 프로젝트에 처음 도입되므로,
  `docs/conventions/tca.md`는 Router-Feature가 하위 Screen Feature를 조합하는 방식과
  화면 이동 이벤트를 다루는 정식 섹션을 포함하도록 갱신되어야 한다.
- **FR-012**: Onboarding Router와 그 하위 Feature, 그리고 `AppRootFeature` 사이에서
  Router 자신보다 긴 생명주기가 필요한 상태를 공유할 때, TCA `@Shared`나 다른 전역 키
  참조, `Binding`, `inout` 기반 저장을 사용하지 않는다. 그런 값은 정본을 가진 계층
  (App Root 자신의 State, 또는 Keychain·서버 같은 Domain/Infrastructure 정본)이
  소유하고, 하위 Feature는 `delegate` Action으로 상위에 알리거나 필요할 때 자신의
  생성자 주입 UseCase로 정본을 다시 조회해야 한다.

### 핵심 엔터티

- **AppRootFeature**: 앱 최상위 Route(`restoring`/`onboarding`/`mainShell`)를 소유하는
  기존 App 패키지 Feature. 이번 리팩토링으로 세션 복원 호출, 회원 프로필 완료 여부
  판단과 Onboarding Router 진입 지점 결정 책임을 추가로 갖는다.
- **화면 이동 이벤트(Screen Transition Event)**: Onboarding Router가 관리하는 화면이
  바뀔 때마다 생성되는 기록. 전환 이전 화면, 전환 이후 화면, 전환을 유발한 액션(또는
  액션을 식별할 수 있는 값)을 포함한다. 여기서 "화면"은 최상위 단위(온보딩
  안내/큐레이션)를 나타내는 연관값 enum이며, 단위 내부에 세부 화면이 있으면(예: 온보딩
  안내의 튜토리얼·약관 동의·로그인) 그 세부 화면을 연관값으로 포함하는 계층형 값이다.
  "완료"는 이 값의 case가 아니다. 프로덕션 로깅·analytics 시스템으로의 전송은
  포함하지 않는다.
- **화면 Feature(Screen Feature)**: 온보딩 안내, 큐레이션(포지션·경력 선택) 각각의
  책임을 갖는 독립된 State·Action·Reducer 단위. Onboarding Router가 조합하는 대상이다.
- **전환 판단 Feature**: Onboarding Router 하위에서 화면 전환 조건(예: 큐레이션 제출
  성공)을 관찰해 "Onboarding Router가 상위(App Root)로 전환해야 하는가"를 판단하고,
  그 결과를 `delegate` Action으로 발생시키는 조건부 Feature. "완료 여부"가 아니라
  "Router 전환 여부"를 판단하는 책임을 갖는다.
- **Onboarding Router Feature**: 화면 Feature들과 전환 판단 Feature를 조합하고, 어떤
  화면이 현재 활성 상태인지 관리하며, 화면 간 전환과 이동 이벤트 생성을 담당하는 상위
  Feature. `AppRootFeature`가 결정한 시작 지점으로 초기화된다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: 리팩토링 이전 `OnboardingFeature`가 통과하던 모든 수용 시나리오에
  대응하는 테스트가 리팩토링 후 `AppRootFeature`·Onboarding Router·화면 Feature 전체를
  합쳐 100% 통과한다.
- **SC-002**: 분리된 화면 Feature 각각을 다른 화면 Feature나 `AppRootFeature`의
  타입을 import하지 않고 독립적으로 컴파일하고 단위 테스트를 실행할 수 있다.
- **SC-003**: `AppRootFeature` 단위 테스트만으로 대표 진입 판단 시나리오(미인증 →
  온보딩 안내부터 시작, 인증+프로필 미완료 → 큐레이션부터 시작, 인증+프로필 완료 →
  MainShell 직행, 복원 가능한 실패 → 재시도) 각각의 결과를 100% 검증할 수 있다.
- **SC-004**: Onboarding Router 단위 테스트만으로 대표 온보딩 여정(정상 완료, 로그인
  실패, 포지션 선택 뒤로 가기) 각각에서 발생한 화면 이동 이벤트의 순서와 전환
  이전·이후 화면을 100% 검증할 수 있다.
- **SC-005**: 리팩토링 후에도 앱을 실행했을 때 최종 사용자가 겪는 화면 순서와 동작에
  차이가 없다(App/Composition 조립 결과 기준 수동 확인 또는 기존 UI 테스트 기준 회귀
  없음).
- **SC-006**: 분리된 각 화면 Feature Reducer가 처리하는 모든 Action case는 자신이
  속한 책임 단위(온보딩 안내 / 큐레이션)의 상태 전이에만 관여하며, 다른 책임 단위의
  상태를 직접 변경하는 case가 하나도 없다(응집도 검증).

## 가정

- 화면 이동 추적은 이번 범위에서 Onboarding Router에 한정된, 테스트 검증 가능한 내부
  이벤트로 한정하며, 실제 analytics·원격 로깅 인프라 연동은 포함하지 않는다.
  `AppRootFeature`의 Route 전환은 이동 이벤트 추적 대상이 아니다. 향후 필요해지면 별도
  기능으로 다룬다.
- Onboarding의 책임 분리 단위는 인증을 제외한 온보딩 안내·큐레이션 2개 화면 Feature와
  이를 조합하는 Router 1개, 그리고 Router 전환 여부를 판단하는 조건부 Feature 1개로
  구성한다. 세션 복원·인증 판단은 `AppRootFeature`가 소유한다.
- Onboarding Router와 그 하위 Feature 사이, 그리고 `AppRootFeature`와의 상태 공유는
  TCA `@Shared`나 다른 전역 키 참조, `Binding`, `inout` 기반 저장을 도입하지 않고
  `delegate` Action과 생성자 주입 UseCase 재조회로 해결한다.
- `AppComposition` 등 기존 통합 지점은 필요한 최소 범위로 갱신하며, 리팩토링의 목적은
  내부 구조 개선이므로 최종 사용자에게 노출되는 화면 흐름·문구·디자인은 변경하지 않는다.
- 리팩토링 대상은 `sources/Projects/Feature/Onboarding/**`(Reducers·Screens·
  Previews·Tests)와 `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
  `sources/Projects/App/GitIt/Screens/AppRootView.swift`이며, 다른 Feature(MainShell,
  ProjectList 등)의 구조 변경은 이번 범위에 포함하지 않는다.
- `AppRootFeature`가 `route`를 `.mainShell`로 정확히 전환하는 것까지만 이번 범위이며,
  `AppRootView`의 `mainShellPlaceholder`(`Text("MainShell")`)를 실제 MainShell 화면으로
  교체하는 작업은 `MainShellFeature`의 화면 구현 자체가 아직 없는 별개의 미완성
  작업이므로 이번 범위에서 제외하고 별도 후속 기능으로 남긴다.
