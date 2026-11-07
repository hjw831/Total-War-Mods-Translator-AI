# TWMT AI Fork — 개발 준비 인덱스

## 프로젝트 목적
원본 Total War Mods Translator(TWMT)를 기반으로, 기존 번역·팩 내보내기 기능을 보존하면서 로컬 LLM과 추가 AI 번역 공급자를 선택적으로 확장한다.

## 현재 단계
**Ollama 로컬 Provider 1차 구현 병합 완료.** 현재 설치된 Ollama 모델을 앱 목록으로 동기화하는 후속 작업을 진행 중이다.

- PR #1: 개발 기반 문서 병합 완료
- PR #3: Flutter 자동 검증 workflow 병합 완료
- PR #2: Ollama 비스트리밍 Provider 병합 완료
- 후속 브랜치: `feature/ollama-model-discovery`
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
Ollama `/api/tags`를 사용해 설치 모델을 앱의 DB 모델 목록에 동기화한다. 동기화는 신규 모델만 비활성 상태로 추가하며 기존 모델의 사용 설정을 덮어쓰지 않는다.

## Ollama 사용 안내

- `docs/OLLAMA_SETUP.md`: 로컬 Ollama 실행, 설치 모델 동기화, 앱 설정 및 기본 문제 해결.
