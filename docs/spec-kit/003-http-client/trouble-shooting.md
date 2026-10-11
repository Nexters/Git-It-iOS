# 003 HTTP 통신 기술 API 문제 해결 기록

**대상 기능**: `003-http-client`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260814-001: `description`의 `String(reflecting:)` 자기 참조로 인한 무한 재귀 중단

**기록일**: 2026-08-14
**상태**: 해결
**발생 단계**: `$speckit-plan` — 계약 문서 서명의 타입 시스템 성립 여부 실측
**관련 항목**: FR-012, SC-007, `HTTPRequestError`,
`specs/003-http-client/research.md` §13,
`specs/003-http-client/contracts/http-client-api.md` §4

### 증상

계약 문서의 공개 서명이 실제로 컴파일·동작하는지 확인하려고 작성한 Swift 검증 프로그램이
컴파일 진단 없이 빌드된 뒤 실행 즉시 종료 코드 139(SIGSEGV)로 중단됐다. 표준 출력과 표준
오류 모두 0바이트였고, 크래시 지점보다 앞에 있던 출력문의 결과조차 남지 않았다.

검증 프로그램에는 실패 열거형(당시 이름 `HTTPRequestFailure`, 이후 사용자 지시로
`HTTPRequestError`로 rename)의 `description`을 케이스 이름에서 자동으로 만들려고 아래
형태를 썼다.

```swift
var description: String { "HTTPRequestFailure.\(String(reflecting: self).split(separator: ".").last!)" }
```

최소 재현은 다음과 같으며 저장소 밖에서 단독으로 다시 실행할 수 있다.

```swift
enum A: CustomStringConvertible {
    case x
    var description: String { "A.\(String(reflecting: self))" }
}
print("시작")
print(A.x)
```

### 영향

이 형태를 그대로 구현에 옮겼다면 `HTTPRequestError.description`을 문자열로 만드는 순간
프로세스가 죽는다. FR-012와 SC-007을 검증하는 `CoreHTTPTests`의 비밀 값 노출 테스트는
실패 케이스의 문자열 표현을 반드시 만들어 보므로, 테스트가 실패로 보고되는 대신 테스트
프로세스 자체가 중단된다. 이 경우 증상이 시뮬레이터·빌드 환경 문제로 오인되기 쉽다.

출력이 0바이트인 점도 오판 요인이다. 크래시 이전 출력문의 결과가 남지 않아 "프로그램이
시작조차 못 했다"고 해석하면 링크·서명·실행 환경을 먼저 의심하게 된다. 실제 원인은
런타임 진입 이후의 스택 오버플로였다.

### 근거

- `swiftc -swift-version 5 -parse-as-library -o constraintcheck constraintcheck.swift`:
  진단 출력 없음(컴파일 성공)
- `./constraintcheck`: 종료 코드 139, 출력 없음
- 최소 재현 프로그램 `./recursion > out.txt 2>&1`: 종료 코드 139,
  `wc -c out.txt` 결과 `0`
- 수정 후 동일 검증 프로그램 재실행: 종료 코드 0, 6개 확인 항목 전부 출력

검증 스크립트는 저장소 밖 세션 임시 디렉터리에서 실행했고 보존하지 않았다. 위 최소 재현
코드만으로 이후 세션에서 같은 결과를 다시 확인할 수 있다.

### 원인

`String(reflecting:)`은 대상이 `CustomDebugStringConvertible`을 구현하면
`debugDescription`을, 구현하지 않으면 `CustomStringConvertible.description`을 사용한다.
문제의 타입은 `CustomStringConvertible`만 구현했으므로 `description` 안에서
`String(reflecting: self)`를 호출하는 순간 `description`이 자기 자신을 다시 호출했다. 종료
조건이 없어 스택이 넘쳤고 런타임이 SIGSEGV로 중단됐다.

Swift 컴파일러는 이 자기 참조를 진단하지 않는다. 따라서 컴파일 성공은 이 결함에 대한
어떤 근거도 되지 못한다.

### 조치

검증 프로그램의 `description`을 여섯 케이스를 명시적으로 나열하는 `switch`로 교체했다.
반사(reflection)를 쓰지 않으므로 자기 참조 경로가 사라진다.

