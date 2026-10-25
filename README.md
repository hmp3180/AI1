# AI1

PE 엔진으로 하는 AI 연구 트랙 저장소. 게임이 아니다 — 산출물은 앱이 아니라 측정과 결론이다.

## 유의사항

- 소스는 BOM 없는 UTF-8.
- 한글이 든 파일을 셸 heredoc · python -c · git diff | git apply 로 고치지 않는다. 글자가 조용히 깨진다.
- 자동화 스크립트는 .ps1 말고 Python 으로. 앱 몰기 · 오래 도는 일은 PEMCP 와 agentchat watch 를 쓴다.
- 앱을 끌 때 Stop-Process -Name 을 쓰지 않는다. app_quit, 아니면 -Id <pid>.
- 엔진에 손대야 하는 일은 엔진 저장소에서 한다. 이 저장소에는 연구 프로젝트와 그 문서만 둔다.
- 작업 전에 docs/JudgmentRules.md(공용 판정 규율)를 검색해서 그 절을 읽는다. 크니까 통째로 읽지 않는다.

## 빌드

프로젝트 폴더의 bat 을 쓴다.

    build.bat      win64
    build_apk.bat  안드로이드

엔진 자리는 루트의 engine.ini(gitignore · engine=<엔진 루트>)가 정한다. pe_engine.bat 이 엔진을 못 찾으면
찾아다니지 말고 사용자에게 엔진 설치와 engine.ini 를 요청한다.

## MCP(PEMCP)

이 저장소의 .mcp.json 으로 붙는다(engine.ini 의 엔진 것을 띄운다).

- 찾기: api_task(작업 문장, project) → api_get · api_examples · api_doc
- 앱 몰기: app_launch(project) → app_cmd → app_log → app_quit
- 빌드: build_start · build_status

## 프로젝트

- ML — 코드(.pes) · 비전 · 자연어를 한꺼번에 배우는 모델 + 학습기. 정본 ML/ML.md · 원리 ML/concept.md · 과정 ML/mllog.md
  - MLT(같은 원리를 트랜스포머로) — ML/MLT.md · ML/mltconcept.md · ML/mltplan_<칸>.md · ML/mltlog_<칸>.md

## 문서

- docs/ResearchTracks.md — 트랙이 무엇이고 문서가 어떻게 갈려 있나
- docs/JudgmentRules.md — 트랙을 건너 쓰는 공용 판정 규율
- docs/Vocabulary.md — 트랙 공용 어휘
- docs/LongRuns.md — 몇 시간짜리 판을 돌릴 때의 진단과 함정

엔진 문서는 엔진 저장소의 Docs/Guide.md 에서 시작한다.
