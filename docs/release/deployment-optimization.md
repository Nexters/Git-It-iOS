# 배포 최적화 — 적용분과 보류분

## 적용 완료

| 항목 | 효과 | 검증 방법 |
| --- | --- | --- |
| 라이브러리 진화 해제 (`BUILD_LIBRARY_FOR_DISTRIBUTION = NO`) | 모듈 경계의 간접 디스패치 제거, 모듈 간 최적화 복원 | 생성된 pbxproj에서 자체 모듈 20개 전부 `NO` |
| Noto Sans KR 서브셋 | 번들 폰트 17.7MB → 8.3MB (**-9.4MB**) | 한글 음절 11,172자 전체 유지, PostScript 이름 동일 |
| iPhone 전용 선언 (`TARGETED_DEVICE_FAMILY = 1`) | 지침 2.4.1 리젝 위험 제거 | iPad 적응 코드 0건 확인 후 결정 |

폰트 서브셋은 한자(8,231자)와 가나(189자)만 제거했습니다. 한글 음절은 전부 남겼으므로
AI가 생성한 어떤 한국어 문장도 대체 글꼴로 떨어지지 않습니다. 원본이 필요하면
같은 폴더의 `NotoSansKR-VariableFont_wght.ttf`에서 다시 뽑을 수 있습니다.

```sh
pyftsubset NotoSansKR-Regular.ttf \
  --unicodes="U+0020-007E,U+00A0-00FF,U+0100-017F,U+2000-206F,U+20A0-20BF,U+2190-21FF,U+2200-22FF,U+2460-24FF,U+25A0-25FF,U+2600-26FF,U+3000-303F,U+1100-11FF,U+3130-318F,U+A960-A97F,U+AC00-D7A3,U+D7B0-D7FF,U+FF00-FFEF" \
  --layout-features='*' --name-IDs='*' --notdef-outline \
  --output-file=NotoSansKR-Regular.ttf
```

## 크래시 리포팅 — Xcode Organizer

서드파티 SDK 없이 Apple 기본 도구만 사용합니다. **추가 코드가 없습니다.**

전제조건은 이미 충족돼 있습니다.

| 설정 | 값 | 위치 |
| --- | --- | --- |
| `DEBUG_INFORMATION_FORMAT` (Release) | `dwarf-with-dsym` | App 프로젝트 수준, 타깃이 상속 |
| `VALIDATE_PRODUCT` (Release) | `YES` | 동일 |

`Distribute App > App Store Connect`의 옵션 화면에서
**"Upload your app's symbols"를 켠 채로 두세요**(최근 Xcode는 기본 체크). 이 옵션은
`.dSYM`을 Apple에 함께 올려 크래시 리포트를 서버에서 심볼화하게 합니다. dSYM은 사용자에게
배포되는 앱에 포함되지 않으므로 용량과 무관합니다.

Crashlytics와 달리 **Organizer에는 사후 dSYM 업로드 경로가 없습니다.** 대신 아카이브가
남아 있는 Mac에서는 Xcode가 바이너리 UUID로 아카이브를 찾아 로컬 심볼화를 해 줍니다.
따라서 아카이브를 지우지 마세요 — 다른 Mac이나 팀원이 볼 때, 또는 아카이브를 잃었을 때는
심볼 업로드를 했을 때만 심볼화됩니다.

```sh
ls ~/Library/Developer/Xcode/Archives
```

확인 경로는 Xcode > Window > Organizer > Crashes 및 Metrics 탭입니다.

알아둘 점입니다.

- **"개발자와 공유"에 동의한 사용자의 데이터만** 올라옵니다. 전수가 아닙니다.
- TestFlight·App Store 빌드만 집계됩니다. 로컬 빌드는 보이지 않습니다.
- 반영에 하루 정도 걸립니다. 실시간 알림이 없습니다.
- 비치명적 오류나 브레드크럼 기록 기능이 없습니다. 필요해지면 그때
  MetricKit(`MXMetricManagerSubscriber`)으로 진단 페이로드를 직접 받아 처리하는 방법을
  검토하세요 — 다만 페이로드를 자체 서버로 보내면 App Store Connect 개인정보 라벨에
  "진단" 항목을 선언해야 합니다.

Firebase Crashlytics는 채택하지 않았습니다. 채택했다면 해당 SDK의 매니페스트가 선언하는
`CrashData`·`OtherDiagnosticData`를 앱 개인정보 라벨에도 반영해야 했고, 전이 의존성
7개(`FirebaseSessions`, `FirebaseCoreExtension`, `Promises` 등)가 번들에 추가됐을 것입니다.

