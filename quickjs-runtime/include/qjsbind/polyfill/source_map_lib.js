var __sourcemap_lib = (() => {
  var __create = Object.create;
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getProtoOf = Object.getPrototypeOf;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __commonJS = (cb, mod) => function __require() {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  };
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
    // If the importer is in node compatibility mode or this is not an ESM
    // file that has been converted to a CommonJS file using a Babel-
    // compatible transform (i.e. "__esModule" has not been set), then set
    // "default" to the CommonJS "module.exports" for node compatibility.
    isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
    mod
  ));
  var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

  // node_modules/.pnpm/@jridgewell+resolve-uri@3.1.2/node_modules/@jridgewell/resolve-uri/dist/resolve-uri.umd.js
  var require_resolve_uri_umd = __commonJS({
    "node_modules/.pnpm/@jridgewell+resolve-uri@3.1.2/node_modules/@jridgewell/resolve-uri/dist/resolve-uri.umd.js"(exports, module) {
      (function(global, factory) {
        typeof exports === "object" && typeof module !== "undefined" ? module.exports = factory() : typeof define === "function" && define.amd ? define(factory) : (global = typeof globalThis !== "undefined" ? globalThis : global || self, global.resolveURI = factory());
      })(exports, (function() {
        "use strict";
        const schemeRegex = /^[\w+.-]+:\/\//;
        const urlRegex = /^([\w+.-]+:)\/\/([^@/#?]*@)?([^:/#?]*)(:\d+)?(\/[^#?]*)?(\?[^#]*)?(#.*)?/;
        const fileRegex = /^file:(?:\/\/((?![a-z]:)[^/#?]*)?)?(\/?[^#?]*)(\?[^#]*)?(#.*)?/i;
        function isAbsoluteUrl(input) {
          return schemeRegex.test(input);
        }
        function isSchemeRelativeUrl(input) {
          return input.startsWith("//");
        }
        function isAbsolutePath(input) {
          return input.startsWith("/");
        }
        function isFileUrl(input) {
          return input.startsWith("file:");
        }
        function isRelative(input) {
          return /^[.?#]/.test(input);
        }
        function parseAbsoluteUrl(input) {
          const match = urlRegex.exec(input);
          return makeUrl(match[1], match[2] || "", match[3], match[4] || "", match[5] || "/", match[6] || "", match[7] || "");
        }
        function parseFileUrl(input) {
          const match = fileRegex.exec(input);
          const path = match[2];
          return makeUrl("file:", "", match[1] || "", "", isAbsolutePath(path) ? path : "/" + path, match[3] || "", match[4] || "");
        }
        function makeUrl(scheme, user, host, port, path, query, hash) {
          return {
            scheme,
            user,
            host,
            port,
            path,
            query,
            hash,
            type: 7
          };
        }
        function parseUrl(input) {
          if (isSchemeRelativeUrl(input)) {
            const url2 = parseAbsoluteUrl("http:" + input);
            url2.scheme = "";
            url2.type = 6;
            return url2;
          }
          if (isAbsolutePath(input)) {
            const url2 = parseAbsoluteUrl("http://foo.com" + input);
            url2.scheme = "";
            url2.host = "";
            url2.type = 5;
            return url2;
          }
          if (isFileUrl(input))
            return parseFileUrl(input);
          if (isAbsoluteUrl(input))
            return parseAbsoluteUrl(input);
          const url = parseAbsoluteUrl("http://foo.com/" + input);
          url.scheme = "";
          url.host = "";
          url.type = input ? input.startsWith("?") ? 3 : input.startsWith("#") ? 2 : 4 : 1;
          return url;
        }
        function stripPathFilename(path) {
          if (path.endsWith("/.."))
            return path;
          const index = path.lastIndexOf("/");
          return path.slice(0, index + 1);
        }
        function mergePaths(url, base) {
          normalizePath(base, base.type);
          if (url.path === "/") {
            url.path = base.path;
          } else {
            url.path = stripPathFilename(base.path) + url.path;
          }
        }
        function normalizePath(url, type) {
          const rel = type <= 4;
          const pieces = url.path.split("/");
          let pointer = 1;
          let positive = 0;
          let addTrailingSlash = false;
          for (let i = 1; i < pieces.length; i++) {
            const piece = pieces[i];
            if (!piece) {
              addTrailingSlash = true;
              continue;
            }
            addTrailingSlash = false;
            if (piece === ".")
              continue;
            if (piece === "..") {
              if (positive) {
                addTrailingSlash = true;
                positive--;
                pointer--;
              } else if (rel) {
                pieces[pointer++] = piece;
              }
              continue;
            }
            pieces[pointer++] = piece;
            positive++;
          }
          let path = "";
          for (let i = 1; i < pointer; i++) {
            path += "/" + pieces[i];
          }
          if (!path || addTrailingSlash && !path.endsWith("/..")) {
            path += "/";
          }
          url.path = path;
        }
        function resolve(input, base) {
          if (!input && !base)
            return "";
          const url = parseUrl(input);
          let inputType = url.type;
          if (base && inputType !== 7) {
            const baseUrl = parseUrl(base);
            const baseType = baseUrl.type;
            switch (inputType) {
              case 1:
                url.hash = baseUrl.hash;
              // fall through
              case 2:
                url.query = baseUrl.query;
              // fall through
              case 3:
              case 4:
                mergePaths(url, baseUrl);
              // fall through
              case 5:
                url.user = baseUrl.user;
                url.host = baseUrl.host;
                url.port = baseUrl.port;
              // fall through
              case 6:
                url.scheme = baseUrl.scheme;
            }
            if (baseType > inputType)
              inputType = baseType;
          }
          normalizePath(url, inputType);
          const queryHash = url.query + url.hash;
          switch (inputType) {
            // This is impossible, because of the empty checks at the start of the function.
            // case UrlType.Empty:
            case 2:
            case 3:
              return queryHash;
            case 4: {
              const path = url.path.slice(1);
              if (!path)
                return queryHash || ".";
              if (isRelative(base || input) && !isRelative(path)) {
                return "./" + path + queryHash;
              }
              return path + queryHash;
            }
            case 5:
              return url.path + queryHash;
            default:
              return url.scheme + "//" + url.user + url.host + url.port + url.path + queryHash;
          }
        }
        return resolve;
      }));
    }
  });

  // src/source_map_lib_entry.js
  var source_map_lib_entry_exports = {};
  __export(source_map_lib_entry_exports, {
    TraceMap: () => TraceMap,
    decodedMappings: () => decodedMappings,
    eachMapping: () => eachMapping,
    encodedMappings: () => encodedMappings,
    originalPositionFor: () => originalPositionFor
  });

  // node_modules/.pnpm/@jridgewell+sourcemap-codec@1.5.5/node_modules/@jridgewell/sourcemap-codec/dist/sourcemap-codec.mjs
  var comma = ",".charCodeAt(0);
  var semicolon = ";".charCodeAt(0);
  var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  var intToChar = new Uint8Array(64);
  var charToInt = new Uint8Array(128);
  for (let i = 0; i < chars.length; i++) {
    const c = chars.charCodeAt(i);
    intToChar[i] = c;
    charToInt[c] = i;
  }
  function decodeInteger(reader, relative) {
    let value = 0;
    let shift = 0;
    let integer = 0;
    do {
      const c = reader.next();
      integer = charToInt[c];
      value |= (integer & 31) << shift;
      shift += 5;
    } while (integer & 32);
    const shouldNegate = value & 1;
    value >>>= 1;
    if (shouldNegate) {
      value = -2147483648 | -value;
    }
    return relative + value;
  }
  function encodeInteger(builder, num, relative) {
    let delta = num - relative;
    delta = delta < 0 ? -delta << 1 | 1 : delta << 1;
    do {
      let clamped = delta & 31;
      delta >>>= 5;
      if (delta > 0) clamped |= 32;
      builder.write(intToChar[clamped]);
    } while (delta > 0);
    return num;
  }
  function hasMoreVlq(reader, max) {
    if (reader.pos >= max) return false;
    return reader.peek() !== comma;
  }
  var bufLength = 1024 * 16;
  var td = typeof TextDecoder !== "undefined" ? /* @__PURE__ */ new TextDecoder() : typeof Buffer !== "undefined" ? {
    decode(buf) {
      const out = Buffer.from(buf.buffer, buf.byteOffset, buf.byteLength);
      return out.toString();
    }
  } : {
    decode(buf) {
      let out = "";
      for (let i = 0; i < buf.length; i++) {
        out += String.fromCharCode(buf[i]);
      }
      return out;
    }
  };
  var StringWriter = class {
    constructor() {
      this.pos = 0;
      this.out = "";
      this.buffer = new Uint8Array(bufLength);
    }
    write(v) {
      const { buffer } = this;
      buffer[this.pos++] = v;
      if (this.pos === bufLength) {
        this.out += td.decode(buffer);
        this.pos = 0;
      }
    }
    flush() {
      const { buffer, out, pos } = this;
      return pos > 0 ? out + td.decode(buffer.subarray(0, pos)) : out;
    }
  };
  var StringReader = class {
    constructor(buffer) {
      this.pos = 0;
      this.buffer = buffer;
    }
    next() {
      return this.buffer.charCodeAt(this.pos++);
    }
    peek() {
      return this.buffer.charCodeAt(this.pos);
    }
    indexOf(char) {
      const { buffer, pos } = this;
      const idx = buffer.indexOf(char, pos);
      return idx === -1 ? buffer.length : idx;
    }
  };
  function decode(mappings) {
    const { length } = mappings;
    const reader = new StringReader(mappings);
    const decoded = [];
    let genColumn = 0;
    let sourcesIndex = 0;
    let sourceLine = 0;
    let sourceColumn = 0;
    let namesIndex = 0;
    do {
      const semi = reader.indexOf(";");
      const line = [];
      let sorted = true;
      let lastCol = 0;
      genColumn = 0;
      while (reader.pos < semi) {
        let seg;
        genColumn = decodeInteger(reader, genColumn);
        if (genColumn < lastCol) sorted = false;
        lastCol = genColumn;
        if (hasMoreVlq(reader, semi)) {
          sourcesIndex = decodeInteger(reader, sourcesIndex);
          sourceLine = decodeInteger(reader, sourceLine);
          sourceColumn = decodeInteger(reader, sourceColumn);
          if (hasMoreVlq(reader, semi)) {
            namesIndex = decodeInteger(reader, namesIndex);
            seg = [genColumn, sourcesIndex, sourceLine, sourceColumn, namesIndex];
          } else {
            seg = [genColumn, sourcesIndex, sourceLine, sourceColumn];
          }
        } else {
          seg = [genColumn];
        }
        line.push(seg);
        reader.pos++;
      }
      if (!sorted) sort(line);
      decoded.push(line);
      reader.pos = semi + 1;
    } while (reader.pos <= length);
    return decoded;
  }
  function sort(line) {
    line.sort(sortComparator);
  }
  function sortComparator(a, b) {
    return a[0] - b[0];
  }
  function encode(decoded) {
    const writer = new StringWriter();
    let sourcesIndex = 0;
    let sourceLine = 0;
    let sourceColumn = 0;
    let namesIndex = 0;
    for (let i = 0; i < decoded.length; i++) {
      const line = decoded[i];
      if (i > 0) writer.write(semicolon);
      if (line.length === 0) continue;
      let genColumn = 0;
      for (let j = 0; j < line.length; j++) {
        const segment = line[j];
        if (j > 0) writer.write(comma);
        genColumn = encodeInteger(writer, segment[0], genColumn);
        if (segment.length === 1) continue;
        sourcesIndex = encodeInteger(writer, segment[1], sourcesIndex);
        sourceLine = encodeInteger(writer, segment[2], sourceLine);
        sourceColumn = encodeInteger(writer, segment[3], sourceColumn);
        if (segment.length === 4) continue;
        namesIndex = encodeInteger(writer, segment[4], namesIndex);
      }
    }
    return writer.flush();
  }

  // node_modules/.pnpm/@jridgewell+trace-mapping@0.3.31/node_modules/@jridgewell/trace-mapping/dist/trace-mapping.mjs
  var import_resolve_uri = __toESM(require_resolve_uri_umd(), 1);
  function stripFilename(path) {
    if (!path) return "";
    const index = path.lastIndexOf("/");
    return path.slice(0, index + 1);
  }
  function resolver(mapUrl, sourceRoot) {
    const from = stripFilename(mapUrl);
    const prefix = sourceRoot ? sourceRoot + "/" : "";
    return (source) => (0, import_resolve_uri.default)(prefix + (source || ""), from);
  }
  var COLUMN = 0;
  var SOURCES_INDEX = 1;
  var SOURCE_LINE = 2;
  var SOURCE_COLUMN = 3;
  var NAMES_INDEX = 4;
  function maybeSort(mappings, owned) {
    const unsortedIndex = nextUnsortedSegmentLine(mappings, 0);
    if (unsortedIndex === mappings.length) return mappings;
    if (!owned) mappings = mappings.slice();
    for (let i = unsortedIndex; i < mappings.length; i = nextUnsortedSegmentLine(mappings, i + 1)) {
      mappings[i] = sortSegments(mappings[i], owned);
    }
    return mappings;
  }
  function nextUnsortedSegmentLine(mappings, start) {
    for (let i = start; i < mappings.length; i++) {
      if (!isSorted(mappings[i])) return i;
    }
    return mappings.length;
  }
  function isSorted(line) {
    for (let j = 1; j < line.length; j++) {
      if (line[j][COLUMN] < line[j - 1][COLUMN]) {
        return false;
      }
    }
    return true;
  }
  function sortSegments(line, owned) {
    if (!owned) line = line.slice();
    return line.sort(sortComparator2);
  }
  function sortComparator2(a, b) {
    return a[COLUMN] - b[COLUMN];
  }
  var found = false;
  function binarySearch(haystack, needle, low, high) {
    while (low <= high) {
      const mid = low + (high - low >> 1);
      const cmp = haystack[mid][COLUMN] - needle;
      if (cmp === 0) {
        found = true;
        return mid;
      }
      if (cmp < 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    found = false;
    return low - 1;
  }
  function upperBound(haystack, needle, index) {
    for (let i = index + 1; i < haystack.length; index = i++) {
      if (haystack[i][COLUMN] !== needle) break;
    }
    return index;
  }
  function lowerBound(haystack, needle, index) {
    for (let i = index - 1; i >= 0; index = i--) {
      if (haystack[i][COLUMN] !== needle) break;
    }
    return index;
  }
  function memoizedState() {
    return {
      lastKey: -1,
      lastNeedle: -1,
      lastIndex: -1
    };
  }
  function memoizedBinarySearch(haystack, needle, state, key) {
    const { lastKey, lastNeedle, lastIndex } = state;
    let low = 0;
    let high = haystack.length - 1;
    if (key === lastKey) {
      if (needle === lastNeedle) {
        found = lastIndex !== -1 && haystack[lastIndex][COLUMN] === needle;
        return lastIndex;
      }
      if (needle >= lastNeedle) {
        low = lastIndex === -1 ? 0 : lastIndex;
      } else {
        high = lastIndex;
      }
    }
    state.lastKey = key;
    state.lastNeedle = needle;
    return state.lastIndex = binarySearch(haystack, needle, low, high);
  }
  function parse(map) {
    return typeof map === "string" ? JSON.parse(map) : map;
  }
  var LINE_GTR_ZERO = "`line` must be greater than 0 (lines start at line 1)";
  var COL_GTR_EQ_ZERO = "`column` must be greater than or equal to 0 (columns start at column 0)";
  var LEAST_UPPER_BOUND = -1;
  var GREATEST_LOWER_BOUND = 1;
  var TraceMap = class {
    constructor(map, mapUrl) {
      const isString = typeof map === "string";
      if (!isString && map._decodedMemo) return map;
      const parsed = parse(map);
      const { version, file, names, sourceRoot, sources, sourcesContent } = parsed;
      this.version = version;
      this.file = file;
      this.names = names || [];
      this.sourceRoot = sourceRoot;
      this.sources = sources;
      this.sourcesContent = sourcesContent;
      this.ignoreList = parsed.ignoreList || parsed.x_google_ignoreList || void 0;
      const resolve = resolver(mapUrl, sourceRoot);
      this.resolvedSources = sources.map(resolve);
      const { mappings } = parsed;
      if (typeof mappings === "string") {
        this._encoded = mappings;
        this._decoded = void 0;
      } else if (Array.isArray(mappings)) {
        this._encoded = void 0;
        this._decoded = maybeSort(mappings, isString);
      } else if (parsed.sections) {
        throw new Error(`TraceMap passed sectioned source map, please use FlattenMap export instead`);
      } else {
        throw new Error(`invalid source map: ${JSON.stringify(parsed)}`);
      }
      this._decodedMemo = memoizedState();
      this._bySources = void 0;
      this._bySourceMemos = void 0;
    }
  };
  function cast(map) {
    return map;
  }
  function encodedMappings(map) {
    var _a, _b;
    return (_b = (_a = cast(map))._encoded) != null ? _b : _a._encoded = encode(cast(map)._decoded);
  }
  function decodedMappings(map) {
    var _a;
    return (_a = cast(map))._decoded || (_a._decoded = decode(cast(map)._encoded));
  }
  function originalPositionFor(map, needle) {
    let { line, column, bias } = needle;
    line--;
    if (line < 0) throw new Error(LINE_GTR_ZERO);
    if (column < 0) throw new Error(COL_GTR_EQ_ZERO);
    const decoded = decodedMappings(map);
    if (line >= decoded.length) return OMapping(null, null, null, null);
    const segments = decoded[line];
    const index = traceSegmentInternal(
      segments,
      cast(map)._decodedMemo,
      line,
      column,
      bias || GREATEST_LOWER_BOUND
    );
    if (index === -1) return OMapping(null, null, null, null);
    const segment = segments[index];
    if (segment.length === 1) return OMapping(null, null, null, null);
    const { names, resolvedSources } = map;
    return OMapping(
      resolvedSources[segment[SOURCES_INDEX]],
      segment[SOURCE_LINE] + 1,
      segment[SOURCE_COLUMN],
      segment.length === 5 ? names[segment[NAMES_INDEX]] : null
    );
  }
  function eachMapping(map, cb) {
    const decoded = decodedMappings(map);
    const { names, resolvedSources } = map;
    for (let i = 0; i < decoded.length; i++) {
      const line = decoded[i];
      for (let j = 0; j < line.length; j++) {
        const seg = line[j];
        const generatedLine = i + 1;
        const generatedColumn = seg[0];
        let source = null;
        let originalLine = null;
        let originalColumn = null;
        let name = null;
        if (seg.length !== 1) {
          source = resolvedSources[seg[1]];
          originalLine = seg[2] + 1;
          originalColumn = seg[3];
        }
        if (seg.length === 5) name = names[seg[4]];
        cb({
          generatedLine,
          generatedColumn,
          source,
          originalLine,
          originalColumn,
          name
        });
      }
    }
  }
  function OMapping(source, line, column, name) {
    return { source, line, column, name };
  }
  function traceSegmentInternal(segments, memo, line, column, bias) {
    let index = memoizedBinarySearch(segments, column, memo, line);
    if (found) {
      index = (bias === LEAST_UPPER_BOUND ? upperBound : lowerBound)(segments, column, index);
    } else if (bias === LEAST_UPPER_BOUND) index++;
    if (index === -1 || index === segments.length) return -1;
    return index;
  }
  return __toCommonJS(source_map_lib_entry_exports);
})();
