# Git It iOS 컨벤션

이 디렉터리는 패키지와 기능을 가로질러 반복 적용하는 작성·구현 규칙의 정본을
관리합니다. 패키지의 책임과 허용 의존성은 `package-rules/`가 소유하고, 구체적인 작성
방식은 이 디렉터리의 컨벤션이 소유합니다.

| 문서 | 소유하는 규칙 |
| --- | --- |
| [공통 원칙](./common/README.md) | 문서 우선순위, 추상·구체 계층과 문서 형식, 구체 구현 배제, 문서 간 참조 |
| [추상화](./abstraction.md) | 프로토콜을 두는 근거, 테스트 더블 주입 지점 |
| [네이밍](./naming.md) | 공개 이름, 경계 값, 접두어·접미어와 외부 고정 명칭 |
| [디렉터리·파일](./directory-file.md) | 소스 루트, 폴더 뎁스와 관심사 세그먼트, Feature 흐름 배치, 자산·매니페스트 일치 |
| [파일·형태 어휘](./file-vocabulary.md) | 파일당 타입 개수, 파일 이름 규칙, 패키지별 형태 폴더 어휘 |
| [테스트](./test.md) | 프레임워크, 테스트 이름·구성, Test Double과 target 배치 |
| [View](./view.md) | SwiftUI 공개 생성 경로, 화면 조립, 화면 전용 서브뷰와 프리뷰 |
| [View 토큰](./view-tokens.md) | 색상·레이아웃·Typography 토큰 사용 규칙 |
| [View 내부 선언](./view-declarations.md) | `Constant`·`Style` 등 View 내부 선언의 정의 위치, 접근 수준과 소유 판정 |
| [UIComponent](./ui-component.md) | 컴포넌트 경계, 공개 입력, 파일·자산 구성과 검증 |
| [현지화](./localization.md) | 사용자 노출 문구의 카탈로그, 키, `LocalizedText` 조회 진입점과 제외 대상 |
| [TCA](./tca/README.md) | TCA 핵심 용어, 제약조건과 하위 문서 안내 |

## 문서 구조

각 주제 컨벤션 파일은 **인덱스**입니다. `##`에 추상 원칙을 서술하고, `###` 아래에는
구체 명시 문서로 가는 링크만 둡니다. 구체 명시는 같은 이름의 하위 디렉터리에 문서
하나씩 있으며, 작업 중에 실제로 열어 보는 참고 단위입니다.

```text
docs/conventions/
├── common/          # 모든 컨벤션에 공통으로 적용하는 원칙
├── abstraction.md   # 인덱스 — ## 추상 원칙 + ### 링크
├── abstraction/     # 참고 단위 — 규칙 하나당 문서 하나
│   ├── protocol-criteria.md
│   └── ...
├── naming.md        # 인덱스 — ## 추상 원칙 + ### 링크
├── naming/          # 참고 단위 — 규칙 하나당 문서 하나
│   ├── responsibility-first.md
│   └── ...
└── tca/
    ├── README.md    # TCA 진입점
    ├── feature.md   # 인덱스
    └── feature/     # 참고 단위
```

이 구조와 `##`·`###` 계층 규칙의 정본은
[컨벤션 공통 원칙 — 추상 원칙과 구체 명시의 계층](./common/document-structure.md)입니다.