계획 산출물에는 같은 실수를 구현 단계에서 반복하지 않도록 제약을 명시했다.

- `specs/003-http-client/research.md` §13: 금지 형태, 최소 재현 코드와 이유 기록
- `specs/003-http-client/contracts/http-client-api.md` §4: `HTTPRequestError`의 계약 표에
  "`description`은 케이스를 나열하는 `switch`로 구현한다" 항목 추가

제품 소스는 아직 존재하지 않으므로 수정하지 않았다.

### 검증

- 수정 후 `swiftc -swift-version 5 -parse-as-library` 재빌드와 실행: 종료 코드 0
- 같은 실행에서 인증 헤더에 더미 토큰(`<redacted>`)을 넣고 `print`, `dump`, 문자열 보간,
  `String(describing:)`, 여섯 실패 케이스의 설명을 모두 문자열로 수집한 뒤 검사:
  토큰 노출 `false`, 헤더 이름 보존 `true`
- 같은 실행에서 실패 설명 출력 예: `HTTPRequestFailure.responseTimedOut`(rename 이전 이름)
- `grep -rn "HTTPRequestFailure" specs/`: rename 이후 잔여 0건

**미검증 범위**: 위 검증은 재현 스크립트와 계획 산출물에 한정된다. `CoreHTTP` 소스와
`CoreHTTPTests`는 아직 만들지 않았으므로, 실제 구현이 이 제약을 지키는지는 구현 단계의
빌드·테스트에서 다시 확인해야 한다.

### 재발 방지

- `description`과 `debugDescription` 안에서 `String(reflecting: self)`,
  `String(describing: self)`, `"\(self)"`를 사용하지 않는다. 열거형 케이스 이름이 필요하면
  케이스를 나열하는 `switch`로 작성한다.
- `customMirror` 안에서도 `self`를 다시 반사하지 않는다.
- 테스트 실행이 실패 보고 없이 프로세스 중단(종료 코드 139, 출력 0바이트)으로 끝나면
  빌드·서명·시뮬레이터 환경을 먼저 의심하기 전에 문자열 표현 구현의 자기 참조를 확인한다.
- 컴파일 성공은 이 결함의 부재를 뜻하지 않는다. 문자열 표현을 새로 구현하면 값을 실제로
  출력해 보는 검증을 포함한다.

### 연결

없음

## TS-20260814-003: 테스트 선행 단계에서 빈 `CoreHTTP` 소스 glob이 target 생성을 막음

**기록일**: 2026-08-14
**상태**: 완화
**발생 단계**: `$speckit-implement` — T003 Tuist workspace 생성 재실행
**관련 항목**: T003, T004~T012, T013

### 증상

sandbox 밖에서 `tuist generate`를 재실행하자 세션 상태 접근은 성공했지만, `CoreHTTP` target의
소스 glob이 가리키는 `sources/Projects/Core/CoreHTTP/` 디렉터리가 없어 target 생성을 중단했다.

### 영향

프로덕션 구현(T013)보다 테스트를 먼저 작성하는 동안에도 `CoreHTTP` scheme을 생성할 수 없어
T003과 T012를 실행할 수 없다.

### 근거

- `tuist generate`: `The target CoreHTTP has the following invalid source files globs`
- `tuist generate`: `CoreHTTP/**`가 가리키는 `sources/Projects/Core/CoreHTTP` 디렉터리가 존재하지 않는다고 보고
- `sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift:17`: module source glob을 `"\\(name)/**"`로 설정

### 원인

T001이 target 선언을 먼저 추가하지만 첫 프로덕션 파일은 T013에서 생성한다. Tuist는 source
glob의 대상 디렉터리가 비어 있는 것은 허용해도, 디렉터리 자체가 없는 상태는 허용하지 않는다.

### 조치

프로덕션 Swift 파일이나 API를 추가하지 않고 `sources/Projects/Core/CoreHTTP/` 빈 디렉터리만
준비한 뒤 `tuist generate`를 다시 실행한다. 디렉터리는 Git이 추적하지 않으며, T013이 첫
추적 파일을 생성하면 이 임시 조건은 자연스럽게 해소된다.

