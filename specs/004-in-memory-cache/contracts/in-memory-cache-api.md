# 계약: `InfrastructureCache` 공개 API

**날짜**: 2026-08-15 | **명세**: [spec.md](../spec.md) |
**데이터 모델**: [data-model.md](../data-model.md) | **조사**: [research.md](../research.md)

`InfrastructureCache` target이 Composition Adapter(또는 다른 Infrastructure API를 조립하는
쪽)에게 제공하는 인터페이스입니다. 아래 서명은 구현 지침이며, 상태 전이와 검증 규칙은
데이터 모델을 정본으로 합니다.

## 공개 표면

최상위 공개 타입은 1개뿐입니다. 명세가 요구하지 않는 별도 오류 타입이나 설정 타입은
두지 않습니다(research.md §3, §4).

```swift
public actor InMemoryCache<Key: Hashable & Sendable, Value: Sendable> {

    /// 빈 캐시를 새로 만든다. 다른 인스턴스와 상태를 공유하지 않는다(FR-012).
    public init()

    /// 키에 값을 저장한다. 같은 키에 값이 이미 있으면 새 값으로 교체한다(FR-004).
    public func store(_ value: Value, forKey key: Key)

    /// 키에 저장된 값을 반환한다. 값이 없으면 오류 없이 `nil`을 반환한다(FR-002, FR-003).
    public func value(forKey key: Key) -> Value?

    /// 키에 저장된 값을 제거한다. 값이 없어도 오류 없이 완료된다(FR-005, FR-007).
    public func removeValue(forKey key: Key)

    /// 저장된 모든 값을 제거한다(FR-006).
    public func removeAll()
}
```

## 비노출 보장

- `InMemoryCache`는 `Dictionary`, `NSCache` 등 내부 저장 기술의 구체 타입을 공개 API의
  어떤 서명에도 노출하지 않는다.
- `InMemoryCache`는 Domain 모델, Data DTO 등 다른 패키지가 소유한 타입을 알지 못한다
  (FR-010, FR-011). 값의 형태는 오직 제네릭 매개변수 `Value`로만 표현한다.

## 사용 예시

```swift
let cache = InMemoryCache<String, ProfileSnapshot>()

await cache.store(snapshot, forKey: "profile-\(userID)")

if let cached = await cache.value(forKey: "profile-\(userID)") {
    // 저장된 값을 사용한다.
}

await cache.removeValue(forKey: "profile-\(userID)")
await cache.removeAll()
```
