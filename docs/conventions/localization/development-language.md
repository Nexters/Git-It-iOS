# 개발 언어와 빌드 설정

[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.

**모든 Tuist 프로젝트의 개발 언어는 `ko`입니다.**
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `Project.Options`가
`developmentRegion: "ko"`와 `defaultKnownRegions: ["ko", "Base"]`를 소유합니다.

기기 언어가 지원 언어가 아니면 개발 언어(`ko`)로 대체됩니다. 따라서 어떤 기기 언어에서도 키나 빈
문자열이 보이지 않아야 합니다.

**카탈로그를 가진 target은 `STRING_CATALOG_GENERATE_SYMBOLS = YES`, `SWIFT_EMIT_LOC_STRINGS = NO`입니다.**
프레임워크는 `Target+Module.swift`의 `module(...)`, 앱은 `AppModuleName.swift`가 설정을 소유합니다.

- 카탈로그 리소스 선언은 target의 manifest가 소유합니다. `Feature`는 `FeatureModuleName.swift`가
  `*/Resources/**`를 리소스로 선언합니다.
- Tuist 리소스 합성기가 만드는 문자열 접근자는 쓰지 않습니다. `ProjectName.swift`의
  `resourceSynthesizers`에서 `.strings()`를 제외합니다.