### 검증

- `tuist generate`: 실패. 빈 디렉터리 준비 후 재실행은 미실행.

### 재발 방지

새 Tuist target을 테스트 우선으로 도입할 때는 첫 프로덕션 Swift 파일을 작성하기 전에도
source glob의 루트 디렉터리가 존재하는지 확인한다. 구현 범위를 넓히지 않기 위해 placeholder
소스 파일을 추가하지 않는다.

### 연결

TS-20260814-002

## TS-20260814-004: Tuist 실행 디렉터리 기준으로 빈 source 디렉터리 경로를 중복 지정

**기록일**: 2026-08-14
**상태**: 해결 중
**발생 단계**: `$speckit-implement` — T003 source glob 완화 조치
**관련 항목**: T003, TS-20260814-003

### 증상

`sources` 디렉터리에서 실행하면서 `mkdir -p sources/Projects/Core/CoreHTTP`를 사용해,
의도한 `sources/Projects/Core/CoreHTTP/`가 아니라
`sources/sources/Projects/Core/CoreHTTP/`를 만들었다. 따라서 다음 `tuist generate`도 같은
`CoreHTTP/` 부재 오류로 중단됐다.

### 영향

T003 완료가 지연됐고, 잘못 만든 빈 디렉터리가 작업 트리에 남았다. Swift 파일이나 공개 API는
생성하지 않았다.

### 근거

- 실행 작업 디렉터리: `.../Git-It-iOS(forked)/sources`
- 실행 명령: `mkdir -p sources/Projects/Core/CoreHTTP`
- 뒤이은 `tuist generate`: 기존과 같은 `sources/Projects/Core/CoreHTTP` 부재 오류

### 원인

저장소 루트 기준 경로를 이미 `sources`인 현재 작업 디렉터리에 다시 적용했다.

### 조치

내가 만든 `sources/sources/Projects/Core/CoreHTTP/` 빈 디렉터리를 명시적으로 제거하고,
현재 작업 디렉터리 기준 `Projects/Core/CoreHTTP/`를 만든 뒤 `tuist generate`를 재실행한다.

### 검증

- `tuist generate`: 실패. 경로 정정 후 재실행은 미실행.

### 재발 방지

명령을 실행하기 전 `workdir`와 경로 기준을 함께 확인한다. 저장소 상대 경로를 하위 작업
디렉터리에서 사용할 때는 해당 접두어를 제거하거나 절대 경로를 사용한다.

### 연결

TS-20260814-003

## TS-20260814-006: T003 workspace 생성 제약의 해소 확인

**기록일**: 2026-08-14
**상태**: 해결
**발생 단계**: `$speckit-implement` — T003 완료 및 T012 Red 단계
**관련 항목**: T003, T012, TS-20260814-002, TS-20260814-003, TS-20260814-004, TS-20260814-005

### 증상

앞선 기록의 sandbox 세션 상태 접근 거부, 누락된 source glob 디렉터리, 작업 디렉터리 기준
경로 중복, scheme 확인 경로 불일치가 순차적으로 T003을 막았다.

### 영향

T003과 T012를 한 번의 정상 실행으로 끝낼 수 없었다. 프로덕션 구현을 추가하지 않은 테스트
선행 범위는 유지됐다.

### 근거

- sandbox 밖 `tuist generate`: `Project generated.`
- `sources/Projects/Core/Core.xcodeproj/xcshareddata/xcschemes/CoreHTTP.xcscheme:31-41`:
  `CoreHTTPTests`의 `<TestableReference` 확인
- `xcodebuild test -workspace GitIt.xcworkspace -scheme CoreHTTP -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`:
  `CoreHTTP` 모듈 의존성을 해소하지 못해 실패. 아직 프로덕션 Swift 선언이 없다는 Red 단계의
  예상 결과와 일치

### 원인

Tuist는 sandbox 밖 세션 상태 기록 권한과 source glob 루트 디렉터리를 모두 요구한다. 또한
생성 scheme은 `.xcodeproj` 컨테이너 안에 있다.

### 조치

