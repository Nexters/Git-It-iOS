# 기존 타입 확장

[Git It iOS 파일·형태 어휘 컨벤션](../file-vocabulary.md)의 규칙 문서입니다.

프로젝트 밖 타입이나 다른 형태의 타입을 확장하는 파일은 `{확장 대상}+{주제}.swift`를
사용합니다.

```text
Extensions/View+ColorToken.swift
Models/HTTPRequest+QueryItem.swift
```

`+` 뒤에는 그 파일이 추가하는 개념을 씁니다. `Extension`, `Helper`, `Utils` 같은
포괄어를 뒤에 붙이지 않습니다.
