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
- 기존 설치판과 다른 앱 식별자/제품 이름/설치 프로그램 ID를 사용한다.
- 기존 API 키·자격 증명을 가져오거나 덮어쓰지 않는다. Windows secure storage의 실제 키 네임스페이스를 조사하고 테스트판 전용 분리를 보장한다.
- Ollama는 기존 로컬 서버(`127.0.0.1:11434`)를 사용하되, 테스트판의 앱 설정·DB만 별도로 유지한다.
- 테스트판은 우선 수동 배포용 ZIP/폴더 패키지로 제공한다. 기존 앱을 덮어쓰는 설치 프로그램은 격리 검증 이후 별도 판단한다.

## 구현 순서

### W1 — 데이터/자격 증명 격리
- `TWMT_ISOLATED_TEST_BUILD` compile-time define 또는 동등한 명시적 빌드 플래그를 도입한다.
- 격리 빌드에서는 디버그/릴리스 모드와 무관하게 전용 AppData 루트를 강제한다.
- DB, config, logs, cache 경로가 모두 테스트 전용인지 검증하는 단위 테스트를 추가한다.
- secure storage 생성 지점과 Windows 플러그인의 Credential Manager 키 구성을 조사한다. 테스트판이 원본 API 키를 읽거나 쓰지 않도록 namespace를 분리한다.
- 격리 플래그가 없는 기존 빌드의 데이터 경로는 변경하지 않는다.

### W2 — Windows 실행 프로젝트 및 식별자
- Flutter Windows runner를 재현 가능한 방식으로 생성하고 저장소에 포함한다.
- 창 제목, 파일 제품 정보, 실행 파일 이름을 테스트판으로 구분한다.
- 원본과 다른 설치 프로그램 ID를 사용한다. 테스트 단계에서는 원본 설치 프로그램을 실행하거나 갱신하지 않는다.

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

## 완료 기준

- 기존 설치판을 제거하거나 변경하지 않고 테스트판을 함께 실행할 수 있다.
- 테스트판은 기존 DB/설정/자격 증명을 읽거나 변경하지 않는다.
- 테스트판의 DB·로그·캐시 경로가 전용 위치임을 로그와 테스트로 확인할 수 있다.
- Windows Release 빌드와 ZIP artifact 생성이 성공한다.
- 실제 Windows Ollama 번역 성공 여부는 사용자 실행 결과로 별도 기록한다.

## 현재 상태

- 전용 브랜치 `feature/windows-isolated-test-build` 생성 완료.
- 위 위험 요소는 GitHub `main`의 `database_config.dart`, `pubspec.yaml`, `lib/main.dart`, workflow 파일을 확인해 기록했다.
- 아직 Windows runner 생성, 코드 변경, 빌드, 실제 실행은 하지 않았다.
