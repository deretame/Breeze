# rquickjs_playground: Boa Engine Migration Assessment

## Summary

This document records an initial engineering assessment of migrating
`rquickjs_playground` from `rquickjs`/QuickJS to `boa_engine`.

Current conclusion:

- Migrating to `boa_engine` is a reasonable direction if the primary goal is
  to improve build ergonomics and reduce native toolchain friction.
- This is not a dependency swap. It is a runtime backend rewrite for the JS
  engine integration layer.
- The migration should be treated as a phased project with validation gates,
  not as an all-at-once replacement.

This document is intentionally scoped to `rquickjs_playground`.

## Motivation

The main motivation is build and maintenance cost around the current QuickJS
integration.

Observed concerns:

- `rquickjs_playground/Cargo.toml` currently depends on:

  ```toml
  rquickjs = { version = "0.11.0", features = ["bindgen"] }
  ```

- The `bindgen` path introduces extra host requirements, especially LLVM/Clang.
- First-time builds and CI setup are heavier than desirable.
- For a Flutter + Rust mixed project, native toolchain complexity directly
  affects contributor experience and cross-platform reliability.

By contrast, `boa_engine` is implemented in Rust and is expected to provide a
 simpler build story with less external tooling friction.

## Why Boa Is Worth Considering

The case for Boa is not that it is universally better than QuickJS. The case
is that it may be a better fit for this repository's constraints.

Expected benefits:

- Simpler local setup for contributors.
- Lower CI environment complexity.
- Fewer platform-specific issues caused by external C toolchain requirements.
- Better alignment with a Rust-first embedding model.

Secondary potential benefits:

- Easier long-term maintenance of the Rust integration layer.
- More predictable dependency behavior across development environments.

## Important Constraint: This Crate Is Not a Thin JS Wrapper

`rquickjs_playground` is already a full host runtime layer, not just a place
that evaluates arbitrary JavaScript.

It currently provides:

- JS runtime lifecycle management
- Promise/job pumping
- host function registration
- web-like polyfills
- `fetch`
- async `fs`
- native binary buffer bridging
- bridge routes into the Rust host
- optional WASI execution support

This matters because a migration to Boa is mainly about re-implementing how
these runtime capabilities are attached to the engine.

## Existing Coupling to QuickJS

The current implementation is deeply coupled to `rquickjs` APIs and the
QuickJS execution model.

Key coupling points include:

- `Runtime` and `Context` ownership patterns
- `Ctx`-based global installation
- `Func::from(...)` and `Function::new(...)`
- explicit pending-job pumping
- promise/microtask execution assumptions
- JS value conversion around strings, JSON, and byte buffers

Relevant files:

- `src/host_runtime.rs`
- `src/web_runtime.rs`

Representative examples of current coupling:

- direct use of `Context::full(...)`
- direct use of `Runtime::new()`
- registration through `ctx.globals().set(...)`
- explicit calls to:
  - `is_job_pending()`
  - `execute_pending_job()`

Because of this, migration work belongs in the runtime backend, not in the
consumer-facing Dart or FRB API surface unless a limitation forces change.

## What Should Stay Stable

If migration proceeds, the first engineering goal should be preserving the
public contract of this crate as much as possible.

Stability targets:

- `AsyncHostRuntime`
- `AsyncHostRuntimeBuilder`
- task spawning and waiting model
- bundle loading and invocation model
- `WebRuntimeOptions`
- host bridge APIs
- existing Rust-side exports consumed by the parent `rust` crate

If consumers can continue using the current API while the backend changes,
migration risk drops substantially.

## What Will Need To Change Internally

At minimum, the following internal areas should be expected to change:

1. Engine initialization
2. Global host binding registration
3. Promise/job execution and scheduling
4. JS function lookup and invocation
5. JS-to-Rust and Rust-to-JS value marshalling
6. Typed array / `ArrayBuffer` interop
7. Error shaping and stack propagation

High-risk internal topics:

- microtask semantics
- timer interaction with promise completion
- byte buffer ownership and zero-copy assumptions
- any behavior that currently relies on QuickJS-specific execution ordering

## Compatibility Considerations

The deciding factor is not abstract ECMAScript compliance alone.

What matters here is:

- whether the plugin bundles used by the application run correctly
- whether host APIs keep behaving consistently
- whether async behavior remains predictable

For this crate, compatibility must be evaluated at three layers:

1. Language/runtime semantics
2. Host integration semantics
3. Real plugin workload behavior

Even if Boa is "compatible enough" at the language level, migration can still
fail if host integration semantics diverge in ways that affect current bundles.

## Major Risk Areas

### 1. Async Execution Model

The current runtime explicitly pumps pending JS jobs. If Boa exposes a
different model, the crate may need a different runtime loop design.

Risk:

