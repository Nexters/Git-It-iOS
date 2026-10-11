# 빠른 시작: Apple 소셜 로그인 검증

이 안내는 구현 완료 후 Apple 로그인 기능을 end-to-end로 검증하는 방법을 정의한다. 상태와
보안 규칙은 [데이터 및 상태 모델](./data-model.md), 구현 교체 경계는
[인증 경계 계약](./contracts/authentication-boundary.md)을 따른다.

## 사전 조건

- iOS 26.0 이상 Simulator 또는 기기와 Xcode/Tuist 개발 환경이 준비되어 있다.
- 최초 실행 환경이면 저장소 루트에서 `make init`을 실행해 Tuist 의존성과 workspace를 만든다.
- 실제 Apple 시스템 인증 검증은 Apple Developer 포털의 App ID와 provisioning profile에서
  Sign in with Apple capability가 활성화되어 있고, 기기 또는 Simulator가 테스트 가능한 Apple
  계정으로 로그인된 경우에만 수행한다. 저장소의 `GitIt.entitlements` 존재만으로 이 준비가
  완료되지는 않는다.
- 실제 Git It 서버 endpoint는 이 기능의 범위 밖이다. 자동화 검증은 명시적으로 주입한
  `MockAuthenticationRepository`와 `MockSessionRemote`를 분리해 사용한다.

## 빌드와 테스트 준비

저장소 루트에서 다음 명령을 순서대로 실행한다.