## 보류 — 빌드 검증이 필요한 변경

### 1. 동적 프레임워크 55개 통합

앱 번들에 dylib 55개가 임베드되어 매 실행마다 dyld가 로드·바인딩합니다. Apple 권장은
6개 이하이며, 이것이 콜드 스타트 지연의 가장 큰 원인입니다.

정적 프레임워크로 바꾸는 방식은 50개 제품 타입을 한꺼번에 바꿔야 하고, 정적 라이브러리가
여러 동적 프레임워크에 링크되면 심볼이 중복됩니다. 더 안전한 대안은 Apple이 이 문제를
위해 만든 **mergeable libraries**입니다. `BUILD_LIBRARY_FOR_DISTRIBUTION = NO`가
선행 조건인데 이미 충족했습니다.

`Target+Module.swift`의 `module(...)` 팩터리:

```diff
             product: .framework,
+            mergeable: true,
```

`AppModuleName.swift`의 `GitIt` 타깃:

```diff
                 entitlements: .file(path: "GitIt.entitlements"),
+                mergedBinaryType: .automatic,
```

**적용 전 확인할 것**: `ShareExtension`이 `Feature`·`CompositionShareExtension`을
링크합니다. 앱 바이너리로 병합된 프레임워크를 확장이 참조할 때 링크가 깨질 수 있으므로,
Release 빌드와 확장 실행을 반드시 함께 확인하세요. 실패하면 위 두 줄만 되돌리면 됩니다.

측정은 이렇게 합니다.

```sh
xcrun xctrace record --template 'App Launch' --launch -- <앱 경로>
```

### 2. Feature 모듈의 MainActor 기본 격리

App 타깃만 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`이고 프레임워크 모듈은
`nonisolated`입니다. 이 차이는 이제 `Target+Module.swift`에 명시되어 의도적입니다.

Feature까지 MainActor로 올리려면 리듀서 30개 전부에 `nonisolated`가 필요합니다.
App의 `AppRootFeature`가 정확히 그 이유로 `nonisolated struct`입니다 — TCA의 `Reducer`
프로토콜 요구사항이 nonisolated라서 MainActor 격리 타입은 준수할 수 없습니다.

```sh
# 대상 확인
grep -rn -A1 '^@Reducer' sources/Projects/Feature --include='*.swift' | grep 'public struct'
```

기계적인 변경이지만 리듀서 외의 충돌(use case 프로토콜 준수, `@Sendable` 클로저 캡처)이
남을 수 있어 빌드를 돌려가며 진행해야 합니다.

### 3. 중첩 `fullScreenCover` 동시 표시

`AppRootFeature`의 `learningRequested`가 `projectDetail`과 `quiz`를 같은 액션에서
동시에 채우고, `AppRootView`가 이를 2단 중첩 `fullScreenCover`로 표시합니다.
한 프레임에 모달 두 단계를 올리는 구조라 간헐적 표시 실패 가능성이 있습니다.

지금은 바꾸지 않았습니다. `AppRootFeatureTests`의 3개 테스트가 두 상태가 함께 설정되는
현재 동작을 검증하고 있어서, 리듀서를 바꾸면 테스트도 함께 고쳐야 하는데 실제 실패가
관측된 적이 없기 때문입니다. 실기기에서 "학습 이어하기" 진입 시 화면이 안 뜨는 현상이
보고되면 그때 `quiz` 설정을 한 틱 뒤로 미루는 방식으로 처리하세요.

## 남은 소소한 정리

- `sources/Projects/UI/Component/Scaffolds/TabShell/TabShell.swift:33`의
  `UITabBar.appearance()`가 `.onAppear`에 있습니다. 외형 프록시는 이후 생성되는 뷰에만
  적용되므로 첫 진입에서 색이 반영되지 않을 수 있습니다. 다만 `TabShell`이 제네릭 타입이라
  일회성 `static let`을 안에 둘 수 없어(제네릭 타입은 정적 저장 프로퍼티 불가) 별도 타입이
  필요합니다.
- `Resources/Fonts` 아래에 번들되지 않는 정적 웨이트 20여 개가 남아 있습니다
  (매니페스트는 Regular·Medium·Bold만 포함). 저장소 용량만 차지합니다.
- `tools/swift-style/swiftstyle.swiftformat`이 깨진 심볼릭 링크입니다
  (`Sources/AirbnbSwiftFormatTool/` → 실제는 `Sources/SwiftStyleFormatTool/`).
  서브모듈 안이라 별도로 처리해야 합니다.
