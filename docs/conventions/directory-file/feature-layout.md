# Feature 패키지의 흐름 배치

[Git It iOS 디렉터리·파일 컨벤션](../directory-file.md)의 규칙 문서입니다.

**Feature 패키지는 흐름을 §3.2의 관심사 세그먼트로 두고, 그 아래 1뎁스는 형태가 아니라
흐름을 이루는 *단위*입니다.** Feature 패키지는 target 하나가 모든 흐름을 담으므로
소스 루트는 `Feature/` 자체이고, 뎁스는 흐름 세그먼트 아래부터 셉니다. 화면마다 소유자가 다른데 형태 폴더(`Screens/`,
`Reducers/`)로 나누면 한 화면을 읽는 데 필요한 파일이 형태별로 흩어지기 때문입니다.

```text
sources/Projects/Feature/ProjectRegistration/
├── Router/
│   ├── ProjectRegistrationRouter.swift            # View
│   ├── ProjectRegistrationRouterFeature.swift
│   ├── SubViews/
│   └── Previews/
│       └── ProjectRegistrationRouterPreviews.swift
├── RepositoryConfirmation/
│   ├── RepositoryConfirmationScreen.swift
│   ├── RepositoryConfirmationFeature.swift
│   ├── SubViews/
│   │   └── RepositoryConfirmationScreen+ThumbnailView.swift
│   ├── ViewModels/
│   └── Previews/
│       └── RepositoryConfirmationScreenPreviews.swift
├── Previews/
│   └── ProjectRegistrationPreviewSupport.swift
└── Shared/
    ├── Views/
    └── Models/
```

1뎁스에는 다음만 옵니다.

| 1뎁스 | 담는 것 |
| --- | --- |
| `Router/` | Router View, RouterFeature와 활성 화면 값 타입 |
| `<화면>/` | 화면 하나와 그 화면이 조합하는 Feature |
| `Previews/` | 여러 화면의 프리뷰가 함께 쓰는 프리뷰 전용 타입 |
| `Shared/` | 여러 화면이 함께 쓰는 선언 — 이 아래에서만 형태 폴더를 씁니다 |
| `Resources/` | 흐름이 소유하는 자산 (§6) |

- **화면 폴더는 Screen 하나와 그 화면이 조합하는 Feature를 담습니다.** 화면과 Feature는
  1:1이 아니며, Feature의 정의 단위가 관심사라는 근거는
  [TCA Feature 컨벤션 — 정의 단위 — 관심사](../tca/feature/definition-unit.md)가 소유합니다.
- 폴더 이름은 화면 이름에서 `Screen`·`Feature` 접미어를 뗀 이름입니다
  (`RepositoryConfirmationScreen` → `RepositoryConfirmation/`).
- **화면 폴더와 `Router/`의 루트에는 그 화면의 View·Feature와 그들이 직접 소유하는 값
  타입만 둡니다.** 서브뷰·표시 모델·프리뷰는 아래 역할 폴더로 내립니다. 폴더를 열었을
  때 그 화면이 무엇인지 먼저 보이게 하고, 서브뷰와 프리뷰가 늘어나도 루트가 덮이지 않게
  하기 위한 것입니다.

  | 역할 폴더 | 담는 것 |
  | --- | --- |
  | `SubViews/` | `{화면}+{서브뷰}.swift` — 화면 전용 서브뷰 ([View 컨벤션 — 화면 전용 서브뷰](../view/screen-subview.md)) |
  | `ViewModels/` | 화면이 Feature `State`에서 파생해 서브뷰에 넘기는 표시 모델과 그 계산 타입 |
  | `Previews/` | 그 화면의 프리뷰 |

  담을 것이 없는 역할 폴더는 만들지 않습니다. 역할 폴더는 이 세 개가 전부이며 그 아래를
  다시 나누지 않습니다.
- **화면이 둘 이상인 흐름에는 `Router/`가 있습니다.** Router를 언제 두는지, 흐름의
  두 종류와 그 구성 규칙은
  [TCA Navigation 컨벤션 — Router-Feature와 화면 전환 소유](../tca/navigation/router.md)이
  소유합니다. 이 문서는 그 파일이 놓이는 자리만 정합니다.
