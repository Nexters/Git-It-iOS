# 폴더와 파일

[Git It iOS UIComponent 컨벤션](../ui-component.md)의 규칙 문서입니다.

- 폴더 뎁스와 타입 패밀리 폴더는
  [디렉터리·파일 컨벤션 — 2뎁스 — 타입 패밀리 폴더](../directory-file.md#5-2뎁스--타입-패밀리-폴더)를,
  파일당 타입 개수와 파일 이름 규칙은
  [파일·형태 어휘 컨벤션 — 파일 규칙](../file-vocabulary.md#2-파일-규칙)를 따릅니다.
- `UI/Component/`의 1뎁스는 §3.2의 역할 폴더와 `Resources/`뿐입니다. `Components/`
  같은 target 이름을 반복하는 중간 폴더를 두지 않습니다.
- 컴포넌트 파일과 타입 이름은 표현 대상을 사용하고 `View` 접미어를 붙이지 않습니다.

```text
UI/Component/
└── Scaffolds/
    └── BottomActionBar/
        ├── BottomActionBar.swift
        └── BottomActionBar+Constant.swift
```