```sh
make init
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

기본 테스트 destination은 `platform=iOS Simulator,name=iPhone 17 Pro`다. 다른 사용 가능한
기기를 쓸 때는 세 명령을 실행하기 전에 `GIT_IT_TEST_DESTINATION`을 설정한다. `compile`과
`test`는 같은 Derived Data를 사용하므로 순서를 바꾸지 않는다.

예상 결과는 모든 공유 scheme의 build 성공과, 새로 추가된 Domain·Data·Core·Composition·
Feature·App 테스트 target의 통과다. 이 문서의 작성 시점에는 구현과 테스트 target이 아직
없으므로 위 명령을 실행한 결과를 성공으로 기록하지 않는다.

## 자동화 검증 시나리오

### 1. 최초 로그인과 중복 탭 차단

1. 빈 인증 참조 저장소·세션 저장소와 `.apple`을 지원하는 Mock 인증 구성을 준비한다.
2. Apple 로그인 제어를 한 번 탭하고, 교환이 끝나기 전에 다시 탭한다.
3. Mock 인증은 단발성 `AuthenticationGrant`를, Mock 세션 Remote는 새 Git It 사용자·세션을
   순서대로 반환하게 한다.

기대 결과: 인증 시도는 하나만 시작되고 Domain `SignIn`이 인증→세션 시작을 순서대로 호출한다.
grant payload는 vault에서 한 번만 소비되고 access/refresh token은 세션 저장 Adapter로 한 번
저장된 뒤 인증된 첫 화면으로 이동한다. Feature/App 상태와 테스트 실패 출력에는 grant payload와
토큰이 없다. Mock 외부 인증 성공 결과를 전달한 시점부터 인증된 첫 화면까지의 경과 시간은 3초
이내로 기록한다.

### 2. 기존 사용자와 선택 프로필 부재

1. 같은 Apple 사용자 식별자로 한 번 로그인한 Mock 계정을 준비한다.
2. 두 번째 Apple 결과에서 이름과 이메일을 생략한다.
3. 로그인 흐름을 완료한다.

기대 결과: 새 Git It 계정을 만들지 않고 기존 사용자로 인증된다. 이메일 일치만으로 다른
계정을 병합하는 시나리오는 성공으로 취급하지 않는다.

### 3. 취소와 인증 오류

1. Mock 인증 Repository 또는 `MockExternalAuthenticationProvider`가 Domain Adapter를 거쳐
   `cancelled`를 반환하게 한다.
2. 별도 실행에서 state 불일치, token/code 누락, 인증 참조 저장 실패, 네트워크 오류를 각각
   반환하게 한다.
3. 오류 뒤 다시 정상 인증을 실행한다.

기대 결과: 취소는 경고 없이 로그인 화면에 남고 grant와 서버 세션을 만들지 않는다. 다른 오류는
이해 가능한 재시도 안내를 보이며 보호된 화면을 열지 않는다. 세션 시작이 실패하면 grant와 임시
인증 상태가 정리되고, 인증 참조 저장이 실패하면 vault payload도 남지 않는다. 마지막 정상 시도는
이전 오류에 영향받지 않고 완료된다. 취소·오류 결과를 전달한 시점부터 안정적인 로그인 또는 복구
화면까지의 경과 시간은 3초 이내로 기록한다.

### 4. 세션 복원과 토큰 갱신

1. 유효한 저장 세션으로 앱을 재시작한다.
2. access token이 만료하고 refresh token은 유효한 경우를 실행한다.
3. generic authorization status 조회 오류, refresh 네트워크 오류, refresh 거부를 각각 실행한다.

기대 결과: 유효 세션과 refresh 성공은 Apple UI 없이 인증된 첫 화면으로 이동한다. 일시 오류는
인증 참조와 토큰을 각각 유지하고 재시도를 제공한다. refresh 거부는 `SessionRepository`가 서버
세션을 삭제하고, `reauthenticationRequired`는 Domain 흐름이 두 Repository를 조정해 인증 참조와
서버 세션을 각각 삭제한 후 로그인 화면으로 이동한다. 유효 세션 복원과 refresh 성공은 각각 앱
시작 또는 갱신 시작부터 3초 이내인지 기록한다.

### 5. Apple 연결 철회와 로그아웃 경쟁

1. Data↔Core 외부 인증 Adapter가 Apple `.revoked`·`.notFound`·`.transferred` 또는 revoked
   알림을 Data `.inactive`로 변환하고, Domain↔Data 인증 Adapter가
   `authorizationChanges()`의 `.reauthenticationRequired`로 변환하게 한다. Domain
   `ObserveAuthorizationChanges`가 이를 처리해 두 Repository를 정리하고 `unauthenticated`
   outcome만 Feature에 전달하게 한다.
2. 별도 실행에서 refresh가 진행 중일 때 로그아웃을 탭하고, 그 뒤 refresh 성공 결과를 전달한다.
3. 서버 리프레시 토큰 폐기 요청의 성공과 네트워크 실패를 각각 재현한다.

기대 결과: 철회는 인증 참조와 서버 세션을 각 Repository를 통해 삭제한다. 로그아웃은 서버
세션을 먼저 로컬에서 제거하고 인증 참조·남은 grant를 정리해 3초 이내 로그인 화면으로 전환하며
서버 폐기 실패에도 되돌아가지 않는다. 늦은 refresh 성공은 Keychain이나 인증 화면을 되살리지 않는다.

## 실제 Apple 시스템 인증 수동 검증

1. capability가 준비된 기기 또는 Apple 계정에 로그인한 Simulator에서 Git It을 실행한다.
2. Apple 로그인 제어를 선택하고 실제 Apple 인증 UI에서 승인, 이메일 가리기, 취소를 각각
   수행한다.
3. 동일 Apple 계정으로 두 번째 인증을 수행하되 이름·이메일이 없는 응답도 허용한다.
4. 실제 서버 Adapter가 아직 없으면 이 단계는 Domain↔Data 인증 Adapter와 Data↔Core 외부 인증
   Adapter가 Domain `.apple` 요청을 Core Apple 인증에 연결해 단발성 grant를 만드는지까지만
   확인하고, 계정 교환·세션 성공은 `MockSessionRemote` 자동화 시나리오로 검증한다.

기대 결과: 표준 Apple UI가 표시되고, 진행·취소·오류·재시도 제어가 VoiceOver로 식별된다.
로그인 시작부터 실제 Apple 승인과 Mock 서버 세션을 거친 인증 화면 도달은 45초 이내,
Apple 승인 결과 수신부터 화면 도달은 3초 이내인지 기록한다. 실제 서버 연결 없이
`MockSessionRemote`도 주입하지 않은 구성에서 성공한 Git It 세션을 표시해서는 안 된다.

## 완료 기준

- [ ] Mock 기반 자동화 시나리오가 모두 통과한다.
- [ ] Domain, Data, Core, Composition, Feature, App의 경계별 테스트가 통과한다.
- [ ] `AuthenticationRepository`가 서버·세션 저장을 호출하지 않고 `SessionRepository`만
  세션 시작·복원·종료를 수행하는 책임 분리 테스트가 통과한다.
- [ ] Domain `AuthenticationRepository` Adapter가 Core·Apple 타입 없이 Data
  `ExternalAuthenticationProvider` Test Double만으로 테스트된다.
- [ ] `build`, `compile`, `test`를 실제로 실행해 결과를 기록한다.
- [ ] 실제 Apple capability가 준비된 환경에서 수동 인증·취소·재인증을 확인한다.
- [ ] 실제 서버 endpoint가 도입될 때 Live Adapter가 인증 경계 계약을 통과하는 통합 검증을
  별도로 기록한다.
