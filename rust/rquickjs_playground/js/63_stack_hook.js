(() => {
  if (!("prepareStackTrace" in Error)) return;

  var _originalPrepareStackTrace = Error.prepareStackTrace;

  // scope 形如 "bundle:<name> fn:... ..."；按 bundle 名查各自的 source map，
  // 解析失败回退 __default__（兼容旧注册）。
  function bundleNameOf(err) {
    try {
      var scope = err && err.__bundle_scope;
      if (typeof scope !== "string") return null;
      var m = scope.match(/bundle:([^\s]+)/);
      return m ? m[1] : null;
    } catch (_e) {
      return null;
    }
  }

  function trySourceMapLookup(err, line, col) {
    if (typeof __sourcemap_lookup !== "function") return null;
    var names = [];
    var bundleName = bundleNameOf(err);
    if (bundleName) names.push(bundleName);
    names.push("__default__");
    for (var i = 0; i < names.length; i++) {
      try {
        var raw = __sourcemap_lookup(names[i], line, col);
        if (!raw) continue;
        return JSON.parse(raw);
      } catch (_e) {}
    }
    return null;
  }

  Error.prepareStackTrace = function (err, frames) {
    var lines = [];
    lines.push("[stack-hook] Error: " + (Error.isError(err) ? err.message : String(err || "")));

    for (var i = 0; i < frames.length; i++) {
      var f = frames[i];
      var fn = f.getFunctionName();
      var file = f.getFileName();
      var line = f.getLineNumber();
      var col = f.getColumnNumber();
      var nat = f.isNative();

      if (nat || line < 1) {
        lines.push("    at " + (fn || "(anonymous)") + " (native)");
        continue;
      }

      var smResult = trySourceMapLookup(err, line, col);
      if (smResult) {
        var displayFn = fn || smResult.name || "(anonymous)";
        lines.push(
          "    at " + displayFn +
          " (" + smResult.source + ":" + smResult.line + ":" + smResult.column + ")"
        );
      } else {
        lines.push(
          "    at " + (fn || "(anonymous)") +
          " (" + (file || "(unknown)") + ":" + line + ":" + col + ")"
        );
      }
    }

    var result = lines.join("\n");

    if (typeof _originalPrepareStackTrace === "function") {
      try {
        return _originalPrepareStackTrace(err, frames);
      } catch (_e) {}
    }
    return result;
  };
})();
