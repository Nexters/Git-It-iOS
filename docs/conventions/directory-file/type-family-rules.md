# 규칙

[Git It iOS 디렉터리·파일 컨벤션](../directory-file.md)의 규칙 문서입니다.

한 메인 타입에 딸린 파일이 **둘 이상일 때만** 그 타입 이름의 폴더를 만들고 파일을
모읍니다. 파일이 하나면 폴더를 만들지 않고 형태 폴더에 직접 둡니다.

```text
Controls/
├── ActionButton.swift              # 파일이 하나이므로 폴더를 만들지 않는다
└── TextField/
    ├── TextField.swift
    └── TextField+Style.swift
```

타입 패밀리 폴더에 함께 두는 파일은 다음과 같습니다.

- 메인 타입 파일
- 중첩 타입을 분리한 `{메인타입}+{중첩타입}.swift`
- 중첩할 수 없어 최상위로 꺼낸 보조 타입
- 그 메인 타입 전용 프리뷰 타입

파일 이름 규칙은 [파일·형태 어휘 컨벤션 — 파일 규칙](../file-vocabulary.md#2-파일-규칙)이 소유합니다.

두 타입이 공유하는 보조 타입은 **이름을 소유한 타입**의 패밀리 폴더에 둡니다. 예를
들어 `SelectionCardStyle`은 `SelectionCard`와 `SelectionCardList`가 함께 쓰더라도
`SelectionCard/`에 둡니다.

폴더 이름은 메인 타입 이름을 그대로 씁니다. Feature 패키지의 흐름 배치는 §4.3의
별도 규칙을 따릅니다.
