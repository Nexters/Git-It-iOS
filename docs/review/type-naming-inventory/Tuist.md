# Tuist 패키지 타입 목록

[인덱스로 돌아가기](README.md) · [단어 사전](glossary.md)

타입 3개, 관심사 폴더 1개. 항목은 파일 경로와 선언 줄 순서다. 각 항목은 `이름` 종류 · 접근 수준 · 파일 링크, 한 줄 설명, 그리고 이름을 이루는 단어와 정의로 구성된다.

| 종류 | 개수 |
|---|---|
| enum | 3 |

## Tuist/ProjectDescriptionHelpers/Projects

- **`ExternalDependenciesName`** `enum` · internal · [ExternalDependenciesName.swift:5](../../../sources/Tuist/ProjectDescriptionHelpers/Projects/ExternalDependenciesName.swift#L5) · 채택: String  
  Tuist manifest에서 사용하는 외부 패키지 의존성 이름(ComposableArchitecture, FirebaseCore, FirebaseMessaging, Lottie)을 String raw value로 고정한 열거형이다. 같은 파일의 TargetDependency.external(_:) 확장이 이 값을 받아 .external(name:) 의존성으로 변환하며, App·Feature·Infrastructure·UI 모듈 manifest에서 외부 의존성을 선언할 때 사용된다.  
  단어: `External` 외부의·바깥의. 여기서는 프로젝트 내부 패키지가 아닌 Tuist Package.swift로 가져오는 외부(서드파티) 의존성을 가리킨다. · `Dependencies` 의존성(복수). 여기서는 target이 링크하는 외부 라이브러리 목록을 가리킨다. · `Name` 이름. 여기서는 Tuist의 .external(name:)에 넘기는 외부 의존성 식별 문자열을 가리킨다.
- **`DesignSystemFontFamily`** `enum` · private · [UIModuleName.swift:28](../../../sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift#L28) · 채택: CaseIterable  
  UI 패키지의 DesignSystem target에 번들할 폰트 패밀리(notoSansKR, plusJakartaSans)를 열거하고, 각 패밀리의 폴더 이름(directoryName)과 PostScript 이름 접두어(postScriptNamePrefix)로 Resources/Fonts 아래 static .ttf 파일의 glob 패턴(resourceFileElements)을 만든다. UIModuleName.designSystemFontResources가 allCases를 flatMap해 DesignSystem target의 resources로 사용한다.  
  단어: `Design` 디자인·설계. 여기서는 앱의 시각 디자인 규칙을 담는 DesignSystem 모듈을 가리키는 앞부분이다. · `System` 체계·시스템. Design과 결합해 색·타이포·폰트 등 디자인 토큰을 모아둔 DesignSystem target을 가리킨다. · `Font` 글꼴. 여기서는 DesignSystem target 리소스로 번들되는 .ttf 글꼴 파일을 가리킨다. · `Family` 가족·계열. 여기서는 Noto Sans KR, Plus Jakarta Sans처럼 여러 굵기를 묶는 글꼴 패밀리 단위를 가리킨다.
- **`DesignSystemFontFamily.Weight`** `enum` · private · [UIModuleName.swift:62](../../../sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift#L62) · 채택: String, CaseIterable  
  DesignSystemFontFamily 안에 중첩된 글꼴 굵기 열거형으로, regular·medium·bold 세 case의 raw value("Regular"·"Medium"·"Bold")가 .ttf 파일 이름의 접미어가 된다. resourceFileElements가 Weight.allCases를 순회해 패밀리별 세 굵기의 static 폰트 파일 glob 패턴을 생성한다.  
  단어(단일): `Weight` 무게·굵기. 여기서는 번들할 글꼴 파일의 굵기(Regular, Medium, Bold)를 가리킨다.
