# 중첩할 수 없는 타입

[Git It iOS 파일·형태 어휘 컨벤션](../file-vocabulary.md)의 규칙 문서입니다.

프로토콜처럼 Swift 제약으로 중첩할 수 없거나, 제네릭 타입에 중첩하면 호출부가 제네릭
인자를 적어야 하는 선언은 최상위에 두고 이름에 소유 타입을 남깁니다
([View 내부 선언 컨벤션 — 중첩할 수 없는 경우](../view-declarations/non-nestable.md)). 파일은
소유 타입과 같은 파일에 둡니다.

```text
Scaffolds/
└── TabShell.swift   # TabShell, TabShellItem(protocol이라 중첩 불가), TabShellPreviewItem(프리뷰 전용)
```
