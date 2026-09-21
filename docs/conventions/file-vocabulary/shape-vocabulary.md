# 패키지별 형태 어휘

[Git It iOS 파일·형태 어휘 컨벤션](../file-vocabulary.md)의 규칙 문서입니다.

아래 표가 형태 폴더 이름의 정본입니다. Feature 패키지의 1뎁스는 형태가 아니라 흐름의
단위 폴더이므로 [디렉터리·파일 컨벤션 — Feature 패키지의 흐름 배치](../directory-file/feature-layout.md)을
따르며, 표에는 그 단위 폴더를 함께 적습니다. 표에 없는 형태를
추가하려면 같은 PR에서 이 표를 갱신합니다. 형태 폴더를 판단하는 기준 자체는
[디렉터리·파일 컨벤션 — 1뎁스 — 형태 폴더](../directory-file/shape-criteria.md)을 따릅니다.

| 소스 루트 | 1뎁스 폴더 | 담는 선언 |
| --- | --- | --- |
| `Domain/<관심사>/` | `Models/` | 비즈니스 모델과 값 타입 |
| | `Contracts/` | Domain이 외부에 요구하는 계약 프로토콜 |
| | `UseCases/` | 유스케이스 계약과 그 구현 |
| | `Errors/` | Domain 오류 타입 |
| `Data/<관심사>/` | `DTOs/` | 외부 전송 모델 |
| | `Requests/` | 요청 값 타입 |
| | `Endpoints/` | 엔드포인트와 요청 조립 |
| | `Contracts/` | Data가 정의하는 remote·store 계약 |
| | `Remotes/` | 네트워크 계약 구현 |
| | `Sources/` | 외부에서 주입되는 프로세스 내 데이터 소스 구현 |
| | `Stores/` | 로컬 저장 계약 구현 |
| | `Factories/` | 기술 능력 구현 선택과 생성 진입점 |
| | `Clients/` | Data 내부 기술 능력 실제 구현 |
| | `AppDelegates/` | 앱 델리게이트 콜백을 위임하는 타입 |
| | `Parsers/` | 외부 입력 문자열을 내부 모델로 해석하는 구현 |
| | `Codings/` | 저장 형식 인코딩·디코딩 |
| | `Layouts/` | 저장소 key 배치 |
| | `Models/` | Data 내부 모델 |
| | `Errors/` | Data 오류 타입 |
| `Infrastructure/<능력>/[<하위 능력>/]` | `Clients/` | 기술 능력의 공개 진입 타입 |
| | `Transports/` | 전송 계층 계약과 구현 |
| | `Stores/` | 저장 계층 계약과 구현 |
| | `Providers/` | 플랫폼 API를 감싸는 제공자 |
| | `Models/` | 요청·응답·설정 값 타입 |
| | `Errors/` | 기술 오류 타입 |
| | `AppDelegates/` | 플랫폼 생명주기 delegate 타입 |
| `Composition/Adapter/` | `Adapters/` | Domain 계약을 구현하는 Adapter |
| | `Assemblies/` | 조립 진입 타입과 객체 수명 선택 |
| | `Codings/` | 경계 간 인코딩·디코딩 |
| | `Layouts/` | 저장소 키 배치 |
| | `Factories/` | 구현 선택과 생성 |
| `Feature/<흐름>/` | `Router/` | Router View, RouterFeature와 활성 화면 값 타입 |
| | `<화면>/` | 화면 하나와 그 화면이 조합하는 Feature |
| | `Previews/` | 여러 화면의 프리뷰가 함께 쓰는 프리뷰 전용 타입 |
| | `Shared/` | 둘 이상의 화면이 함께 쓰는 선언 — 이 아래에서만 형태 폴더를 씁니다 |
| | `Resources/` | 흐름이 소유하는 자산 |
| `Feature/<흐름>/<화면>/` | `SubViews/` | 그 화면 전용 서브뷰 |
| | `ViewModels/` | 그 화면이 `State`에서 파생하는 표시 모델과 계산 타입 |
| | `Previews/` | 그 화면의 프리뷰 |
| `Feature/<흐름>/Shared/` | `Views/` | 둘 이상의 화면이 함께 쓰는 View |
| | `Models/` | 둘 이상의 화면이 함께 쓰는 표시 모델 |
| | `Reducers/` | 같은 흐름의 둘 이상 화면이 합성하는 기능 Feature |
| `Feature/Shared/` | `Views/` | 둘 이상의 흐름이 함께 쓰는 View |
| | `Models/` | 둘 이상의 흐름이 함께 쓰는 값 타입 |
| | `Reducers/` | 둘 이상의 흐름이 합성하는 기능 Feature — View를 두지 않습니다 |
| `UI/DesignSystem/` | `Tokens/` | 원시·의미 디자인 토큰 |
| | `Layout/` | 화면 크기에서 파생하는 런타임 레이아웃 변수 |
| | `Extensions/` | 토큰 적용 API와 폰트 등록 |
| | `Resources/` | 폰트 자산 |
| `UI/Component/` | 역할 폴더 | [UIComponent 컨벤션 — 컴포넌트 역할 분류](../ui-component.md#3-컴포넌트-역할-분류)이 소유 |
| | `Contracts/` | 여러 역할 폴더가 채택하는 시각 속성 계약 프로토콜 |
| | `Resources/` | 이미지·애니메이션 자산 |
| `UI/ComponentPreviewApp/` | `Catalogs/` | 레이아웃 계약 검토 카탈로그 |
| `App/GitIt/` | `Reducers/` · `Screens/` | 앱 루트 Feature와 화면 |
| | `Configurations/` | 실행 환경과 번들 설정 |
| | `Loaders/` | 번들 리소스 해석 |
| | `Resources/` | 앱 자산과 정책 문서 |
| | `AppDelegates/` | 플랫폼 생명주기 delegate 타입 |
| `Tests/<역할>/` | production과 같은 형태 폴더 | 대상 형태를 그대로 사용 |
| | `TestDoubles/` | 둘 이상의 파일에서 쓰는 Test Double |
| `Feature/Tests/<흐름>/` | `Router/` · `<화면>/` | production의 흐름 축을 그대로 미러링 |

`Mocks/`는 사용하지 않습니다. Stub·Spy·Fake를 모두 포함하는 `TestDoubles/`로 통일합니다.

여러 형태에 걸쳐 있어 하나의 형태로 판정할 수 없는 테스트 — 앱 조립 검증, 민감 값 노출
검사, 생명주기 검증 — 은 형태 폴더가 아니라
[디렉터리·파일 컨벤션 — 소스 루트](../directory-file/test-source-root.md)의 test 소스 루트에
둡니다.
