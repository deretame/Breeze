(() => {
  if (!("prepareStackTrace" in Error)) return;

  var _originalPrepareStackTrace = Error.prepareStackTrace;

  function trySourceMapLookup(line, col) {
    if (typeof __sourcemap_lookup !== "function") return null;
    try {
      var raw = __sourcemap_lookup("__default__", line, col);
      if (!raw) return null;
      return JSON.parse(raw);
    } catch (_e) {
      return null;
    }
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

      var smResult = trySourceMapLookup(line, col);
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