- promise completion timing changes
- tasks that currently resolve may stall or resolve in a different order
- tests around timers and task waiting may need redesign

### 2. Typed Arrays and Binary Bridge

This crate makes serious use of `Uint8Array`, `ArrayBuffer`, and host-managed
binary buffers.

Risk:

- extra copying
- ownership mistakes
- performance regressions
- behavior differences in buffer views and slicing

### 3. Error Surface

The crate currently shapes errors with runtime context and JS stack data.

Risk:

- lower quality diagnostics
- missing stack details
- changed error messages that break assumptions in tests or higher layers

### 4. Polyfill Assumptions

A large part of the runtime behavior is implemented in injected JS. That is
good for portability, but those polyfills still rely on specific engine
behavior.

Risk:

- subtle differences in global object behavior
- differing Promise/microtask edge cases
- changed semantics around functions, prototypes, or property access

### 5. WASI Is Separate But Not Free

The WASI path is host-side and does not directly depend on QuickJS as an
engine implementation detail. However, the JS-facing integration still does.

Risk:

- the host-side WASI executor stays fine, but the JS surface exposed to call it
  needs re-integration and re-validation

## Benefits If Migration Succeeds

If the migration succeeds, expected repository-level gains are:

- easier onboarding
- simpler CI
- fewer external build prerequisites
- lower maintenance cost for engine setup

The primary benefit is operational, not feature-driven.

## Recommended Migration Strategy

Do not replace the engine in-place without creating an abstraction boundary.

Recommended phases:

### Phase 0: Freeze Scope

Define what the first Boa-backed milestone must support.

Recommended minimum scope:

- create runtime
- evaluate JS
- load bundle
- invoke exported function with JSON arguments
- return JSON or bytes

Explicitly defer:

- `fs`
- `fetch`
- `wasi`
- advanced native buffer optimizations

unless validation shows one of them is required to prove viability.

### Phase 1: Introduce an Engine Adapter Boundary

Extract a minimal engine-facing abstraction from the existing runtime code.

Example responsibility split:

- host runtime orchestration remains crate-owned
- engine adapter owns:
  - engine/context creation
  - global binding installation
  - code evaluation
  - callable lookup
  - job/microtask execution
  - value conversion hooks

This phase should not change behavior.

### Phase 2: Implement a Minimal Boa Backend

Build a minimal backend that supports:

- runtime boot
- bootstrap/polyfill injection
- bundle loading
- function invocation
- promise completion path

Success criterion:

- a narrow set of smoke tests passes
- at least one real plugin bundle can execute core calls successfully

### Phase 3: Validate Real Workloads

Use real plugin bundles first, not synthetic tests only.

Suggested validation order:

1. bundle `init`
2. simple JSON-returning calls
3. byte-returning calls
4. repeated task start/wait patterns
5. cancellation behavior

If this phase fails, stop before porting the rest of the runtime.

### Phase 4: Port Host Features Incrementally

Recommended order:

1. timers / task utilities
2. `fetch`
3. native binary bridge
4. `fs`
5. `wasi`

This order minimizes the chance of doing expensive work before the core engine
fit is proven.

### Phase 5: Dual Backend Period

If practical, keep the QuickJS backend available behind a feature flag during
validation.

Possible strategy:

- `quickjs-backend`
- `boa-backend`

This gives a safer rollback path and allows side-by-side comparison during the
transition.

## Success Criteria

The migration should be considered successful only if all of the following are
true:

- contributor setup is materially simpler
- CI setup is materially simpler
- real plugin bundles run without user-visible regressions
- async task behavior remains stable enough for current callers
- binary-returning flows remain correct
- performance is acceptable for current workloads

Note that "acceptable" is enough. This does not need to beat QuickJS in every
benchmark to be a good migration.

## Non-Goals For The First Migration Pass

The first pass should not try to:

- redesign the external runtime API
- redesign the plugin execution model
- rewrite JS polyfills for style reasons
- optimize every binary path immediately
- improve unrelated architecture in the parent `rust` crate

Keeping scope tight is important. The migration is already large.

## Current Recommendation

Proceed only if the team accepts the following framing:

- this is an engine backend rewrite
- the main payoff is build and maintenance ergonomics
- the project should be validated in phases
- real plugin bundles are the deciding benchmark

Recommended next step:

- write a small technical design for an engine abstraction layer inside
  `rquickjs_playground`
- then build a minimal Boa prototype before committing to full migration

## Open Questions

These should be answered before implementation starts:

1. Which real plugin bundles are the required compatibility targets?
2. Which current tests define non-negotiable behavior?
3. Is dual-backend support acceptable during migration?
4. Are there any consumers depending on QuickJS-specific error messages?
5. Is the goal complete replacement, or "Boa by default with fallback"?

