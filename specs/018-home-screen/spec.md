# 기능 명세: 홈 화면과 MainShell 4탭 통합

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/home-screen`

**브랜치 상태**: `생성`

**생성일**: 2026-08-29

**상태**: 초안

**입력**: 사용자 설명: "`feature/onboarding-login-tutorial-app-integration`을 기준으로 인증과 온보딩을 완료한 사용자의 MainShell에 Home을 기본 탭으로 추가하고, Figma의 프로젝트 있음·없음 상태를 기존 LearningProject 및 Member Domain 계약으로 구현할 수 있는 명세를 작성한다."

## 명확화

### 세션 2026-08-29

- 질문: 이번 기능에서 Project·Saved·My의 실제 Screen도 생성해 MainShell에 연결하는가? → 답변: Home만 실제 Screen으로 구현하고 Project·Saved·My는 현재 탭 제목 placeholder를 유지한다.
- 질문: 프로젝트가 3개를 초과할 때 Home 카드 영역은 어떻게 표시하는가? → 답변: 조회된 모든 프로젝트 카드를 좌우로 스크롤할 수 있게 표시하고, 각 카드의 기울기는 현재 화면의 스크롤 좌표에 따라 정한다.
- 질문: `지금 불러오기`는 이번 기능에서 실제 프로젝트 등록 Screen으로 이동해야 하는가? → 답변: Home은 등록 intent만 출력하고 실제 `ProjectRegistration` Screen과 App navigation 연결은 후속 기능으로 이관한다.
- 질문: 프로젝트 카드의 학습 계속하기는 이번 기능에서 실제 학습 화면으로 이동해야 하는가? → 답변: Home은 `projectID`, `nextSetID`, `nextQuestionID`를 담은 학습 intent만 출력하고 실제 ProjectDetail·Quiz Screen과 App navigation은 후속 기능으로 이관한다.
- 질문: `LearningProjectPage.hasNext == true`일 때 Home이 추가 페이지를 조회해야 하는가? → 답변: 추가 페이지를 조회하지 않고 현재 `FetchLearningProjectsUseCase`가 반환한 `items` 전체만 표시하며, 전체 프로젝트 탐색은 후속 Project 화면으로 이관한다.
- 질문: Home의 프로필과 프로젝트 데이터는 언제 다시 조회하는가? → 답변: MainShell에서 Home이 최초 표시될 때 각각 한 번 조회하고 다른 탭에서 돌아올 때는 다시 조회하지 않는다. 프로필 실패는 명시적으로 재시도할 수 있고, 프로젝트 실패에는 전용 재시도를 제공하지 않는다.

### 세션 2026-08-30

- 질문: 사용자 제공 참조 영상에 따른 카드 스크롤 기준은 무엇인가? → 답변: 초기 진입 상태의 카드 중심 좌표를 선행 앵커 `P0`와 후속 앵커 `P1`, `P2`로 고정하고 정지 포즈를 각각 `0°`, `+16°`, `-12°`로 둔다. 드래그·감속 중에는 실제 데이터 인덱스가 아니라 현재 중심 좌표가 통과하는 인접 앵커의 각도를 연속 보간하며, 감속이 끝나면 가장 가까운 카드를 `P0`에 정렬한다.
- 질문: 카드 색상 variant와 위치 기반 회전은 어떤 관계인가? → 답변: 색상 variant는 Domain 조회 순서의 `index % 3`으로 정해 해당 카드에 유지하고, 회전만 현재 카드 중심 좌표와 `P0`·`P1`·`P2` 앵커를 기준으로 계산한다.
- 질문: 프로젝트 카드에서 실제 탭 동작을 갖는 영역은 어디인가? → 답변: 재생 버튼은 학습 계속하기 intent를, 카드 본문은 `projectID`를 담은 ProjectDetail intent를 각각 출력한다. 수평 드래그가 인식되면 스크롤을 우선하고 두 탭 intent는 모두 출력하지 않는다.
- 질문: `MemberProfile.position` 또는 `careerLevel`이 없을 때 프로필 보조 문구는 어떻게 표시하는가? → 답변: 존재하는 값만 표시하고 둘 다 없으면 이름만 표시하며, 누락 값을 기본값이나 `미설정` 문구로 대체하지 않는다.
- 질문: 프로필 조회만 실패했을 때 오류와 재시도는 어디에 표시하는가? → 답변: 프로필 헤더 영역 안에 오류 안내와 프로필 전용 재시도를 표시하고 프로젝트 영역은 현재 상태를 그대로 유지한다.
- 질문: 프로젝트 조회만 실패했을 때 오류와 재시도는 어디에 표시하는가? → 답변: 프로젝트 없음 상태와 동일한 illustration·문구·CTA를 표시하고 프로젝트 오류 안내와 전용 재시도는 제공하지 않는다. 프로필 영역은 현재 상태를 유지한다.
- 질문: 최초 조회 후 Home에 일반 새로고침 진입점을 두는가? → 답변: 두지 않는다. 이번 기능의 후속 조회는 실패한 프로필의 명시적 재시도로만 제한한다.
- 질문: Dynamic Type은 어느 크기까지 검증하는가? → 답변: iOS 26 `DynamicTypeSize` 전체 12단계인 `xSmall`~`accessibility5`를 검증한다.
- 질문: Figma 비교에서 확인된 차이를 어떻게 완료 판정하는가? → 답변: 수정하지 않은 차이는 사용자의 명시적 승인과 검증 결과·PR의 차이·근거·영향·미검증 범위 기록이 모두 있을 때만 승인 예외로 분류한다.
- 질문: 카드 접촉을 수평 드래그로 판정하는 기준은 무엇인가? → 답변: 임의 거리 임계값을 추가하지 않고 SwiftUI `ScrollView`의 플랫폼 scroll gesture 인식 결과를 사용하며, scroll로 인식된 접촉에서는 tap intent를 출력하지 않는다.

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - MainShell이 Home부터 시작하고 네 탭을 전환한다 (우선순위: P1)

인증과 온보딩을 완료한 사용자는 MainShell에 진입하면 실제 Home 화면을 먼저 보고, 하단의 홈·프로젝트·저장·마이 탭을 전환한다. 이번 기능에서 상세 화면을 구현하지 않는 프로젝트·저장·마이 탭은 현재 탭 제목 placeholder를 유지한다.

**주요 행위자**: 인증과 온보딩을 완료한 사용자

**우선순위 이유**: Home이 제품의 새 기본 진입점이며 기존 세 탭을 보존한 4탭 구조가 나머지 Home 상호작용의 전제다.

**독립 테스트**: MainShell의 초기 상태와 탭 선택 Action을 검증하고, Home에서는 scoped `HomeFeature` 화면이, 나머지 세 탭에서는 해당 탭 제목 placeholder가 렌더링되는지 확인한다.

**수용 시나리오**:

1. **전제** 사용자가 인증과 온보딩을 완료했다, **실행** MainShell에 처음 진입한다, **결과** Home 탭이 선택되고 Home 화면이 표시된다.
2. **전제** MainShell이 표시된다, **실행** 사용자가 프로젝트·저장·마이 탭을 차례로 선택한다, **결과** 선택한 탭의 기존 제목 placeholder가 표시되고 `ProjectListFeature`·`SavedFeature`·`SettingsFeature` child 상태는 MainShell이 계속 소유한다.
3. **전제** 사용자가 탭을 전환했다, **실행** 다시 Home 탭을 선택한다, **결과** Home의 현재 조회 상태가 불필요하게 초기화되지 않은 채 Home 화면으로 돌아온다.
4. **전제** MainShell 화면을 렌더링한다, **실행** Home 탭을 확인한다, **결과** `홈` 제목 placeholder 대신 실제 Home 화면이 표시된다.
5. **전제** Home의 최초 조회가 완료되었다, **실행** 다른 탭을 선택한 뒤 Home으로 돌아온다, **결과** 프로필과 프로젝트를 자동으로 다시 조회하지 않고 기존 상태를 유지한다.

---

### 시나리오 2 - 등록된 학습 프로젝트를 Home에서 확인하고 이어서 학습한다 (우선순위: P1)

등록된 프로젝트가 있는 사용자는 자신의 프로필과 실제 학습 프로젝트 요약을 Home에서 확인하고, 프로젝트 카드의 학습 계속하기 동작으로 다음 학습 지점을 상위 흐름에 요청한다. 실제 학습 화면 이동은 이번 기능 범위가 아니다.

**주요 행위자**: 한 개 이상의 학습 프로젝트를 등록한 사용자

**우선순위 이유**: 진행 중인 학습으로 빠르게 복귀하는 것이 프로젝트가 있는 Home의 핵심 가치다.

**독립 테스트**: 프로필과 한 개 이상의 `LearningProjectSummary`를 반환하는 Test Double을 주입해 카드 표시 값, 진행률, 학습 요청 payload를 reducer 및 화면 검증으로 확인한다.

**수용 시나리오**:

1. **전제** 프로필과 학습 프로젝트 조회가 성공하고 프로젝트가 한 개 이상이다, **실행** Home을 확인한다, **결과** 사용자 이름·분야/경력 정보와 프로젝트 카드가 프로젝트 있음 Figma node `1465:19015`의 정보 구조에 맞게 표시된다.
2. **전제** `LearningProjectSummary`가 제공된다, **실행** 프로젝트 카드를 확인한다, **결과** `repositoryName`, `techStack`, `currentSetLabel`, `currentSetTitle`, `overallProgressPercent`가 표시되고 Figma의 샘플 프로젝트 문구는 데이터 대신 사용되지 않는다.
3. **전제** 카드에 `projectID`, `nextSetID`, `nextQuestionID`가 모두 있다, **실행** 사용자가 학습 계속하기를 선택한다, **결과** 세 ID가 원문 그대로 포함된 학습 intent가 상위 흐름에 정확히 한 번 전달되고 이번 기능에서는 실제 학습 화면으로 이동하지 않는다.
4. **전제** 다음 학습 위치에 필요한 ID 중 하나가 없다, **실행** 카드의 학습 계속하기 표현을 확인하거나 선택한다, **결과** 앱은 문자열에서 ID를 재구성하거나 임의 ID를 만들지 않고 실행 불가능한 상태를 사용자와 보조 기술에 일관되게 알린다.
5. **전제** 프로젝트가 화면에 동시에 표시 가능한 수보다 많다, **실행** 사용자가 카드 영역을 좌우로 드래그하고 손을 뗀다, **결과** 조회된 모든 프로젝트 카드에 Domain 순서대로 접근할 수 있고 각 카드의 기울기는 현재 중심 좌표가 통과하는 초기 앵커 `P0(0°)`, `P1(+16°)`, `P2(-12°)` 사이에서 연속으로 변하며, 감속 종료 후 가장 가까운 카드가 `P0`에 정렬된다.
6. **전제** 특정 프로젝트 카드가 스크롤 중 여러 앵커를 통과한다, **실행** 카드의 시각 상태를 관찰한다, **결과** Domain 조회 순서의 `index % 3`으로 선택된 색상 variant는 바뀌지 않고 회전만 현재 위치에 맞게 변한다.
7. **전제** 프로젝트 카드가 표시된다, **실행** 사용자가 재생 버튼 밖의 카드 본문을 탭한다, **결과** 해당 카드의 `projectID`를 담은 ProjectDetail intent가 상위 흐름에 정확히 한 번 전달되고 이번 기능에서는 실제 상세 화면으로 이동하지 않는다.
8. **전제** 카드 본문 또는 재생 버튼에서 시작한 접촉이 수평 드래그로 인식된다, **실행** 사용자가 손을 뗀다, **결과** 카드 목록만 스크롤되고 ProjectDetail intent와 학습 intent는 모두 출력되지 않는다.

---

### 시나리오 3 - 프로젝트 조회 결과에 맞는 로딩·빈 상태·실패 표현을 제공한다 (우선순위: P1)

사용자는 Home 진입 직후 빈 상태를 잘못 보지 않으며, 조회 성공 결과가 0개이거나 프로젝트 조회가 실패하면 동일한 등록 프로젝트 없음 안내와 등록 CTA를 확인한다. 프로젝트 실패에는 별도 오류 안내와 재시도를 제공하지 않는다.

**주요 행위자**: Home에 진입한 사용자

**우선순위 이유**: 초기 빈 배열을 실제 빈 결과로 오인하면 사용자에게 잘못된 상태와 불필요한 등록 CTA를 보여 준다.

**독립 테스트**: `idle`, `loading`, 성공 0개, 성공 1개 이상, 실패 상태를 각각 주입해 표시 분기를 검증하고, 성공 0개와 실패의 프로젝트 영역 렌더가 동일한지 확인한다.

**수용 시나리오**:

1. **전제** 프로젝트 조회가 시작되지 않았거나 진행 중이다, **실행** Home을 표시한다, **결과** `아직 등록된 프로젝트가 없어요.` 문구와 빈 상태 illustration은 노출되지 않고 로딩 중임을 알 수 있다.
2. **전제** 프로젝트 조회가 성공하고 결과가 0개다, **실행** Home을 확인한다, **결과** 프로젝트 없음 Figma node `1542:19610`의 illustration과 `아직 등록된 프로젝트가 없어요.` 문구가 표시된다.
3. **전제** 프로젝트 조회가 실패했다, **실행** Home을 확인한다, **결과** 성공 0개와 동일한 illustration·`아직 등록된 프로젝트가 없어요.` 문구·프로젝트 등록 CTA가 표시되고 프로젝트 오류 안내와 전용 재시도는 표시되지 않는다.
4. **전제** 프로젝트 조회가 실패하고 프로필 조회는 성공했다, **실행** Home을 확인한다, **결과** 성공한 프로필 헤더는 유지되고 프로젝트 영역만 프로젝트 없음 상태와 동일하게 표시된다.
5. **전제** 프로필 조회만 실패하고 프로젝트 조회는 성공했다, **실행** Home을 확인한다, **결과** 프로젝트의 성공·빈 상태 판정과 콘텐츠는 유지되고 프로필 헤더 영역 안에 오류 안내와 프로필 전용 재시도가 표시된다.
6. **전제** 프로필 조회가 성공했지만 `position` 또는 `careerLevel`이 없다, **실행** 프로필 헤더를 확인한다, **결과** 존재하는 값만 보조 문구에 표시되고 둘 다 없으면 이름만 표시되며 기본값이나 `미설정` 문구는 나타나지 않는다.
7. **전제** 프로필 헤더가 오류 상태다, **실행** 사용자가 프로필 재시도를 한 번 선택한다, **결과** 프로필 조회만 정확히 한 번 실행되고 프로젝트 조회와 현재 프로젝트 콘텐츠는 변경되지 않는다.

---

### 시나리오 4 - 기존 프로젝트 흐름을 요청한다 (우선순위: P1)

사용자는 프로젝트가 있든 없든 Home에서 기존 등록 흐름을 요청하고, `전체 보기`로 MainShell의 프로젝트 탭을 선택할 수 있다. 실제 등록 Screen과 App navigation 연결 및 프로젝트 탭의 실제 목록 Screen은 이번 기능 범위가 아니다.

**주요 행위자**: 학습 프로젝트를 등록하거나 전체 목록을 보려는 사용자

**우선순위 이유**: Home은 새 프로젝트 등록과 향후 전체 프로젝트 탐색의 일관된 진입점을 제공해야 하며 같은 책임을 중복 구현해서는 안 된다.

**독립 테스트**: 빈 상태와 프로젝트 있음 상태에서 CTA Action을 보내 MainShell 및 App 경계로 전달되는 navigation intent와 선택 탭을 검증한다.

**수용 시나리오**:

1. **전제** 프로젝트가 0개다, **실행** `지금 불러오기`를 선택한다, **결과** 기존 `ProjectRegistrationFeature`가 소유하는 프로젝트 등록 흐름을 열기 위한 intent가 상위에 정확히 한 번 전달되고 이번 기능에서는 실제 Screen으로 이동하지 않는다.
2. **전제** 프로젝트가 한 개 이상이다, **실행** `지금 불러오기`를 선택한다, **결과** 빈 상태와 동일한 프로젝트 등록 intent가 상위에 정확히 한 번 전달되고 이번 기능에서는 실제 Screen으로 이동하지 않는다.
3. **전제** Home이 표시된다, **실행** `전체 보기`를 선택한다, **결과** MainShell의 선택 탭이 프로젝트로 변경되고 이번 기능에서는 기존 `프로젝트` 제목 placeholder가 표시된다.
4. **전제** 사용자가 Home에서 등록 흐름을 요청한다, **실행** 이동을 처리한다, **결과** Home 전용 등록 API·Domain 모델·프로젝트 목록 화면은 새로 생성되지 않는다.

---

### 시나리오 5 - Figma 근거와 접근성을 갖춘 Home을 검증한다 (우선순위: P2)

개발자와 리뷰어는 프로젝트 있음·없음 Home 상태를 지정된 Figma node와 비교하고, 사용자는 Dynamic Type과 VoiceOver에서도 주요 정보와 동작을 이해할 수 있다.

**주요 행위자**: 앱 사용자, 개발자, 리뷰어

**우선순위 이유**: 시각 정합성뿐 아니라 카드 겹침과 작은 아이콘이 정보 손실이나 조작 불가로 이어지지 않아야 한다.

**독립 테스트**: 두 상태의 deterministic Preview 또는 동등한 렌더를 `360×800` 기준 Figma node와 비교하고, 접근성 식별자·라벨·선택 상태·터치 영역과 `xSmall`~`accessibility5` 전체 Dynamic Type을 검사한다. 차이가 남으면 수정하거나 사용자 승인과 검증 기록을 남긴다.

**수용 시나리오**:

1. **전제** Home의 프로젝트 있음·없음 상태를 검토한다, **실행** 대응 Preview를 연다, **결과** 각각 node `1465:19015`, `1542:19610`을 식별할 수 있고 동일 상태끼리 비교할 수 있다.
2. **전제** 카드가 회전하거나 겹쳐 보이는 디자인이다, **실행** 카드 영역을 좌우로 스크롤한다, **결과** 카드가 초기 좌표 앵커와 현재 중심 좌표에 따라 끊김 없이 기울어지고 감속 후 선행 앵커에 정렬되며 자동 순환·사용자 재정렬은 발생하지 않는다.
3. **전제** VoiceOver를 사용한다, **실행** 프로필, CTA, 전체 보기, 프로젝트 카드와 네 탭을 탐색한다, **결과** 각 요소의 의미·동작·선택 상태를 중복 없이 알 수 있다.
4. **전제** 사용자가 iOS 26 `DynamicTypeSize` 중 `xSmall`, `small`, `medium`, `large`, `xLarge`, `xxLarge`, `xxxLarge`, `accessibility1`, `accessibility2`, `accessibility3`, `accessibility4`, `accessibility5` 중 하나를 사용한다, **실행** Home을 확인한다, **결과** 핵심 CTA와 프로젝트 식별 정보가 잘리거나 서로 가리지 않는다.

### 예외·경계 사례

- 프로젝트 조회 요청이 중복 시작되거나 순서가 뒤바뀌어 완료되면 최신 request identity의 결과만 반영한다.
- 프로필 조회와 프로젝트 조회 중 하나만 실패해도 다른 조회의 성공 결과를 폐기하지 않는다. 프로젝트 실패는 의도적으로 프로젝트 없음 상태와 동일하게 표시하되 내부 조회 상태는 실패로 유지한다.
- 프로필 조회 실패는 프로필 헤더 내부의 오류 안내와 전용 재시도로 표현하고 프로젝트 조회를 자동으로 다시 시작하거나 프로젝트 콘텐츠를 가리지 않아야 한다.
- 프로젝트 조회 실패는 성공 0개와 동일한 illustration·문구·프로젝트 등록 CTA로 표현하고 프로젝트 오류 안내와 전용 재시도를 제공하지 않아야 한다.
- `MemberProfile.position` 또는 `careerLevel`이 없으면 존재하는 값만 표시하고, 둘 다 없으면 이름만 표시하며 누락 값을 기본값이나 `미설정` 문구로 대체하지 않는다.
- `MemberProfile`에는 프로필 이미지 URL이 없으므로 원격 이미지 요청이나 새 Avatar 계약을 만들지 않고 앱 기본 프로필 자산을 사용한다.
- `overallProgressPercent`가 표시 범위를 벗어나면 화면 표현은 안전한 범위로 제한하되 Domain 원본을 덮어쓰지 않는다.
- `techStack`이 비어 있거나 항목이 많고, 프로젝트·세트 제목이 길어도 카드 간 상호작용과 핵심 식별 정보가 손상되지 않아야 한다.
- 현재 `FetchLearningProjectsUseCase`가 반환한 프로젝트 수가 화면에 동시에 표시 가능한 카드 수보다 많으면 Home의 좌우 스크롤 카드 영역에서 반환된 모든 항목에 접근할 수 있어야 하며, 스크롤 위치가 경계에 도달하면 더 이상 이동하지 않아야 한다.
- `LearningProjectPage.hasNext == true`여도 Home은 추가 페이지를 조회하지 않고 현재 응답의 `items`만 표시하며, 전체 프로젝트 탐색은 후속 Project 화면의 책임으로 남긴다.
- 초기 진입 시 선행 카드의 중심 좌표를 `P0`, 뒤따르는 두 카드의 중심 좌표를 순서대로 `P1`, `P2`로 기록하며 화면 크기나 Dynamic Type 변화로 레이아웃이 다시 결정되면 현재 레이아웃에서 이 앵커를 다시 산출해야 한다.
- `P0`, `P1`, `P2`는 `LearningProjectSummary`의 배열 인덱스나 고정 프로젝트 식별자가 아니라 현재 화면의 시각 위치 기준이다.
- 드래그·감속 중 카드가 `P0 ↔ P1` 또는 `P1 ↔ P2` 구간을 이동하면 각 구간의 목표 각도 `0° ↔ +16°`, `+16° ↔ -12°` 사이를 현재 중심 좌표 비율로 연속 보간하고, 화면 밖 카드의 기울기는 사용자에게 다시 보이기 전까지 검증 범위에서 제외한다.
- 프로젝트가 한 개뿐이면 해당 카드를 `P0`과 `0°`에 정렬하고, 두 개이면 `P0(0°)`, `P1(+16°)` 포즈만 사용한다.
- 카드 색상 variant는 현재 응답의 Domain 조회 순서 `index % 3`으로 결정하고 스크롤 중 해당 카드에 유지하며, 정렬 앵커나 현재 가시 순서로 다시 계산하지 않아야 한다.
- 카드 본문이나 재생 버튼에서 시작한 상호작용은 임의 거리 임계값 없이 SwiftUI `ScrollView`의 플랫폼 scroll gesture 인식 결과를 따른다. scroll로 인식되면 스크롤이 탭보다 우선하며 해당 접촉에서 ProjectDetail intent와 학습 intent를 함께 또는 뒤늦게 출력하지 않아야 한다.
- 다음 학습 ID가 없으면 표시 문자열, 배열 순서 또는 진행률로 ID를 추론하지 않는다.
- 로그아웃·계정 삭제로 MainShell 상태가 초기화되면 다음 인증 완료 진입도 Home 탭에서 시작해야 한다.
- 기존 authentication·onboarding·splash의 destination 판단은 이 기능으로 변경하지 않는다.

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: MainShell은 `home`, `projects`, `saved`, `settings`의 네 탭을 이 순서로 제공하고 사용자에게 각각 `홈`, `프로젝트`, `저장`, `마이`로 표시해야 한다.
- **FR-002**: MainShell의 새 상태와 로그아웃·계정 삭제 후 초기화된 상태는 Home을 기본 선택 탭으로 사용해야 한다.
- **FR-003**: MainShell은 Home을 독립적인 child Feature로 소유하고 기존 `ProjectListFeature`, `SavedFeature`, `SettingsFeature`와 함께 각 child 상태와 Action을 명시적으로 조합해야 한다.
- **FR-004**: MainShell 화면은 Home 탭에서 `홈` 제목 placeholder 대신 scoped `HomeFeature` 화면을 렌더링하고, 프로젝트·저장·마이 탭에서는 현재 탭 제목 placeholder를 유지해야 한다.
- **FR-005**: Home은 initializer로 주입된 `FetchLearningProjectsUseCase`와 `FetchMemberProfileUseCase`를 통해 프로젝트와 프로필을 조회하고, View에서 Use Case를 직접 호출하지 않아야 한다.
- **FR-006**: Home production 코드는 `@Dependency`, dependency key, Service Locator 또는 전역 mutable container를 사용해 production dependency를 조회하지 않아야 한다.
- **FR-007**: Home은 프로젝트 조회의 시작 전, 진행 중, 성공, 실패를 배타적인 내부 상태로 구분하고 성공 상태에 응답의 프로젝트 목록을 보존해야 한다.
- **FR-008**: Home은 프로젝트 조회 성공 목록이 0개이거나 내부 상태가 실패일 때만 Figma node `1542:19610`에 대응하는 빈 상태 illustration과 `아직 등록된 프로젝트가 없어요.`를 표시해야 한다. 시작 전·진행 중·성공 1개 이상에서는 이 빈 상태를 표시하지 않아야 한다.
- **FR-009**: 프로젝트 조회 성공 결과가 한 개 이상이면 Figma node `1465:19015`에 대응하는 프로젝트 카드 영역을 표시해야 한다.
- **FR-010**: Home 프로젝트 카드의 source of truth는 `LearningProjectSummary`여야 하며 `repositoryName`, `techStack`, `currentSetLabel`, `currentSetTitle`, `overallProgressPercent`를 표시 값으로 사용해야 한다.
- **FR-011**: Home은 Figma의 `Now in Android`, `Kotlin`, `Compose`, `Set 1`, `Compose 핵심 개념`, `Nexters` 등 샘플 값을 production 프로젝트 데이터로 하드코딩하지 않아야 한다.
- **FR-012**: 프로젝트 학습 계속하기 요청은 `projectID`, `nextSetID`, `nextQuestionID`를 원문 그대로 담은 학습 intent를 상위에 출력해야 하며, 누락된 ID를 표시 문자열이나 다른 값에서 재구성하지 않아야 한다.
- **FR-013**: `nextSetID` 또는 `nextQuestionID`가 없어 유효한 다음 학습 목적지를 만들 수 없으면 학습 계속하기를 실행하지 않고 해당 상태를 접근성 정보와 함께 일관되게 표현해야 한다.
- **FR-014**: Home 프로필 영역의 source of truth는 `MemberProfile`이어야 하며 이름과 존재하는 `position`·`careerLevel`만 표시해야 한다. 두 보조 값이 모두 없으면 이름만 표시하고 누락 값을 기본값이나 `미설정` 문구로 대체하지 않아야 한다.
- **FR-015**: Home은 프로필 이미지 URL을 위한 새 Backend API, Domain 필드 또는 Avatar 전용 계약을 추가하지 않고 앱이 소유한 기본 프로필 이미지/asset을 fallback으로 사용해야 한다.
- **FR-016**: Home은 프로필 조회와 프로젝트 조회의 내부 상태를 독립적으로 보존해 한 조회의 실패로 다른 조회의 성공 결과를 폐기하거나 상태를 변경하지 않아야 한다. 프로젝트 실패 자체는 의도적으로 프로젝트 없음 상태와 동일하게 표시해야 한다.
- **FR-017**: 교체 가능한 Home 조회는 request identity와 취소 정책을 사용해 이전 요청의 늦은 결과가 최신 상태를 덮어쓰지 못하게 해야 한다.
- **FR-018**: Home은 프로필 조회 실패에 오류 의미와 명시적 프로필 전용 재시도를 제공해야 하며, 사용자 재시도 한 번당 프로필 조회를 최대 한 번 실행해야 한다. 프로젝트 조회 실패에는 오류 의미와 전용 재시도를 제공하지 않아야 한다.
- **FR-019**: 빈 상태와 프로젝트 있음 상태의 `지금 불러오기`는 동일한 프로젝트 등록 navigation intent를 상위에 출력해야 하며, 실제 `ProjectRegistration` Screen 생성과 App navigation 연결은 수행하지 않아야 한다.
- **FR-020**: Home은 프로젝트 등록을 위한 새 API, Domain 모델 또는 등록 Feature를 만들지 않아야 한다.
- **FR-021**: `전체 보기` 선택은 새 목록 화면을 만들지 않고 MainShell의 선택 탭을 `projects`로 바꿔야 하며, 이번 기능에서는 기존 `프로젝트` 제목 placeholder를 표시해야 한다.
- **FR-022**: Home에서 Feature 바깥으로 이동하는 등록·ProjectDetail·학습 의도는 목적지의 전환 방식을 직접 실행하지 않고 상위 MainShell 또는 App이 해석할 delegate/navigation intent로 전달해야 한다.
- **FR-023**: Home의 프로젝트 있음·없음 화면은 프로필 헤더, `Hello World`, `Let’s Git -it-!`, 프로젝트 불러오기 CTA, `학습 중인 레포지토리`, `전체 보기`와 네 탭을 공통으로 제공해야 한다.
- **FR-024**: Home 시각 구현은 기존 `ScreenContainer`, `ScreenHeader`, `TabShell`, `HomeProjectCard` 등 동일 의미의 UIComponent와 DesignSystem 토큰을 먼저 대조해 재사용하고, 의미가 맞지 않는 표현만 UI 패키지의 공개 계약으로 확장해야 한다.
- **FR-025**: Feature 화면은 Domain 업무 모델이나 TCA 타입을 UIComponent 공개 API에 전달하지 않고 표시 값과 콜백으로 변환해야 한다.
- **FR-026**: Home은 현재 `FetchLearningProjectsUseCase` 응답의 `items` 전체를 Domain 조회 순서대로 좌우 스크롤 영역에 표시하고, `hasNext == true`여도 추가 페이지를 조회하지 않아야 한다. 초기 진입 상태의 카드 중심 좌표를 선행 앵커 `P0`와 후속 앵커 `P1`, `P2`로 정하고 각 앵커의 정지 각도를 `0°`, `+16°`, `-12°`로 사용해야 한다. `P0`·`P1`·`P2`는 프로젝트 배열 인덱스가 아닌 현재 레이아웃의 시각 위치 기준이며, 드래그·감속 중 각 카드의 현재 중심 좌표가 인접 앵커 사이를 이동하는 비율로 목표 각도를 연속 보간해야 한다. 사용자가 손을 떼면 관성 감속 후 가장 가까운 카드가 `P0`에 정렬되어야 하며 자동 순환과 사용자 재정렬은 제공하지 않아야 한다.
- **FR-027**: Home의 프로젝트 있음 상태는 node `1465:19015`, 빈 상태는 node `1542:19610`을 최종 시각 근거로 사용하며, 색·타이포·자산·간격은 조회된 Figma 변수와 기존 DesignSystem/UIComponent 계약으로 추적 가능해야 한다.
- **FR-028**: Home은 프로필, 프로젝트 CTA, 전체 보기, 학습 계속하기와 탭에 의미가 분명한 접근성 라벨·trait·선택 상태를 제공하고 모든 조작 요소의 유효 터치 영역을 최소 `44pt × 44pt`로 유지해야 한다.
- **FR-029**: Home은 iOS 26 `DynamicTypeSize` 전체 12단계(`xSmall`, `small`, `medium`, `large`, `xLarge`, `xxLarge`, `xxxLarge`, `accessibility1`, `accessibility2`, `accessibility3`, `accessibility4`, `accessibility5`)와 긴 이름·기술 스택·세트 제목에서 핵심 동작과 프로젝트 식별 정보를 사용할 수 있어야 한다.
- **FR-030**: 기존 authentication, onboarding, splash destination 판정과 MainShell 진입 조건은 이 기능으로 변경하지 않아야 한다.
- **FR-031**: Project·Saved·My의 Screen 생성과 실제 scoped store 화면 연결은 이 Home 명세에서 제외하며, 각 탭의 기존 제목 placeholder와 child Reducer 조합을 유지해야 한다.
- **FR-032**: 프로젝트 있음·없음, 조회 중, 프로젝트 실패를 빈 상태로 표시한 상태, 프로필 오류 상태는 서로 독립적으로 재현 가능한 Preview 또는 동등한 시각 검증 진입점을 제공해야 하고 Figma 대응 상태 이름에는 node ID를 포함해야 한다.
- **FR-033**: Home은 MainShell에서 최초 표시될 때 프로필과 프로젝트 조회를 각각 한 번 시작하고, 다른 탭에서 Home으로 돌아올 때 자동으로 다시 조회하지 않아야 한다. 이후 조회는 프로필 실패에 대한 명시적 재시도로만 실행해야 한다.
- **FR-034**: Home 프로젝트 카드의 색상 variant는 현재 Domain 조회 결과 순서의 `index % 3`으로 결정해 해당 카드가 표시되는 동안 유지해야 하며, 위치 기반 회전과 독립적이어야 한다. 스크롤 중 색상 variant를 현재 앵커나 가시 순서로 다시 계산하지 않아야 한다.
- **FR-035**: Home 프로젝트 카드의 재생 버튼은 FR-012·013의 학습 intent를, 재생 버튼을 제외한 카드 본문은 해당 `projectID`를 담은 ProjectDetail intent를 출력해야 한다. SwiftUI `ScrollView`가 scroll gesture로 인식한 접촉에서는 스크롤을 우선하고 두 intent를 모두 출력하지 않아야 한다. 실제 ProjectDetail·Quiz Screen과 App navigation 연결은 수행하지 않아야 한다.
- **FR-036**: 프로필 조회만 실패하면 Home은 프로필 헤더 영역 안에 오류 안내와 프로필 전용 재시도를 표시하고 프로젝트 영역의 현재 상태와 콘텐츠를 유지해야 한다. 프로필 재시도는 프로필 조회만 실행하고 프로젝트 조회를 시작하지 않아야 한다.
- **FR-037**: 프로젝트 조회만 실패하면 FR-008의 빈 상태에 프로젝트 등록 CTA를 포함하고 프로젝트 오류 안내와 전용 재시도를 제공하지 않아야 한다. 프로필 영역의 현재 상태와 콘텐츠는 유지해야 한다.

### 핵심 엔터티

- **Home 상태**: 프로필 조회 상태, 프로젝트 조회 상태, 최신 요청 식별자와 조회된 `MemberProfile`·`LearningProjectSummary` 목록을 소유하며 표시 상태를 결정한다.
- **프로필 조회 상태**: 시작 전, 진행 중, 성공한 `MemberProfile`, 재시도 가능한 실패를 구분하고 프로젝트 조회 상태와 독립적으로 유지된다.
- **프로젝트 조회 상태**: 시작 전, 진행 중, 성공한 프로젝트 목록, 실패를 내부적으로 구분한다. 빈 상태 화면 표현은 성공 목록이 0개이거나 조회가 실패했을 때 파생되며 실패에는 전용 재시도를 제공하지 않는다.
- **학습 프로젝트 요약**: `projectID`, 저장소 이름, 저장소 이미지 URL, 기술 스택, 현재 세트 라벨과 제목, 다음 세트·문제 ID, 전체 진행률을 제공하는 기존 Domain 정본이다.
- **멤버 프로필**: 사용자 이름, 이메일, 분야, 경력 수준과 학습 통계를 제공하는 기존 Domain 정본이며 프로필 이미지 URL을 포함하지 않는다.
- **MainShell 탭**: Home·Project·Saved·My의 순서, 표시 이름, 아이콘과 현재 선택을 나타내며 각 child Feature 화면에 대응한다.
- **Home navigation intent**: 기존 프로젝트 등록 흐름 요청, 프로젝트 탭 전환, `projectID` 기반 ProjectDetail 요청, 다음 학습 요청을 상위 경계가 해석할 수 있는 완전한 payload로 나타낸다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: 인증과 온보딩 완료 후 MainShell 최초 진입 및 로그아웃 후 재진입 자동화 시나리오의 100%에서 Home이 기본 선택되고 네 탭이 `홈 → 프로젝트 → 저장 → 마이` 순서로 표시된다.
- **SC-002**: `idle`, `loading`, 성공 0개, 성공 1개 이상, 실패의 프로젝트 조회 조건에서 `아직 등록된 프로젝트가 없어요.`는 성공 0개와 실패 조건에서만 표시되고, `idle`·`loading`·성공 1개 이상 조건의 노출은 0건이다.
- **SC-003**: 프로젝트 있음 검증 데이터의 `repositoryName`, `techStack`, `currentSetLabel`, `currentSetTitle`, `overallProgressPercent`가 Home 카드 표시와 100% 일치하고 Figma 샘플 프로젝트 값의 production 하드코딩은 0건이다.
- **SC-004**: 유효한 다음 학습 ID가 있는 카드의 학습 intent payload는 Domain ID와 100% 일치하고 사용자 선택당 정확히 1회 출력된다. 실제 학습 Screen·App 목적지 연결, ID가 누락된 조건에서의 임의 ID 생성 및 학습 이동은 모두 0건이다.
- **SC-005**: 프로젝트 있음·없음 상태 모두에서 `지금 불러오기`가 동일한 기존 프로젝트 등록 intent를 정확히 1회 출력하고, 실제 등록 Screen·App 목적지 연결 및 Home 전용 등록 API·Domain 모델·Feature 추가는 모두 0건이다.
- **SC-006**: `전체 보기` 선택 자동화 시나리오의 100%에서 MainShell이 프로젝트 탭으로 전환하고 기존 `프로젝트` 제목 placeholder를 표시하며 새 프로젝트 목록 Screen 생성은 0건이다.
- **SC-007**: 프로필 실패/프로젝트 성공, 프로필 성공/프로젝트 실패의 교차 조건에서 성공한 다른 영역의 데이터 손실은 0건이다. 프로필 실패에는 전용 재시도가 존재하고 프로젝트 실패의 오류 안내·전용 재시도는 각각 0건이다.
- **SC-008**: 반복 프로필 재시도와 순서가 뒤바뀐 응답을 포함한 검증에서 사용자 재시도 1회당 프로필 조회 호출은 최대 1회이고 stale 응답에 따른 최신 상태 변경은 0건이다.
- **SC-009**: 프로젝트 있음 node `1465:19015`와 빈 상태 node `1542:19610`의 두 상태가 모두 재현 가능한 렌더로 비교되고, 확인된 차이는 수정 또는 승인 예외로 100% 분류된다. 승인 예외는 사용자의 명시적 승인과 검증 결과·PR의 차이·근거·영향·미검증 범위 기록을 모두 갖춰야 하며, 미승인 차이가 하나라도 남으면 이 기준은 실패다.
- **SC-010**: Home 관련 production Feature source에서 Data·Infrastructure·Composition 직접 import, production `@Dependency` 기반 Use Case 조회, 새 Avatar Backend/Domain 계약은 모두 0건이다.
- **SC-011**: VoiceOver 검증에서 프로필·CTA·전체 보기·카드·네 탭의 의미와 현재 선택을 식별할 수 없는 핵심 요소는 0개이며 조작 요소의 터치 영역 미달은 0건이다.
- **SC-012**: iOS 26 `DynamicTypeSize` 전체 12단계 검증과 긴 표시 값 표본에서 `지금 불러오기`, `전체 보기`, 학습 계속하기 중 가려지거나 실행할 수 없는 핵심 동작은 0건이다.
- **SC-013**: Home 탭 선택 시 `홈` 제목 placeholder 노출은 0건이고 실제 Home 화면이 표시되며, 프로젝트·저장·마이 탭에서는 기존 제목 placeholder가 각각 표시된다.
- **SC-014**: 현재 조회 응답의 프로젝트 개수와 관계없이 `items`의 접근 가능 비율은 100%이고, `hasNext == true` 조건의 추가 페이지 조회는 0회다. 카드 정지 상태 검증에서 `P0`, `P1`, `P2`의 각도는 각각 `0°`, `+16°`, `-12°`이고 목표 오차는 `±0.5°` 이하다. 인접 앵커 중간 좌표의 선형 보간 오차는 `±0.5°` 이하이며 감속 종료 후 가장 가까운 카드 중심은 `P0`에서 `±1pt` 이내다. 실제 프로젝트 배열 인덱스를 앵커 판정에 사용하거나 자동 순환·사용자 재정렬을 추가한 동작은 각각 0건이다.
- **SC-015**: 최초 Home 표시 후 프로젝트·저장·마이 탭을 거쳐 Home으로 돌아오는 검증에서 프로필 및 프로젝트 자동 추가 조회는 각각 0회이고, 최초 성공 상태가 그대로 유지된다.
- **SC-016**: 세 개 이상의 카드를 `P0`·`P1`·`P2` 사이로 이동하는 검증에서 각 카드의 색상 variant는 최초 Domain 조회 순서의 `index % 3` 결과와 100% 일치하고, 스크롤 위치 변화로 색상이 바뀌는 사례는 0건이다.
- **SC-017**: 카드 본문 탭은 해당 `projectID`의 ProjectDetail intent를, 재생 버튼 탭은 세 Domain ID의 학습 intent를 사용자 선택당 각각 정확히 한 번 출력한다. 같은 시작 위치에서 수평 드래그로 판정된 상호작용의 ProjectDetail·학습 intent 출력은 각각 0회이며 실제 상세·학습 화면 이동은 0건이다.
- **SC-018**: `position`만 있음, `careerLevel`만 있음, 둘 다 있음, 둘 다 없음의 네 프로필 표본에서 존재하는 값의 표시율은 100%이고 누락 값의 기본값·`미설정` 문구 노출은 0건이다. 둘 다 없는 표본은 이름만 표시한다.
- **SC-019**: 프로필 실패·프로젝트 성공 교차 조건에서 프로필 오류와 전용 재시도는 헤더 영역에 100% 표시되고 프로젝트 콘텐츠 손실은 0건이다. 프로필 재시도 한 번당 프로필 조회는 정확히 1회, 프로젝트 추가 조회는 0회다.
- **SC-020**: 프로젝트 실패·프로필 성공 조건의 프로젝트 영역은 성공 0개 조건과 시각 요소가 100% 일치하고 성공한 프로필 손실은 0건이다. 프로젝트 오류 안내·전용 재시도·자동 추가 조회는 각각 0건이다.

## 가정

- 구현 기준은 기능 브랜치를 만들기 직전의 `feature/onboarding-login-tutorial-app-integration` HEAD `f22467dc1b0224883f0b59c7f241123605d58fc3`이다.
- Figma 파일 `mCRt0ejmzI4EFW3UnC9Bzb`의 Home 프로젝트 있음 node `1465:19015`와 프로젝트 없음 node `1542:19610`은 모두 `360×800` 화면이며 이번 명세 세션에서 렌더, design context와 variable definitions를 직접 확인했다.
- 사용자 제공 3.36초 참조 영상은 2026-08-30에 초기·드래그·감속·정지 구간을 프레임 단위로 확인했으며, 카드의 색상·콘텐츠나 영상 끝의 상세 화면 이동이 아니라 스크롤 위치·회전·정렬 동작만 요구사항 근거로 사용했다.
- Home 최초 표시에서 프로필과 프로젝트 조회는 각각 한 번 시작하고 서로 독립적인 결과를 보존하며, 다른 탭에서 복귀할 때는 다시 조회하지 않는다.
- `MemberProfile.position` 또는 `careerLevel`이 없을 때는 존재하는 값만 표시하고 둘 다 없으면 이름만 표시한다.
- `LearningProjectSummary.repositoryImageURL`은 현재 Home 카드의 필수 표시 요구가 아니며, 사용하더라도 기존 이미지 계약과 fallback을 따른다.
- 기존 `HomeProjectCard`와 `TabShell`은 재사용 후보지만 Figma 인덱스에서 일부 매핑이 `추정`이므로 계획·구현 단계에서 입력 의미와 레이아웃 계약을 직접 대조한 뒤 확정한다.
- 기존 `HomeProjectCard.Variant`는 색상과 고정 회전을 함께 제공하므로, 계획·구현 단계에서 색상 variant는 유지하면서 스크롤 위치 기반 회전을 별도 입력으로 표현할 수 있도록 책임을 대조한다.
- 기존 `ProjectListFeature`, `SavedFeature`, `SettingsFeature`는 reducer 상태와 동작을 계속 소유하지만 이번 기능에서는 Screen을 생성하거나 scoped 화면으로 연결하지 않고 현재 제목 placeholder를 유지한다.
- `ProjectRegistrationFeature`의 Reducer 책임은 재사용하지만 실제 등록 Screen과 App navigation 연결은 후속 기능에서 다룬다.
- ProjectDetail·Quiz Screen과 App navigation은 후속 기능에서 다루며, Home은 카드 본문의 `projectID` 기반 ProjectDetail intent와 재생 버튼의 완전한 학습 intent payload까지만 제공한다.

## 범위 경계와 의존성

### 포함

- Home child Feature의 상태, 조회, 프로필 오류·재시도, 프로젝트 실패의 빈 상태 표현, delegate/navigation intent와 화면
- MainShell의 Home 기본 선택 및 홈·프로젝트·저장·마이 4탭 구성
- MainShell의 Home 화면 scoping과 Home 탭 제목 placeholder 제거
- 기존 `FetchLearningProjectsUseCase`, `LearningProjectSummary`, `FetchMemberProfileUseCase`, `MemberProfile` 재사용
- 기존 프로젝트 등록 흐름, 프로젝트 탭, ProjectDetail, 다음 학습 흐름을 요청하는 intent
- 두 Home Figma 상태, DesignSystem/UIComponent 재사용 검토, Preview와 접근성 검증
- Home 및 MainShell 상태·Effect·delegate의 자동화 테스트

### 제외

- authentication·onboarding·splash의 destination 판정 변경
- 새 Home Backend API, Home 전용 Domain 모델, Avatar API 또는 프로필 이미지 Domain 필드
- 프로젝트 등록 기능과 Project List 기능 자체의 재구현
- Project·Saved·My Screen 생성, scoped store 화면 연결, 상세 시각 디자인 또는 Figma 정합성 범위 확대
- `ProjectRegistration` Screen 생성과 App navigation 목적지 연결
- ProjectDetail·Quiz Screen 생성과 App navigation 목적지 연결
- Home의 학습 프로젝트 추가 페이지 조회와 이를 위한 Domain pagination 계약 변경
- Home 탭 재선택 시 자동 갱신과 당겨서 새로고침 UI
- 카드 자동 순환, 무한 순환, 사용자 재정렬
- 표시 문자열에서 Domain ID를 재구성하거나 임의 생성하는 동작

### 외부 의존성

- 후속 기능에서 기존 `ProjectRegistrationFeature`를 목적지로 연결할 App 수준 navigation 정책
- 후속 기능에서 학습 intent를 ProjectDetail·Quiz 목적지로 연결할 App 수준 navigation 정책
- 기존 프로젝트 상세 또는 학습 시작 흐름이 해석할 `projectID`, `nextSetID`, `nextQuestionID` 계약
- 후속 기능에서 정의할 프로젝트·저장·마이 child Feature의 화면 생성 경계
- Figma node `1465:19015`, `1542:19610`과 프로젝트 DesignSystem/UIComponent
