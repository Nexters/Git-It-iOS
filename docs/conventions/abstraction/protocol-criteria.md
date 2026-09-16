# 두 가지 근거

[Git It iOS 추상화 컨벤션](../abstraction.md)의 규칙 문서입니다.

프로젝트가 소유한 타입에 프로토콜을 두는 근거는 다음 둘뿐입니다.

## 근거 A — 패키지 경계를 넘는 계약이다

한 패키지가 요구하는 기능을 다른 패키지가 제공하고, 요구하는 쪽이 제공하는 쪽의 구체
타입을 알아서는 안 되는 경우입니다. 의존 방향을 뒤집기 위해 요구하는 쪽이 계약을
소유합니다.

```swift
// Domain이 소유하고 Composition Adapter가 채택한다
public protocol LearningProjectRepository: Sendable { ... }

// Infrastructure가 소유하고 Data가 사용한다
public protocol HTTPTransport: Sendable { ... }
```

경계를 넘더라도 **의존 방향을 뒤집을 필요가 없으면** 근거 A가 아닙니다. Composition이
Data의 구체 타입을 직접 받는 것은 아키텍처가 허용하는 방향이므로, 그 사이에 프로토콜을
두지 않습니다.

## 근거 B — 구현을 교체하는 지점이 프로덕션에 실재한다

같은 계약에 대해 둘 이상의 구현이 프로덕션 코드에 존재하고, 실행 환경이나 조립 결정에
따라 고르는 경우입니다.

"언젠가 교체할 수도 있다"는 예상은 근거가 아닙니다. 지금 저장소에 구현이 둘 이상
있거나, 이 변경으로 둘이 되는 것이 확정된 경우만 해당합니다.

## 판정

- 근거 A 또는 B 중 하나를 충족하면 프로토콜을 둡니다.
- 둘 다 아니면 구체 타입 하나만 만듭니다.
- 판정이 갈리면 구체 타입 쪽을 고릅니다. 나중에 근거가 생기면 그때 프로토콜을 추출하는
  비용이, 쓰이지 않는 추상화를 유지하는 비용보다 작습니다.

## 예시

| 타입 | 판정 | 근거 |
| --- | --- | --- |
| `HTTPTransport` | 둔다 | 근거 A — Infrastructure가 소유하고 Data가 사용한다 |
| `LearningProjectRepository` | 둔다 | 근거 A — Domain이 소유하고 Composition이 채택한다 |
| `ProjectRemote` | 두지 않는다 | Data 안에서만 쓰이고 구현이 하나다. Composition은 이 구체 타입을 직접 받는다 |
| `LocalPolicyConsentStore` | 두지 않는다 | 같음 |
