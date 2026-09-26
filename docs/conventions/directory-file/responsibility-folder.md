# 책임 이름 폴더

[Git It iOS 디렉터리·파일 컨벤션](../directory-file.md)의 규칙 문서입니다.

메인 타입이 없지만 하나의 외부 계약이나 한 가지 책임에 함께 속하는 파일이 둘 이상이면
**책임 이름**의 폴더를 사용할 수 있습니다. 같은 API 연산의 요청·응답 DTO 묶음이
대표적입니다.

```text
DTOs/
└── Example/
    ├── CreateExampleRequestDTO.swift
    ├── CreateExampleResponseDTO.swift
    ├── UpdateExampleRequestDTO.swift
    └── UpdateExampleResponseDTO.swift
```

책임 이름 폴더는 형태 폴더의 대체물이 아닙니다. 묶으려는 파일들의 **형태가 서로
다르면** 폴더로 묶을 것이 아니라 각자의 형태 폴더로 나눕니다.

파일 하나에 타입을 몇 개 담을 수 있는지, 파일 이름 규칙과 형태 폴더 이름의 어휘
목록은 [파일·형태 어휘 컨벤션](../file-vocabulary.md)이 소유합니다.
