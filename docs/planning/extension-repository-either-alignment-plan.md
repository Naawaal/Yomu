# Extension Repository Either Alignment Plan

## Purpose

This document captures the follow-up plan for aligning the extension repository contract with the `Either<Failure, T>` pattern already used in the sources runtime path.

This is intentionally separated from the source runtime parser boundary work and should be handled in a dedicated change set.

## Current State

The extension repository API still mixes typed failures and exceptions:

- `getAvailableExtensions()` returns `Future<List<ExtensionItem>>`
- `trust()` throws `ExtensionTrustException` on platform errors
- `install()` throws `ExtensionInstallException` for native install outcomes and platform failures
- fallback behavior is still routed through a bridge repository and native host client

This differs from the newer sources runtime path, where repository boundaries already return `Either<Failure, T>`.

## Goal

Move extension repository operations toward a consistent failure model without breaking current callers all at once.

Target outcome:

- repository contracts are explicit about recoverable failures
- platform/bridge exceptions are mapped at the data boundary
- callers receive typed `Failure` values instead of ad hoc exception handling where practical

## Recommended Approach

### Phase 1: Introduce typed result wrappers behind the existing API

- Add new methods or adapter classes that return `Either<Failure, T>` for extension list, trust, and install operations
- Keep the current repository interface stable until consumers are migrated
- Preserve existing fallback behavior for unsupported capabilities and missing plugins

### Phase 2: Normalize bridge error mapping

- Map platform exception codes to shared failure types at the data layer
- Reuse the existing `Failure` hierarchy instead of introducing extension-specific exception handling in new paths
- Keep user-action cases explicit, especially install flows that require consent or recovery

### Phase 3: Migrate consumers incrementally

- Update presentation/controller code to consume typed failures where the calling flow benefits from it
- Remove exception-based branches only after the new result-based path is validated
- Add regression tests for both success and failure branches before deleting legacy handling

## Risks

- A full interface swap would be too disruptive for current extension callers
- Install flows have a user-action branch that should not be flattened into generic failure handling without preserving the code/message context
- Dual contract support can temporarily increase maintenance cost, so migration should be staged

## Non-Goals

- No code changes in the current source runtime parser boundary feature
- No redesign of the extension host protocol in this follow-up alone
- No UI changes until the repository contract migration is stable

## Acceptance Criteria

- New extension repository paths can return `Either<Failure, T>` without breaking current runtime behavior
- Failure mapping is deterministic and test-covered
- Existing callers continue to work during the migration window
- The old exception-based paths are only removed after consumer migration is complete
