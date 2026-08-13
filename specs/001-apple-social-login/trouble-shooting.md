# 001 Apple 소셜 로그인 문제 해결 기록

**대상 기능**: `001-apple-social-login`

**기록 기준일**: 2026-08-12

**범위**: 명세 작성부터 Core 패키지 구현 완료까지 발생한 문제, 잘못된 판단과 교정 내역

이 문서는 현재 저장소의 Git 이력·Spec Kit 산출물과 같은 프로젝트에서 실행된 다른
Codex 작업 세션의 기록을 대조해 작성했다. 과거 세션의 수치나 판단이 현재 파일과 다르면
현재 Constitution, `tasks.md`, 소스와 커밋을 기준으로 교정했다. 앞으로 다시 발생했을 때
증상만으로 제품 코드 문제라고 단정하지 않도록 원인, 교정, 검증 경계를 함께 기록한다.

## 현재 기준

- 완료 범위는 준비 단계 T001~T017, Domain T018~T047, Data T048~T076, Core
  T077~T088이다.
- 다음 작업 패키지는 Composition이며 이후 순서는
  `Domain → Data → Core → Composition → UI → Feature → App`이다.
- 실제 Git It 서버 HTTP 계약과 `LiveSessionRemote`는 아직 구현되지 않았다. 현재 Data에는
  `SessionRemote` 계약과 DTO가 있고, 실제 세션 교환·저장·refresh 경쟁 처리는 이후
  Composition 작업에 남아 있다.
- `quickstart.md`는 완료 후 실행할 검증 절차다. 그 문서에 명령이나 기대 결과가 있다는
  사실은 실행 성공의 증거가 아니다.

## 명세와 계획

### 1. 계획 템플릿을 완성된 계획으로 오인

**증상**

- `check-prerequisites.sh --require-tasks`가
  `specs/001-apple-social-login/tasks.md`를 찾지 못했다.
- 당시 `plan.md`에는 `[FEATURE]`, `[DATE]`, `[###-feature-name]`,
  `NEEDS CLARIFICATION` 같은 자리표시자가 남아 있었고 `research.md`,
  `data-model.md`, `quickstart.md`, `contracts/**`도 준비되지 않았다.

**원인**

`setup-plan.sh`가 계획 템플릿을 만든 상태를 계획 단계 완료로 해석하고, 선행 산출물이 없는
상태에서 `speckit-tasks` 또는 `speckit-analyze`를 실행하려 했다.

**교정**

Apple 인증, 서버 교환과 Mock 경계, 보호 저장소, 패키지 책임, 검증 전략을 먼저 결정하고
`plan.md`, `research.md`, `data-model.md`, `quickstart.md`,
`contracts/authentication-boundary.md`를 작성한 뒤 작업 목록을 생성했다. 이 결과는
`e5e1fe1` (`[Docs] Apple 소셜 로그인 설계 및 작업 목록 추가`)에 반영됐다.

**재발 방지**

- 계획 파일이 템플릿과 동일하거나 자리표시자가 남아 있으면 미완료로 취급한다.
- `speckit-analyze`는 `tasks.md` 생성 뒤에만 실행한다.
- 설계 문서의 검증 명령은 미래 절차이며 실제 빌드·테스트 결과와 구분한다.

### 2. Spec Kit 산출물이 영어로 생성됨

**증상**

명세와 체크리스트의 고정 제목·지침이 영어로 출력되어 프로젝트의 한국어 문서 정책과
맞지 않았다.

**원인**

기능 입력의 문제가 아니라 Spec Kit 핵심 템플릿 5개와 스킬의 고정 문구가 영어였고,
`resolve_template`이 프로젝트 override가 없을 때 그 템플릿을 사용하고 있었다.

**교정**

Constitution, `AGENTS.md`, Spec Kit 스킬의 산출물 언어 지침과 템플릿을 한국어 기준으로
동기화했다. 코드 식별자·경로·명령·API 이름은 원문을 유지하도록 예외를 명시했다.
`cb45517` (`[Docs] Spec Kit 한국어 산출물 정책 적용`)로 기록됐다.

**재발 방지**

새 스킬이나 템플릿을 추가할 때 자연어 산출물 언어와 고정 boilerplate를 함께 확인한다.
대규모 다중 파일 패치가 충돌하면 의미를 바꾸지 않고 파일별 작은 패치로 나눈다.

