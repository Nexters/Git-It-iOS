# 검증

[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.

**표시 문구를 검증하는 테스트는 키가 아니라 한국어 최종 문구를 기대값으로 삼습니다.** 조회에
실패하면 키가 반환되어 테스트가 실패해야 합니다.

**카탈로그를 가진 target마다 대표 항목이 한국어로 조회되는지 검증하는 테스트를 둡니다.** 위치는
`Tests/<역할>/Localization/LocalizedTextTests.swift`이며, 고정 항목 하나와 보간 항목 하나를
검증합니다. 테스트 이름과 구성은 [테스트 컨벤션](../test.md)을 따릅니다.

**리뷰는 다음 검사 결과가 [제외 대상](./exclusion.md)뿐인지 확인합니다.**

```sh
grep -rn '"[^"]*[가-힣]' --include='*.swift' \
  sources/Projects/UI sources/Projects/Feature sources/Projects/App \
  | grep -v '/Tests/' | grep -v '/Previews/' | grep -v '/Derived/'
```

자동 누락 검출과 pre-commit·CI 강제는 이 컨벤션의 범위 밖입니다.
