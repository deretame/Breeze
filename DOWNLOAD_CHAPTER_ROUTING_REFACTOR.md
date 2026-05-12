# Download Chapter Routing Refactor

## Background

The current download pipeline mixes multiple concepts into a small set of fields:

- `chapterId`
- `order`
- `requestId`

This works for simple plugins, but breaks down once a plugin needs:

1. one logical chapter for storage/history
2. multiple request chunks for transport
3. different display names for chunk entries

`ehentai` exposed this problem first, but the issue is host-side and affects other plugins as soon as the host starts guessing routing ids.

The concrete regression seen during this round:

- `bikaComic` expects `getChapter.chapterId` to be a numeric order
- host inferred `requestId` from `ep.id`
- host then preferred `requestId` during download
- plugin received a string id instead of numeric order
- plugin failed with `chapterId 不能为空`

This means:

- host must not synthesize request routing ids from unrelated plugin fields
- host must carry complete chapter routing context into download tasks

## Goal

Move download chapter selection from a single-string protocol to an object protocol.

Instead of:

```dart
selectedChapters: List<String>
chapterExternById: Map<String, Map<String, dynamic>>
```

use a full chapter payload:

```dart
class DownloadChapterRef {
  final String chapterId;
  final String requestId;
  final String storageChapterId;
  final String title;
  final int order;
  final Map<String, dynamic> extern;
}
```

Notes:

- `chapterId`: logical chapter identity
- `requestId`: plugin-defined request routing id, optional
- `storageChapterId`: final storage grouping id
- `title`: UI display title
- `order`: compatibility/display sort only
- `extern`: original plugin chapter payload

## Field Semantics

### chapterId

Meaning:

- logical chapter identity
- used for history and chapter ownership

Rules:

- host can read it
- host should not rewrite it
- storage may use this directly unless plugin-specific grouping wants a separate storage key

### requestId

Meaning:

- request routing identity for plugin `getChapter` / `getReadSnapshot`

Rules:

- only valid when explicitly provided by plugin
- host must never synthesize it from `id`
- host may fall back to `chapterId` when calling plugin if `requestId` is empty
- host should not persist fake `requestId = id` values

### storageChapterId

Meaning:

- final chapter bucket for downloaded images

Rules:

- for most plugins: `storageChapterId == chapterId`
- for EH chunk downloads: multiple chunks share one `storageChapterId`

### order

Meaning:

- display sort only

Rules:

- do not use as unique identifier
- do not use as storage key
- only use as compatibility fallback for very old plugins when nothing else exists

## Proposed Data Flow

### 1. Comic detail parsing

When building chapter refs from plugin detail:

- preserve plugin `id`
- preserve plugin `extern`
- extract explicit `extern.requestId` only
- do not invent `requestId`
- optionally precompute `storageChapterId`

### 2. Download page selection

Selection state should not use `order`.

Use:

```dart
selectionKey =
  requestId if non-empty
  else chapterId if non-empty
  else order.toString()
```

Important:

- `selectionKey` is UI/task-local only
- do not persist it as plugin routing data

### 3. Download task payload

Current:

```dart
selectedChapters: List<String>
chapterExternById: Map<String, Map<String, dynamic>>
```

Replace with:

```dart
selectedChapters: List<DownloadChapterRef>
```

That removes host-side reverse lookup and prevents context loss.

### 4. Plugin chapter fetch

When calling plugin `getChapter`:

```dart
final requestChapterId =
  chapter.requestId if non-empty
  else chapter.chapterId
  else chapter.order.toString()
```

And pass:

```dart
core: {
  'comicId': comicId,
  'chapterId': requestChapterId,
}

extern: {
  ...chapter.extern,
  'chapterId': requestChapterId,
}
```

Important:

- current chapter id must overwrite stale extern chapter id
- host should not merge in any synthetic request ids

### 5. Download storage

Downloaded images should be grouped by:

```dart
storageChapterId
```

not by response `epId` when chunk requests are merged.

## Practical Migration Plan

### Phase 1: Task structure refactor

Change `DownloadTaskJson`:

- remove `selectedChapters: List<String>`
- remove `chapterExternById`
- add `selectedChapters: List<Map<String, dynamic>>` or typed model

Suggested chapter JSON shape:

```json
{
  "chapterId": "...",
  "requestId": "...",
  "storageChapterId": "...",
  "title": "...",
  "order": 1,
  "extern": {}
}
```

### Phase 2: Download page writer

When user starts a download:

- write full selected chapter objects into task payload
- stop building reverse lookup maps

### Phase 3: Task reader

In `unified_download_task.dart`:

- read selected chapter objects directly
- stop resolving through `selectedIds.contains(...)`
- stop looking up `chapterExternById[...]`

### Phase 4: Storage save path

Save chapters using `storageChapterId`.

### Phase 5: Cleanup compatibility

After the new task format is stable:

- reduce old fallback logic around `order`
- keep compatibility only at plugin boundary

## Minimal Host Rules After Refactor

### For request routing

- use explicit `requestId` if plugin gave one
- else use `chapterId`
- else use `order` only as last-ditch compatibility

### For storage

- use `storageChapterId`

### For display

- use `title`

### For selection

- use `selectionKey`

## Things The Host Should Stop Doing

- do not infer `requestId` from `id`
- do not use `order` as unique chapter identity
- do not use response `epId` as final storage key in chunked workflows
- do not rebuild plugin routing context from partial fields if full chapter payload is available

## Why This Is Better

This separates:

1. logical identity
2. request routing
3. storage grouping
4. UI sorting

Once these are separate, EH chunking becomes a plugin-specific transport concern instead of a host-wide identity bug source.

It also avoids future regressions for plugins like:

- Bika
- JM
- ZaiManHuan

which may each interpret chapter identifiers differently.

## Recommended Next Step

Tomorrow's first change should be:

1. redefine `DownloadTaskJson`
2. pass full selected chapter objects into task payload
3. remove `chapterExternById` from the download task path

That is the cleanest point to stop the current `order/id/requestId` confusion from spreading further.
