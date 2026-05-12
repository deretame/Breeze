# HostRuntime Context Pool Design

## Background

`AsyncHostRuntime` currently runs a single `HostRuntime` on a dedicated worker thread.  
`HostRuntime` currently owns a single QuickJS `Context`:

```rust
pub struct HostRuntime {
    runtime: Runtime,
    context: Context,
    cache_scope_id: String,
    options: WebRuntimeOptions,
}
```

This model works well for the normal runtime path because:

- one runtime instance maps to one dedicated system thread
- one `Context` is reused for normal async task execution
- JS globals, host bindings, timers, and bundle helpers stay attached to that one execution world

The problem appears in the `bundle_call_once_start` path.

## Problem

`bundle_call_once_start` is used for isolated one-shot bundle execution. In debug scenarios we want:

- no CommonJS / bundle registry pollution across runs
- no leaked global state between one-shot executions
- behavior close to a fresh environment per call

The current isolation approach effectively forces strict serialization:

- execute on the shared context
- clear or isolate state before/after execution
- protect the cleanup path with a lock

That removes useful async concurrency inside a single runtime instance.  
The issue is not CPU parallelism. The issue is that debug-time isolation collapses naturally concurrent async work into a single serialized path.

More precisely:

- the worker thread is still allowed to drive multiple async tasks forward
- but one-shot execution currently funnels through one shared isolated context path
- cleanup requirements force a lock around that path
- so independent async one-shot calls lose overlap and behave like a queue

That is the bottleneck this design is trying to remove.

## Goal

Restore async concurrency for isolated one-shot bundle execution without changing the published runtime model for normal execution.

Concretely:

- normal runtime path keeps using the primary context
- `bundle_call_once_start` uses isolated contexts from a pool
- one-shot executions no longer need to serialize on one shared cleanup lock
- published / non-debug path should not pay meaningful extra complexity or runtime cost

## Non-goals

This proposal does **not** try to:

- make QuickJS execution multi-threaded
- run one `AsyncHostRuntime` across multiple worker threads
- redesign all runtime APIs to become multi-context aware
- move the runtime model to a Tokio-managed worker architecture

This is not a general multi-context runtime redesign. It is a targeted isolation mechanism for one-shot bundle execution.

## Why not switch thread management to Tokio

That would solve a different problem.

Today the main runtime model is already simple and stable:

- one `AsyncHostRuntime`
- one dedicated system thread
- one `HostRuntime` living on that thread
- one primary QuickJS `Runtime` + `Context` pair for the normal path

Moving the worker model to Tokio would not automatically fix the current slowdown because:

- the slowdown comes from one-shot isolation being serialized on one shared context path
- QuickJS execution is still fundamentally thread-affine here
- the normal runtime path is not the thing causing the debug bottleneck

So a Tokio-managed worker redesign would be broader, riskier, and not directly aimed at the observed regression.

The context-pool approach is narrower:

- keep the stable worker-thread model
- keep the normal persistent context path
- only add isolated contexts where the debug bottleneck actually appears

## Proposed approach

Keep the current primary context, and add a secondary context pool dedicated to isolated one-shot execution.

Suggested shape:

```rust
pub struct HostRuntime {
    runtime: Runtime,
    context: Context,
    pooled_contexts: Vec<ContextSlot>,
    cache_scope_id: String,
    options: WebRuntimeOptions,
}

struct ContextSlot {
    context: Context,
    busy: bool,
}
```

Notes:

- `context` remains the primary context for existing runtime behavior
- `pooled_contexts` are used only by `bundle_call_once*`
- a slot stays owned by one in-flight one-shot execution until completion
- this is thread-local state inside the worker thread; no extra cross-thread locking should be needed for slot ownership itself

## Why not replace `context` with `Vec<Context>` directly

Replacing the primary field outright would imply a much broader redesign:

- all context accessors become multi-context aware
- host event callbacks need explicit routing to a target context
- dispatcher installation becomes multi-context by default
- tests and runtime semantics would shift even for normal execution

That is more invasive than the problem requires.

Keeping:

- one primary context
- one dedicated isolated context pool

lets us solve the debug bottleneck without destabilizing the rest of the runtime.

It also matches the actual use case better:

- most runtime features still want one long-lived context with persistent globals
- only isolated `bundle_call_once*` execution wants fresh-world semantics

So turning the whole runtime into a pooled-context system would spread complexity into code paths that do not benefit from it.

## Expected benefit

This does not introduce multi-core parallel execution.  
It restores **single-thread async concurrency** for isolated one-shot tasks.

Today, if all one-shot calls share one cleanup-locked context:

- task A starts
- task B must wait for task A to fully finish and cleanup

With a pool:

- task A gets slot 0
- task B gets slot 1
- both tasks can exist concurrently in the same runtime worker
- the worker still pumps jobs on one thread, but tasks no longer serialize on a single shared isolated context

That is the intended improvement.

This is best understood as recovering **concurrent progress** inside one runtime instance, not as increasing raw CPU parallel compute.

## Scope of first implementation

Only these paths should use the pool in the first version:

- `bundle_call_once_start`
- `bundle_call_once`
- `bundle_call_once_bytes`

Normal paths should stay unchanged:

- `spawn`
- bundle load / invoke on the persistent runtime
- host event routing
- timer / fetch / fs / wasi callback plumbing

This keeps the first implementation small and easy to validate.

