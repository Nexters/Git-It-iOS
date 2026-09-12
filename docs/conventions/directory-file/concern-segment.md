# 관심사 세그먼트

[Git It iOS 디렉터리·파일 컨벤션](../directory-file.md)의 규칙 문서입니다.

하나의 target이 서로 독립적인 관심사를 둘 이상 담고 있으면 소스 루트 아래에 **관심사
세그먼트**를 하나 더 두고, 형태·타입 패밀리 뎁스는 그 아래에서 셉니다.

```text
sources/Projects/Infrastructure/Authentication/Keychain/Stores/
                 └────────────────────────────┘ └──────┘ └────┘
                          소스 루트              관심사   1뎁스
```

Infrastructure는 하나의 기술 능력 target이 여러 하위 능력을 담을 수 있으므로 관심사
세그먼트를 기본으로 사용합니다. `Authentication` target의 Apple 인증·Keychain·난수는
서로 대체되지 않는 기술 능력이며, target을 쪼개지 않고 관심사 세그먼트로 구분합니다.

여러 관심사가 함께 쓰는 선언은 `Shared` 관심사 세그먼트에 모으고, 그 아래에서도 형태
폴더 규칙을 그대로 적용합니다(`Feature/Shared/Models/`). `Shared`는 관심사 세그먼트
자리에서만 쓸 수 있고 형태 폴더 이름으로는 쓰지 않습니다(§4.1).

관심사 세그먼트는 **target 분리를 미루기 위한 수단이 아닙니다.** 새 관심사가 생기면
target 분리를 먼저 검토하고, 분리하지 않기로 했다면 그 이유를 PR에 남깁니다. 관심사
세그먼트는 한 단계만 허용하며 중첩하지 않습니다.
