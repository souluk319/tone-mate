# Architecture decision records

주요 기술·제품 구조 선택은 `NNNN-short-title.md` 형식의 ADR로 기록한다.

## Required fields

```markdown
# ADR NNNN: 제목

- Status: Proposed | Accepted | Superseded | Rejected
- Date: YYYY-MM-DD
- Deciders:
- Related decisions: D01, D02, ...

## Context
## Decision
## Alternatives considered
## Consequences
## Validation evidence
## Follow-up
```

실험이 필요한 선택은 측정 전에 `Proposed`로 작성하고 합격선과 필요한 증적을 연결한다. 결과를 확인한 뒤 `Accepted` 또는 `Rejected`로 바꾸며 원래 결과와 기각 근거를 삭제하지 않는다.

초기 우선 ADR 대상은 DSP 공유 방식, F0 추정기, PCM buffer·thread 계약, iOS package lane과 공개 패키지 좌표다.
