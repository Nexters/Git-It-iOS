# 계약: Domain UseCase Protocol

**소유 패키지**: Domain | **관련 요구사항**: FR-001 ~ FR-009

## 계약 규칙

1. Protocol 이름은 `<동사><명사>UseCase`, 구현 타입 이름은 `<동사><명사>`로 한다.
2. 호출 진입점은 `callAsFunction`으로 통일한다.
3. 모든 UseCase Protocol은 `Sendable`을 요구한다.
4. 파라미터, 반환값, 던지는 오류는 Domain 소유 타입이거나 언어 표준 타입만 사용한다.
5. 하나의 Protocol은 하나의 비즈니스 작업만 노출한다.
6. Protocol과 구현은 같은 Domain target 안에 둔다.

## 신설 대상 (DomainAuthentication)

```swift
public protocol SignInUseCase: Sendable {
    func callAsFunction(_ method: AuthenticationMethod) async -> AuthenticationOutcome
}

public protocol SignOutUseCase: Sendable {
    func callAsFunction() async -> AuthenticationOutcome
}

public protocol RestoreSessionUseCase: Sendable {
    func callAsFunction() async -> AuthenticationOutcome
}

public protocol ObserveAuthenticationOutcomesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<AuthenticationOutcome>
}
```

기존 `SignIn`, `SignOut`, `RestoreSession`과 rename 후 `ObserveAuthenticationOutcomes`가 각각
conform한다. 구현 본문과 동작은 바꾸지 않는다.

`ObserveAuthorizationChanges` → `ObserveAuthenticationOutcomes` rename은 이름과 그 참조만
바꾸는 순수 rename이다. 상세는
[naming-and-signatures.md](./naming-and-signatures.md) §4.2를 따른다.

## 금지 사항

- 파라미터·반환·오류 위치에 DTO, `HTTPRequest`, `HTTPResponse`, `HTTPClientError`,
  `Data*Error`, 외부 SDK 타입이 나타나서는 안 된다.
- 여러 비즈니스 작업을 하나의 Protocol에 묶어서는 안 된다.
- 구현 타입에 `Default` 같은 책임을 드러내지 않는 접두어를 붙여서는 안 된다.
- 표준 약어는 `Url`·`Id`·`Http` 절충 표기를 쓰지 않는다. 식별자 첫 단어가 아니면 전부 대문자,
  첫 단어이면 전부 소문자로 쓴다.

## 검증

- 각 concrete UseCase가 대응 Protocol을 구현하는지 컴파일로 확인한다.
- Protocol 시그니처에 Domain 외부 타입이 없는지 선언을 검토한다.
- 기존 Domain 테스트가 그대로 통과한다.
- rename 전후로 동일한 테스트 집합이 통과해 동작이 보존됐음을 확인한다 (FR-067).
