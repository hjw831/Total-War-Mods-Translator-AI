# 개발 환경 준비

## 프로젝트 스택 확인

- Flutter Windows 데스크톱 앱
- Dart SDK 제약: `^3.10.0`
- 앱 버전 기준: `2.0.7+1`
- 상태 관리: Riverpod
- HTTP: Dio 및 http
- 로컬 데이터: SQLite 계열(sqflite_common_ffi)
- API 키 저장 의존성: flutter_secure_storage
- 팩 파일 작업: 외부 RPFM CLI 필요

정확한 Flutter SDK 버전, RPFM CLI 권장 버전, Windows 빌드 도구 버전은 첫 로컬 환경 점검에서 확인하고 고정한다. 이 문서는 아직 특정 버전을 임의로 지정하지 않는다.

## Windows 준비 순서

1. Git 설치 및 저장소 clone
2. Flutter SDK 설치 후 `flutter doctor -v`
3. Visual Studio의 Desktop development with C++ 워크로드 확인
4. RPFM CLI 설치 및 앱 설정에서 실행 파일 경로 확인
5. 저장소 루트에서 의존성 설치
6. 정적 분석 및 기존 테스트 실행

```powershell
git clone https://github.com/hjw831/Total-War-Mods-Translator-AI.git
cd Total-War-Mods-Translator-AI
flutter doctor -v
flutter pub get
flutter analyze
flutter test
```

실제 실행 결과는 로컬 PC에서 확인 후 작업 기록에 남긴다. 이 문서 작성만으로 빌드나 테스트가 실행된 것은 아니다.

## 비밀정보 및 사용자 데이터

- API 키, 토큰, 개인 경로, 실제 게임 설치 경로를 커밋하지 않는다.
- `.env`, 설정 파일, 로그에 비밀정보가 포함되지 않았는지 커밋 전 확인한다.
- API 키는 기존 secure storage 경로를 우선 재사용한다.
- Ollama 로컬 연결은 기본적으로 loopback 주소만 사용한다. 사용자가 원격 호스트를 명시적으로 설정하는 기능은 별도 보안 검토 후 추가한다.
- 테스트에는 실제 사용자 번역 DB나 개인 API 키를 사용하지 않는다.

## 로컬 Ollama 개발 준비

첫 Provider 구현 전 Ollama가 실행되는지 로컬에서 확인한다.

```powershell
ollama --version
ollama list
```

사용자 환경에 이미 설치된 모델을 그대로 활용하고, 앱이 임의로 모델을 다운로드하거나 GPU 메모리를 점유하지 않도록 한다. 모델명과 실제 응답 형식은 Provider 테스트에서 확인한다.

## 개발 완료 기준

- `flutter analyze` 오류 없음
- 변경 영역 관련 테스트 통과
- 기존 번역·글로서리·번역 메모리·팩 내보내기 회귀 영향 점검
- 비밀정보 및 사용자 데이터 변경 없음
- 문서와 작업 기록 갱신