## 인증과 세션 아키텍처

### 3. 외부 인증과 Git It 서버 세션 책임이 결합됨

**초기 문제**

`AuthenticationRepository`가 Apple 인증 결과를 받은 뒤 서버 세션 생성과 저장까지
책임지는 형태가 검토됐다. 이 구조에서는 외부 공급자 인증과 앱 서버 세션의 수명·오류·저장
정책이 하나의 Repository에 섞인다.

**교정**

- `AuthenticationRepository.authenticate(using:)`는 외부 인증 후 일회성
  `AuthenticationGrant(id, method)`만 반환한다.
- `SessionRepository.start(with:)`가 grant를 한 번 소비해 서버 세션으로 교환하고, 보호
  저장이 성공한 뒤에만 `AuthenticatedUser`를 반환한다.
- `restore()`는 access token 만료 시 내부 refresh를 수행하고, `signOut()`은 로컬 세션을
  먼저 삭제한 뒤 원격 폐기를 best-effort로 처리한다.
- `SignIn`, `RestoreSession`, `ObserveAuthorizationChanges`, `SignOut` use case가 두
  Repository의 순서와 정리 정책을 조정한다.

이 경계는 `b11dbaf` (`[Docs] Apple 로그인 인증 경계와 구현 작업 구체화`)와
`contracts/authentication-boundary.md`에 반영됐다.

### 4. 공급자 중립 계층에 Apple 기술이 누출됨

**초기 문제**

Domain 또는 Data 공개 경계에 `AppleAuthorizationClient`, `SignInWithApple`,
`ASAuthorization`, `appleUserID`, Apple credential state 같은 타입·필드가 들어갈 수
있었다. Apple API를 프로토콜로 감싸더라도 공유 계층의 언어가 Apple에 고정되는 문제는
사라지지 않는다.

**교정**

- Domain에는 지원 방식이라는 비즈니스 값 `AuthenticationMethod.apple`만 둔다.
- Data `ExternalAuthenticationProvider`에는 method identifier, 불투명 evidence,
  `active`·`inactive`·`temporarilyUnavailable`만 둔다.
- Apple API·credential·상태·오류는 Core가 소유하고, Composition의 Data↔Core Adapter만
  이를 Data 타입으로 변환한다.
- Feature는 Repository 또는 공급자 상태를 직접 보지 않고 Domain use case만 사용한다.

현재 Domain과 Data 구현·테스트는 각각 프로젝트 내부 의존성 없이 이 경계를 검증한다.

### 5. Apple 원시 credential과 앱 세션 토큰을 같은 값으로 취급할 위험

**초기 문제**

`identityToken` 또는 `authorizationCode`를 앱의 장기 세션 값처럼 저장하거나 Domain과
Feature까지 전달할 가능성이 있었다.

**교정**

- Apple 원시 credential은 서버 검증을 위한 일회성 입력으로만 취급한다.
- 원시 payload는 영구 저장·로그·UI에 노출하지 않고, Composition의
  `AuthenticationGrantVault`에서 grant ID로 한 번만 소비하도록 설계했다.
- 영구 저장 대상은 Git It access/refresh token과 별도 인증 참조뿐이며 서로 다른 저장
  계약과 namespace를 사용한다.
- DTO·저장 모델·Core credential의 문자열 표현은 실제 값 대신 `<redacted>`를 반환하며,
  민감 값 비노출 회귀 테스트를 추가했다.

실제 서버 URL, HTTP method와 JSON은 아직 합의되지 않았으므로 문서나 구현에서 추측해
고정하지 않는다.

## 작업 목록과 실행 정책

### 6. 작업이 너무 크고 검증 경로가 불명확함

**증상**

초기 작업 목록은 한 항목이 여러 책임과 파일을 포괄해 Red/Green 관계, 수정 허용 경로,
계약별 누락 여부를 바로 확인하기 어려웠다.

**교정**

각 작업을 파일·책임 단위로 분해하고 다음 규칙을 적용했다.

- 쓰기 작업마다 정확한 저장소 상대 경로를 기록한다.
- 테스트는 Red 작업과 대응 Green 구현을 분리한다.
- 실행만 하는 검증은 `[no-write]`로 표시한다.
- `SessionRemote`, `SessionStorage`, 인증 참조 저장소, `AuthenticationGrantVault`,
  `AppComposition` 같은 경계를 각각 테스트·구현 작업으로 둔다.
