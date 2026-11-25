# MockMate Architecture Design

This document records the architectural structure and technical decisions of MockMate.

## Core Design Principles

1. Engine Decoupling:
   The core mocking engine in `packages/mockmate` is pure Dart. It has zero dependencies on Flutter, allowing it to execute in server apps, command line utilities, background workers, and unit tests.

2. Determinism by Default:
   To ensure test suites execute swiftly without flaky test results, network latency and delays rely on an injectable `DelayProvider`. In unit tests, `ZeroDelayProvider` eliminates pauses entirely.

3. Layered Request Pipeline:
   Incoming requests pass through a sequence:
   - Network simulation layer (checks offline mode, timeouts, jitter)
   - Scenario resolution layer (matches route/global scenario overrides)
   - Route resolution layer (matches HTTP method, path parameters, wildcards, query parameters, and headers)
   - Request recorder layer (captures transaction metadata while masking secret tokens and credentials)

4. Developer Security:
   `RedactionRules` sanitizes sensitive values from authorization headers, cookies, API keys, and credential fields before saving them in memory or presenting them in the inspector.