권한을 올려 Tuist를 재실행하고, 프로덕션 소스 파일을 추가하지 않은 빈 `CoreHTTP/` 디렉터리와
새 테스트 파일을 준비한 뒤 workspace를 생성했다. 실제 scheme 위치에서 test target을 확인하고
Red 테스트를 실행했다.

### 검증

- `xcrun swiftc -parse`로 `CoreHTTPTests`의 8개 Swift 파일 검사: 성공
- `git diff --check`: 성공
- T012 xcodebuild: 의도된 Red 실패. Green 테스트는 T013~T028 구현 뒤 실행해야 한다.

### 재발 방지

다음 구현 단계에서는 `CoreHTTP/`에 첫 Swift 파일(T013)을 추가한 뒤 workspace를 다시 생성한다.
그 후에는 모듈 의존성 실패 대신 각 테스트의 실제 컴파일·동작 결과를 Green 단계(T029)에서
검증한다.

### 연결

TS-20260814-002, TS-20260814-003, TS-20260814-004, TS-20260814-005

## TS-20260814-005: T003의 scheme 확인 경로가 Tuist 실제 생성 위치와 다름

**기록일**: 2026-08-14
**상태**: 해결
**발생 단계**: `$speckit-implement` — T003 Tuist workspace 생성 확인
**관련 항목**: T003, `sources/Projects/Core/Core.xcodeproj/xcshareddata/xcschemes/CoreHTTP.xcscheme`

### 증상

`tuist generate`는 성공했지만 작업 목록에 적힌
`sources/Projects/Core/xcshareddata/xcschemes/CoreHTTP.xcscheme`에는 scheme 파일이 없었다.

### 영향

명세에 적힌 경로만 검사하면 scheme과 test target 등록이 누락됐다고 잘못 판단할 수 있다.
생성된 프로젝트와 scheme 자체에는 영향이 없다.

### 근거

- `tuist generate`: `Project generated.`로 성공
- `sources/Projects/Core/xcshareddata/xcschemes/CoreHTTP.xcscheme`: 파일 없음
- `sources/Projects/Core/Core.xcodeproj/xcshareddata/xcschemes/CoreHTTP.xcscheme:31-41`:
  `<TestableReference`와 `CoreHTTPTests` 존재

### 원인

Tuist가 Core 프로젝트를 `sources/Projects/Core/Core.xcodeproj`로 생성하는데, T003이
`.xcodeproj` 컨테이너를 생략한 경로를 사용했다.

### 조치

실제 생성 경로에서 `CoreHTTPTests`의 `<TestableReference`를 확인했다. T003의 검증 근거는
이 실제 경로를 사용한다.

### 검증

- `rg -uuu -n "TestableReference|CoreHTTPTests" sources/Projects/Core -g 'CoreHTTP.xcscheme'`:
  `<TestableReference` 1개와 `CoreHTTPTests` 참조 확인

### 재발 방지

Tuist 생성물 검증은 target 디렉터리 바로 아래가 아니라 생성된 `.xcodeproj` 컨테이너까지 포함한
경로를 탐색한다. 작업 목록 갱신 시에는 실제 생성 경로를 기록한다.

### 연결

TS-20260814-003

## TS-20260814-002: sandbox에서 Tuist 세션 상태 디렉터리 접근 거부

**기록일**: 2026-08-14
**상태**: 환경 제약
**발생 단계**: `$speckit-implement` — T003 Tuist workspace 생성
**관련 항목**: T003, `sources/Projects/Core/xcshareddata/xcschemes/CoreHTTP.xcscheme`

### 증상

저장소 루트에서 `make tuist`를 실행했지만 `tuist install`이 사용자 상태 디렉터리의 세션
파일을 만들지 못해 종료 코드 133으로 중단됐다.

### 영향

T003의 workspace 생성과 `CoreHTTP.xcscheme`의 `<TestableReference` 확인을 진행할 수 없다.
이후 Red 단계(T012)도 생성된 scheme이 필요하므로 실행할 수 없다.

### 근거

