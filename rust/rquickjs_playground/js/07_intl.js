(() => {
  if (typeof globalThis.Intl !== "undefined" && typeof globalThis.Intl.DateTimeFormat === "function") {
    return;
  }

  function hostOk(raw) {
    const res = typeof raw === "string" ? JSON.parse(raw) : raw;
    if (!res || res.ok !== true) {
      const message = (res && res.error) || "Intl host error";
      const type = res && res.errorType;
      if (type === "TypeError") throw new TypeError(message);
      throw new RangeError(message);
    }
    return res.data;
  }

  function parseLocaleList(locales) {
    if (locales == null) return "en";
    if (typeof locales === "string") return locales || "en";
    if (Array.isArray(locales) && locales.length > 0) {
      return String(locales[0] || "en");
    }
    return "en";
  }

  function parseUnicodeExtensions(locale) {
    const out = {};
    const s = String(locale || "");
    // en-u-hc-h23-ca-iso8601
    const m = s.match(/-u(?:-[a-z0-9]+)+/i);
    if (!m) return out;
    const parts = m[0].slice(3).split("-");
    for (let i = 0; i < parts.length; ) {
      const key = parts[i];
      const val = parts[i + 1];
      if (!val) break;
      if (key === "hc") out.hourCycle = val;
      if (key === "ca") out.calendar = val;
      if (key === "nu") out.numberingSystem = val;
      i += 2;
    }
    return out;
  }

  // ECMA-402 Table: fields that conflict with dateStyle/timeStyle.
  const STYLE_CONFLICT_KEYS = [
    "weekday",
    "era",
    "year",
    "month",
    "day",
    "hour",
    "minute",
    "second",
    "dayPeriod",
    "fractionalSecondDigits",
    "timeZoneName",
  ];

  function validateStyleConflicts(options) {
    const hasDateStyle = options.dateStyle != null;
    const hasTimeStyle = options.timeStyle != null;
    if (!hasDateStyle && !hasTimeStyle) return;
    for (let i = 0; i < STYLE_CONFLICT_KEYS.length; i++) {
      const key = STYLE_CONFLICT_KEYS[i];
      if (options[key] != null) {
        throw new TypeError(
          `option ${key} cannot be set together with dateStyle/timeStyle`,
        );
      }
    }
  }

  function normalizeOptions(locales, options) {
    options = options && typeof options === "object" ? Object.assign({}, options) : {};
    const locale = parseLocaleList(locales);
    const ext = parseUnicodeExtensions(locale);
    if (options.calendar == null && ext.calendar) options.calendar = ext.calendar;
    if (options.hourCycle == null && ext.hourCycle) options.hourCycle = ext.hourCycle;
    if (options.numberingSystem == null && ext.numberingSystem) {
      options.numberingSystem = ext.numberingSystem;
    }
    if (options.timeZone == null) {
      // leave undefined so host uses system zone
    } else {
      options.timeZone = String(options.timeZone);
      // ECMA-402 / Temporal: empty string is not a valid time zone id.
      if (options.timeZone === "") {
        throw new RangeError("Invalid time zone specified: ");
      }
    }
    if (options.calendar == null) options.calendar = "iso8601";
    // Do NOT force hourCycle=h23; leave unset so locale default applies (en-US => h12).
    // Temporal scrape paths pass hourCycle explicitly via locale -u-hc-h23.
    validateStyleConflicts(options);
    options.locale = locale;
    return options;
  }

  function toEpochMilli(date) {
    if (date === undefined) date = Date.now();
    if (date && typeof date.valueOf === "function") {
      const v = date.valueOf();
      if (typeof v === "number") return v;
    }
    const n = Number(date);
    if (!Number.isFinite(n)) throw new RangeError("Invalid time value");
    return n;
  }

  function DateTimeFormat(locales, options) {
    if (!(this instanceof DateTimeFormat)) {
      return new DateTimeFormat(locales, options);
    }
    this.__options = normalizeOptions(locales, options);
    // Validate timezone early (spec behavior).
    if (this.__options.timeZone != null) {
      const canon = hostOk(globalThis.__intl_canonicalize_time_zone(String(this.__options.timeZone)));
      this.__options.timeZone = canon;
    }
  }

  DateTimeFormat.prototype.resolvedOptions = function resolvedOptions() {
    const data = hostOk(globalThis.__intl_dtf_resolved_options(JSON.stringify(this.__options)));
    // Merge requested field styles for callers that inspect them.
    return Object.assign({}, this.__options, data);
  };

  DateTimeFormat.prototype.formatToParts = function formatToParts(date) {
    const epochMilli = toEpochMilli(date);
    return hostOk(
      globalThis.__intl_dtf_format_to_parts(epochMilli, JSON.stringify(this.__options)),
    );
  };

  DateTimeFormat.prototype.format = function format(date) {
    const epochMilli = toEpochMilli(date);
    if (typeof globalThis.__intl_dtf_format === "function") {
      return hostOk(
        globalThis.__intl_dtf_format(epochMilli, JSON.stringify(this.__options)),
      );
    }
    const parts = this.formatToParts(date);
    return parts.map((p) => p.value).join("");
  };

  DateTimeFormat.supportedLocalesOf = function supportedLocalesOf(locales) {
    if (locales == null) return [];
    const list = Array.isArray(locales) ? locales : [locales];
    return list.map(String);
  };

  function supportedValuesOf(key) {
    return hostOk(globalThis.__intl_supported_values_of(String(key)));
  }

  const IntlObj = globalThis.Intl || {};
  IntlObj.DateTimeFormat = DateTimeFormat;
  IntlObj.supportedValuesOf = supportedValuesOf;
  // Provide a minimal getCanonicalLocales if missing.
  if (typeof IntlObj.getCanonicalLocales !== "function") {
    IntlObj.getCanonicalLocales = function getCanonicalLocales(locales) {
      if (locales == null) return [];
      const list = Array.isArray(locales) ? locales : [locales];
      return list.map((l) => String(l));
    };
  }
  globalThis.Intl = IntlObj;

  // Wire Date locale methods to Intl.DateTimeFormat (QuickJS has no real Intl).
  if (typeof Date === "function" && Date.prototype) {
    Date.prototype.toLocaleString = function toLocaleString(locales, options) {
      return new DateTimeFormat(locales, options).format(this);
    };
    Date.prototype.toLocaleDateString = function toLocaleDateString(locales, options) {
      const opts = options && typeof options === "object" ? Object.assign({}, options) : {};
      if (opts.dateStyle == null && opts.timeStyle == null) {
        if (opts.year == null && opts.month == null && opts.day == null && opts.weekday == null) {
          opts.year = "numeric";
          opts.month = "numeric";
          opts.day = "numeric";
        }
      }
      // date-only: drop time fields when not using timeStyle
      if (opts.timeStyle == null) {
        delete opts.hour;
        delete opts.minute;
        delete opts.second;
        delete opts.dayPeriod;
        delete opts.fractionalSecondDigits;
      }
      return new DateTimeFormat(locales, opts).format(this);
    };
    Date.prototype.toLocaleTimeString = function toLocaleTimeString(locales, options) {
      const opts = options && typeof options === "object" ? Object.assign({}, options) : {};
      if (opts.dateStyle == null && opts.timeStyle == null) {
        if (opts.hour == null && opts.minute == null && opts.second == null) {
          opts.hour = "numeric";
          opts.minute = "numeric";
          opts.second = "numeric";
        }
      }
      if (opts.dateStyle == null) {
        delete opts.year;
        delete opts.month;
        delete opts.day;
        delete opts.weekday;
        delete opts.era;
      }
      return new DateTimeFormat(locales, opts).format(this);
    };
  }
})();
