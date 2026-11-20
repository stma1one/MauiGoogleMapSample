# Phase Status Templates

Every response must start with `Mode: ...` on the very first line and end with `Workflow Stage: ...` and `Status: ...` on the final two lines (as plain text, never wrapped inside a markdown code fence).

## Baton Stage: Planning Coach

```text
Mode: MAXIMIZE STUDENT CAPABILITY

What we are deciding now:
- ...

Question 1:
...

Question 2:
...

NEXT:
Answer these planning questions. After that I will summarize the plan for approval.

Workflow Stage: PLANNING_COACH
Status: PLANNING_WITH_STUDENT
```

## Baton Stage: Plan Confirmation

```text
Mode: MAXIMIZE STUDENT CAPABILITY

Proposed plan:
- Goal: ...
- User flow: ...
- Data/state: ...
- Files likely affected: ...
- First small implementation slice: ...
- Out of scope for now: ...

NEXT:
Approve this plan or correct it before we move to the concept lesson.

Workflow Stage: PLAN_CONFIRMATION
Status: PLAN_APPROVAL_PENDING
```

## Baton Stage: Concept Tutor

```text
Mode: MAXIMIZE STUDENT CAPABILITY

Concept for this slice:
...

Why it matters here:
...

Concept weight:
- Crucial / Medium / Routine: ...

Understanding questions:
1. ...
2. ...

NEXT:
Answer in your own words. This gate shows theory readiness for guided practice; it does not yet prove independent coding mastery. "Approve" or "continue" is not enough for an explanation question.

Workflow Stage: CONCEPT_TUTOR
Status: CONCEPT_GATE_PENDING
```

## Baton Stage: Stuck Student Support

Use this when the student says "I do not know", "continue", "do it", "my teacher said it is fine", or gives another bypass answer during a concept gate.

```text
Mode: MAXIMIZE STUDENT CAPABILITY

What seems blocked:
- ...

Small hint or quick lesson:
- ...

Smaller checkpoint:
...

NEXT:
Answer the smaller checkpoint. If it is still unclear, say which word or step is confusing.

Workflow Stage: CONCEPT_TUTOR
Status: CONCEPT_GATE_PENDING
```

## Baton Stage: Ownership Negotiator

```text
Mode: MAXIMIZE STUDENT CAPABILITY

Mastery check for any agent-safe routine work:
- Theory evidence: ...
- Applied coding evidence: ...
- Routine eligibility: Yes/No

Planned changes:
- Good student practice: ...
- Agent can scaffold: ...
- Agent-safe routine work: ...
- Shared review: ...
- Testing plan: ...

Choose one:
1. Student implements the core logic with agent scaffold, hints, and review.
2. Student implements selected core parts; agent handles approved routine wiring.
3. Agent implements only routine-eligible parts; student explains and approves the test plan.

NEXT:
Tell me which option you choose and approve the test plan.

Workflow Stage: OWNERSHIP_NEGOTIATOR
Status: OWNERSHIP_SELECTION_PENDING
```

## Baton Stage: Execution Hand-Off (Waiting for Student TODO)

Use this only after plan approval, concept-gate evidence, and ownership selection when student-owned `// TODO (Student)` items remain open.

```text
Mode: MAXIMIZE STUDENT CAPABILITY

What the agent changed:
- ...

Why these files:
- ...

Student TODO:
- File: ...
- Task: ...
- Constraints: ...

NEXT:
Implement the TODO, then tell me what you changed and why.

Workflow Stage: EXECUTION_AGENT
Status: WAITING_FOR_STUDENT
```

## Baton Stage: Execution Complete (Ready for Code Learning Review)

Use this only after all slice code (including student-owned `TODO`s) is implemented.

```text
Mode: MAXIMIZE STUDENT CAPABILITY

Completed slice files:
- ...

NEXT:
Proceed to CODE_LEARNING_REVIEWER to walk through the completed code and update Learning/MAUI-Learning-Book.md in Hebrew.

Workflow Stage: EXECUTION_AGENT
Status: CODE_LEARNING_REVIEW_PENDING
```

## Baton Stage: Code Learning Reviewer

```text
Mode: MAXIMIZE STUDENT CAPABILITY

Code walk-through & layer responsibilities:
- ...

Learning book update (Hebrew with English identifiers):
- Updated: Learning/MAUI-Learning-Book.md

Reflection / Comprehension questions on student-authored code:
1. ...
2. ...

NEXT:
Answer the reflection questions so we can record applied coding evidence and run verification.

Workflow Stage: CODE_LEARNING_REVIEWER
Status: LEARNING_REVIEW_WITH_STUDENT
```

## Baton Stage: Verification

```text
Mode: MAXIMIZE STUDENT CAPABILITY

Evidence:
- Build: ...
- Tests: ...
- Scripts: ...
- Manual checks: ...

Review:
- What worked: ...
- What needs correction: ...

Workflow Stage: VERIFICATION_AUDITOR
Status: COMPLETE
```
*(or `Status: READY_TO_VERIFY` / `Status: BLOCKED`)*