- **자신의 화면을 갖지 않고 `Router/`만 있는 흐름이 있을 수 있습니다.** Router가 다른
  target의 흐름을 조합하는 경우이며, `MainShell`이 그 예입니다. 이때 흐름 폴더에는
  화면 폴더가 없습니다.
- **활성 화면 값 타입은 `Router/`에 둡니다.** 순차 흐름의 계층형 enum과 셸 흐름의 탭
  enum(`MainShellTab`) 모두 Router가 소유하는 상태이므로 형태 폴더(`Models/`)로 빼지
  않습니다.
- **Router View와 Router Feature는 같은 `Router/`에 둡니다.** 타입 이름은 흐름 이름을
  접두어로 갖고(`ProjectRegistrationRouter`, `ProjectRegistrationRouterFeature`),
  폴더 이름은 역할인 `Router/`를 씁니다. Router View가 무엇을 소유하는지는 위 Navigation
  컨벤션 §2.3이 정합니다.
- `Shared/`는 여러 화면이 함께 쓰는 선언만 담습니다. 한 화면만 쓰는 선언을 여기에 두지
  않습니다. `Shared/` 아래에서는 §4.2의 형태 폴더 규칙을 그대로 적용합니다.
- **기능 Feature는 그것을 합성하는 범위로 자리를 정합니다.** 한 화면만 합성하면 그 화면
  폴더 루트, 한 전환 계층(Router·Shell)만 합성하면 그 흐름의 `Router/`, 같은 흐름의 둘 이상
  화면이 합성하면 `<흐름>/Shared/Reducers/`, 둘 이상 흐름이 합성하면 `Feature/Shared/Reducers/`에
  둡니다. 둘 이상 흐름이 쓰는 값 타입은 `Feature/Shared/Models/`에 둡니다. 한 파일을 넘는 기능
  Feature는 [타입 패밀리 규칙](./type-family-rules.md)에 따라 타입 패밀리 폴더를 만듭니다.

  | 합성 범위 | 자리 |
  | --- | --- |
  | 한 화면 | `Feature/<흐름>/<화면>/` |
  | 한 전환 계층 | `Feature/<흐름>/Router/` |
  | 같은 흐름의 둘 이상 화면 | `Feature/<흐름>/Shared/Reducers/` |
  | 둘 이상 흐름 | `Feature/Shared/Reducers/` |

- **참조 방향은 전환 계층 → 화면 → 공용의 한 방향입니다.** `Feature/Shared/**`는 흐름
  디렉터리의 타입을 참조하지 않고, `Shared/Reducers/`에는 View를 두지 않습니다. 기능 상태를
  렌더링하는 View는 그 기능 Feature를 합성하거나 관찰하는 화면 폴더에 남습니다.
- **화면 폴더의 Screen은 공용 기능 Feature를 직접 관찰할 수 있습니다.** 관심사가 하나뿐인
  화면은 화면 합성 Feature 없이 공용 기능 Feature의 store를 받아 렌더링하며, 이때 그 화면
  폴더에는 Feature 파일이 없을 수 있습니다(`Onboarding/LegalAgreement/`는
  `Feature/Shared/Reducers/LegalAgreementFeature.swift`를 관찰하는 `LegalAgreementScreen`만
  둡니다).
- **프리뷰는 언제나 `Previews/` 폴더로 분리합니다.** 한 화면의 프리뷰는 그 화면 폴더의
  `Previews/`에, 여러 화면의 프리뷰가 함께 쓰는 프리뷰 전용 지원 타입은 흐름 1뎁스의
  `Previews/`에 둡니다. 프리뷰는 구현이 아니라 검토용 산출물이고 화면 하나가 상태
  조합마다 여러 프리뷰를 가지므로 구현 파일과 섞지 않습니다
  ([View 컨벤션 — 프리뷰](../view/preview.md)).
- test 소스 루트도 같은 축을 미러링합니다 — `Tests/<흐름>/<화면>/`. 역할 폴더는 검증 대상이 있는 것만
  만듭니다(`Tests/Home/Home/ViewModels/`).

이 배치는 Feature 패키지에만 적용합니다. 다른 패키지의 1뎁스는 §4.1·§4.2의 형태
폴더입니다.

흐름 폴더를 추가하거나 옮겨도 Tuist 매니페스트는 바꾸지 않습니다. `Feature` target의
`sourceDirectory`는 패키지 루트 하나이며 흐름별 glob을 갖지 않습니다(§7).
