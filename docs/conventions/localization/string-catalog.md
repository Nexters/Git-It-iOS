# String Catalog

[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.

**형식은 String Catalog(`.xcstrings`)입니다.** `.strings`·`.stringsdict`를 새로 만들지 않습니다.

**카탈로그는 문구를 쓰는 target마다 `Localizable.xcstrings` 하나이며, 그 target의 `LocalizedText`와
같은 `Localization/` 폴더에 둡니다.**

| target | 경로 | 테이블 이름 |
| --- | --- | --- |
| `UIComponent` | `UI/Component/Localization/Localizable.xcstrings` | `Localizable` |
| `Feature` | `Feature/Shared/Localization/Localizable.xcstrings` | `Localizable` |
| `GitIt` | `App/GitIt/Localization/Localizable.xcstrings` | `Localizable` |

`Feature`는 모든 흐름의 문구를 한 카탈로그에 둡니다. 흐름 구분은 카탈로그가 아니라
`LocalizedText`의 흐름 enum이 맡습니다. 카탈로그를 흐름별로 나누거나 `Resources/`에 두지 않습니다.

- 다른 target의 카탈로그나 번들을 조회하지 않습니다. Feature는 UIComponent 문구를, App은 Feature
  문구를 참조하지 않습니다.
- `sourceLanguage`는 `ko`입니다. 지원 언어는 현재 `ko`뿐이며 다른 언어 값을 미리 만들지 않습니다.
- 모든 항목은 수동 관리 항목(`extractionState: manual`)입니다. 컴파일러 추출 항목을 두지 않습니다.
- 카탈로그는 Xcode String Catalog 편집기로 편집하는 것을 기본으로 합니다. 직접 편집했다면 Xcode가
  저장한 JSON 형식을 유지합니다.
- 쓰이지 않게 된 항목은 호출부를 지우는 같은 커밋에서 삭제합니다.