- `speckit-implement`는 현재 패키지의 명시 경로와 `tasks.md` 완료 표시만 수정한다.

과거 세션의 T001~T153 수치는 중간 상태다. 이후 패키지 재배치로 현재 live
`tasks.md`는 T001~T160이며, 작업 수는 항상 현재 파일에서 다시 계산한다.

### 7. 의존 그래프 화살표를 구현 순서로 반대로 읽음

**초기 문제**

한때 소비자 중심의 `App → Feature → Composition → Domain → UI → Data → Core` 순서가
제안됐다. `A → B`를 “A 다음에 B를 구현”으로 해석했기 때문이다.

**원인**

이 저장소의 그래프에서 `A → B`는 A가 B에 컴파일 의존한다는 뜻이다. 따라서 실제 구현
선행자는 B다.

**교정**

provider에서 consumer로 올라가도록 Constitution과 `tasks.md`를
`Domain → Data → Core → Composition → UI → Feature → App`으로 맞췄다. 한 번의
`speckit-implement`는 첫 미완료 패키지 하나만 구현·검증하고, 결과 보고와 사용자 승인 뒤
다음 패키지로 진행한다. 현재 순서는 `50bf8a3`의 작업 목록과 이후 Constitution 갱신을
반영한 live 기준이다.

### 8. 구현 중 새 파일 분리가 허용 경로에 없음

**증상**

Core 구현 후 `AppleAuthorizationProvider.swift`와 `KeychainStore.swift`의 타입을 더 작은
파일로 분리하려 했지만, 새 경로가 당시 `tasks.md`에 없었다.

**교정**

구현 단계에서 임의로 새 파일을 만들지 않았다. 먼저 작업 목록에
`AppleAuthorizationAttempt.swift`, `AppleCredential.swift`,
`AppleAuthorizationError.swift`, `KeychainNamespace.swift`,
`KeychainAccessibility.swift`, `KeychainStoreError.swift`를 정확히 추가하고 관련 작업을
미완료로 되돌린 뒤 `speckit-implement`로 분리·재검증했다.

**재발 방지**

구현 중 필요한 경로가 작업 목록에 없으면 현재 구현을 확장하지 않고 `speckit-tasks`에서
경로와 책임부터 교정한다.

## Tuist, Xcode와 테스트

### 9. 새 테스트 파일을 추가했지만 0개 테스트가 실행됨

**증상**

Domain, Data, Core의 Red 테스트 파일을 추가한 직후 기존 테스트 target이 성공하거나 0개
테스트만 실행했다.

**원인**

생성된 Xcode project가 Tuist source glob의 새 파일을 아직 포함하지 않은 오래된 graph였다.
이는 Red 테스트 성공이 아니다.

**교정**

`tuist generate --no-open`으로 workspace와 project graph를 갱신한 뒤 다시 실행해 구현 타입
부재에 따른 예상 컴파일 실패를 확인했다. Green 구현과 Placeholder 삭제 뒤에도 다시
생성해 최종 target 포함 여부를 확인했다.

**재발 방지**

Tuist glob 아래 파일을 추가·삭제한 뒤에는 테스트 개수와 실제 source 포함 여부를 확인하고,
필요하면 graph를 재생성한 다음 Red/Green을 판정한다.

### 10. 공유 Derived Data 때문에 XCTest discovery가 SIGSEGV로 종료됨

**증상**

Domain 코드는 컴파일·링크되었지만 명세의 원래 `xcodebuild` 명령으로 실행하면 XCTest
bootstrap 전에 runner가 종료됐다. 기존 `GitIt.app`, `XCTestDynamicOverlay` 등이 함께
로드되며 discovery 중 SIGSEGV가 발생했다.

**원인**

Xcode 전역 `IDEBuildLocationStyle = Shared` 설정을 상속한 기본 Derived Data에서 다른
scheme 산출물과 충돌했다. 제품 코드나 Domain 테스트 자체의 실패가 아니었다.

**교정**

전역 Xcode 설정을 바꾸는 대신 저장소 공용 경로 reader로 Derived Data root를 구하고 scheme별
경로를 명시했다.

