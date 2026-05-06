---
name: tdd
description: Test-driven development with red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, or asks for test-first development. HITL only — AFK loops should read CODING_STANDARDS.md directly, never invoke this skill.
---

# Test-Driven Development

If `CODING_STANDARDS.md` exists at the repo root, read it (sections: TDD, Tests, Mocking, Interface Design, Deep Modules, Refactoring) and follow its rules — that file is the canonical doctrine for this repo. Otherwise use the bundled defaults that follow.

This skill is **HITL only**. The "Get user approval on the plan" step in §Workflow is mandatory and blocks on user input. AFK loops (e.g. `.looper/PROMPT_BUILD.md`) must not invoke this skill — they read `CODING_STANDARDS.md` directly.

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (like querying a database directly instead of using the interface). The warning sign: your test breaks when you refactor, but behavior hasn't changed.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" — treating RED as "write all tests" and GREEN as "write all code." It produces tests that verify imagined behavior, not actual behavior.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
```

## Workflow

### 1. Planning

Use the project's `docs/CONTEXT.md` glossary so test names and interface vocabulary match the project's language. Respect ADRs in the area you're touching.

Before writing any code:

- [ ] Confirm with user what interface changes are needed.
- [ ] Confirm with user which behaviors to test (prioritize).
- [ ] Identify opportunities for [deep modules](deep-modules.md) (small interface, deep implementation).
- [ ] Design interfaces for [testability](interface-design.md).
- [ ] List the behaviors to test (not implementation steps).
- [ ] Get user approval on the plan. **(HITL gate — do not proceed without it.)**

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This proves the path works end-to-end.

### 3. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:

- One test at a time.
- Only enough code to pass current test.
- Don't anticipate future tests.
- Keep tests focused on observable behavior.

### 4. Refactor

After all tests pass, look for [refactor candidates](refactoring.md).

**Never refactor while RED.** Get to GREEN first.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```
