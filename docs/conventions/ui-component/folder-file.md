# 폴더와 파일

[Git It iOS UIComponent 컨벤션](../ui-component.md)의 규칙 문서입니다.

- `UI/Component/`의 1뎁스는 §3.2의 역할 폴더, 여러 역할 폴더의 컴포넌트가 채택하는 시각 속성
  계약을 두는 `Contracts/`와 `Resources/`뿐입니다. `Components/` 같은 target 이름을 반복하는
  중간 폴더를 두지 않습니다.
- 컴포넌트 파일과 타입 이름은 표현 대상을 사용하고 `View` 접미어를 붙이지 않습니다.
- **컴포넌트 하나는 파일 하나입니다.** 컴포넌트의 공개 계약과 렌더링 규칙을 한 파일에서
  읽을 수 있도록, 컴포넌트에 딸린 선언을 모두 `<역할 폴더>/<컴포넌트>.swift`에 둡니다.
  - 중첩 타입(`Style`, `Size`, `DisplayModel`, `StateModel`, `Item`, `Constant` 등)을
    `{컴포넌트}+{중첩타입}.swift`로 나누지 않습니다.
  - 중첩할 수 없어 최상위로 꺼낸 보조 타입(`TabShellItem`)과 그 컴포넌트 전용 프리뷰
    타입(`TabShellPreviewItem`)도 같은 파일의 최상위에 둡니다. 이것은
    [파일 하나에 타입 하나](../file-vocabulary/one-type-per-file.md) 규칙의 UIComponent 예외입니다.
  - 따라서 `UI/Component/`에는
    [타입 패밀리 폴더](../directory-file.md#5-2뎁스--타입-패밀리-폴더)를 만들지 않습니다.
- 두 컴포넌트가 함께 쓰는 선언이 필요하면 한 컴포넌트에 중첩해 공유하지 말고, 각 컴포넌트가
  자기 선언을 중첩합니다. 제네릭 컴포넌트에 중첩한 타입은 제네릭 인자마다 다른 타입이 되어
  공유할 수 없기 때문입니다(`SelectionCard.Style`과 `SelectionCardList.Style`).

```text
UI/Component/
└── Scaffolds/
    ├── BottomActionBar.swift   # BottomActionBar와 중첩 Constant
    └── TabShell.swift          # TabShell, TabShellItem, TabShellPreviewItem
```