```sh
derived_data_root=$(./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_DERIVED_DATA_PATH)
xcodebuild \
  -workspace sources/GitIt.xcworkspace \
  -scheme DomainAuthentication \
  -derivedDataPath "$derived_data_root/TestSchemes/DomainAuthentication" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

같은 방식을 Domain, Data, Core와 예정된 UI 검증 명령에 반영했다. Domain은 23개 테스트,
Data는 13개 테스트, Core는 7개 테스트가 각 격리 경로에서 통과했다.

### 11. 제한된 실행 환경의 workspace·Simulator 오류를 코드 실패로 볼 위험

**증상**

일부 세션에서 다음과 같은 오류가 발생했다.

- `sources/GitIt.xcworkspace is not a workspace file`
- `CoreSimulatorService connection became invalid`
- SwiftPM·Clang cache 쓰기 권한 오류

**원인과 교정**

샌드박스의 Xcode workspace, Simulator 또는 cache 접근 제한일 수 있으므로 같은 변경을
Xcode 접근이 허용된 환경에서 다시 실행했다. Stage 1은 그 환경에서
`tuist generate --no-open`, build 13/13, compile 6/6이 통과했다. 이후 패키지 테스트도
격리 Derived Data와 허용된 Xcode 환경에서 실제 코드 실패와 환경 실패를 구분했다.

**재발 방지**

제한 환경의 인프라 오류만으로 코드 실패를 선언하지 않는다. 다만 권한 환경에서 재실행하지
않았다면 성공으로도 기록하지 않는다.

### 12. 빈 umbrella target과 공유 Scheme 구성이 검증을 흐림

**증상**

실제 모듈과 별개인 빈 `Domain`, `Data`, `Feature` umbrella target과 Placeholder, 자동 생성
Scheme이 남아 패키지별 build/test 대상을 명확히 식별하기 어려웠다.

**교정**

빈 umbrella target과 Placeholder를 제거하고 실제 production/test 모듈별 공유 Scheme을
명시적으로 구성했다. `tuist generate --no-open`과 공유 Scheme 9/9 빌드 후
`98b3794` (`[Build] 모듈별 공유 Scheme 구성 정리`)로 기록했다. 링크 search path 경고는
있었지만 빌드 실패는 아니었으며 별도 문제로 구분했다.

## 포맷, 린트와 동시성

### 13. formatter의 일부 성공 메시지를 전체 성공으로 오인

**증상**

한 파일에서 `0 violations`가 출력된 뒤 전체 Swift 포맷 훅이 실패해 SwiftFormat 문제로
보였다.

**원인**

실제 원인은 이후 파일에서 검출된 SwiftLint `no_unchecked_sendable` 3건이었다.

- `AppleAuthorizationProvider`: `@unchecked Sendable` 1건
- `KeychainStore`: `@unchecked Sendable` 2건

샌드박스 cache 권한 오류가 함께 나타나 원인이 섞였지만, 권한 환경에서 재실행해 린트
위반을 분리했다.

**교정**

규칙 예외를 추가하지 않고 `Synchronization.Mutex`에 가변 상태를 넣어 모든 접근을 짧은
`withLock` 임계 구역으로 제한하고 두 타입을 일반 `Sendable`로 선언했다. `Mutex`의 목적은
클로저를 `@Sendable`로 만드는 것이 아니라 공유 가변 상태 접근을 직렬화하는 것이다.
`withLock` 안에서는 `await`, 네트워크, Keychain 같은 장시간·재진입 작업을 수행하지 않는다.

Core 테스트 7개와 Swift 포맷·린트 훅이 통과한 뒤 `38bd866`
(`[Feat] Core 인증 기술 API 추가`)에 포함됐다.

### 14. pre-commit 포맷 적용 뒤 index와 working tree가 달라짐

**증상**

pre-commit이 Swift 파일을 수정한 뒤 `swift-format.restage-required`로 커밋을 중단하거나,
staged 내용과 포맷 결과가 달라졌다.

**교정**

훅을 우회하지 않았다. formatter diff를 검토하고 의도한 파일만 다시 stage한 뒤 훅을
재실행했다. Data와 Core 커밋은 최종적으로 스크립트 회귀와 Swift 포맷·린트를 통과했다.

**재발 방지**

- `--no-verify`를 사용하지 않는다.
- formatter가 파일을 바꾸면 cached/uncached diff를 다시 분리해 확인한다.
- 최초 실패를 커밋 성공이나 stage 완료로 기록하지 않는다.

## 구현 의미에 대한 교정

### 15. `SecureRandomGenerator`를 임시 인증 서버로 오해

`SecureRandomGenerator`는 서버 대체물이 아니다. `nonce`, `state`, `attemptID`, `grantID`
같은 요청 보호·식별 값을 만드는 CSPRNG 기반 도구이며 실제 서버가 연결된 뒤에도 필요하다.
서버 계약 확정 전 `SessionRemote`를 대체하는 구성요소는 이후 Composition에서 구현할
`MockSessionRemote`다.

### 16. Data 계약 구현을 서버 세션 연동 완료로 오해

현재 구현된 것은 Domain의 `SessionRepository` 계약과 use case, Data의 `SessionRemote`,
세션 DTO와 저장 계약이다. 다음 항목은 아직 완료되지 않았다.

- Domain↔Data·Data↔Core Adapter와 `DomainSessionRepositoryAdapter`
- `AuthenticationGrantVault`
- `MockSessionRemote`, `UnavailableSessionRemote`, 실제 `LiveSessionRemote`
- 실제 Keychain 세션 저장 Adapter
- refresh token 교체 저장, 중복 refresh, 로그아웃 경쟁 차단의 Composition 통합 구현
- App 조립과 end-to-end Mock 시나리오

따라서 Core Apple 인증 요청 기반이 존재하더라도 Apple 결과를 실제 Git It 서버 세션으로
교환해 로그인 완료 상태를 만드는 production 경로는 아직 연결되지 않았다.

### 17. refresh 테스트가 모두 구현됐다고 오해

- Domain 테스트는 복원 중 refresh의 일시 실패와 거부·만료에 따른 결과·정리 정책을 검증한다.
- Data 테스트는 refresh 요청·응답 DTO와 `SessionRemote.refreshSession` 계약을 검증한다.
- 실제 refresh 실행, token 교체 저장, 중복 실행과 로그아웃 경쟁 차단을 연결하는 Composition
  통합 테스트는 아직 미완료다.

계약 테스트 통과와 실제 Adapter 통합 동작 통과를 별개의 검증 수준으로 보고한다.

## 교정 커밋 요약

| 커밋 | 교정 내용 |
| --- | --- |
| `acc827f` | Apple 로그인 요구사항, 자체 서버 token 교환, Mock 기준 명세화 |
| `cb45517` | Spec Kit 한국어 산출물 정책 적용 |
| `e5e1fe1` | 계획·조사·데이터 모델·계약·quickstart·초기 작업 목록 완성 |
| `b11dbaf` | 외부 인증과 서버 세션 분리, Apple 기술 격리, 작업 구체화 |
| `d102c0d` | 인증 production/test target과 Tuist graph 기반 추가 |
| `50bf8a3` | 작업을 dependency-first 패키지 순서와 승인 게이트로 재정의 |
| `03a37e7` | 공급자 중립 Domain 모델·계약·use case와 테스트 구현 |
| `98b3794` | 빈 umbrella target 제거와 모듈별 공유 Scheme 정리 |
| `ebf5f38` | 공급자 중립 Data 계약·DTO·저장 모델과 보안 테스트 구현 |
| `38bd866` | Core Apple·Keychain·CSPRNG API, `Mutex` 동시성 교정과 테스트 구현 |

## 확인한 Codex 작업 기록

다음은 현재 프로젝트 경로에서 실행된 별도 Codex 세션 중 이 문서의 교정 근거로 대조한
기록이다. 세션의 과거 작업 번호·순서보다 현재 저장소 파일과 커밋을 우선했다.

| Codex task ID | 확인한 내용 |
| --- | --- |
| `019fea35-5c2e-7d82-b4ed-c5d706641e23` | 최초 명세·clarify·문서 커밋 |
| `019feac0-cf99-7c22-ab8f-299bf4126b62` | 영어 산출물 원인과 한국어 정책 교정 |
| `019feadd-97a2-7ec3-bec4-7177e450d443` | 미완성 plan과 `tasks.md` 부재 진단 |
| `019feae0-6b47-7c13-86c4-7ca21ec8437c` | plan과 설계 산출물 작성 |
| `019ff0b0-03e3-7cf1-a13b-85fa6e4e009f` | 인증/세션 분리와 Apple 기술 의존성 격리 |
| `019ff133-16e1-7003-9e45-e42e465159ad` | 파일·책임 단위 작업 분해 |
| `019ff184-78eb-7010-9c98-24ad7b39a029` | Stage 1 구현, Xcode 환경 재검증, formatter 재stage |
| `019ff1b0-ab46-7792-b64f-696964e41d18` | dependency-first 패키지 순서 교정 |
| `019ff1d1-0770-7970-90b3-485eae02151f` | Domain TDD, 공유 Derived Data SIGSEGV 진단과 격리 |
| `019ff4f8-1b81-7ae1-abcc-f6b9cf32c2ae` | 패키지 승인 정책, Domain·Scheme 커밋 범위 분리 |
| `019ff547-8ad9-7531-9fa8-bbdf73de5f06` | Data TDD, 민감 값 redaction, Tuist graph 갱신 |
| `019ff5e5-30e3-7352-aed6-dcd34d5a51f7` | Core `no_unchecked_sendable` 진단과 `Mutex` 교정 |
| `019ff5f3-cdda-71c0-a731-4487da5b7af3` | CSPRNG와 서버 Mock 책임, 현재 서버 세션 구현 범위 확인 |

## TS-20260813-001: 스킬 validator의 PyYAML 모듈 부재

**기록일**: 2026-08-13
**상태**: 완화
**발생 단계**: `$skill-creator` 기반 Spec Kit 기록 스킬 검증
**관련 항목**: `.agents/skills/speckit-troubleshooting/SKILL.md`,
`.agents/skills/speckit-tacit-knowledge/SKILL.md`

### 증상

두 새 스킬에 `quick_validate.py`를 실행했을 때 기본 `python3`가 `yaml` 모듈을 가져오지
못해 validator가 시작 전에 종료됐다. Codex workspace dependency Python으로 바꿔도 같은
오류가 재현됐다.

### 영향

스킬 내용과 frontmatter가 올바르더라도 validator 자체의 런타임 의존성이 없어 검증 실패로
보일 수 있었다. 이 상태에서 오류를 스킬 문법 문제로 해석하거나 검증을 생략할 위험이 있었다.

### 근거

- `python3 .../skill-creator/scripts/quick_validate.py
  .agents/skills/speckit-troubleshooting`: `ModuleNotFoundError: No module named 'yaml'`
- Codex workspace dependency의 `python3`로 같은 validator 실행: 동일한
  `ModuleNotFoundError`
- `/Users/jerry/.cache/uv/archive-v0/HiYdSTC7RnNqv5jB/lib/python3.14/site-packages/yaml/__init__.py`:
  사용할 수 있는 cached `PyYAML` 모듈 확인

### 원인

기본 Python과 Codex workspace dependency Python의 import 경로에 validator가 요구하는
`PyYAML`이 포함돼 있지 않았다. 새 스킬의 Markdown 또는 YAML frontmatter 오류는 아니었다.

### 조치

검증 프로세스에 cached `PyYAML`의 `site-packages` 경로를 `PYTHONPATH`로 지정하고 동일한
validator를 다시 실행했다. 시스템 Python 환경이나 저장소 의존성은 변경하지 않았다.

### 검증

- `env PYTHONPATH=/Users/jerry/.cache/uv/archive-v0/HiYdSTC7RnNqv5jB/lib/python3.14/site-packages
  python3 .../quick_validate.py .agents/skills/speckit-troubleshooting`: `Skill is valid!`
- 같은 명령의 대상만 `.agents/skills/speckit-tacit-knowledge`로 변경: `Skill is valid!`

### 재발 방지

`quick_validate.py`가 `yaml` import 단계에서 실패하면 스킬 오류로 단정하지 않고 실행
Python의 `PyYAML` 가용성을 먼저 확인한다. cached 경로는 환경에 따라 바뀔 수 있으므로
현재 존재를 확인한 경로만 사용하고, 경로가 없으면 `PyYAML`을 제공하는 관리된 실행 환경을
별도로 준비한다.

### 연결

없음
