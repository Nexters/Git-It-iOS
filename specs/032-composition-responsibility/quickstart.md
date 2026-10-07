# 검증 가이드: Composition 책임 되돌리기

## 사전 조건

```sh
cd sources && tuist generate --no-open
```

## 기준선 측정

적용 전에 실행해 값을 `tasks.md`의 "기준선 기록" 절에 남긴다.

```sh
# Composition 프로덕션 코드 줄수
find sources/Projects/Composition -name '*.swift' -not -path '*/Tests/*' -not -path '*/Derived/*' -exec cat {} + | wc -l

# Infrastructure 저장 API 직접 사용
grep -rnE "UserDefaults\(|UserDefaultsStore\(|KeychainStore\(" sources/Projects/Composition --include='*.swift' | grep -v '/Tests/' | wc -l

# 번들·프로세스 조회
grep -rnE "Bundle\.main|ProcessInfo" sources/Projects/Composition --include='*.swift' | grep -v '/Tests/' | wc -l

# 외부 라이브러리 타입 이름
grep -rn "Firebase" sources/Projects/Composition --include='*.swift' | grep -v '/Tests/' | wc -l
```

## 시나리오별 검증

### 시나리오 1 — 저장 스키마를 Data가 소유한다

```sh
ls sources/Projects/Composition/Adapter/
```

**기대 결과**: `Codings/`, `Layouts/`, `Migrations/`, `Resolvers/`, `Models/`가 없다.
`Adapters/`, `Assemblies/`, `Factories/`만 남는다.

```sh
grep -rn "com.nexters.hytime.gitit" sources/Projects/Composition --include='*.swift' | grep -v '/Tests/'
```

**기대 결과**: 결과가 없다. 네임스페이스·App Group 문자열이 Composition에 없다.

```sh
grep -rnE "\.value\(forKey|\.store\(|keychainStore\.(save|load|delete)" sources/Projects/Composition --include='*.swift' | grep -v '/Tests/'
```

**기대 결과**: 결과가 없다. Composition이 저장 API로 직접 읽고 쓰지 않는다. 조립 시점의
인스턴스 생성은 이 기준의 대상이 아니다([research.md](./research.md) 1절).

키 보존은 이동 후 소유 패키지의 테스트로 확인한다.

```sh
cd sources
xcodebuild test -workspace GitIt.xcworkspace -scheme Data -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath DerivedData/PreCommit
```

**기대 결과**: 키 문자열을 고정 상수로 비교하는 테스트가 통과한다.

### 시나리오 2 — 세션 판정과 기기 등록을 Domain이 소유한다

```sh
grep -rn "Bundle.main\|ProcessInfo" sources/Projects/Composition --include='*.swift' | grep -v '/Tests/'
```

**기대 결과**: 결과가 없다.

```sh
cd sources
xcodebuild test -workspace GitIt.xcworkspace -scheme Domain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath DerivedData/PreCommit
```

**기대 결과**: 만료된 access token과 유효한 access token 각각의 판정, 기기 등록의 정보 구성이
Domain 테스트로 검증된다.

### 시나리오 3 — 리마인드 정책과 문구

```sh
grep -rn '"[가-힣]' sources/Projects/Composition --include='*.swift' | grep -v '/Tests/' | grep -v 'logger'
```

**기대 결과**: 결과가 없다. 남은 한국어 문자열은 `logger` 인자뿐이다.

**기대 결과**(Domain 테스트): 완료·미완료 결과와 알림 권한 유무 조합에 대해 예약 여부와 예약
시각이 검증된다.

### 시나리오 4 — 기동 순서와 외부 라이브러리

```sh
grep -rn "Firebase" sources/Projects/Composition --include='*.swift' | grep -v '/Tests/'
grep -n "bootstrap" sources/Projects/Composition/App/Assemblies/AppComposition.swift
```

**기대 결과**: 둘 다 결과가 없다.

```sh
grep -rn "bootstrap\|configure(" sources/Projects/App --include='*.swift' | grep -v '/Tests/'
```

**기대 결과**: 기동 순서를 실행하는 App 타입이 존재하고, 순서가 이동 전과 같다.

## 패키지별 테스트

```sh
cd sources
for scheme in Infrastructure Domain Data Composition; do
  xcodebuild test -workspace GitIt.xcworkspace -scheme "$scheme" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath DerivedData/PreCommit
done
```

## 전체 검증

```sh
runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$runner" build && "$runner" compile && "$runner" test
```

`Feature`와 `AppTests`는 이 브랜치 시작 시점에 이미 실패하는 기존 문제를 갖고 있다
(`AppEntryFeature` 스플래시 게이트 계열). 이 명세의 변경으로 새로 생긴 실패인지 구분해 기록한다.

## 수동 회귀

기존 설치 상태를 지우지 않은 기기에서 확인한다. 시뮬레이터라면 앱을 삭제하지 않고 새 빌드를
덮어쓴다.

1. **로그인 유지** — 적용 전 빌드로 로그인한 뒤 적용 후 빌드를 설치한다. 다시 로그인하라는
   화면이 뜨지 않아야 한다.
2. **공유 확장 세션 판정** — 로그인 상태에서 공유 확장을 연다. 로그인 유도 화면이 아니라 등록
   화면이 떠야 한다.
3. **생성 완료 리마인드** — 리마인드를 켜고 프로젝트를 등록해 생성이 끝나면 알림이 오고, 제목과
   본문이 이동 전과 같아야 한다.
