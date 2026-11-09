# TWMT AI Fork — 개발 준비 인덱스

## 프로젝트 목적
원본 Total War Mods Translator(TWMT)를 기반으로, 기존 번역·팩 내보내기 기능을 보존하면서 로컬 LLM과 추가 AI 번역 공급자를 선택적으로 확장한다.

## 현재 단계
**Ollama 로컬 Provider 및 설치 모델 동기화 구현 병합 완료.** 다음은 실제 Windows Ollama 실행 검증과 필요 시 사용자 지정 서버 주소 지원을 검토한다.

- PR #1: 개발 기반 문서 병합 완료
- PR #3: Flutter 자동 검증 workflow 병합 완료
- PR #2: Ollama 비스트리밍 Provider 병합 완료
- PR #4: 설치 모델 자동 동기화 병합 완료
- PR #5: Ollama 모델 이름 검증 예외 처리 병합 완료
- Flutter 테스트 및 실제 Windows Ollama 실행 검증은 별도 확인 필요

## 문서
- [포크 운영 전략](FORK_STRATEGY.md)
- [개발 환경 준비](DEVELOPMENT_SETUP.md)
- [AI Provider 확장 로드맵](AI_PROVIDER_ROADMAP.md)
- [작업 기록](WORKLOG.md)

## 기준 정보
- 포크: `hjw831/Total-War-Mods-Translator-AI`
- 원본: `Slavyk82/Total-War-Mods-Translator`
- 기본 브랜치: `main`
- 앱 프레임워크: Flutter / Dart
- 현재 확인된 앱 버전: `2.0.7+1`
- 라이선스: MIT (원본 저작권 및 라이선스 고지 유지)

## 범위 통제 원칙
한 번에 하나의 작은 기능만 구현한다. 각 기능은 별도 브랜치, 테스트, 문서 갱신을 거친다. 사용자가 승인한 일반 기능 작업은 자동 검토·병합까지 진행할 수 있다. 빌드·릴리스·대규모 구조 변경은 별도 승인 대상으로 둔다.

## 현재 후속 작업
Ollama `/api/tags` 설치 모델 동기화까지 병합했다. 신규 모델만 비활성 상태로 추가하며 기존 모델의 사용 설정을 덮어쓰지 않는다. Flutter CI 실행 기록과 실제 Windows Ollama 연결/번역은 아직 확인되지 않았다.

## Ollama 사용 안내

- `docs/OLLAMA_SETUP.md`: 로컬 Ollama 실행, 설치 모델 동기화, 앱 설정 및 기본 문제 해결.
- `docs/WINDOWS_ISOLATED_TEST_BUILD.md`: 기존 설치판과 사용자 데이터를 보호하는 별도 Windows 테스트판 계획.

## 다음 작업 — Windows 격리 테스트판
- 전용 브랜치 `feature/windows-isolated-test-build`에서 준비 중.
- 현재 코드의 Windows 디버그 데이터 경로가 기존 설치판과 공유됨을 확인했다. 테스트판 데이터 경로 격리를 최우선으로 구현한다.
- Windows runner가 저장소에 없고, 기존 Inno Setup ID도 원본과 같으므로 식별자/패키징을 분리해야 한다.
- 구현 후 수동 Windows 빌드 및 ZIP artifact를 준비한다. 기존 설치판은 변경하지 않는다.