That scope limit matters.  
If the first version starts changing the normal runtime path, it becomes much harder to tell whether a regression comes from the pool itself or from a broader execution-model change.

## Context lifecycle options

There are two viable strategies for pooled slots after a one-shot execution completes.

### Option A: reset by rebuilding the slot

After the task completes:

- discard the used context
- create a fresh context in the same slot
- reinstall polyfills / bindings / bundle dispatcher

Pros:

- strongest isolation guarantee
- easiest reasoning
- avoids subtle cleanup misses

Cons:

- pays context creation + initialization cost per completed use

### Option B: explicit cleanup and reuse

After the task completes:

- clear bundle/global pollution from the slot
- reuse the same context object

Pros:

- potentially faster

Cons:

- much easier to get wrong
- hard to prove cleanup completeness
- risks recreating the current debug pollution issue in a different form

### Recommendation

Start with **Option A** for correctness.

This feature exists to avoid debug-time contamination. Isolation is more important than squeezing maximum reuse out of one-shot slots on the first pass.

That recommendation is especially important because the motivation here is developer workflow.  
If the pool is fast but occasionally leaks bundle registry or global pollution, it fails the primary requirement.

## Initialization requirements for each pooled context

Each pooled context must receive the same minimum initialization as the primary runtime context for one-shot bundle execution:

- host bindings
- polyfill script
- bundle dispatcher support used by `bundle_call_once*`

The initialization should be factored so the same setup path can be applied to:

- the primary context
- a newly created pooled context slot

This likely means extracting a reusable helper in `HostRuntime`.

## Slot ownership model

Each one-shot task must reserve exactly one slot for its full lifetime.

That means:

- `bundle_call_once_start` chooses a free slot
- the slot is marked busy immediately
- the returned task handle must carry enough information to release the slot on completion / drop / failure
- once the task reaches a final state, the slot is released and reset

The important part is that slot lifetime follows task lifetime, not only synchronous submission lifetime.

This is the main reason the implementation should be centered around task ownership, not just around “pick a context, run some code, put it back”.

## API impact

External API impact should be minimal.

Expected external behavior:

- existing APIs stay the same
- `bundle_call_once_start` just becomes less serialized in debug-heavy workflows

Internal additions likely needed:

- slot acquisition helper
- slot release helper
- pooled-context initialization helper
- pooled-context rebuild helper
- task metadata linking a one-shot task to its slot

## Suggested internal model

One simple direction:

```rust
struct ContextSlot {
    context: Context,
    busy: bool,
}

struct OneShotTaskContext {
    slot_index: usize,
}
```

And associate the slot index with the in-flight task state for one-shot tasks.

Because the worker thread owns execution, slot mutation can remain internal to the worker thread model instead of becoming shared global state.

## Interaction with `bundle_call_once_lock`

Current `bundle_call_once_lock` exists to serialize one-shot execution.

With a working context pool:

- the global serialization lock should no longer be the main isolation mechanism
- it may be removable entirely
- or temporarily retained only around tiny critical sections during migration

Target end state:

- no lock-based full serialization of one-shot calls
- slot ownership provides isolation instead

## Risks

### 1. Hidden assumptions about a single context

Some code may implicitly assume:

- one dispatcher instance
- one bundle registry
- one global callback surface

The first implementation avoids most of that risk by restricting pooled contexts to `bundle_call_once*`.

### 2. Task completion and slot release bugs

If a one-shot task completes, errors, or gets dropped and its slot is not released:

- pool capacity shrinks
- later calls may block or fail permanently

This part must be tested carefully.

### 3. Context rebuild cost

If rebuilding a slot after each use is too expensive, the optimization may help less than expected.

Even then, it still gives a correctness-first baseline and a clean place to optimize later.

## Testing plan

Add tests focused on the new pool behavior:

1. multiple `bundle_call_once_start` calls can be in flight without serializing on one global lock
2. slot is released after successful completion
3. slot is released after failure
4. slot is released after task handle drop / cancellation
5. bundle/global state does not leak across pooled one-shot executions
6. normal runtime path still behaves exactly as before

## Implementation notes for the first pass

The safest first pass is likely:

1. factor context creation and initialization into a reusable helper
2. keep `HostRuntime.context` exactly as the primary context
3. add a small internal pool dedicated to isolated one-shot calls
4. route only `bundle_call_once_start` / `bundle_call_once` / `bundle_call_once_bytes` through that pool
5. rebuild a slot after completion instead of trying to deeply scrub it

This keeps the change aligned with the problem statement and avoids turning the refactor into a general runtime rewrite.

## Rollout plan

### Step 1

Refactor `HostRuntime` initialization so a fresh context can be created and initialized via a reusable helper.

### Step 2

Add `pooled_contexts` and slot tracking to `HostRuntime`.

### Step 3

Route only `bundle_call_once*` through the pool.

### Step 4

Release / rebuild slot on task completion.

### Step 5

Remove or narrow the old `bundle_call_once_lock` behavior.

## Summary

This proposal is a targeted optimization for debug-time isolated bundle execution.

It intentionally does **not** redesign the whole runtime into a general multi-context system.

The recommended first version is:

- keep the primary context
- add a dedicated pooled context set for `bundle_call_once*`
- rebuild slot contexts after use
- remove full serialization caused by the old cleanup-lock approach

This should recover the async concurrency that was lost in debug mode while keeping the normal runtime path stable.
