# TWMT AI Fork — 개발 준비 인덱스

## 프로젝트 목적
원본 Total War Mods Translator(TWMT)를 기반으로, 기존 번역·팩 내보내기 기능을 보존하면서 로컬 LLM과 추가 AI 번역 공급자를 선택적으로 확장한다.

## 현재 단계
**개발 준비 단계 완료 목표:** 저장소 운영 규칙, 개발 환경 안내, 코드 조사 결과, 최소 로드맵을 문서화한다.

- 앱 기능 변경 없음
- Provider 코드 변경 없음
- 의존성 및 데이터베이스 변경 없음
- 빌드·릴리스·팩 파일 생성 없음

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
한 번에 하나의 작은 기능만 구현한다. 각 기능은 별도 브랜치, 테스트, 문서 갱신을 거친다. 사용자가 명시적으로 요청하기 전에는 기능 구현, 빌드, 릴리스를 진행하지 않는다.

## 첫 구현 후보
Ollama 로컬 Provider를 기존 Provider 인터페이스에 연결하는 최소 수직 기능(vertical slice). 모델 자동 검색, 고급 설정, 멀티 Provider 자동 라우팅은 첫 구현에 포함하지 않는다.
