# 자산과 생성물

[Git It iOS 디렉터리·파일 컨벤션](../directory-file.md)의 규칙 문서입니다.

- 자산은 소스 루트 아래 `Resources/`가 소유합니다. Swift 소스와 같은 형태 폴더에 섞지
  않습니다.
- String Catalog(`*.xcstrings`)는 예외로 `Resources/`가 아니라 문구 조회 진입점 `LocalizedText`와 같은 `Localization/`에 두며, 배치와 형식은
  [현지화 컨벤션 §3.1](../localization.md#31-string-catalog)이 소유합니다.
- `*.xcassets` 내부 폴더 구조는 Xcode 자산 카탈로그가 소유하므로 §2의 뎁스 규칙을
  적용하지 않습니다.
- 서드파티가 배포한 폰트 폴더는 배포 구조를 그대로 보존한 채 `Resources/Fonts/` 아래에
  둡니다.
- `Derived/`, `build/`, `*.xcodeproj`는 Tuist 생성물이므로 손으로 만들거나 옮기지
  않습니다.