- `make tuist`: `Permission denied: /Users/jerry/.local/state/tuist/sessions/D62D5141-11E0-4A5A-A4BB-3E7F677A1020`
- `make tuist`: `tuist install` 종료 뒤 `make: *** [tuist] Error 133`

### 원인

현재 sandbox의 쓰기 허용 범위가 저장소·임시 디렉터리로 제한되어 있고, Tuist가 저장소 밖
`/Users/jerry/.local/state/tuist/sessions/`에 세션 상태를 기록하려 했다.

### 조치

sandbox 밖에서 `make tuist`를 다시 실행해 Tuist 세션 상태 기록을 허용할 예정이다.

### 검증

- `make tuist`: 실패. sandbox 밖 재실행은 미실행.

### 재발 방지

Tuist를 처음 실행하기 전, 저장소 밖 세션 상태 경로에 쓰기가 필요한지 확인한다. sandbox
거부가 발생하면 같은 명령을 반복하지 말고 권한을 명시적으로 올린 단일 재실행으로 구분한다.

### 연결

없음

## TS-20260815-001: 완료 표시된 T010 테스트의 Swift Testing 매크로 문법 오류

**기록일**: 2026-08-15
**상태**: 미해결
**발생 단계**: `$speckit-implement` — Core 패키지 Green 단계 사전 컴파일
**관련 항목**: T010, T029, `sources/Projects/Core/CoreHTTPTests/TransportSubstitutionTests.swift:76`

### 증상

`CoreHTTP` 구현을 추가하고 Tuist workspace를 다시 생성한 뒤 `CoreHTTP` scheme 테스트를
실행하자, 완료 표시된 T010의 테스트 파일에서 컴파일이 중단됐다. `#expect` 매크로의 비교식
오른쪽에 `try JSONEncoder().encode(body)`를 직접 두어 Swift가 이를 허용하지 않는다.

### 영향

CoreHTTPTests 전체가 컴파일되지 않아 T029의 Green 검증과 T030~T031의 패키지 검증으로 진행할
수 없다. 현재 `tasks.md`에서 T010은 `[X]`이고 같은 경로를 명시하는 미완료 작업이 없으므로,
`speckit-implement`의 허용 수정 경로 규칙상 이 세션에서 테스트 파일을 수정할 수 없다.

### 근거

- `xcodebuild test -workspace GitIt.xcworkspace -scheme CoreHTTP -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`:
  `TransportSubstitutionTests.swift:76:30: error: 'try' cannot appear to the right of a non-assignment operator`
- `sources/Projects/Core/CoreHTTPTests/TransportSubstitutionTests.swift:76`:
  `#expect(sent.body == try JSONEncoder().encode(body))`
- `specs/003-http-client/tasks.md`: T010이 `[X]`로 완료 표시되어 있고 해당 파일을 허용하는
  미완료 작업이 없음

### 원인

Swift Testing의 `#expect` 비교식은 `try`를 비교 연산자 오른쪽에 둘 수 없다. 인코딩 결과를
먼저 지역 상수로 구한 뒤 비교하거나, 테스트의 오류 전파가 가능한 별도 표현으로 바꿔야 한다.

### 조치

`CoreHTTP` 프로덕션 소스 추가와 Tuist workspace 재생성까지 수행했다. 완료된 T010의 소유
테스트 파일은 수정하지 않았으며, 작업 목록 갱신을 요청한 뒤 중단했다.

### 검증

- `make tuist`: 성공. 새 `CoreHTTP` 소스가 target에 포함된 workspace 생성 완료.
- 위 `xcodebuild test` 명령: 실패. 프로덕션 target은 컴파일됐으나 T010 테스트 컴파일 오류로
  테스트 실행은 시작되지 못함.
- T028의 URLProtocol 리다이렉트 검증과 T029~T031: 미실행.

### 재발 방지

테스트 작업을 완료 표시하기 전에 `#expect` 매크로 내부의 throwing 표현이 Swift 문법에 맞는지
`xcodebuild test`로 확인한다. 완료된 작업의 파일에서 후속 컴파일 오류가 발견되면, 수정 전에
해당 파일을 다시 여는 미완료 작업을 `tasks.md`에 추가한다.

### 연결

TS-20260814-006
