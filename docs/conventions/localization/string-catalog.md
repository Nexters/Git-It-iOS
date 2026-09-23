# String Catalog

[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.

**형식은 String Catalog(`.xcstrings`)입니다.** `.strings`·`.stringsdict`를 새로 만들지 않습니다.

**카탈로그는 문구를 쓰는 target이 소유하며 그 target의 `Resources/`에 둡니다.**

| target | 경로 | 테이블 이름 |
| --- | --- | --- |
| `UIComponent` | `UI/Component/Resources/Localizable.xcstrings` | `Localizable` |
| `Feature` | `Feature/<흐름>/Resources/<흐름>.xcstrings` | 흐름 이름 |
| `GitIt` | `App/GitIt/Resources/Localizable.xcstrings` | `Localizable` |

`Feature`는 target이 하나이므로 흐름마다 테이블 하나를 둡니다. 흐름 안의 `<흐름>/Shared/`·화면
폴더가 쓰는 문구도 그 흐름 테이블에 둡니다. 둘 이상의 흐름이 같은 용도로 쓰는 문구가 생기면
`Feature/Shared/Resources/Shared.xcstrings`를 만들고
[형태 어휘 표](../file-vocabulary/shape-vocabulary.md)에 행을 추가합니다.

- 다른 target의 카탈로그나 번들을 조회하지 않습니다. Feature는 UIComponent 문구를, App은 Feature
  문구를 참조하지 않습니다.
- `sourceLanguage`는 `ko`입니다. 지원 언어는 현재 `ko`뿐이며 다른 언어 값을 미리 만들지 않습니다.
- 모든 항목은 수동 관리 항목(`extractionState: manual`)입니다. 컴파일러 추출 항목을 두지 않습니다.
- 카탈로그는 Xcode String Catalog 편집기로 편집하는 것을 기본으로 합니다. 직접 편집했다면 Xcode가
  저장한 JSON 형식을 유지합니다.
- 쓰이지 않게 된 항목은 호출부를 지우는 같은 커밋에서 삭제합니다.
