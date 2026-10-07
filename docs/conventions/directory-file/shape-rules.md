# 규칙

[Git It iOS 디렉터리·파일 컨벤션](../directory-file.md)의 규칙 문서입니다.

- 형태 폴더는 담는 파일이 **하나뿐이어도 만듭니다.** 모든 target에서 같은 경로로 같은
  종류를 찾을 수 있어야 합니다.
- 이름은 그 종류를 나타내는 **복수형 영문 명사**를 PascalCase로 씁니다.
  (`Models`, `Contracts`, `UseCases`, `Errors`, `Tokens`, `TestDoubles`)
- 표준 약어는 [네이밍 컨벤션 — 축약과 약어](../naming/abbreviation.md)을 따르고 복수형 `s`만
  소문자로 붙입니다. (`DTOs` ○ / `DTOS` ×, `Dtos` ×)
- 형태 어휘는 자유롭게 늘리지 않습니다.
  [파일·형태 어휘 컨벤션 — 패키지별 형태 어휘](../file-vocabulary/shape-vocabulary.md)의 표에 없는
  형태 폴더를 추가하려면 같은 PR에서 그 표를 함께 갱신합니다.
