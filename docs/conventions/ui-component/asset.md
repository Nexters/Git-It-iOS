# 자산

[Git It iOS UIComponent 컨벤션](../ui-component.md)의 규칙 문서입니다.

- 이미지, Lottie 애니메이션과 일러스트레이션처럼 컴포넌트가 렌더링하는 자산은
  `Component/Resources/`가 소유합니다.
- Feature는 자산 이름이나 bundle 탐색을 직접 해석하지 않고 UIComponent의 표현 API를
  사용합니다.
- 컴포넌트 고정 문구는 `Component/Resources/Localizable.xcstrings`가 소유하며, Feature는
  UIComponent 문구를 조회하지 않습니다([현지화 컨벤션 §3.1](../localization.md#31-string-catalog)).
- 폰트와 토큰 카탈로그는 `DesignSystem/`이 소유하며 UIComponent 자산과 섞지 않습니다.
