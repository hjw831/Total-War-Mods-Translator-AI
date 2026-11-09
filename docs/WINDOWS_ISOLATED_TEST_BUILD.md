# Windows 격리 테스트판 준비 계획

## 목적

기존에 설치된 원본 TWMT와 포크 테스트판을 같은 Windows PC에서 동시에 실행하되, 원본 앱·번역 DB·설정·API 키·로그를 읽거나 변경하지 않는 테스트 환경을 만든다.

## 현재 확인된 위험

1. 저장소 `main`에는 `windows/` 플랫폼 프로젝트 디렉터리가 없다. 현재 `pubspec.yaml`은 Flutter Windows 빌드에 필요한 `windows/runner/resources/app_icon.ico`도 참조한다.
2. `lib/config/database_config.dart`의 Windows 디버그 실행 경로는 `%APPDATA%\com.github.slavyk82\twmt`를 직접 사용한다. 주석에도 설치판과 개발판이 같은 데이터를 공유한다고 명시되어 있다.
3. 이 경로 공유는 새 테스트판이 원본 DB·설정에 접근할 수 있는 직접적인 위험이다. 단순히 다른 폴더에 EXE를 두거나 앱 창 제목만 바꾸는 것으로는 격리가 보장되지 않는다.
4. 현재 `pubspec.yaml`의 Inno Setup ID와 제품 이름은 원본 TWMT 값(`0a4229e1-c281-4206-98f9-1482448c8674`, `TWMT`)이다. 이를 그대로 사용해 별도 설치판을 만들면 기존 설치와 충돌할 가능성이 있다.
5. `flutter-validation.yml`은 Dart 분석/테스트만 수행하며 Windows 데스크톱 빌드는 수행하지 않는다.

## 안전성 원칙

- 원본 설치 폴더, 원본 사용자 데이터, 원본 DB를 복사·초기화·수정하지 않는다.
- 테스트판은 별도 앱 데이터 루트를 사용한다. 기본 제안 경로는 `%APPDATA%\TWMT_AI_Test`이며 DB, config, logs, cache를 모두 이 루트 아래로 모은다.
- 테스트판에서 원본 데이터 경로로 fallback하는 동작은 금지한다. 격리 경로를 결정할 수 없으면 시작을 중단하고 명확한 오류를 표시한다.
- 테스트판은 원본과 다른 Windows runner 식별자/제품 이름/실행 파일 이름을 사용한다. ZIP 방식이므로 기존 Inno Setup ID는 변경하지 않고 사용하지도 않는다.
- 기존 API 키·자격 증명을 가져오거나 덮어쓰지 않는다. Windows secure storage의 실제 키 네임스페이스를 조사하고 테스트판 전용 분리를 보장한다.
- Ollama는 기존 로컬 서버(`127.0.0.1:11434`)를 사용하되, 테스트판의 앱 설정·DB만 별도로 유지한다.
- 테스트판은 우선 수동 배포용 ZIP/폴더 패키지로 제공한다. 기존 앱을 덮어쓰는 설치 프로그램은 격리 검증 이후 별도 판단한다.

## 구현 순서

### W1 — 데이터/자격 증명 격리
- `TWMT_ISOLATED_TEST_BUILD` compile-time define 또는 동등한 명시적 빌드 플래그를 도입한다.
- 격리 빌드에서는 디버그/릴리스 모드와 무관하게 전용 AppData 루트를 강제한다.
- DB, config, logs, cache 경로가 모두 테스트 전용인지 검증하는 단위 테스트를 추가한다.
- secure storage 생성 지점과 Windows 플러그인의 저장 경로를 조사한다. Application Support 경로를 runner VERSIONINFO로 분리하고 구형 Credential Manager 호환 이전은 비활성화한다.
- 격리 플래그가 없는 기존 빌드의 데이터 경로는 변경하지 않는다.

### W2 — Windows 실행 프로젝트 및 식별자
- Flutter Windows runner를 수동 빌드 workflow의 임시 CI 작업공간에서 재현 가능하게 생성한다. runner 원본은 현재 저장소에 커밋하지 않는다.
- 창 제목, 파일 제품 정보, 실행 파일 이름을 테스트판으로 구분한다.
- runner VERSIONINFO와 실행 파일 이름을 원본과 분리한다. 테스트 단계에서는 원본 설치 프로그램을 실행하거나 갱신하지 않는다.

### W3 — 수동 Windows 빌드
- GitHub Actions에 `workflow_dispatch` 전용 Windows 빌드 작업을 추가한다.
- Flutter stable 설치, 의존성/코드 생성, `flutter analyze`, 관련 테스트, 격리 define을 적용한 Windows Release 빌드를 수행한다.
- 산출물에는 테스트판 실행 파일과 필요한 런타임 파일만 포함하고, 별도 ZIP artifact로 제공한다.
- 빌드 성공과 실제 Windows 실행 검증을 구분해 기록한다.

### W4 — 사용자 실행 확인
- 테스트판을 별도 폴더에 압축 해제하고 실행한다.
- 최초 실행 시 빈 테스트 전용 DB가 만들어지는지 확인한다.
- 기존 원본 TWMT와 테스트판을 번갈아 실행해 양쪽 DB/설정이 독립적인지 확인한다.
- Ollama 연결 → 설치 모델 동기화 → 모델 활성화 → 짧은 번역 순서로 확인한다.

## W1 조사 결과 및 구현 진행 상황 (2026-11-09)

