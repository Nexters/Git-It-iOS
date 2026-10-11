# 기능 명세: Domain UseCase 분해 기준 확정과 통합

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/usecase-consolidation`

**브랜치 상태**: `생성`

**생성일**: 2026-09-16

**상태**: 초안

**입력**: 사용자 설명: "docs/review/usecase-consolidation-requirements.md 의 요구사항을 기능 명세로 정의한다. Domain UseCase의 분해 기준을 하나로 정하고 기준에 맞지 않는 분해를 통합해 Feature·App의 주입 배관을 줄인다. 전제: Domain↔Data 경계 구조 현행 유지, Feature 단일 target 유지."

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - 분해 기준을 문서에서 확인할 수 있다 (우선순위: P1)

Domain에 새 동작을 추가하는 개발자가 그것을 독립 UseCase 타입으로 둘지 기존 계약에
메서드로 더할지를 규칙 문서 하나만 읽고 판단할 수 있다. 지금은 같은 저장소에 대한
같은 성격의 동작이 어떤 것은 독립 타입이고 어떤 것은 다중 메서드 계약이어서 판단 근거가
없다.

**주요 행위자**: Domain 패키지를 수정하는 개발자

**우선순위 이유**: 나머지 모든 통합 판단의 근거다. 기준이 없으면 통합 결과가 다시
흩어지고, 이 명세가 줄인 수치가 다음 기능에서 그대로 되돌아온다.

**독립 테스트**: `docs/package-rules/domain.md`만 읽고 현재 Domain UseCase 각각이
독립 타입으로 남아야 하는지 아닌지를 같은 결론으로 판정할 수 있는지 확인한다.

**수용 시나리오**:

1. **전제** 개발자가 새 조회 동작을 추가하려 한다, **실행** `docs/package-rules/domain.md`의
   분해 기준을 읽는다, **결과** 저장소 호출 외 판단·조율·보상·동시성 제어가 없고 계약을
   하나만 쓰므로 독립 타입으로 두지 않는다고 판정한다.
2. **전제** 개발자가 두 계약을 조합하는 동작을 추가하려 한다, **실행** 같은 기준을 읽는다,
   **결과** 독립 타입으로 둔다고 판정한다.
3. **전제** 남은 UseCase 목록을 본다, **실행** 각 항목을 기준에 대입한다, **결과** 모든
   항목이 기준을 충족하며 충족하지 못하는 항목이 남아 있지 않다.

---

### 시나리오 2 - 같은 저장소를 변경하는 연산의 순서 보장이 계약 안에 있다 (우선순위: P1)

회원 정보 변경 세 연산과 북마크 변경 연산은 지금 각각 독립 UseCase이고, 그들 사이의
직렬화를 위해 UseCase 밖에 별도 직렬화 타입 두 개가 존재한다. 순서 보장 책임이 계약
바깥에 있어서, 새 변경 연산을 추가하는 개발자가 그 타입을 함께 쓰는 것을 잊으면 보장이
조용히 깨진다.

**주요 행위자**: Domain 패키지를 수정하는 개발자

**우선순위 이유**: 동시성 보장이 걸려 있어 통합 전후 동치성을 개별로 확인해야 한다.
범위가 좁고 다른 시나리오와 독립적으로 검증할 수 있다.

**독립 테스트**: 같은 회원 정보를 동시에 두 번 바꾸는 호출과 같은 문제의 북마크를 동시에
두 번 바꾸는 호출이 통합 계약 하나만 써도 순서대로 처리되는지 Domain 테스트로 확인한다.

**수용 시나리오**:

1. **전제** 회원 정보 변경 연산 두 개를 동시에 호출한다, **실행** 통합 계약으로 실행한다,
   **결과** 두 연산이 시작 순서대로 직렬 처리되고 결과가 통합 전과 같다.
2. **전제** 같은 문제의 북마크 변경을 동시에 두 번 호출한다, **실행** 통합 계약으로
   실행한다, **결과** 두 호출이 직렬 처리된다.
3. **전제** 통합이 끝났다, **실행** Domain에서 직렬화 전용 타입을 찾는다, **결과** 찾을 수
   없고 순서 보장은 통합 계약 구현 안에 있다.

---

### 시나리오 3 - 주입 배관이 줄어든다 (우선순위: P2)

상위 Feature와 App이 Domain 의존성을 하나씩 받아 하위로 전달하는 배관이 지금 가장 큰
초기화 인자 목록을 만들고 있다. 화면을 하나 추가하거나 옮길 때 그 배관을 여러 단계에서
같이 고쳐야 한다.

**주요 행위자**: Feature·App 패키지를 수정하는 개발자

**우선순위 이유**: 시나리오 1과 2가 끝나야 통합 대상이 확정되므로 뒤에 온다. 개발자가
체감하는 비용은 여기서 가장 크게 줄어든다.

**독립 테스트**: 가장 넓은 Router Feature의 Domain 의존성 파라미터 개수와 조립이 공개하는
Domain 의존성 개수를 세어 기준 이하인지 확인한다.

**수용 시나리오**:

1. **전제** 통합이 끝났다, **실행** 가장 넓은 Router Feature의 초기화 인자를 센다,
   **결과** Domain 의존성 파라미터가 5개 이하다.
2. **전제** 통합이 끝났다, **실행** 앱 조립이 공개하는 Domain 의존성을 센다, **결과**
   12개 이하다.
3. **전제** 하위 Feature가 통합 계약의 일부만 쓴다, **실행** 상위가 하위에 전달하는 값을
   본다, **결과** 하위가 쓰는 최소 범위만 전달하며 통합 계약을 통째로 넘겨 기존 제약을
   우회하지 않는다.

---

### 시나리오 4 - 통합으로 사라진 타입의 흔적이 남지 않는다 (우선순위: P3)

**주요 행위자**: Domain 패키지를 읽는 개발자

**우선순위 이유**: 앞 세 시나리오의 결과를 정리하는 단계다. 기능 동작에는 영향이 없지만
남은 빈 폴더와 파일이 다음 개발자에게 잘못된 기준을 암시한다.

**독립 테스트**: 통합으로 사라진 UseCase 이름으로 저장소를 검색해 프로토콜 파일, 구현
파일, 폴더가 모두 없는지 확인한다.

**수용 시나리오**:

1. **전제** 통합이 끝났다, **실행** 사라진 UseCase 이름을 검색한다, **결과** 프로덕션
   소스에 결과가 없다.
2. **전제** 통합이 끝났다, **실행** `sources/Projects/Domain/*/UseCases/` 아래를 본다,
   **결과** 남은 폴더가 모두 실제 타입을 담고 있고 빈 폴더가 없다.

---

### 예외·경계 사례

- 통합 계약 하나가 여러 화면에 걸쳐 쓰일 때, 한 화면만 쓰는 하위 Feature에 계약 전체를
  넘기면 Feature 패키지 규칙의 최소 전달 제약을 우회하게 된다. 이 경우 어떻게 전달하는가?
- 다중 메서드 계약(`PolicyConsentUseCase` 5개 메서드, `RequestGenerationReminderUseCase`
  3개 메서드)은 이미 "1 UseCase = 1 동작"과 다르다. 기준을 확정할 때 이들을 위반으로
  볼 것인가, 능력 단위 계약의 선례로 볼 것인가?
- 통합 전 UseCase별 테스트가 보장하던 동작 중 통합 계약 테스트로 옮길 자리가 없는 것이
  나오면 어떻게 처리하는가?
- 명세 032가 추가한 `ResolveSessionAvailability`, `RegisterCurrentDevice`,
  `ScheduleGenerationReminder`는 근거 문서 작성 시점에 없었다. 이들도 같은 기준으로
  판정하는가?

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: `docs/package-rules/domain.md`는 UseCase를 독립 타입으로 둘 기준을 검증
  가능한 문장으로 명시해야 한다. 기준은 (가) 저장소 호출 외에 판단·조율·보상·동시성 제어
  중 하나 이상을 수행하거나 (나) 둘 이상의 계약을 조합하는 것이다.
- **FR-002**: FR-001의 기준을 충족하지 못하는 UseCase는 독립 타입으로 두지 않고 도메인
  능력 단위 계약으로 통합해야 한다. 통합 계약은 Domain 모듈당 1개를 기본으로 한다.
- **FR-003**: 통합 계약의 이름은 [네이밍 컨벤션](../../docs/conventions/naming.md)을 따르며
  일괄 접두어·접미어를 적용하지 않아야 한다.
- **FR-004**: FR-001의 기준을 충족하는 UseCase는 독립 타입으로 유지해야 한다. 조율·보상
  (`SignIn`, `SignOut`, `RestoreSession`, `DeleteMemberAccount`), 동시성(`RefreshSession`),
  사전 검증(`FetchExternalRepository`, `SubmitChoiceAnswer`, `SubmitEssayAnswer`), 조건부
  효과(`FetchLearningProjects`, `RequestGenerationReminder`), 상태 수명
  (`CreateLearningProject`, `PolicyConsent`, `TrackGeneration`), 그리고 명세 032가 추가한
  `ResolveSessionAvailability`, `RegisterCurrentDevice`, `ScheduleGenerationReminder`가
  여기에 해당하는지를 기준에 대입해 판정하고 결과를 기록해야 한다.
- **FR-005**: 같은 저장소를 변경하는 연산은 하나의 계약으로 묶고 순서 보장을 그 계약 구현
  내부에서 제공해야 한다. 회원 정보 변경 세 연산(`UpdateMemberPosition`,
  `UpdateMemberCareerLevel`, `CompleteCuration`)을 하나로 묶고, 북마크 변경
  (`SetQuestionBookmark`)의 직렬화를 구현 내부로 옮긴다.
- **FR-006**: 통합 후 `MemberMutationSerializer`와 `QuestionMutationSerializer`는 Domain
  프로덕션 소스에 존재하지 않아야 한다.
- **FR-007**: 통합 전 각 UseCase 테스트가 보장하던 동작은 통합 계약 테스트로 모두 이관해야
  한다. 이관할 자리가 없는 보장은 제거 근거를 기록해야 한다.
- **FR-008**: 가장 넓은 Router Feature(`MainShellRouterFeature`)가 받는 Domain 의존성
  파라미터는 11개 이하여야 한다. 이 값은 FR-001의 기준을 적용했을 때 도달 가능한 실측값이다
  (아래 "수치 목표 조정" 참조).
- **FR-009**: 앱 조립(`AppComposition`)이 공개하는 Domain 의존성은 19개 이하여야 한다.
  이 값도 같은 근거로 조정한 실측값이다.
- **FR-010**: 상위 Feature가 하위 Feature에 전달할 때 하위가 사용하는 최소 범위만 전달한다는
  [Feature 패키지 규칙](../../docs/package-rules/feature.md)의 제약을 유지해야 한다. 통합
  계약을 하위에 통째로 넘기는 것이 이 제약을 우회하는 수단이 되어서는 안 된다.
- **FR-011**: 통합으로 사라지는 UseCase의 프로토콜 파일, 구현 파일, 폴더를 남기지 않아야
  한다.
- **FR-012**: 남는 UseCase는 [디렉터리·파일 컨벤션](../../docs/conventions/directory-file.md)의
  형태 1뎁스·관심사 2뎁스 규칙을 계속 따라야 한다.
- **FR-013**: 저장소 계약(`Domain/*/Contracts/**`)과 Domain↔Data Adapter의 구조는 바뀌지
  않아야 한다.
- **FR-014**: 통합 전후로 사용자에게 보이는 동작은 바뀌지 않아야 한다. 화면 구성, 상태
  구조, 네트워크 호출 순서와 오류 표현이 같아야 한다.

### 핵심 엔터티

- **분해 기준**: UseCase를 독립 타입으로 둘지 판정하는 규칙. 판단·조율·보상·동시성 제어
  수행 여부와 조합하는 계약 수를 입력으로 받아 참/거짓을 낸다.
- **능력 단위 계약**: 기준을 충족하지 못하는 동작들을 모은 Domain 모듈별 계약. 저장소
  계약을 한 번 더 복제하지 않고 Feature가 쓰는 동작만 노출한다.
- **변경 연산 계약**: 같은 저장소를 변경하는 연산과 그 사이의 순서 보장을 함께 담는 계약.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: `docs/package-rules/domain.md`를 읽은 개발자가 현재 Domain UseCase 28개
  각각에 대해 독립 유지 여부를 같은 결론으로 판정할 수 있다.
- **SC-002**: `find sources/Projects/Domain -path "*UseCases*" -name "*.swift" -not -path "*/Tests/*"`
  결과가 60개에서 46개 이하로 줄어든다.
- **SC-003**: Domain UseCase 프로토콜 수가 28개에서 22개 이하로 줄어든다.
- **SC-004**: `MainShellRouterFeature.init`의 Domain 의존성 파라미터가 14개에서 11개
  이하로 줄어든다.
- **SC-005**: `AppComposition`이 공개하는 Domain 의존성이 25개에서 19개 이하로 줄어든다.
- **SC-006**: `MemberMutationSerializer`와 `QuestionMutationSerializer`를 프로덕션 소스에서
  찾을 수 없다.
- **SC-007**: 회원 정보 변경의 동시 호출 순서 보장 테스트가 통합 계약 기준으로 통과한다.
- **SC-008**: 북마크 변경의 동시 호출 순서 보장 테스트가 통합 계약 기준으로 통과한다.
- **SC-009**: 통합 전 UseCase별 테스트가 보장하던 항목이 통합 계약 테스트로 모두 이관되었고,
  이관처 또는 제거 근거가 기록된 항목 수가 이관 대상 수와 같다.
- **SC-010**: Domain 테스트의 총 검증 항목 수가 통합 전보다 줄지 않는다.
- **SC-011**: `build`와 `compile`이 전체 scheme에서 성공하고, `test`의 scheme별 성공·실패
  목록이 이 명세 시작 전과 같다.

## 수치 목표 조정

근거 문서 [UseCase 통합 요구사항](../../docs/review/usecase-consolidation-requirements.md)의
FR-5는 `MainShellRouterFeature` 5개 이하, `AppComposition` 12개 이하를 요구하고 수용 기준은
UseCase 파일 수 절반 이하를 요구한다. 같은 문서 FR-3이 독립 유지 대상으로 지정한 목록을
그대로 지키면 이 수치에 닿을 수 없다.

현재 소스 기준 산술은 다음과 같다.

| 항목 | 현재 | 기준 적용 후 도달 가능 | 근거 문서 목표 |
| --- | --- | --- | --- |
| UseCase 프로토콜 | 28 | 22 | 14 (절반) |
| 프로덕션 UseCase 파일 | 60 | 46 | 30 (절반) |
| `MainShellRouterFeature` Domain 의존성 | 14 | 11 | 5 |
| `AppComposition` Domain 의존성 | 25 | 19 | 12 |

FR-001의 기준을 충족하지 못하는 것은 순수 위임 7개(`VerifyAccessToken`,
`DeleteLearningProject`, `FetchBookmarkedQuestions`, `FetchLearningProjectDetail`,
`FetchLearningSet`, `FetchMemberProfile`, `RegisterMemberDevice`)와 회원 정보 변경 3개다.
나머지는 판단·조율·보상·동시성 제어를 수행하거나 둘 이상의 계약을 조합한다. 근거 문서의
수치에 닿으려면 그 나머지까지 묶어야 하는데, 그것은 FR-001의 기준을 버리는 일이다.

**결정**: 분해 기준을 우선하고 수치 목표를 실측 도달 가능값으로 조정한다. 근거 문서의
원래 수치와의 차이를 이 절에 남긴다. 주입 표면을 더 줄이려면 Feature가 받는 단위 자체를
재정의해야 하며, 그것은 이 명세의 범위 밖이다.

## 가정

- 근거 문서 [UseCase 통합 요구사항](../../docs/review/usecase-consolidation-requirements.md)의
  기준 시점은 commit `bee2388`이고 UseCase 26개를 전제한다. 그 뒤 명세 030·031·032가
  적용되어 현재는 프로토콜 28개, 프로덕션 파일 60개다. 이 명세는 현재 소스에서 직접 센
  값을 기준으로 삼는다.
- 근거 문서가 대상으로 지목한 `ObserveGenerationOutcomes`, `TrackGenerationProgress`,
  `AuthenticationOutcomes`는 명세 030에서 이미 정리되어 존재하지 않는다. 그만큼 대상이
  줄었고, 명세 032가 추가한 세 UseCase가 새 판정 대상이 된다.
- 근거 문서 FR-2가 예시로 든 통합 대상 중 `DomainAuthentication`의 "토큰 검증"은
  `VerifyAccessToken` 하나이며, `VerifyAuthorization`은 두 계약을 조합하므로 기준을
  충족해 독립 유지 대상이다.
- Domain↔Data 경계 구조는 현행을 유지한다. 저장소 계약과 Adapter는 이 명세의 범위 밖이다.
- Feature는 단일 target을 유지한다. Feature target 분할은 이 명세의 범위 밖이다.
- Domain 모델 타입과 오류 타입은 바꾸지 않는다.
- Feature의 화면 구성과 State 구조는 바꾸지 않는다. 바뀌는 것은 초기화 인자와 전달 경로다.
- 근거 문서의 수치 목표는 위 "수치 목표 조정"의 결정에 따라 실측 도달 가능값으로 바꿔
  적용한다.
- `AppTests`의 `AppRootFeature root 전환` suite와 `Feature` scheme의
  `AppEntryFeatureTests` 계열 실패는 이 명세 시작 전부터 존재하는 별개 문제이며, 이
  명세는 그 목록을 늘리지 않는 것을 판정 기준으로 삼는다.
