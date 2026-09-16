# 테스트 더블은 근거가 아닙니다

[Git It iOS 추상화 컨벤션](../abstraction.md)의 규칙 문서입니다.

"테스트에서 이 타입을 대체해야 한다"는 것만으로 프로토콜을 두지 않습니다. 그 대신 그
타입이 **의존하는 경계 계약**에 더블을 주입합니다.

## 왜 근거가 되지 않는가

테스트 더블을 위해 프로토콜을 두면, 테스트는 그 프로토콜이 선언한 형태만 검증하게
됩니다. 실제 구현이 요청을 어떻게 만들고 응답을 어떻게 해석하는지는 지나치지 않습니다.
더블을 한 단계 아래 경계로 내리면 그 구간까지 함께 지나므로 검증 범위가 넓어집니다.

## 어디에 주입하는가

그 타입이 이미 의존하고 있는, 근거 A를 충족하는 계약에 주입합니다.

| 검증 대상 | 더블을 주입하는 곳 |
| --- | --- |
| HTTP 기반 Remote | `HTTPTransport` |
| `UserDefaults` 기반 Store | 격리된 suite로 만든 `UserDefaultsStore` |
| Keychain 기반 Store | 테스트 전용 접근 그룹으로 만든 `KeychainStore` |
| Composition Adapter | 그 어댑터가 받는 Data 구체 타입이 의존하는 위 계약 |

## 예시

`ProjectRemote`의 동작을 검증할 때 별도의 remote 프로토콜과 그 스텁을 만들지
않고, `StubHTTPTransport`를 주입합니다.

```swift
let transport = StubHTTPTransport(responses: [...])
let remote = ProjectRemote(client: HTTPClient(transport: transport), accessTokenProvider: { nil })
```

이 구성은 요청 경로·헤더·본문과 응답 디코딩까지 함께 검증합니다. 그런 프로토콜 스텁은
그중 어느 것도 검증하지 못합니다.

Composition Adapter 테스트도 같은 구성을 씁니다. 어댑터가 받는 Data 구체 타입을 실제로
만들고 그 아래 전송 계층에만 더블을 둡니다. 어댑터의 DTO→Domain 변환과 오류 재매핑이
실제 응답을 지나 검증됩니다.

## 예외

근거 A 또는 B를 이미 충족해 존재하는 프로토콜에는 자유롭게 더블을 만듭니다. 이 규칙은
**더블을 만들기 위해 프로토콜을 새로 추가하는 것**만 금지합니다.