### 확인한 저장소/플러그인 구조
- `flutter_secure_storage`는 `pubspec.yaml`에서 ^9.0.0을 사용하고, 현재 lockfile은 Windows 구현 `flutter_secure_storage_windows 3.1.2`를 고정한다.
- 앱은 `lib/services/locators/llm_service_locator.dart`에서 `FlutterSecureStorage(WindowsOptions(useBackwardCompatibility: false))`를 생성한다.
- Windows 플러그인의 현재 파일 저장 방식은 `path_provider.getApplicationSupportDirectory()` 기반이다. 따라서 이 저장소의 DB 경로만 바꿔서는 API 키 저장소가 격리되지 않는다. Windows runner의 CompanyName/ProductName 및 application support 경로가 원본 앱과 달라야 한다.
- `shared_preferences`도 앱의 Windows 식별자/저장 경로에 의존하므로 W2에서 runner 식별자를 별도로 설정하고, W4에서 실제 파일 위치를 확인한다.
- Windows secure storage의 구형 Credential Manager 호환 읽기/자동 이전은 `useBackwardCompatibility: false`로 이미 비활성화되어 있다. 이 설정을 true로 바꾸지 않는다.

### Windows 앱 식별자 분리 설계 (W2)
- Windows `path_provider`는 실행 파일 VERSIONINFO의 `CompanyName\\ProductName` 조합으로 앱별 Application Support 경로를 만든다.
- 따라서 secure storage(현재 Windows 플러그인은 application support directory에 암호화 파일을 저장)와 shared_preferences는 runner VERSIONINFO를 원본과 다르게 설정해 분리한다.
- 테스트판 runner 식별자 제안: `CompanyName=TWMT_AI`, `ProductName=TWMT AI Test`, 실행 파일 `TWMT_AI_Test.exe`.
- 테스트판의 DB/config/log/cache 루트는 계속 명시적인 `%APPDATA%\\TWMT_AI_Test`를 사용한다. secure storage/shared_preferences는 runner identity 기반 경로 `%APPDATA%\\TWMT_AI\\TWMT AI Test`를 사용한다. 두 경로 모두 원본 `%APPDATA%\\com.github.slavyk82\\twmt`와 분리된다.
- Inno Setup 설정은 건드리지 않는다. 첫 테스트 배포는 설치 프로그램이 아닌 ZIP만 사용한다.

### 이번 커밋에서 구현한 범위
- `TWMT_ISOLATED_TEST_BUILD=true` compile-time define 추가.
- 격리 빌드는 Windows에서 `%APPDATA%\\TWMT_AI_Test`를 전용 데이터 루트로 사용한다.
- 격리 빌드에서 APPDATA가 비어 있거나 Windows가 아니면 원본 경로로 fallback하지 않고 시작을 거부한다.
- DB와 config는 전용 루트를 사용한다.
- 로그와 cache도 전용 루트 아래로 이동한다.
- `LoggingService`가 독립적으로 path_provider 경로를 계산하지 않고 `DatabaseConfig.getLogsDirectory()`를 사용하도록 중앙화했다.
- 격리 빌드에서는 Windows 창 제목과 Flutter 앱 제목을 `TWMT AI Test`로 표시한다.
- 전용 경로 계산 및 빈 APPDATA 거부 단위 테스트를 추가했다.

### 아직 격리 검증이 끝나지 않은 항목
- Secure storage와 shared_preferences는 Windows `path_provider`의 Application Support 경로를 사용한다. 수동 빌드 workflow가 runner VERSIONINFO의 CompanyName/ProductName을 분리해 이 저장소 경로를 원본과 다르게 설정한다.
- Windows runner 소스는 저장소에 직접 추가하지 않고 수동 빌드 workflow가 임시 CI 작업공간에서 생성한다. 따라서 로컬 Windows 실행은 아직 불가능하지만, workflow를 통한 ZIP 산출 경로는 준비됐다.
- GitHub Actions 또는 로컬 Windows 환경에서 테스트/빌드를 아직 실행하지 않았다. workflow 구성은 완료했지만 실제 산출물과 경로는 검증 대기 상태다.

### W1 완료 기준
- [x] DB/config 전용 루트
- [x] 로그/cache 전용 루트
- [x] 격리 플래그 없을 때 기존 경로 동작 보존
- [x] APPDATA 누락 시 fail-closed
- [x] 경로 정책 단위 테스트 추가
- [x] secure storage/shared_preferences용 별도 runner identity 빌드 설정 추가
- [ ] 실제 Windows에서 secure storage/shared_preferences 경로 확인
- [ ] Windows 환경 테스트 실행

## 완료 기준

- 기존 설치판을 제거하거나 변경하지 않고 테스트판을 함께 실행할 수 있다.
- 테스트판은 기존 DB/설정/자격 증명을 읽거나 변경하지 않는다.
- 테스트판의 DB·로그·캐시 경로가 전용 위치임을 로그와 테스트로 확인할 수 있다.
- Windows Release 빌드와 ZIP artifact 생성이 성공한다.
- 실제 Windows Ollama 번역 성공 여부는 사용자 실행 결과로 별도 기록한다.

## 현재 상태

- 전용 브랜치 `feature/windows-isolated-test-build` 생성 완료.
- 위 위험 요소는 GitHub `main`의 `database_config.dart`, `pubspec.yaml`, `lib/main.dart`, workflow 파일을 확인해 기록했다.
- Windows runner는 수동 빌드 workflow가 CI 작업공간에서 생성하도록 구성했다. 저장소에 runner 원본을 커밋하지 않았다.
- 수동 Windows ZIP 빌드 workflow는 추가했지만 아직 실행하지 않았다.
