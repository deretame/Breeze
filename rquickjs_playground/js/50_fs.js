(() => {
  const { stringToArrayBuffer } = globalThis.__web;
  const EVENTED_FS_PENDING = new Map();

  globalThis.__host_runtime_fs_complete = function __host_runtime_fs_complete(requestId, payloadRaw) {
    const pending = EVENTED_FS_PENDING.get(Number(requestId));
    if (!pending) return;
    EVENTED_FS_PENDING.delete(Number(requestId));

    const { resolve, reject, finish, mapResult, path } = pending;
    let payload;
    try {
      payload = JSON.parse(String(payloadRaw || "{}"));
    } catch (err) {
      finish(() => reject(err));
      return;
    }
    if (!payload.ok) {
      finish(() => reject(createFSError(payload, path)));
      return;
    }
    finish(() => resolve(mapResult ? mapResult(payload) : undefined));
  };

  class MiniEmitter {
    constructor() {
      this._events = new Map();
    }

    on(event, listener) {
      if (typeof listener !== "function") return this;
      const list = this._events.get(event) || [];
      list.push({ listener, once: false });
      this._events.set(event, list);
      return this;
    }

    once(event, listener) {
      if (typeof listener !== "function") return this;
      const list = this._events.get(event) || [];
      list.push({ listener, once: true });
      this._events.set(event, list);
      return this;
    }

    off(event, listener) {
      const list = this._events.get(event) || [];
      this._events.set(event, list.filter((item) => item.listener !== listener));
      return this;
    }

    emit(event, ...args) {
      const list = this._events.get(event) || [];
      if (list.length === 0 && event === "error" && args[0] instanceof Error) {
        throw args[0];
      }
      const next = [];
      for (const item of list) {
        item.listener(...args);
        if (!item.once) next.push(item);
      }
      this._events.set(event, next);
      return this;
    }
  }

  class FSError extends Error {
    constructor(message, code, path) {
      super(message || "文件系统操作失败");
      this.name = "Error";
      this.code = code || "EIO";
      if (path !== undefined) this.path = String(path);
    }
  }

  class Dirent {
    constructor(entry) {
      this.name = entry.name;
      this._isFile = Boolean(entry.isFile);
      this._isDirectory = Boolean(entry.isDirectory);
      this._isSymbolicLink = Boolean(entry.isSymbolicLink);
    }

    isFile() {
      return this._isFile;
    }

    isDirectory() {
      return this._isDirectory;
    }

    isSymbolicLink() {
      return this._isSymbolicLink;
    }
  }

  class Stats {
    constructor(raw) {
      this.size = Number(raw.size || 0);
      this.atimeMs = raw.atimeMs === null || raw.atimeMs === undefined ? null : Number(raw.atimeMs);
      this.mtimeMs = raw.mtimeMs === null || raw.mtimeMs === undefined ? null : Number(raw.mtimeMs);
      this.ctimeMs = raw.ctimeMs === null || raw.ctimeMs === undefined ? null : Number(raw.ctimeMs);
      this._isFile = Boolean(raw.isFile);
      this._isDirectory = Boolean(raw.isDirectory);
      this._isSymbolicLink = Boolean(raw.isSymbolicLink);
      this._readonly = Boolean(raw.readonly);
    }

    isFile() {
      return this._isFile;
    }

    isDirectory() {
      return this._isDirectory;
    }

    isSymbolicLink() {
      return this._isSymbolicLink;
    }

    get readonly() {
      return this._readonly;
    }

    get atime() {
      return this.atimeMs === null ? new Date(0) : new Date(this.atimeMs);
    }

    get mtime() {
      return this.mtimeMs === null ? new Date(0) : new Date(this.mtimeMs);
    }

    get ctime() {
      return this.ctimeMs === null ? new Date(0) : new Date(this.ctimeMs);
    }
  }

  class Dir {
    constructor(path, entries) {
      this.path = String(path);
      this._entries = entries || [];
      this._cursor = 0;
      this._closed = false;
    }

    read() {
      if (this._closed) return Promise.resolve(null);
      if (this._cursor >= this._entries.length) return Promise.resolve(null);
      const entry = this._entries[this._cursor];
      this._cursor += 1;
      return Promise.resolve(entry);
    }

    close() {
      this._closed = true;
      return Promise.resolve();
    }

    async *[Symbol.asyncIterator]() {
      while (true) {
        const item = await this.read();
        if (item === null) break;
        yield item;
      }
    }
  }

  class FileHandle {
    constructor(path, flags = "r") {
      this.path = String(path);
      this.flags = String(flags || "r");
      this._closed = false;
      this._position = 0;
    }

    _assertOpen() {
      if (this._closed) {
        throw new FSError("文件句柄已关闭", "EBADF", this.path);
      }
    }

    close() {
      this._closed = true;
      return Promise.resolve();
    }

    readFile(options) {
      this._assertOpen();
      return readFile(this.path, options);
    }

    writeFile(data, options) {
      this._assertOpen();
      return writeFile(this.path, data, options);
    }

    appendFile(data, options) {
      this._assertOpen();
      return appendFile(this.path, data, options);
    }

    stat() {
      this._assertOpen();
      return stat(this.path);
    }

    truncate(len = 0) {
      this._assertOpen();
      return truncate(this.path, len);
    }

    chmod(mode) {
      this._assertOpen();
      return chmod(this.path, mode);
    }

    utimes(atime, mtime) {
      this._assertOpen();
      return utimes(this.path, atime, mtime);
    }

    sync() {
      this._assertOpen();
      return Promise.resolve();
    }

    datasync() {
      this._assertOpen();
      return Promise.resolve();
    }

    read(buffer, offset = 0, length, position = null) {
      this._assertOpen();
      if (!(buffer instanceof Uint8Array)) {
        return Promise.reject(new FSError("buffer 必须是 Uint8Array", "EINVAL", this.path));
      }
      const effectiveLength = length === undefined ? buffer.length - offset : Number(length);
      const startPos = position === null || position === undefined ? this._position : Number(position);
      return readFile(this.path).then((fileBytes) => {
        const start = Math.max(0, startPos);
        const end = Math.max(start, Math.min(start + effectiveLength, fileBytes.length));
        const chunk = fileBytes.subarray(start, end);
        buffer.set(chunk, offset);
        const bytesRead = chunk.length;
        if (position === null || position === undefined) {
          this._position = start + bytesRead;
        }
        return { bytesRead, buffer };
      });
    }

    write(data, position = null, encoding) {
      this._assertOpen();
      const pos = position === null || position === undefined ? this._position : Number(position);
      const payload = normalizeWriteData(data);

      if (this.flags.includes("a")) {
        return appendFile(this.path, data, encoding).then(() => ({
          bytesWritten: payload.kind === "bytes" ? payload.data.length : String(payload.data).length,
          buffer: data,
        }));
      }

      return readFile(this.path)
        .catch(() => new Uint8Array(0))
        .then((current) => {
          const dataBytes = payload.kind === "bytes" ? Uint8Array.from(payload.data) : Uint8Array.from(String(payload.data), (c) => c.charCodeAt(0) & 0xff);
          const need = Math.max(current.length, pos + dataBytes.length);
          const merged = new Uint8Array(need);
          merged.set(current, 0);
          merged.set(dataBytes, pos);
          return writeFile(this.path, merged, encoding).then(() => {
            this._position = pos + dataBytes.length;
            return { bytesWritten: dataBytes.length, buffer: data };
          });
        });
    }
  }

  function toBytes(data) {
    if (data instanceof Uint8Array) return data;
    if (ArrayBuffer.isView(data)) return new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
    if (data instanceof ArrayBuffer) return new Uint8Array(data);
    const text = String(data);
    return Uint8Array.from(text, (c) => c.charCodeAt(0) & 0xff);
  }

  class ReadStream extends MiniEmitter {
    constructor(path, options = {}) {
      super();
      this.path = String(path);
      this.readable = true;
      this.destroyed = false;
      this.bytesRead = 0;
      this._encoding = options && options.encoding ? String(options.encoding) : undefined;
      this._highWaterMark = Number(options && options.highWaterMark) > 0 ? Number(options.highWaterMark) : 64 * 1024;
      this._autoClose = options && options.autoClose !== undefined ? Boolean(options.autoClose) : true;
      this._start = Number(options && options.start) || 0;
      this._end = options && options.end !== undefined ? Number(options.end) : null;

      Promise.resolve().then(() => {
        this.emit("open", 0);
        this.emit("ready");
        return readFile(this.path);
      }).then((allBytes) => {
        if (this.destroyed) return;
        const start = Math.max(0, this._start);
        const end = this._end === null ? allBytes.length - 1 : Math.min(allBytes.length - 1, this._end);
        if (end < start) {
          this._finish();
          return;
        }

        let offset = start;
        const emitChunk = () => {
          if (this.destroyed) return;
          if (offset > end) {
            this._finish();
            return;
          }
          const nextEnd = Math.min(offset + this._highWaterMark, end + 1);
          const chunk = allBytes.subarray(offset, nextEnd);
          offset = nextEnd;
          this.bytesRead += chunk.length;
          if (this._encoding) {
            this.emit("data", String.fromCharCode(...chunk));
          } else {
            this.emit("data", Uint8Array.from(chunk));
          }
          Promise.resolve().then(emitChunk);
        };

        Promise.resolve().then(emitChunk);
      }).catch((err) => {
        if (this.destroyed) return;
        this.emit("error", err);
        this._finish();
      });
    }

    _finish() {
      if (this.destroyed) return;
      this.readable = false;
      this.emit("end");
      if (this._autoClose) {
        this.destroy();
      }
    }

    pipe(dest) {
      this.on("data", (chunk) => {
        if (dest && typeof dest.write === "function") {
          dest.write(chunk);
        }
      });
      this.on("end", () => {
        if (dest && typeof dest.end === "function") {
          dest.end();
        }
      });
      this.on("error", (err) => {
        if (dest && typeof dest.emit === "function") {
          dest.emit("error", err);
        }
      });
      return dest;
    }

    destroy(err) {
      if (this.destroyed) return this;
      this.destroyed = true;
      this.readable = false;
      if (err) this.emit("error", err);
      this.emit("close");
      return this;
    }
  }

  class WriteStream extends MiniEmitter {
    constructor(path, options = {}) {
      super();
      this.path = String(path);
      this.writable = true;
      this.destroyed = false;
      this.bytesWritten = 0;
      this._flags = String((options && options.flags) || "w");
      this._encoding = options && options.defaultEncoding ? String(options.defaultEncoding) : undefined;
      this._autoClose = options && options.autoClose !== undefined ? Boolean(options.autoClose) : true;
      this._pending = Promise.resolve();

      this._pending = this._pending
        .then(() => {
          this.emit("open", 0);
          this.emit("ready");
          if (this._flags.includes("a")) return undefined;
          return writeFile(this.path, new Uint8Array(0));
        })
        .catch((err) => {
          this.emit("error", err);
          this.destroy(err);
        });
    }

    write(chunk, encoding, callback) {
      if (typeof encoding === "function") {
        callback = encoding;
        encoding = undefined;
      }
      if (!this.writable || this.destroyed) {
        const err = new FSError("流已结束", "ERR_STREAM_WRITE_AFTER_END", this.path);
        if (typeof callback === "function") callback(err);
        this.emit("error", err);
        return false;
      }

      const bytes = toBytes(chunk);
      this._pending = this._pending
        .then(() => {
          if (this._flags.includes("a")) {
            return appendFile(this.path, bytes, encoding || this._encoding);
          }
          return appendFile(this.path, bytes, encoding || this._encoding);
        })
        .then(() => {
          this.bytesWritten += bytes.length;
          this.emit("drain");
          if (typeof callback === "function") callback();
        })
        .catch((err) => {
          if (typeof callback === "function") callback(err);
          this.emit("error", err);
          this.destroy(err);
        });

      return true;
    }

    end(chunk, encoding, callback) {
      if (typeof chunk === "function") {
        callback = chunk;
        chunk = undefined;
        encoding = undefined;
      } else if (typeof encoding === "function") {
        callback = encoding;
        encoding = undefined;
      }

      if (chunk !== undefined && chunk !== null) {
        this.write(chunk, encoding);
      }

      this.writable = false;
      this._pending = this._pending.then(() => {
        this.emit("finish");
        if (typeof callback === "function") callback();
        if (this._autoClose) this.destroy();
      });
      return this;
    }

    destroy(err) {
      if (this.destroyed) return this;
      this.destroyed = true;
      this.writable = false;
      if (err) this.emit("error", err);
      this.emit("close");
      return this;
    }
  }

  function baseName(path) {
    const text = String(path);
    const normalized = text.replace(/\\/g, "/");
    const idx = normalized.lastIndexOf("/");
    return idx >= 0 ? normalized.slice(idx + 1) : normalized;
  }

  function normalizePathString(path) {
    return String(path).replace(/\\/g, "/");
  }

  const activeWatchers = new Set();

  function matchesWatch(watchPath, changedPath, recursive) {
    const w = normalizePathString(watchPath);
    const c = normalizePathString(changedPath);
    if (w === c) return true;
    if (!recursive) return false;
    return c.startsWith(`${w}/`);
  }

  function notifyWatchers(changedPath, eventType = "change") {
    for (const watcher of activeWatchers) {
      if (!watcher._active) continue;
      if (matchesWatch(watcher.path, changedPath, watcher._recursive)) {
        watcher.emit("change", eventType, baseName(changedPath));
      }
    }
  }

  class FSWatcher extends MiniEmitter {
    constructor(path, options = {}, listener) {
      super();
      this.path = String(path);
      this._active = true;
      this._recursive = Boolean(options && options.recursive);

      if (typeof listener === "function") {
        this.on("change", listener);
      }
      activeWatchers.add(this);
    }

    close() {
      if (!this._active) return;
      this._active = false;
      activeWatchers.delete(this);
      this.emit("close");
    }
  }

  function createFSError(payload, path) {
    return new FSError(payload.error, payload.code, path);
  }

  const FS_ASYNC_OP_MAP = new Map([
    [globalThis.__fs_read_file, "readFile"],
    [globalThis.__fs_write_file, "writeFile"],
    [globalThis.__fs_mkdir, "mkdir"],
    [globalThis.__fs_readdir, "readdir"],
    [globalThis.__fs_stat, "stat"],
    [globalThis.__fs_lstat, "lstat"],
    [globalThis.__fs_access, "access"],
    [globalThis.__fs_unlink, "unlink"],
    [globalThis.__fs_rm, "rm"],
    [globalThis.__fs_rename, "rename"],
    [globalThis.__fs_copy_file, "copyFile"],
    [globalThis.__fs_cp, "cp"],
    [globalThis.__fs_realpath, "realpath"],
    [globalThis.__fs_readlink, "readlink"],
    [globalThis.__fs_symlink, "symlink"],
    [globalThis.__fs_link, "link"],
    [globalThis.__fs_truncate, "truncate"],
    [globalThis.__fs_chmod, "chmod"],
    [globalThis.__fs_utimes, "utimes"],
    [globalThis.__fs_mkdtemp, "mkdtemp"],
  ]);

  function callHost(hostFn, args, path, mapResult) {
    const op = FS_ASYNC_OP_MAP.get(hostFn);
    if (op && typeof globalThis.__fs_task_start_evented === "function") {
      return new Promise((resolve, reject) => {
        let requestId = null;
        let settled = false;

        const finish = (fn) => {
          if (settled) return;
          settled = true;
          fn();
        };

        try {
          const start = JSON.parse(globalThis.__fs_task_start_evented(op, JSON.stringify(args)));
          if (!start.ok) {
            finish(() => reject(createFSError({ error: start.error, code: "EIO" }, path)));
            return;
          }
          requestId = Number(start.id);
          EVENTED_FS_PENDING.set(requestId, {
            resolve,
            reject,
            finish,
            mapResult,
            path,
          });
        } catch (err) {
          if (requestId !== null && typeof globalThis.__fs_task_drop_evented === "function") {
            try {
              globalThis.__fs_task_drop_evented(requestId);
            } catch (_dropErr) {
            }
          }
          finish(() => reject(err));
        }
      });
    }

    return Promise.resolve().then(() => {
      const raw = hostFn(...args);
      const payload = JSON.parse(raw);
      if (!payload.ok) {
        throw createFSError(payload, path);
      }
      return mapResult ? mapResult(payload) : undefined;
    });
  }

  function normalizeReadEncoding(options) {
    if (typeof options === "string") return options;
    if (options && typeof options === "object" && options.encoding) return String(options.encoding);
    return undefined;
  }

  function normalizeWriteOptions(options) {
    if (typeof options === "string") {
      return { encoding: options };
    }
    if (options && typeof options === "object") {
      return { encoding: options.encoding !== undefined ? String(options.encoding) : undefined };
    }
    return { encoding: undefined };
  }

  function normalizeWriteData(data) {
    if (data instanceof Uint8Array) {
      return { kind: "bytes", data: Array.from(data) };
    }
    if (ArrayBuffer.isView(data)) {
      return { kind: "bytes", data: Array.from(new Uint8Array(data.buffer, data.byteOffset, data.byteLength)) };
    }
    if (data instanceof ArrayBuffer) {
      return { kind: "bytes", data: Array.from(new Uint8Array(data)) };
    }
    return { kind: "text", data: String(data) };
  }

  function decodeReadPayload(payload) {
    if (payload.kind === "text") return payload.data;
    if (payload.kind === "bytes") return Uint8Array.from(payload.data || []);
    throw new FSError("无效的 readFile 返回类型", "EINVAL");
  }

  function readFile(path, options) {
    const encoding = normalizeReadEncoding(options);
    return callHost(globalThis.__fs_read_file, [String(path), encoding], path, decodeReadPayload);
  }

  function writeFile(path, data, options) {
    const normalized = normalizeWriteOptions(options);
    return callHost(
      globalThis.__fs_write_file,
      [String(path), JSON.stringify(normalizeWriteData(data)), normalized.encoding, false],
      path,
    ).then((result) => {
      notifyWatchers(path, "change");
      return result;
    });
  }

  function appendFile(path, data, options) {
    const normalized = normalizeWriteOptions(options);
    return callHost(
      globalThis.__fs_write_file,
      [String(path), JSON.stringify(normalizeWriteData(data)), normalized.encoding, true],
      path,
    ).then((result) => {
      notifyWatchers(path, "change");
      return result;
    });
  }

  function mkdir(path, options) {
    const recursive = Boolean(options && typeof options === "object" && options.recursive);
    return callHost(globalThis.__fs_mkdir, [String(path), recursive], path).then((result) => {
      notifyWatchers(path, "rename");
      return result;
    });
  }

  function _readdirOnce(path, withFileTypes) {
    return callHost(globalThis.__fs_readdir, [String(path), withFileTypes], path, (payload) => payload.entries || []);
  }

  function readdir(path, options) {
    const withFileTypes = Boolean(options && typeof options === "object" && options.withFileTypes);
    const recursive = Boolean(options && typeof options === "object" && options.recursive);
    const base = String(path);
    if (!recursive) {
      return _readdirOnce(base, withFileTypes).then((entries) => {
        if (!withFileTypes) return entries;
        return entries.map((entry) => new Dirent(entry));
      });
    }

    const out = [];
    const walk = (dir, prefix) => _readdirOnce(dir, true).then((entries) => Promise.all(entries.map((entry) => {
      const relName = prefix ? `${prefix}/${entry.name}` : entry.name;
      if (withFileTypes) {
        const dirent = new Dirent({ ...entry, name: relName });
        out.push(dirent);
      } else {
        out.push(relName);
      }
      if (entry.isDirectory) {
        return walk(`${dir}/${entry.name}`, relName);
      }
      return null;
    })));

    return walk(base, "").then(() => out);
  }

  function stat(path) {
    return callHost(globalThis.__fs_stat, [String(path)], path, (payload) => new Stats(payload));
  }

  function lstat(path) {
    return callHost(globalThis.__fs_lstat, [String(path)], path, (payload) => new Stats(payload));
  }

  function access(path) {
    return callHost(globalThis.__fs_access, [String(path)], path);
  }

  function unlink(path) {
    return callHost(globalThis.__fs_unlink, [String(path)], path).then((result) => {
      notifyWatchers(path, "rename");
      return result;
    });
  }

  function rm(path, options) {
    const recursive = Boolean(options && typeof options === "object" && options.recursive);
    const force = Boolean(options && typeof options === "object" && options.force);
    return callHost(globalThis.__fs_rm, [String(path), recursive, force], path).then((result) => {
      notifyWatchers(path, "rename");
      return result;
    });
  }

  function rmdir(path, options) {
    return rm(path, { recursive: Boolean(options && options.recursive), force: false });
  }

  function rename(oldPath, newPath) {
    return callHost(globalThis.__fs_rename, [String(oldPath), String(newPath)], oldPath).then((result) => {
      notifyWatchers(oldPath, "rename");
      notifyWatchers(newPath, "rename");
      return result;
    });
  }

  function copyFile(src, dst) {
    return callHost(globalThis.__fs_copy_file, [String(src), String(dst)], src).then((result) => {
      notifyWatchers(dst, "rename");
      return result;
    });
  }

  function cp(src, dst, options) {
    const recursive = Boolean(options && typeof options === "object" && options.recursive);
    const force = options && typeof options === "object" && options.force !== undefined ? Boolean(options.force) : true;
    const errorOnExist = Boolean(options && typeof options === "object" && options.errorOnExist);
    return callHost(globalThis.__fs_cp, [String(src), String(dst), recursive, force, errorOnExist], src).then((result) => {
      notifyWatchers(dst, "rename");
      return result;
    });
  }

  function realpath(path) {
    return callHost(globalThis.__fs_realpath, [String(path)], path, (payload) => payload.path);
  }

  function readlink(path) {
    return callHost(globalThis.__fs_readlink, [String(path)], path, (payload) => payload.path);
  }

  function symlink(target, path, type) {
    const isDir = type === "dir" || type === "junction";
    return callHost(globalThis.__fs_symlink, [String(target), String(path), isDir], path).then((result) => {
      notifyWatchers(path, "rename");
      return result;
    });
  }

  function link(existingPath, newPath) {
    return callHost(globalThis.__fs_link, [String(existingPath), String(newPath)], existingPath).then((result) => {
      notifyWatchers(newPath, "rename");
      return result;
    });
  }

  function truncate(path, len = 0) {
    return callHost(globalThis.__fs_truncate, [String(path), Number(len)], path).then((result) => {
      notifyWatchers(path, "change");
      return result;
    });
  }

  function chmod(path, mode) {
    return callHost(globalThis.__fs_chmod, [String(path), Number(mode)], path).then((result) => {
      notifyWatchers(path, "change");
      return result;
    });
  }

  function toMillis(value) {
    if (value instanceof Date) return value.getTime();
    if (typeof value === "number") {
      if (Math.abs(value) < 1e12) return Math.trunc(value * 1000);
      return Math.trunc(value);
    }
    return Date.now();
  }

  function utimes(path, atime, mtime) {
    return callHost(globalThis.__fs_utimes, [String(path), toMillis(atime), toMillis(mtime)], path).then((result) => {
      notifyWatchers(path, "change");
      return result;
    });
  }

  function mkdtemp(prefix) {
    return callHost(globalThis.__fs_mkdtemp, [String(prefix)], prefix, (payload) => payload.path);
  }

  function open(path, flags = "r") {
    return Promise.resolve(new FileHandle(path, flags));
  }

  function opendir(path) {
    return readdir(path, { withFileTypes: true }).then((entries) => new Dir(path, entries));
  }

  function watch(path, options, listener) {
    let resolvedOptions = options;
    let resolvedListener = listener;
    if (typeof options === "function") {
      resolvedListener = options;
      resolvedOptions = {};
    }
    return new FSWatcher(path, resolvedOptions || {}, resolvedListener);
  }

  function createReadStream(path, options) {
    return new ReadStream(path, options || {});
  }

  function createWriteStream(path, options) {
    return new WriteStream(path, options || {});
  }

  function readFileAsArrayBuffer(path) {
    return readFile(path).then((value) => {
      if (value instanceof Uint8Array) return value.buffer;
      return stringToArrayBuffer(String(value));
    });
  }

  const constants = {
    F_OK: 0,
    R_OK: 4,
    W_OK: 2,
    X_OK: 1,
  };

  const promises = {
    readFile,
    writeFile,
    appendFile,
    mkdir,
    readdir,
    stat,
    lstat,
    access,
    unlink,
    rm,
    rmdir,
    rename,
    copyFile,
    cp,
    realpath,
    readlink,
    symlink,
    link,
    truncate,
    chmod,
    utimes,
    mkdtemp,
    open,
    opendir,
    watch,
    readFileAsArrayBuffer,
  };

  const fs = {
    promises,
    constants,
    readFile,
    writeFile,
    appendFile,
    mkdir,
    readdir,
    stat,
    lstat,
    access,
    unlink,
    rm,
    rmdir,
    rename,
    copyFile,
    cp,
    realpath,
    readlink,
    symlink,
    link,
    truncate,
    chmod,
    utimes,
    mkdtemp,
    open,
    opendir,
    watch,
    createReadStream,
    createWriteStream,
    Dirent,
    Stats,
    Dir,
    FileHandle,
    ReadStream,
    WriteStream,
    FSWatcher,
  };

  if (!globalThis.require) {
    globalThis.require = function require(name) {
      if (name === "fs") return fs;
      if (name === "fs/promises") return promises;
      if (name === "path") return globalThis.__web.path;
      if (name === "buffer") return globalThis.__web.bufferModule;
      if (name === "crypto") return globalThis.__web.cryptoModule;
      if (name === "uuidv4") return globalThis.__web.uuidv4Module;
      throw new Error(`Cannot find module '${name}'`);
    };
  }

  globalThis.__web.fs = fs;
  globalThis.__web.FSError = FSError;
})();
