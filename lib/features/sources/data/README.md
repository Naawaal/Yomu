# Sources Data Layer

This folder owns the runtime bridge between the native extension host and the domain layer for source execution.

## Boundary Summary

- `datasources/` talks to the host bridge and returns raw host payloads.
- `parsers/` converts host payloads into domain entities.
- `repositories/` coordinates bridge access, parser usage, and failure mapping.
- `mappers/` translates bridge/runtime error codes into typed failures.

## Current Runtime Flow

1. `SourceRuntimeRepositoryImpl` receives a `SourceRuntimeRequest` from the domain layer.
2. `MethodChannelSourceRuntimeBridgeDataSource` checks host capabilities and executes the requested runtime operation.
3. The datasource delegates payload-to-domain conversion to `SourceRuntimePageParser`.
4. `DefaultSourceRuntimePageParser` preserves the current fallback behavior for missing `sourceId` values.
5. Repository-level error handling maps parse and bridge failures into `Either<Failure, SourceRuntimePage>`.

## Parser Boundary Rules

- Parser code must stay in `data/parsers/` and should not depend on presentation code.
- Datasources should not inline payload mapping once a parser contract exists.
- Parsers should be deterministic and keep identifier fallback behavior stable.
- Repository code owns failure normalization, not parser code.

## Why This Boundary Exists

This split keeps bridge transport concerns separate from payload interpretation.
It also makes the runtime mapping logic easier to test, swap, and extend when source schemas change.

## Extending the Layer

When adding a new runtime payload shape:

1. Add or extend a parser contract in `data/parsers/`.
2. Keep the datasource focused on capability checks and host invocation.
3. Add repository tests for `Either` and failure mapping behavior.
4. Update this document if the runtime boundary or responsibilities change.
