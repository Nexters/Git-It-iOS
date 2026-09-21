# 중첩할 수 없는 타입

[Git It iOS 파일·형태 어휘 컨벤션](../file-vocabulary.md)의 규칙 문서입니다.

프로토콜처럼 Swift 제약으로 중첩할 수 없거나, 제네릭 타입에 중첩하면 호출부가 제네릭
인자를 적어야 하는 선언은 최상위에 두고 이름에 소유 타입을 남깁니다
([View 내부 선언 컨벤션 — 중첩할 수 없는 경우](../view-declarations/non-nestable.md)). UIComponent는
소유 컴포넌트와 같은 파일에 두고([UIComponent 컨벤션 — 폴더와 파일](../ui-component/folder-file.md)),
그 밖의 패키지는 별도 파일로 나눠 소유 타입의 패밀리 폴더에 둡니다.

```text
Scaffolds/
└── TabShell.swift   # TabShell, TabShellItem(protocol이라 중첩 불가), TabShellPreviewItem(프리뷰 전용)
```
