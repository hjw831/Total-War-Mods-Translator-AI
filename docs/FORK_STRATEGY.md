# 포크 운영 전략

## 저장소 관계

| 구분 | 저장소 | 역할 |
|---|---|---|
| Upstream | `Slavyk82/Total-War-Mods-Translator` | 원본 프로젝트 및 변경사항 참조 |
| Origin | `hjw831/Total-War-Mods-Translator-AI` | AI 확장 개발의 기준 저장소 |

원본 저장소에 직접 커밋하거나 원본의 릴리스/배포 경로를 변경하지 않는다.

## 브랜치 정책

- `main`: 항상 검토 가능한 안정 기준. 준비 문서 외의 실험 코드는 직접 넣지 않는다.
- `chore/*`: 문서, 저장소 설정, 개발환경 정비.
- `feature/*`: 사용자에게 보이는 기능 또는 Provider 구현.
- `fix/*`: 확인된 결함 수정.

기능 브랜치는 최신 `main`에서 생성하고, 완료 후 PR로 `main`에 병합한다. 하나의 PR은 하나의 목적만 가진다.

## Upstream 동기화

로컬 저장소에서 최초 1회 upstream을 등록한다.

```bash
git remote add upstream https://github.com/Slavyk82/Total-War-Mods-Translator.git
git fetch upstream
```

원본 변경사항 검토 후에만 병합한다.

```bash
git checkout main
git fetch upstream
git merge --ff-only upstream/main
git push origin main
```

Fast-forward가 불가능하면 무리하게 강제 병합하지 말고 차이를 검토한 뒤 별도 동기화 PR을 만든다. 포크 전용 기능과 원본 변경을 한 커밋에 섞지 않는다.

## 커밋 및 PR 규칙

권장 커밋 접두사: `docs:`, `chore:`, `feat:`, `fix:`, `test:`, `refactor:`.

PR에는 다음을 적는다.
1. 목적과 변경 범위
2. 수정 파일
3. 실행한 테스트 및 결과
4. 미검증 항목과 위험
5. 사용자 데이터·설정·기존 번역 결과에 미치는 영향

## 원본 고지 및 라이선스

원본 저장소의 LICENSE는 MIT이며 저작권 고지는 Slavyk82, 2025로 기재되어 있다. 재배포하는 복사본 및 실질적인 코드 부분에는 원본 저작권·라이선스 고지를 유지한다. 포크의 기여분에 대한 별도 저작권 표기가 필요하면 실제 기여자와 배포 정책을 확인해 추가한다.

## 변경 금지 영역 — 별도 승인 전

- 원본 번역 데이터 및 사용자 프로젝트 데이터 구조
- 기존 Provider 동작과 API 요청 형식
- 데이터베이스 스키마 및 마이그레이션
- 팩 추출·수정·내보내기 파이프라인
- 앱 식별자, 서명, 설치 프로그램 및 자동 업데이트 경로

이 영역은 확장 기능의 필요성이 확인되고 영향 분석과 테스트 계획이 준비된 후 변경한다.
