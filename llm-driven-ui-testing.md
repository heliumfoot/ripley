# LLM-Driven UI Testing (Half-Baked Idea)

> **Status: Partially formed — not ready for implementation. Captured here for future refinement.**

## Core Idea

Use a vision-capable LLM as the "brain" for automated UI tests. Instead of writing tests that reference hardcoded accessibility identifiers or coordinates, a test feeds the LLM a screenshot of the current screen and a plain-language instruction. The LLM responds with what to tap — either a control name or screen coordinates — and the test framework executes the tap and advances to the next state.

The loop looks like:

1. Screen appears
2. Screenshot is taken
3. Screenshot + instruction prompt is sent to the LLM
4. LLM responds with a control or coordinate to tap
5. Test framework executes the tap
6. Repeat

## Why This Is Interesting

- Tests describe *intent*, not implementation — "log in as a guest" rather than `app.buttons["guestLoginButton"].tap()`
- Tests don't break when UI is redesigned, only when behavior changes
- The same test script could potentially run across platforms (iOS, Android, web) with minimal adaptation

## Open Questions

- How does the LLM communicate what to tap? Accessibility label? Coordinate pair? Both?
- How do you assert outcomes — does the LLM also evaluate whether the resulting screen looks correct?
- What's the failure mode when the LLM is wrong or ambiguous?
- How slow would this be in practice given the LLM round-trip per interaction?
- Does this work best for high-level flow tests (smoke tests) rather than exhaustive UI coverage?
- Is XCUITest the right host, or would a lower-level screenshot + tap API be cleaner?
