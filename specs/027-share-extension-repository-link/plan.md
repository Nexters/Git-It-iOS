# 구현 계획: 공유 시트에서 GitHub 저장소를 등록하는 Share Extension

**Git-flow 유형**: `feature`

**브랜치**: `feature/share-extension-repository-link`

**날짜**: 2026-09-05 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/027-share-extension-repository-link/spec.md`의 기능 명세

**참고**: 이 템플릿은 `/speckit-plan`이 채운다. 스킬 정의에는 실행 흐름이 설명되어 있다.

## 요약

외부 앱의 공유 시트에서 GitHub 저장소 URL을 받아 Extension 자체 UI 안에서 세션 확인, 저장소
조회, 프로젝트 등록까지 완결한다. 본 앱은 실행하지 않고 서버 변경도 없다.

조사 결과 세 가지가 구조 변경을 요구한다. 첫째, `CompositionAdapter`가
`InfrastructurePushMessaging`을 통해 Firebase를 링크하므로 Extension이 그대로 링크할 수 없다.
원격 푸시 조립을 새 `CompositionApp` target으로 분리하고 로컬 알림을 별도 Infrastructure
target으로 떼어내 공유 가능한 조립 요소만 남긴다. 둘째, 현재 Keychain 저장은 access group이
없고 `WhenUnlockedThisDeviceOnly`라 Extension이 세션을 읽을 수 없다. 공유 access group과 최초
잠금 해제 이후 접근성으로 바꾸고 본 앱이 1회성 이전을 수행한다. 셋째, 기존 리마인더는 생성
완료 시점에 메모리 목록을 보고 예약하므로 Extension이 직접 예약할 수 없다. Extension은 App
Group에 대기 항목만 남기고 본 앱 조정자가 흡수한다. 근거와 대안은
[research.md](./research.md)에 있다.

## 기술 맥락

**언어/버전**: Swift 5.0 모드, Swift 6 도구 체인, `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`

**주요 의존성**: SwiftUI, ComposableArchitecture, UserNotifications, Security(Keychain).
Extension은 FirebaseCore·FirebaseMessaging을 링크하지 않는다.

**저장소**: 공유 Keychain access group(세션 토큰), App Group UserDefaults(세션 상태 마커,
리마인더 대기 목록)

**테스트**: Swift Testing(기본), 테스트 함수 이름은 한국어 동작 문장

**대상 플랫폼**: iOS 26.0 이상

**프로젝트 유형**: Tuist 기반 멀티 패키지 iOS 앱 + Share Extension

**성능 목표**: URL 오류·로그인 필요 판정 1초 이내(SC-002), 등록 가능 상태 도달은 본 앱 저장소
확인 화면과 동등(SC-002a)

**제약 조건**: Share Extension 메모리 상한 이내에서 종료 없이 완주(SC-007), Extension에서 토큰
갱신 0건(SC-004), 애플리케이션 단위 API 미사용(FR-026)

**규모/범위**: 신규 Extension 화면 1개(상태 8종), 신규 target 6개(App 1, Composition 2와 그
테스트 target 2, Infrastructure 1), 기존 target 수정 3개(App·Composition·Infrastructure)

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

**게이트 판정(0단계 전 / 1단계 후 동일하게 통과)**

| 원칙 | 게이트 | 판정 | 근거 |
|---|---|---|---|
| 1 명시적인 경계 | 새 target의 의존 방향이 아키텍처 표를 지키는가 | 통과 | Extension은 App 패키지 target으로 Feature·Composition·Domain만 참조하고, Composition은 Domain·Data·Infrastructure만 참조한다. 순환은 없다 |
| 1 명시적인 경계 | 의존성을 Tuist에 명시하는가 | 통과 | 신규·변경 target의 의존성을 manifest에 선언하는 작업을 1·3·5·7 단위에 배정했다 |
| 2 상태와 데이터 안전성 | 자격 증명 취급과 취소 경로 | 통과 | 토큰은 Keychain에만 두고 `ThisDeviceOnly`를 유지하며, 화면 종료 시 진행 중 요청을 취소한다(FR-018). 공유 저장소에는 토큰을 쓰지 않는다 |
| 3 검증 가능한 변경 | 동작 변경의 검증 근거 | 통과 | 단위 테스트 범위와 실기기 수동 검증을 [quickstart.md](./quickstart.md)에 정의했다. 실기기 미수행 범위는 PR에 미검증으로 남긴다 |
| 4·5 수정 경로 | 계획 단계가 산출물 밖을 바꾸지 않는가 | 통과 | 이 실행은 `plan.md`·`research.md`·`data-model.md`·`quickstart.md`·`contracts/**`만 만들었다 |
| 6 한국어 산출물 | 산출물 언어 | 통과 | 모든 계획 산출물을 한국어로 작성하고 식별자·경로는 원문을 유지했다 |
| 7 위험 기반 실행 단위 | 위상 순서와 다중 패키지 단위 근거 | 통과 | 아래 "실행 단위와 순서"에 순서, 분리 불가 근거, 통합 검증을 기록했다 |
| 8 브랜치 네임스페이스 | 검증된 Git-flow 브랜치 | 통과 | `feature/share-extension-repository-link`를 재사용했고 명세 메타데이터와 일치한다 |
| 10 책임 기반 네이밍 | 공개 이름이 책임을 드러내는가 | 통과 | `CompositionApp`·`CompositionShareExtension`·`InfrastructureLocalNotification`은 각 조립·변환 책임을 드러내고, 공급자 이름(Firebase)을 공유 경계에 노출하지 않는다 |

**1단계 설계 후 재점검**: 설계로 추가된 것은 target 경계 분리와 공유 저장소 계약뿐이며 새
위반이 발생하지 않았다. 정당화가 필요한 복잡성은 "복잡성 추적"에 기록했다.

**브랜치 네임스페이스**: 이 헌법 개정 후 새로 생성한 브랜치는 `feature/`, `hotfix/`,
`release/` 중 목적에 맞는 네임스페이스를 사용해야 한다. 개정 전에 생성된 기존 브랜치는
소급해 바꾸지 않고 기존 브랜치임을 기록한다. `/speckit-specify`는 명세 산출물을 만들기
전에 현재 HEAD에서 검증된 브랜치를 직접 생성하거나 이미 현재인 동일 브랜치를 재사용해야
하며, branch 생성에 실패한 명세로 계획을 진행하지 않는다. `before_specify` hook은 브랜치
생성이나 전환을 대신 수행하지 않는다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정할 수 있다. 이 산출물 밖의 구현 파일은 정확한
경로를 `tasks.md`에 기록하며 계획 단계에서는 수정하지 않는다.

**세션 지식 기록**: 적용 여부와 문턱은 Constitution 원칙 9를 정본으로 따른다. 기록 조건을
충족하면 해당 전용 스킬을 별도로 사용하며 계획 산출물이나 구현 작업으로 만들지 않는다.

**Git 실행 직렬화**: 같은 checkout에서 `git commit`, pre-commit과 staged formatter처럼
Git index, 작업 파일 또는 공유 formatter cache를 사용하는 변경 체인은 하나만 실행한다.
기존 체인의 종료와 결과를 확인하기 전에는 재시도하지 않으며, 중복 실행을 발견하면 실행
소유자와 index·작업 파일 상태를 확인하고 사용자 승인 없이 임의로 종료하지 않는다. 읽기
전용 Git 조회, 서로 다른 checkout과 실행별로 격리된 build·test 경로는 이 제한에서 제외한다.

**커밋 단위 구현**: `/speckit-implement`는 미완료 작업을 실행 시점에 논리적이고 독립적으로
되돌릴 수 있는 커밋 단위로 설계한다. 단일 패키지가 기본이며, 분리하면 compile되지 않는
공개 API 이전이나 공용 manifest 변경은 근거와 통합 검증을 가진 다중 패키지 단위로 묶는다.
각 단위는 작업 ID, 정확한 파일,
검증과 커밋 메시지를 명시하고, 구현·검증·`tasks.md` 완료 표시·정확한 staging·commit 성공
확인을 마친 뒤에만 다음 단위로 진행한다. 훅을 우회하거나 무관한 변경을 포함하거나 amend,
rebase, push하지 않는다. 마지막 적용 패키지의 마지막 단위는 전체 읽기 전용 검증과 필수
`after_implement` hook까지 실행·재검증한 뒤 최종 commit한다. 시작 전 tasks.md의 일반 변경은
blob hash와 전체 diff로 기준선을 고정하며 별도 commit은 선택 사항이다. 확정된 기능 범위의
후속 단위와 읽기 전용 전체 검증은 반복 승인 없이 진행하고 새 권한이 필요한 경우에만 중단한다.

**책임 기반 네이밍**: 프로젝트가 소유하는 공개 API와 경계를 넘는 값은 실제 책임과 필요한
최소 문맥을 드러내야 한다. 표면적인 통일만을 위한 공통 접두어·접미어·축약은 적용하지 않고,
저장·전달되는 값은 독립적으로 목적을 식별할 수 있게 계획한다. 외부 계약의 고정 이름은
보존하고 공급자 중립 경계에는 특정 공급자나 저장 기술의 용어를 노출하지 않는다. 네이밍과
설계·동작 변경이 함께 필요하면 범위와 검증을 분리한다. `docs/conventions/naming.md`가 없으면
Constitution 원칙 10을 직접 적용하고, 문서가 작성된 뒤에는 세부 기준과 예외를 함께 참조한다.

**실행 단위 진행**: 현재 명세가 변경하는 패키지를 식별하고 의존성 위상 순서로 구현 경계를
계획한다. 단일 패키지 단위를 기본으로 하되 분리하면 중간 상태가 깨지는 경우에는 불가분한
다중 패키지 integration unit을 사용한다. 각 단위의 변경 파일과 검증 결과를 진행 상황으로
보고하며 같은 기능 범위의 다음 단위는 반복 승인 없이 진행한다. 공용 구성 파일이나 공개 API
이전이 여러 패키지를 함께 바꿔야 안전하면 분리 불가 근거, 정확한 경로와 통합 검증을 기록한다.
패키지에 속하지 않는 파일도 책임 단위에 배정하며, 배정할 수 없으면 계획을 중단한다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/027-share-extension-repository-link/
├── spec.md              # 기능 명세(/speckit-specify, /speckit-clarify)
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md        # 1단계 산출물(/speckit-plan)
├── quickstart.md        # 1단계 산출물(/speckit-plan)
├── contracts/
│   ├── shared-storage.md
│   ├── share-extension-composition.md
│   └── share-extension-ui.md
├── checklists/requirements.md
└── tasks.md             # 2단계 산출물(/speckit-tasks, /speckit-plan이 생성하지 않음)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/
├── Infrastructure/
│   ├── LocalNotification/            # 신규 target: PushMessaging/Local/** 이전
│   ├── PushMessaging/                # 원격 푸시(Firebase)만 남김
│   └── Authentication/Keychain/      # access group·접근성 변경
├── Composition/
│   ├── Adapter/                      # 공유 조립 요소(원격 푸시 의존 제거)
│   ├── App/                          # 신규 target: AppComposition, 푸시 AppDelegate
│   └── ShareExtension/               # 신규 target: Extension 조립 루트
├── Feature/
│   └── ShareRegistration/            # 신규 관심사: Extension 화면과 Reducer
└── App/
    ├── GitIt/                        # 본 앱: 세션 이전, 상태 마커, 복귀 갱신
    └── ShareExtension/               # 신규 target: Share Extension 번들

sources/Tuist/ProjectDescriptionHelpers/Projects/
├── AppModuleName.swift               # ShareExtension target·scheme 추가
├── CompositionModuleName.swift       # CompositionApp, CompositionShareExtension 추가
└── InfrastructureModuleName.swift    # InfrastructureLocalNotification 추가
```

**구조 결정**: 새 코드는 기존 패키지 책임을 그대로 따른다. 화면과 상태는 Feature, 조립은
Composition, 플랫폼 기능 변환은 Infrastructure, 번들과 진입점은 App이 소유한다. Extension은
독립 패키지를 만들지 않고 App 패키지의 target으로 둔다. Domain·Data·UI는 이 기능에서 변경하지
않는다. target 분리 근거는 [research.md](./research.md) R1·R2·R6에 있다.

## 실행 단위와 순서

의존성 위상 순서는 [아키텍처 문서](../../docs/architecture.md) 7.1을 따른다. 적용 대상은
Infrastructure → Composition → Feature → App이며 Domain·Data·UI는 대상이 아니다.

| 순서 | 단위 | 유형 | 범위 | 검증 |
|---|---|---|---|---|
| 1 | 로컬 알림 target 분리 | 다중 패키지 통합 | `Infrastructure/PushMessaging/Local/**` 이동, `InfrastructureModuleName.swift`, `CompositionModuleName.swift`, Composition의 import 갱신 | 전체 build·compile |
| 2 | 공유 Keychain 접근 | 다중 패키지 통합 | `KeychainStore`, 접근성·access group 모델, 본 앱과 Extension 두 entitlements | 단위 테스트 + build |
| 3 | Composition 조립 루트 분리 | 다중 패키지 통합 | `AppComposition.swift`·`PushNotificationAppDelegate.swift`를 `Composition/App/`으로 이동, manifest, `GitItApp.swift` import 갱신 | 전체 build·compile |
| 4 | 공유 저장소와 세션 판정 | 단일 패키지(Composition) | 공유 저장소 접근 타입, 세션 이전 절차, 세션 판정, 조정자 흡수 경로 | 단위 테스트 |
| 5 | Extension 조립 루트 | 단일 패키지(Composition) | `Composition/ShareExtension/**`, manifest | 단위 테스트 + build |
| 6 | Extension 화면 | 단일 패키지(Feature) | `Feature/ShareRegistration/**`(상태·화면·진단 이벤트)과 테스트 | 단위 테스트 |
| 7 | Extension 번들과 본 앱 정리 | 다중 패키지 통합 | `App/ShareExtension/**`(진입점·항목 해석·진단 기록), Info.plist, `AppModuleName.swift`, `ProjectName.swift`, 본 앱 복귀 갱신, 선행 구현 잔여 정리 | 전체 build·compile·test |

세부 작업 배정의 정본은 [tasks.md](./tasks.md)다. 세션 이전 절차는 Infrastructure가 아니라
Composition이 소유하므로 4번에, target·scheme manifest 변경은 각 target을 도입하는 단위에
배정했다.

**다중 패키지 통합 단위 근거**

- 1·3번: Swift target 경계 변경은 파일 이동과 manifest, 참조 갱신이 한 커밋에 함께 있어야
  컴파일된다. 나누면 중간 상태에서 빌드가 깨진다.
- 2번: Keychain 접근 방식과 entitlements는 함께 바뀌지 않으면 실행 시 항목을 읽지 못한다.
- 7번: Extension target 추가는 manifest, 번들 리소스, 본 앱 embed 설정이 동시에 필요하고,
  선행 구현 잔여 정리를 남기면 빌드가 중간 상태로 남는다.

**패키지에 속하지 않는 파일 배정**

| 파일 | 책임 단위 |
|---|---|
| `sources/Tuist/ProjectDescriptionHelpers/Projects/*.swift` | 해당 target을 도입·변경하는 단위(1·3·5·7) |
| `sources/Projects/App/GitIt.entitlements`, 신규 `ShareExtension.entitlements` | 2번(공유 자격 증명 선언). Extension target이 이를 소비하는 연결은 7번 |
| Extension Info.plist | 7번 |

## 복잡성 추적

> 헌법 점검에서 정당화해야 하는 위반이 있을 때만 작성한다

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| 신규 target 4개 추가 | Extension이 Firebase를 링크하지 않고 기존 조립 요소를 재사용하려면 조립 루트와 로컬 알림 경계를 분리해야 한다 | 기존 target을 그대로 링크하면 Extension에 Firebase가 들어와 FR-027과 메모리 제약을 위반하고, 조립을 Extension에 중복 구현하면 Adapter가 이중화된다 |
| 기존 조립 루트 파일 이동 | `CompositionAdapter`에서 원격 푸시 의존을 제거하려면 참조 파일 2개를 새 target으로 옮겨야 한다 | Infrastructure를 계약·구현 target으로 쪼개는 대안은 조립 책임이 App으로 새어 아키텍처 표와 어긋난다 |
| 본 앱 리마인더 대기 목록의 영속화 | Extension은 생성 완료를 관찰할 수 없어 기존 메모리 목록으로는 FR-016a를 만족할 수 없다 | Extension이 시간 기반 알림을 즉시 예약하는 대안은 "본 앱과 동일한 리마인더"가 아니며 생성 전 알림이 발생한다 |
