// temporal-polyfill full/global.js v1.0.1
// Source: https://github.com/fullcalendar/temporal-polyfill
// License: MIT (see js/THIRD_PARTY_TEMPORAL_POLYFILL.LICENSE)
// Vendored for QuickJS host runtime Temporal support.
!function() {
  "use strict";
  function normalizeOptions(options) {
    return void 0 === options ? Object.create(null) : requireObjectLike(options);
  }
  function toFiniteNumber(arg, entityName = "number") {
    if ("bigint" == typeof arg) {
      throw new TypeError((entityName => `Cannot convert bigint to ${entityName}`)(entityName));
    }
    if (arg = Number(arg), !Number.isFinite(arg)) {
      throw new RangeError(((entityName, num) => `Non-finite ${entityName}: ${num}`)(entityName, arg));
    }
    return arg;
  }
  function toIntegerWithTrunc(arg, entityName) {
    return Math.trunc(toFiniteNumber(arg, entityName)) || 0;
  }
  function toPositiveIntegerWithTruncation(arg, entityName) {
    return ((num, entityName = "number") => {
      if (num <= 0) {
        throw new RangeError(((entityName, num) => `Non-positive ${entityName}: ${num}`)(entityName, num));
      }
      return num;
    })(toIntegerWithTrunc(arg, entityName), entityName);
  }
  function isObjectLike$1(arg) {
    return null !== arg && ("object" == typeof arg || "function" == typeof arg);
  }
  function requireObjectLike(arg) {
    if (!isObjectLike$1(arg)) {
      throw new TypeError("Invalid object");
    }
    return arg;
  }
  function throwRangeError(message) {
    throw new RangeError(message);
  }
  function throwTypeError(message) {
    throw new TypeError(message);
  }
  function clampProp(props, propName, min, max, overflow) {
    return clampEntity(propName, ((props, propName) => {
      const propVal = props[propName];
      return void 0 === propVal && throwTypeError(missingField(propName)), propVal;
    })(props, propName), min, max, overflow);
  }
  function clampEntity(entityName, num, min, max, overflow, choices) {
    const clamped = constrainToRange(num, min, max);
    return overflow && num !== clamped && throwRangeError(((entityName, val, min, max, choices) => choices ? numberOutOfRange(entityName, choices[val], choices[min], choices[max]) : numberOutOfRange(entityName, val, min, max))(entityName, num, min, max, choices)), 
    clamped;
  }
  function memoize(generator, MapClass = Map) {
    const map = new MapClass;
    return (key, ...otherArgs) => {
      if (map.has(key)) {
        return map.get(key);
      }
      const val = generator(key, ...otherArgs);
      return map.set(key, val), val;
    };
  }
  function mapProps(transformer, props) {
    const res = {};
    for (const propName in props) {
      res[propName] = transformer(props[propName], propName);
    }
    return res;
  }
  function zipPropsConst(propNames, propVal) {
    const res = {};
    for (const propName of propNames) {
      res[propName] = propVal;
    }
    return res;
  }
  function createPropGetters(propNames) {
    const getters = {};
    for (const propName of propNames) {
      getters[propName] = slots => slots[propName];
    }
    return getters;
  }
  function pluckProps(propNames, props, dest = Object.create(null)) {
    for (const propName of propNames) {
      dest[propName] = props[propName];
    }
    return dest;
  }
  function allPropsEqual(propNames, props0, props1) {
    for (const propName of propNames) {
      if (props0[propName] !== props1[propName]) {
        return 0;
      }
    }
    return 1;
  }
  function zeroOutProps(propNames, clearUntilI, props) {
    const copy = {
      ...props
    };
    for (let i = 0; i < clearUntilI; i++) {
      copy[propNames[i]] = 0;
    }
    return copy;
  }
  function bindArgs(f, ...boundArgs) {
    return (...dynamicArgs) => f(...boundArgs, ...dynamicArgs);
  }
  function identity(arg) {
    return arg;
  }
  function noop() {}
  function capitalize(s) {
    return s[0].toUpperCase() + s.substring(1);
  }
  function sortStrings(...strss) {
    return [].concat(...strss).sort();
  }
  function createRegExp(meat) {
    return new RegExp(`^${meat}$`, "i");
  }
  function parseSubsecNano(fracStr) {
    return parseInt(fracStr.padEnd(9, "0"));
  }
  function parseSign(s) {
    return s && "+" !== s ? -1 : 1;
  }
  function parseInt0(s) {
    return void 0 === s ? 0 : parseInt(s);
  }
  function padNumber(digits, num) {
    return String(num).padStart(digits, "0");
  }
  function compareNumbers(a, b) {
    return Math.sign(a - b);
  }
  function compareBigInts(a, b) {
    return a < b ? -1 : a > b ? 1 : 0;
  }
  function divFloorBigInt(num, denom) {
    const whole = num / denom;
    return num % denom < 0n ? whole - 1n : whole;
  }
  function divModFloorBigInt(num, divisor) {
    const quotient = divFloorBigInt(num, divisor);
    return [ quotient, num - quotient * divisor ];
  }
  function divModFloor(num, divisor) {
    return [ Math.floor(num / divisor), modFloor(num, divisor) ];
  }
  function modFloor(num, divisor) {
    return (num % divisor + divisor) % divisor;
  }
  function divTrunc(num, divisor) {
    return Math.trunc(num / divisor) || 0;
  }
  function modTrunc(num, divisor) {
    return num % divisor || 0;
  }
  function fabricateNearHalfFraction(halfCompare, sign = 1) {
    return sign * (.5 + halfCompare / 5);
  }
  function hasHalf(num) {
    return .5 === Math.abs(num % 1);
  }
  function normalizeEraName(era) {
    const normalized = era.normalize("NFD").toLowerCase().replace(/[^a-z0-9]/g, "");
    return "bc" === normalized || "b" === normalized ? "bce" : "ad" === normalized || "a" === normalized ? "ce" : normalized;
  }
  function getCalendarSlotId(calendar) {
    return calendar === isoCalendarImpl ? "iso8601" : 0 === calendar ? "gregory" : calendar.id;
  }
  function parseMonthCode(monthCode) {
    const m = monthCodeRegExp.exec(monthCode);
    return m || throwRangeError((monthCode => `Invalid monthCode: ${monthCode}`)(monthCode)), 
    [ parseInt(m[1]), Boolean(m[2]) ];
  }
  function formatMonthCode(monthCodeNumber, isLeapMonth) {
    return "M" + padNumber2(monthCodeNumber) + (isLeapMonth ? "L" : "");
  }
  function monthCodeNumberToMonth(monthCodeNumber, isLeapMonth, leapMonth) {
    return monthCodeNumber + (isLeapMonth || leapMonth && monthCodeNumber >= leapMonth ? 1 : 0);
  }
  function monthToMonthCodeNumber(month, leapMonth) {
    return month - (leapMonth && month >= leapMonth ? 1 : 0);
  }
  function divideBigNanoToExactNumber(bigNano, divisorNano) {
    const days = Number(bigNano / bigNanoInUtcDay);
    const timeNano = Number(bigNano % bigNanoInUtcDay);
    return days * (nanoInUtcDay / divisorNano) + (Math.trunc(timeNano / divisorNano) + timeNano % divisorNano / divisorNano);
  }
  function validateTimeFields(timeFields) {
    return constrainTimeFields(timeFields, 1), timeFields;
  }
  function constrainTimeFields(timeFields, overflow) {
    const constrainedFields = {};
    for (const fieldName of timeFieldNamesAsc) {
      constrainedFields[fieldName] = clampEntity(fieldName, timeFields[fieldName], 0, maxValues[fieldName] || 999, overflow);
    }
    return constrainedFields;
  }
  function timeFieldsToNano(timeFields) {
    return timeFieldsToSec(timeFields) * nanoInSec + timeFieldsToSubsecNano(timeFields);
  }
  function timeFieldsToMilli(timeFields) {
    return 1e3 * timeFieldsToSec(timeFields) + timeFields.millisecond;
  }
  function timeFieldsToSec(timeFields) {
    return 3600 * timeFields.hour + 60 * timeFields.minute + timeFields.second;
  }
  function timeFieldsToSubsecNano(timeFields) {
    return timeFields.millisecond * nanoInMilli + 1e3 * timeFields.microsecond + timeFields.nanosecond;
  }
  function nanoToTimeAndDay(nano) {
    const [dayDelta, timeNano] = divModFloor(nano, nanoInUtcDay);
    return [ nanoToTimeFields(timeNano), dayDelta ];
  }
  function nanoToTimeFields(timeNano) {
    const [timeMilli, nanoAfterMilli] = divModFloor(timeNano, nanoInMilli);
    const [microsecond, nanosecond] = divModFloor(nanoAfterMilli, 1e3);
    return milliToTimeFields(timeMilli, microsecond, nanosecond);
  }
  function milliToTimeFields(timeMilli, microsecond = 0, nanosecond = 0) {
    const [hour, milliAfterHour] = divModFloor(timeMilli, 36e5);
    const [minute, milliAfterMinute] = divModFloor(milliAfterHour, 6e4);
    const [second, millisecond] = divModFloor(milliAfterMinute, 1e3);
    return {
      hour: hour,
      minute: minute,
      second: second,
      millisecond: millisecond,
      microsecond: microsecond,
      nanosecond: nanosecond
    };
  }
  function epochNanoToSecMod(epochNano) {
    const [epochSec, nano] = divModFloorBigInt(epochNano, bigNanoInSec);
    return [ Number(epochSec), Number(nano) ];
  }
  function isoDateTimeToEpochNano(isoDateTime) {
    return isoDateToEpochNano(isoDateTime) + BigInt(timeFieldsToNano(isoDateTime));
  }
  function isoDateTimeToEpochMilli(isoDateTime) {
    return isoDateToEpochMilli(isoDateTime) + timeFieldsToMilli(isoDateTime);
  }
  function isoDateToEpochNano(isoDate) {
    return BigInt(isoDateToEpochDays(isoDate)) * bigNanoInUtcDay;
  }
  function isoDateToEpochMilli(isoDate) {
    return 864e5 * isoDateToEpochDays(isoDate);
  }
  function isoDateToEpochDays(isoDate) {
    return isoArgsToEpochDays(isoDate.year, isoDate.month, isoDate.day);
  }
  function isoArgsToEpochDays(isoYear, isoMonth = 1, isoDay = 1) {
    const monthIndex = isoMonth - 1;
    return isoYear += Math.floor(monthIndex / 12), isoMonth = modFloor(monthIndex, 12), 
    Date.UTC(isoYear % 400 - 400, isoMonth, 0) / 864e5 + 146097 * (divTrunc(isoYear, 400) + 1) + isoDay;
  }
  function epochNanoToIsoDateTime(epochNano) {
    const [epochDays, nanoAfterDay] = divModFloorBigInt(epochNano, bigNanoInUtcDay);
    return {
      ...epochDaysToIsoDate(Number(epochDays)),
      ...nanoToTimeFields(Number(nanoAfterDay))
    };
  }
  function epochDaysToIsoDate(epochDays) {
    const legacyDate = new Date(864e5 * modFloor(epochDays, 146097));
    return {
      year: legacyDate.getUTCFullYear() + 400 * Math.floor(epochDays / 146097),
      month: legacyDate.getUTCMonth() + 1,
      day: legacyDate.getUTCDate()
    };
  }
  function diffEpochMilliDays(epochMilli0, epochMilli1) {
    return Math.trunc((epochMilli1 - epochMilli0) / 864e5);
  }
  function computeIsoMonthCodeParts(month) {
    return [ month, 0 ];
  }
  function computeIsoYearMonthFieldsForMonthDay(monthCodeNumber, isLeapMonth) {
    if (!isLeapMonth) {
      return {
        year: 1972,
        month: monthCodeNumber
      };
    }
  }
  function computeIsoFieldsFromParts(year, month, day) {
    return {
      year: year,
      month: month,
      day: day
    };
  }
  function computeIsoDaysInMonth(year, month) {
    switch (month) {
     case 2:
      return computeIsoInLeapYear(year) ? 29 : 28;

     case 4:
     case 6:
     case 9:
     case 11:
      return 30;
    }
    return 31;
  }
  function computeIsoDaysInYear(year) {
    return computeIsoInLeapYear(year) ? 366 : 365;
  }
  function computeIsoInLeapYear(year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  }
  function addIsoMonths(year, month, monthDelta) {
    return year += divTrunc(monthDelta, 12), (month += modTrunc(monthDelta, 12)) < 1 ? (year--, 
    month += 12) : month > 12 && (year++, month -= 12), {
      year: year,
      month: month
    };
  }
  function diffIsoMonthSlots(year0, month0, year1, month1) {
    return 12 * (year1 - year0) + month1 - month0;
  }
  function computeIsoDayOfWeek(isoDateFields) {
    return modFloor(isoArgsToEpochDays(isoDateFields.year, isoDateFields.month, isoDateFields.day) + 4, 7) || 7;
  }
  function computeIsoDayOfYear(isoDateFields) {
    return isoArgsToEpochDays(isoDateFields.year, isoDateFields.month, isoDateFields.day) - isoArgsToEpochDays(isoDateFields.year) + 1;
  }
  function computeIsoWeekFields(isoDateFields) {
    let yearOfWeek = isoDateFields.year;
    let weekOfYear = Math.floor((computeIsoDayOfYear(isoDateFields) - computeIsoDayOfWeek(isoDateFields) + 10) / 7);
    let weeksInYear = computeIsoWeeksInYear(yearOfWeek);
    return weekOfYear < 1 ? weekOfYear = weeksInYear = computeIsoWeeksInYear(--yearOfWeek) : weekOfYear > weeksInYear && (weekOfYear = 1, 
    weeksInYear = computeIsoWeeksInYear(++yearOfWeek)), {
      weekOfYear: weekOfYear,
      yearOfWeek: yearOfWeek,
      Ie: weeksInYear
    };
  }
  function computeIsoWeeksInYear(year) {
    const y0DayOfWeek = computeIsoDayOfWeek({
      year: year,
      month: 1,
      day: 1
    });
    return 4 === y0DayOfWeek || 3 === y0DayOfWeek && computeIsoInLeapYear(year) ? 53 : 52;
  }
  function computeGregoryEraFields({year: year}) {
    return year < 1 ? {
      era: "bce",
      eraYear: 1 - year
    } : {
      era: "ce",
      eraYear: year
    };
  }
  function validateIsoDateTimeFields(isoDateTime) {
    return validateIsoDateFields(isoDateTime), validateTimeFields(isoDateTime);
  }
  function validateIsoDateFields(isoInternals) {
    return constrainIsoDateFields(isoInternals, 1), isoInternals;
  }
  function isIsoDateFieldsValid(isoDate) {
    return allPropsEqual(calendarDateFieldNamesAsc, isoDate, constrainIsoDateFields(isoDate));
  }
  function constrainIsoDateFields(isoDate, overflow) {
    const {year: year} = isoDate;
    const month = clampProp(isoDate, "month", 1, 12, overflow);
    return {
      year: year,
      month: month,
      day: clampProp(isoDate, "day", 1, computeIsoDaysInMonth(year, month), overflow)
    };
  }
  function computeCalendarDateFields(calendar, isoDate) {
    return calendar ? calendar.ie(isoDate) : isoDate;
  }
  function computeCalendarMonthCodeParts(calendar, year, month) {
    return calendar ? calendar.O(year, month) : computeIsoMonthCodeParts(month);
  }
  function computeCalendarEraFields(calendar, isoDate) {
    return 0 === calendar ? computeGregoryEraFields(isoDate) : calendar ? calendar.h(isoDate) : {};
  }
  function computeCalendarIsoFieldsFromParts(calendar, year, month, day) {
    return calendar ? calendar.je(year, month, day) : computeIsoFieldsFromParts(year, month, day);
  }
  function computeCalendarMonthsInYearForYear(calendar, year) {
    return calendar ? calendar.k(year) : 12;
  }
  function computeCalendarDaysInMonthForYearMonth(calendar, year, month) {
    return calendar ? calendar.p(year, month) : computeIsoDaysInMonth(year, month);
  }
  function computeCalendarMonthCode(calendar, isoDate) {
    const {year: year, month: month} = computeCalendarDateFields(calendar, isoDate);
    const [monthCodeNumber, isLeapMonth] = computeCalendarMonthCodeParts(calendar, year, month);
    return formatMonthCode(monthCodeNumber, isLeapMonth);
  }
  function computeCalendarInLeapYear(calendar, isoDate) {
    const {year: year} = computeCalendarDateFields(calendar, isoDate);
    return calendar ? calendar.u(year) : computeIsoInLeapYear(year);
  }
  function computeCalendarMonthsInYear(calendar, isoDate) {
    const {year: year} = computeCalendarDateFields(calendar, isoDate);
    return computeCalendarMonthsInYearForYear(calendar, year);
  }
  function computeCalendarDaysInMonth(calendar, isoDate) {
    const {year: year, month: month} = computeCalendarDateFields(calendar, isoDate);
    return computeCalendarDaysInMonthForYearMonth(calendar, year, month);
  }
  function computeCalendarDaysInYear(calendar, isoDate) {
    const {year: year} = computeCalendarDateFields(calendar, isoDate);
    return calendar ? calendar.j(year) : computeIsoDaysInYear(year);
  }
  function requirePropDefined(optionName, optionVal) {
    return null == optionVal && throwRangeError(missingField(optionName)), optionVal;
  }
  function requireType(typeName, arg, entityName = typeName) {
    return typeof arg !== typeName && throwTypeError(invalidEntity(entityName, arg)), 
    arg;
  }
  function requireNumberIsInteger(num, entityName = "number") {
    return Number.isInteger(num) || throwRangeError(((entityName, num) => `Non-integer ${entityName}: ${num}`)(entityName, num)), 
    num || 0;
  }
  function toString(arg) {
    return "symbol" == typeof arg && throwTypeError("Cannot convert Symbol to string"), 
    String(arg);
  }
  function toStringViaPrimitive(arg, entityName) {
    return isObjectLike$1(arg) ? String(arg) : requireString(arg, entityName);
  }
  function toBigInt(bi) {
    return "boolean" == typeof bi ? BigInt(bi ? 1 : 0) : "string" == typeof bi ? BigInt(bi) : ("bigint" != typeof bi && throwTypeError(`Invalid bigint: ${bi}`), 
    bi);
  }
  function toStrictInteger(arg, entityName) {
    return requireNumberIsInteger(toFiniteNumber(arg, entityName), entityName);
  }
  function normalizeOptionsOrString(options, optionName) {
    return "string" == typeof options ? ((optionName, optionVal) => {
      const res = Object.create(null);
      return res[optionName] = optionVal, res;
    })(optionName, options) : requireObjectLike(options);
  }
  function coerceRoundingIncInteger(options) {
    const roundingInc = options.roundingIncrement;
    return void 0 === roundingInc ? 1 : toIntegerWithTrunc(roundingInc, "roundingIncrement");
  }
  function coerceFractionalSecondDigits(options) {
    let subsecDigits = options.fractionalSecondDigits;
    if (void 0 !== subsecDigits) {
      if ("number" != typeof subsecDigits) {
        if ("auto" === toString(subsecDigits)) {
          return;
        }
        throwRangeError(invalidEntity("fractionalSecondDigits", subsecDigits));
      }
      subsecDigits = clampEntity("fractionalSecondDigits", Math.floor(subsecDigits), 0, 9, 1);
    }
    return subsecDigits;
  }
  function coerceUnitOption(optionName, options, minUnit = 0, ensureDefined) {
    let unitStr = options[optionName];
    if (void 0 === unitStr) {
      return ensureDefined ? minUnit : void 0;
    }
    if (unitStr = toString(unitStr), "auto" === unitStr) {
      return ensureDefined ? minUnit : null;
    }
    let unit = unitNameMap[unitStr];
    return void 0 === unit && (unit = durationFieldIndexes[unitStr]), void 0 === unit && throwRangeError(invalidChoice(optionName, unitStr, unitNameMap)), 
    unit;
  }
  function coerceChoiceOption(optionName, enumNameMap, options, defaultChoice = 0) {
    const enumArg = options[optionName];
    if (void 0 === enumArg) {
      return defaultChoice;
    }
    const enumStr = toString(enumArg);
    const enumNum = enumNameMap[enumStr];
    return void 0 === enumNum && throwRangeError(invalidChoice(optionName, enumStr, enumNameMap)), 
    enumNum;
  }
  function validateRoundingInc(roundingInc, smallestUnit, allowManyLargeUnits, solarMode) {
    const upUnitNano = solarMode ? nanoInUtcDay : unitNanoMap[smallestUnit + 1];
    if (upUnitNano) {
      const unitNano = unitNanoMap[smallestUnit];
      upUnitNano % ((roundingInc = clampEntity("roundingIncrement", roundingInc, 1, upUnitNano / unitNano - (solarMode ? 0 : 1), 1)) * unitNano) && throwRangeError(invalidEntity("roundingIncrement", roundingInc));
    } else {
      roundingInc = clampEntity("roundingIncrement", roundingInc, 1, allowManyLargeUnits ? 10 ** 9 : 1, 1);
    }
    return roundingInc;
  }
  function validateUnitRange(optionName, unit, minUnit, maxUnit) {
    return null != unit && clampEntity(optionName, unit, minUnit, maxUnit, 1, unitNamesAsc), 
    unit;
  }
  function checkLargestSmallestUnit(largestUnit, smallestUnit) {
    smallestUnit > largestUnit && throwRangeError("smallestUnit > largestUnit");
  }
  function refineDiffOptions(roundingModeInvert, options, defaultLargestUnit, maxUnit = 9, minUnit = 0, defaultRoundingMode = 4) {
    options = normalizeOptions(options);
    let largestUnit = coerceLargestUnit(options, minUnit);
    let roundingInc = coerceRoundingIncInteger(options);
    let roundingMode = coerceRoundingMode(options, defaultRoundingMode);
    let smallestUnit = coerceSmallestUnit(options, minUnit, 1);
    return largestUnit = validateUnitRange("largestUnit", largestUnit, minUnit, maxUnit), 
    smallestUnit = validateUnitRange(smallestUnitStr, smallestUnit, minUnit, maxUnit), 
    null == largestUnit ? largestUnit = Math.max(defaultLargestUnit, smallestUnit) : checkLargestSmallestUnit(largestUnit, smallestUnit), 
    roundingInc = validateRoundingInc(roundingInc, smallestUnit, 1), roundingModeInvert && (roundingMode = (roundingMode => roundingMode < 4 ? (roundingMode + 2) % 4 : roundingMode)(roundingMode)), 
    [ largestUnit, smallestUnit, roundingInc, roundingMode ];
  }
  function refineRoundingOptions(options, maxUnit = 6, solarMode) {
    let roundingInc = coerceRoundingIncInteger(options = normalizeOptionsOrString(options, smallestUnitStr));
    const roundingMode = coerceRoundingMode(options, 7);
    let smallestUnit = coerceSmallestUnit(options);
    return smallestUnit = requirePropDefined(smallestUnitStr, smallestUnit), smallestUnit = validateUnitRange(smallestUnitStr, smallestUnit, 0, maxUnit), 
    roundingInc = validateRoundingInc(roundingInc, smallestUnit, void 0, solarMode), 
    [ smallestUnit, roundingInc, roundingMode ];
  }
  function combineDateAndTime(isoDate, time) {
    return pluckProps(calendarDateFieldNamesAsc, isoDate, pluckProps(timeFieldNamesAsc, time));
  }
  function refineOverflowOptions(options) {
    return void 0 === options ? 0 : coerceOverflow(requireObjectLike(options));
  }
  function refineZonedFieldOptions(options, defaultOffsetDisambig = 0) {
    options = normalizeOptions(options);
    const epochDisambig = coerceEpochDisambig(options);
    const offsetDisambig = coerceOffsetDisambig(options, defaultOffsetDisambig);
    return [ coerceOverflow(options), offsetDisambig, epochDisambig ];
  }
  function checkIsoYearMonthInBounds(isoDate) {
    const isoYearMonthIndex = 12 * isoDate.year + isoDate.month;
    return (isoYearMonthIndex < isoYearMonthIndexMin || isoYearMonthIndex > 3309129) && throwRangeError(outOfBoundsDate), 
    isoDate;
  }
  function checkIsoDateInBounds(isoDate, allowPlainDateLowerEdge = 1) {
    return checkIsoDateEpochNanoInBounds(isoDateToEpochNano(isoDate), allowPlainDateLowerEdge), 
    isoDate;
  }
  function checkIsoDateTimeInBounds(isoDateTime) {
    const epochNano = isoDateToEpochNano(isoDateTime);
    return checkIsoDateEpochNanoInBounds(epochNano), epochNano !== plainDateEpochNanoMin || timeFieldsToNano(isoDateTime) || throwRangeError(outOfBoundsDate), 
    isoDateTime;
  }
  function checkIsoDateEpochNanoInBounds(epochNano, allowPlainDateLowerEdge = 1) {
    (epochNano < (allowPlainDateLowerEdge ? plainDateEpochNanoMin : epochNanoMin) || epochNano > epochNanoMax) && throwRangeError(outOfBoundsDate);
  }
  function checkEpochNanoInBounds(epochNano) {
    return (epochNano < epochNanoMin || epochNano > epochNanoMax) && throwRangeError(outOfBoundsDate), 
    epochNano;
  }
  function isoDateTimeAndOffsetToEpochNano(isoDateTime, offsetNano) {
    return checkEpochNanoInBounds(isoDateToEpochNano(isoDateTime) + BigInt(timeFieldsToNano(isoDateTime) - offsetNano));
  }
  function createEpochNanoSlots(epochNano) {
    return {
      epochNanoseconds: epochNano
    };
  }
  function createZonedEpochNanoSlots(epochNano, timeZone, calendar) {
    return {
      calendar: calendar,
      timeZone: timeZone,
      epochNanoseconds: epochNano
    };
  }
  function createDateTimeSlots(isoDateTime, calendar) {
    return pluckProps(timeFieldNamesAsc, isoDateTime, createDateSlots(isoDateTime, calendar));
  }
  function createDateSlots(isoDate, calendar) {
    return pluckProps(calendarDateFieldNamesAsc, isoDate, {
      calendar: calendar
    });
  }
  function createTimeSlots(time) {
    return pluckProps(timeFieldNamesAsc, time);
  }
  function createDurationSlots(durationFields) {
    return pluckProps(durationFieldNamesAsc, durationFields, {
      sign: computeDurationSign(durationFields)
    });
  }
  function getEpochMilli(slots) {
    return epochNano = slots.epochNanoseconds, Number(divFloorBigInt(epochNano, bigNanoInMilli));
    var epochNano;
  }
  function getEpochNano(slots) {
    return slots.epochNanoseconds;
  }
  function totalDayTimeDuration(durationFields, totalUnit) {
    return divideBigNanoToExactNumber(durationDayTimeToBigNano(durationFields), unitNanoMap[totalUnit]);
  }
  function clampRelativeDuration(durationFields, clampUnit, clampDistance, markerMoveOps, epochNanoProgress) {
    const unitName = durationFieldNamesAsc[clampUnit];
    let startDurationFields = durationFields;
    let shifted = 0;
    let window = computeRelativeDurationWindow(startDurationFields, unitName, clampDistance, markerMoveOps);
    return epochNanoProgress && !((epochNanoProgress, epochNano0, epochNano1, sign) => sign > 0 ? compareBigInts(epochNano0, epochNanoProgress) <= 0 && compareBigInts(epochNanoProgress, epochNano1) <= 0 : compareBigInts(epochNano1, epochNanoProgress) <= 0 && compareBigInts(epochNanoProgress, epochNano0) <= 0)(epochNanoProgress, window.ae, window.de, Math.sign(clampDistance)) && (startDurationFields = {
      ...durationFields,
      [unitName]: durationFields[unitName] + clampDistance
    }, shifted = 1, window = computeRelativeDurationWindow(startDurationFields, unitName, clampDistance, markerMoveOps)), 
    {
      ...window,
      ye: startDurationFields,
      He: shifted
    };
  }
  function computeRelativeDurationWindow(startDurationFields, unitName, clampDistance, markerMoveOps) {
    const endDurationFields = {
      ...startDurationFields,
      [unitName]: startDurationFields[unitName] + clampDistance
    };
    return {
      ae: moveMarkerToEpochNano(markerMoveOps, startDurationFields),
      de: moveMarkerToEpochNano(markerMoveOps, endDurationFields),
      Ae: endDurationFields
    };
  }
  function computeEpochNanoFrac(epochNanoProgress, epochNano0, epochNano1) {
    const denomBig = epochNano1 - epochNano0;
    const numeratorBig = epochNanoProgress - epochNano0;
    if (!numeratorBig) {
      return 0;
    }
    const absNumerator = numeratorBig < 0n ? -numeratorBig : numeratorBig;
    const absDenom = denomBig < 0n ? -denomBig : denomBig;
    const fracSign = compareBigInts(numeratorBig, 0n) === compareBigInts(denomBig, 0n) ? 1 : -1;
    return compareBigInts(absNumerator, absDenom) <= 0 ? absNumerator === absDenom ? fracSign : fabricateNearHalfFraction(compareBigInts(2n * absNumerator, absDenom), fracSign) : Number(numeratorBig) / Number(denomBig);
  }
  function roundDateTimeToNano(isoDateTime, nanoInc, roundingMode) {
    const [roundedTimeFields, dayDelta] = roundTimeToNano(isoDateTime, nanoInc, roundingMode);
    const roundedIsoDateTime = combineDateAndTime(moveByDays(isoDateTime, dayDelta), roundedTimeFields);
    return checkIsoDateTimeInBounds(roundedIsoDateTime), roundedIsoDateTime;
  }
  function roundTimeToNano(timeFields, nanoInc, roundingMode) {
    return nanoToTimeAndDay(roundNumberToInc(timeFieldsToNano(timeFields), nanoInc, roundingMode));
  }
  function roundToMinute(offsetNano) {
    return roundNumberToInc(offsetNano, nanoInMinute, 7);
  }
  function computeNanoInc(smallestUnit, roundingInc) {
    return unitNanoMap[smallestUnit] * roundingInc;
  }
  function computeBigNanoInc(smallestUnit, roundingInc) {
    return BigInt(unitNanoMap[smallestUnit]) * BigInt(roundingInc);
  }
  function roundDayTimeDurationByInc(durationFields, nanoInc, roundingMode) {
    const maxUnit = Math.min(getMaxDurationUnit(durationFields), 6);
    return nanoToDurationDayTimeFields(roundBigNanoToInc(durationDayTimeToBigNano(durationFields), BigInt(nanoInc), roundingMode), maxUnit);
  }
  function roundRelativeDuration(durationFields, endEpochNano, largestUnit, smallestUnit, roundingInc, roundingMode, markerMoveOps) {
    if (0 === smallestUnit && 1 === roundingInc) {
      return durationFields;
    }
    const sign = computeDurationSign(durationFields) || 1;
    const nudgeFunc = isUniformUnit(smallestUnit, markerMoveOps.i) ? isZonedEpochSlots(markerMoveOps.i) && smallestUnit < 6 && largestUnit >= 6 ? nudgeZonedTimeDuration : nudgeDayTimeDuration : nudgeRelativeDuration;
    let [roundedDurationFields, roundedEpochNano, grewBigUnit] = nudgeFunc(sign, durationFields, endEpochNano, largestUnit, smallestUnit, roundingInc, roundingMode, markerMoveOps);
    return grewBigUnit && 7 !== smallestUnit && (roundedDurationFields = ((durationFields, endEpochNano, largestUnit, smallestUnit, sign, markerMoveOps) => {
      for (let currentUnit = smallestUnit + 1; currentUnit <= largestUnit; currentUnit++) {
        if (7 === currentUnit && 7 !== largestUnit) {
          continue;
        }
        const baseDurationFields = clearDurationFields(currentUnit, durationFields);
        baseDurationFields[durationFieldNamesAsc[currentUnit]] += sign;
        const thresholdCompare = compareBigInts(endEpochNano, moveMarkerToEpochNano(markerMoveOps, baseDurationFields));
        if (thresholdCompare && thresholdCompare !== sign) {
          break;
        }
        durationFields = baseDurationFields;
      }
      return durationFields;
    })(roundedDurationFields, roundedEpochNano, largestUnit, Math.max(6, smallestUnit), sign, markerMoveOps)), 
    roundedDurationFields;
  }
  function roundBigNanoToInc(bigNano, bigNanoInc, roundingMode) {
    return roundBigNanoToIncWithTail(bigNano, bigNanoInc, roundingMode, bigNano / bigNanoInc % 2n);
  }
  function roundBigNanoToDayOriginInc(bigNano, bigNanoInc, roundingMode) {
    const [day, timeNano] = divModFloorBigInt(bigNano, bigNanoInUtcDay);
    const dayOriginNano = day * bigNanoInUtcDay;
    return dayOriginNano + roundBigNanoToIncWithTail(timeNano, bigNanoInc, roundingMode, (dayOriginNano / bigNanoInc + timeNano / bigNanoInc) % 2n);
  }
  function roundBigNanoToIncWithTail(bigNano, bigNanoInc, roundingMode, quotientTail) {
    const quotient = bigNano / bigNanoInc;
    const remainder = bigNano % bigNanoInc;
    let fraction = 0;
    remainder && (fraction = fabricateNearHalfFraction(compareBigInts(2n * (remainder < 0n ? -remainder : remainder), bigNanoInc), Math.sign(Number(remainder))));
    const roundedTail = roundWithMode(Number(quotientTail) + fraction, roundingMode);
    return (quotient - quotientTail + BigInt(roundedTail)) * bigNanoInc;
  }
  function roundNumberToInc(num, roundingInc, roundingMode) {
    return roundWithMode(num / roundingInc, roundingMode) * roundingInc;
  }
  function roundWithMode(num, roundingMode) {
    return roundingModeFuncs[roundingMode](num);
  }
  function nudgeDayTimeDuration(sign, durationFields, endEpochNano, largestUnit, smallestUnit, roundingInc, roundingMode) {
    const bigNano = durationDayTimeToBigNano(durationFields);
    const roundedBigNano = roundBigNanoToInc(bigNano, computeBigNanoInc(smallestUnit, roundingInc), roundingMode);
    const nanoDiff = roundedBigNano - bigNano;
    const expandedBigUnit = Math.sign(Number(roundedBigNano / bigNanoInUtcDay) - Number(bigNano / bigNanoInUtcDay)) === sign;
    const roundedDayTimeFields = nanoToDurationDayTimeFields(roundedBigNano, Math.min(largestUnit, 6));
    return [ {
      ...durationFields,
      ...roundedDayTimeFields
    }, endEpochNano + nanoDiff, expandedBigUnit ];
  }
  function nudgeZonedTimeDuration(sign, durationFields, endEpochNano, _largestUnit, smallestUnit, roundingInc, roundingMode, markerMoveOps) {
    const timeNano = Number(durationTimeToBigNano(durationFields));
    const nanoInc = computeNanoInc(smallestUnit, roundingInc);
    let roundedTimeNano = roundNumberToInc(timeNano, nanoInc, roundingMode);
    const dayWindow = clampRelativeDuration({
      ...durationFields,
      ...durationTimeFieldDefaults
    }, 6, sign, markerMoveOps, endEpochNano);
    const dayEpochNano0 = dayWindow.ae;
    const dayEpochNano1 = dayWindow.de;
    const beyondDayNano = roundedTimeNano - Number(dayEpochNano1 - dayEpochNano0);
    let dayDelta = 0;
    beyondDayNano && Math.sign(beyondDayNano) !== sign ? endEpochNano = dayEpochNano0 + BigInt(roundedTimeNano) : (dayDelta += sign, 
    roundedTimeNano = roundNumberToInc(beyondDayNano, nanoInc, roundingMode), endEpochNano = dayEpochNano1 + BigInt(roundedTimeNano));
    const durationTimeFields = nanoToDurationTimeFields(roundedTimeNano);
    return [ {
      ...durationFields,
      ...durationTimeFields,
      days: durationFields.days + dayDelta
    }, endEpochNano, Boolean(dayDelta) ];
  }
  function nudgeRelativeDuration(sign, durationFields, endEpochNano, _largestUnit, smallestUnit, roundingInc, roundingMode, markerMoveOps) {
    const smallestUnitFieldName = durationFieldNamesAsc[smallestUnit];
    const baseDurationFields = clearDurationFields(smallestUnit, durationFields);
    7 === smallestUnit && (durationFields = {
      ...durationFields,
      weeks: durationFields.weeks + Math.trunc(durationFields.days / 7)
    });
    const truncedVal = divTrunc(durationFields[smallestUnitFieldName], roundingInc) * roundingInc;
    baseDurationFields[smallestUnitFieldName] = truncedVal;
    const nudgeWindow = clampRelativeDuration(baseDurationFields, smallestUnit, roundingInc * sign, markerMoveOps, endEpochNano);
    const epochNano0 = nudgeWindow.ae;
    const epochNano1 = nudgeWindow.de;
    const frac = computeEpochNanoFrac(endEpochNano, epochNano0, epochNano1);
    const windowStartVal = nudgeWindow.ye[smallestUnitFieldName];
    const windowEndVal = nudgeWindow.Ae[smallestUnitFieldName];
    const roundedVal = roundNumberToInc(windowStartVal + frac * sign * roundingInc, roundingInc, roundingMode);
    const roundedToEnd = roundedVal === windowEndVal;
    return baseDurationFields[smallestUnitFieldName] = roundedVal, [ baseDurationFields, roundedToEnd ? epochNano1 : epochNano0, nudgeWindow.He || roundedToEnd ];
  }
  function _zonedEpochSlotsToIso(slots) {
    const {epochNanoseconds: epochNanoseconds, timeZone: timeZone} = slots;
    const offsetNanoseconds = timeZone.C(epochNanoseconds);
    return {
      ...epochNanoToIsoDateTime(epochNanoseconds + BigInt(offsetNanoseconds)),
      offsetNanoseconds: offsetNanoseconds
    };
  }
  function getMatchingInstantFor(timeZone, isoDateTime, offsetNano, offsetDisambig = 0, epochDisambig = 0, epochFuzzy, hasZ) {
    if (void 0 !== offsetNano && 1 === offsetDisambig && (1 === offsetDisambig || hasZ)) {
      return isoDateTimeAndOffsetToEpochNano(isoDateTime, offsetNano);
    }
    2 !== offsetDisambig && 0 !== offsetDisambig || checkIsoDateInBounds(isoDateTime, 0);
    const possibleEpochNanos = timeZone.R(isoDateTime);
    if (void 0 !== offsetNano && 3 !== offsetDisambig) {
      const matchingEpochNano = ((possibleEpochNanos, isoDateTime, offsetNano, fuzzy) => {
        const zonedEpochNano = isoDateTimeToEpochNano(isoDateTime);
        fuzzy && (offsetNano = roundToMinute(offsetNano));
        for (const possibleEpochNano of possibleEpochNanos) {
          let possibleOffsetNano = Number(zonedEpochNano - possibleEpochNano);
          if (fuzzy && (possibleOffsetNano = roundToMinute(possibleOffsetNano)), possibleOffsetNano === offsetNano) {
            return possibleEpochNano;
          }
        }
      })(possibleEpochNanos, isoDateTime, offsetNano, epochFuzzy);
      if (void 0 !== matchingEpochNano) {
        return matchingEpochNano;
      }
      0 === offsetDisambig && throwRangeError("Invalid TimeZone offset");
    }
    return hasZ ? isoDateTimeToEpochNano(isoDateTime) : getSingleInstantFor(timeZone, isoDateTime, epochDisambig, possibleEpochNanos);
  }
  function getSingleInstantFor(timeZone, isoDateTime, disambig = 0, possibleEpochNanos = timeZone.R(isoDateTime)) {
    if (1 === possibleEpochNanos.length) {
      return possibleEpochNanos[0];
    }
    if (1 === disambig && throwRangeError("Ambiguous offset"), possibleEpochNanos.length) {
      return possibleEpochNanos[3 === disambig ? 1 : 0];
    }
    const zonedEpochNano = isoDateTimeToEpochNano(isoDateTime);
    const gapNano = ((timeZone, zonedEpochNano) => {
      const startOffsetNano = timeZone.C(zonedEpochNano - bigNanoInUtcDay);
      return (gapNano => (gapNano > nanoInUtcDay && throwRangeError("Out-of-bounds TimeZone gap"), 
      gapNano))(timeZone.C(zonedEpochNano + bigNanoInUtcDay) - startOffsetNano);
    })(timeZone, zonedEpochNano);
    const shiftedIsoDateTime = epochNanoToIsoDateTime(zonedEpochNano + BigInt(gapNano * (2 === disambig ? -1 : 1)));
    return (possibleEpochNanos = timeZone.R(shiftedIsoDateTime))[2 === disambig ? 0 : possibleEpochNanos.length - 1];
  }
  function getStartOfDayInstantFor(timeZone, isoDateTime) {
    const possibleEpochNanos = timeZone.R(isoDateTime);
    if (possibleEpochNanos.length) {
      return possibleEpochNanos[0];
    }
    const zonedEpochNanoDayBefore = isoDateTimeToEpochNano(isoDateTime) - bigNanoInUtcDay;
    return timeZone.U(zonedEpochNanoDayBefore, 1);
  }
  function moveYearMonth(doSubtract, calendar, isoDateFields, durationSlots, options) {
    const overflow = refineOverflowOptions(options);
    durationSlots.sign && getMaxDurationUnit(durationSlots) < 8 && throwRangeError("Cannot use small units");
    const startOfMonthFields = checkIsoDateInBounds(moveToStartOfMonth(calendar, isoDateFields));
    return moveToStartOfMonth(calendar, dateAddWithOverflow(calendar, startOfMonthFields, doSubtract ? negateDurationFields(durationSlots) : durationSlots, overflow));
  }
  function moveEpochNano(epochNano, durationFields) {
    return checkEpochNanoInBounds(epochNano + (durationHasDateParts(fields = durationFields) && throwRangeError("Cannot use large units"), 
    durationTimeToBigNano(fields)));
    var fields;
  }
  function moveZonedEpochSlots(slots, durationFields, options) {
    const {calendar: calendar, epochNanoseconds: epochNano, timeZone: timeZone} = slots;
    const timeOnlyNano = durationTimeToBigNano(durationFields);
    let movedEpochNano = epochNano;
    if (durationHasDateParts(durationFields)) {
      const isoDateTime = zonedEpochSlotsToIso(slots);
      movedEpochNano = getSingleInstantFor(timeZone, combineDateAndTime(moveDate(calendar, isoDateTime, {
        ...durationFields,
        ...durationTimeFieldDefaults
      }, options), isoDateTime)) + timeOnlyNano;
    } else {
      movedEpochNano += timeOnlyNano, refineOverflowOptions(options);
    }
    return {
      ...slots,
      epochNanoseconds: checkEpochNanoInBounds(movedEpochNano)
    };
  }
  function moveDateTime(calendar, isoDateTimeFields, durationFields, options) {
    const [movedTimeFields, dayDelta] = moveTime(isoDateTimeFields, durationFields);
    const movedIsoDateTimeFields = combineDateAndTime(moveDate(calendar, isoDateTimeFields, {
      ...durationFields,
      ...durationTimeFieldDefaults,
      days: durationFields.days + dayDelta
    }, options), movedTimeFields);
    return checkIsoDateTimeInBounds(movedIsoDateTimeFields), movedIsoDateTimeFields;
  }
  function moveDate(calendar, isoDateFields, durationFields, options) {
    if (durationFields.years || durationFields.months || durationFields.weeks) {
      return dateAddWithOverflow(calendar, isoDateFields, durationFields, refineOverflowOptions(options));
    }
    refineOverflowOptions(options);
    const days = durationFields.days + Number(durationTimeToBigNano(durationFields) / bigNanoInUtcDay);
    return days ? checkIsoDateInBounds(moveByDays(isoDateFields, days)) : isoDateFields;
  }
  function moveToStartOfMonth(calendar, isoDateFields) {
    return moveByDays(isoDateFields, 1 - computeCalendarDateFields(calendar, isoDateFields).day);
  }
  function moveTime(timeFields, durationFields) {
    const durationBigNano = durationTimeToBigNano(durationFields);
    const durDays = Number(durationBigNano / bigNanoInUtcDay);
    const durTimeNano = Number(durationBigNano % bigNanoInUtcDay);
    const [newTimeFields, overflowDays] = nanoToTimeAndDay(timeFieldsToNano(timeFields) + durTimeNano);
    return [ newTimeFields, durDays + overflowDays ];
  }
  function moveByDays(isoDate, days) {
    return days ? epochDaysToIsoDate(isoDateToEpochDays(isoDate) + days) : isoDate;
  }
  function dateAddWithOverflow(calendar, isoDateFields, durationFields, overflow) {
    let {years: years, months: months, weeks: weeks, days: days} = durationFields;
    let isoDate;
    if (days += Number(durationTimeToBigNano(durationFields) / bigNanoInUtcDay), years || months) {
      isoDate = addDateMonths(calendar, isoDateFields, years, months, overflow);
    } else {
      if (!weeks && !days) {
        return isoDateFields;
      }
      isoDate = isoDateFields;
    }
    return (weeks || days) && (isoDate = moveByDays(isoDate, 7 * weeks + days)), checkIsoDateInBounds(isoDate);
  }
  function addDateMonths(calendar, isoDateFields, years, months, overflow) {
    const dateParts = computeCalendarDateFields(calendar, isoDateFields);
    let {year: year, month: month, day: day} = dateParts;
    if (years) {
      const [monthCodeNumber, isLeapMonth] = computeCalendarMonthCodeParts(calendar, year, month);
      year += years, month = computeYearMovedMonth(calendar, monthCodeNumber, isLeapMonth, calendar ? calendar.q(year) : void 0, overflow), 
      month = clampEntity("month", month, 1, computeCalendarMonthsInYearForYear(calendar, year), overflow);
    }
    if (months) {
      const yearMonthParts = calendar ? calendar.N(year, month, months) : addIsoMonths(year, month, months);
      ({year: year, month: month} = yearMonthParts);
    }
    return day = clampEntity("day", day, 1, computeCalendarDaysInMonthForYearMonth(calendar, year, month), overflow), 
    computeCalendarIsoFieldsFromParts(calendar, year, month, day);
  }
  function computeYearMovedMonth(calendar, monthCodeNumber, isLeapMonth, targetLeapMonth, overflow) {
    if (isLeapMonth) {
      const leapMonthMeta = calendar ? calendar.m : void 0;
      return void 0 !== targetLeapMonth && (leapMonthMeta < 0 || targetLeapMonth === monthCodeNumber + 1) ? targetLeapMonth : (1 === overflow && throwRangeError(invalidLeapMonth), 
      leapMonthMeta < 0 ? -leapMonthMeta : monthCodeNumber);
    }
    return monthCodeNumberToMonth(monthCodeNumber, 0, targetLeapMonth);
  }
  function getCommonCalendar(a, b) {
    return getCalendarSlotId(a) !== getCalendarSlotId(b) && throwRangeError("Mismatching Calendars"), 
    a;
  }
  function diffInstants(invert, instantSlots0, instantSlots1, options) {
    const [largestUnit, smallestUnit, roundingInc, roundingMode] = refineDiffOptions(invert, options, 3, 5);
    const durationFields = diffEpochNanos(instantSlots0.epochNanoseconds, instantSlots1.epochNanoseconds, largestUnit, smallestUnit, roundingInc, roundingMode);
    return createDurationSlots(invert ? negateDurationFields(durationFields) : durationFields);
  }
  function diffZonedDateTimes(invert, calendar, slots0, slots1, options) {
    const [largestUnit, smallestUnit, roundingInc, roundingMode] = refineDiffOptions(invert, options, 5);
    const epochNano0 = slots0.epochNanoseconds;
    const epochNano1 = slots1.epochNanoseconds;
    let durationFields;
    return compareBigInts(epochNano1, epochNano0) ? largestUnit < 6 ? durationFields = diffEpochNanos(epochNano0, epochNano1, largestUnit, smallestUnit, roundingInc, roundingMode) : (durationFields = diffZonedEpochsExact((a = slots0.timeZone, 
    b = slots1.timeZone, a.o !== b.o && throwRangeError("Mismatching TimeZones"), a), calendar, slots0, slots1, largestUnit), 
    durationFields = roundRelativeDuration(durationFields, epochNano1, largestUnit, smallestUnit, roundingInc, roundingMode, createMarkerMoveOps(slots0, getEpochNano, moveZonedEpochSlots))) : durationFields = durationFieldDefaults, 
    createDurationSlots(invert ? negateDurationFields(durationFields) : durationFields);
    var a, b;
  }
  function diffPlainDateTimes(invert, calendar, plainDateTimeSlots0, plainDateTimeSlots1, options) {
    const [largestUnit, smallestUnit, roundingInc, roundingMode] = refineDiffOptions(invert, options, 6);
    const startEpochNano = isoDateTimeToEpochNano(plainDateTimeSlots0);
    const endEpochNano = isoDateTimeToEpochNano(plainDateTimeSlots1);
    const sign = compareBigInts(endEpochNano, startEpochNano);
    let durationFields;
    return sign ? largestUnit <= 6 ? durationFields = diffEpochNanos(startEpochNano, endEpochNano, largestUnit, smallestUnit, roundingInc, roundingMode) : (durationFields = diffDateTimesBig(calendar, plainDateTimeSlots0, plainDateTimeSlots1, sign, largestUnit), 
    durationFields = roundRelativeDuration(durationFields, endEpochNano, largestUnit, smallestUnit, roundingInc, roundingMode, createMarkerMoveOps(plainDateTimeSlots0, isoDateTimeToEpochNano, bindArgs(moveDateTime, calendar)))) : durationFields = durationFieldDefaults, 
    createDurationSlots(invert ? negateDurationFields(durationFields) : durationFields);
  }
  function diffPlainDates(invert, calendar, plainDateSlots0, plainDateSlots1, options) {
    const [largestUnit, smallestUnit, roundingInc, roundingMode] = refineDiffOptions(invert, options, 6, 9, 6);
    return diffDateLike(invert, calendar, plainDateSlots0, plainDateSlots1, largestUnit, smallestUnit, roundingInc, roundingMode);
  }
  function diffPlainYearMonth(invert, calendar, plainYearMonthSlots0, plainYearMonthSlots1, options) {
    const [largestUnit, smallestUnit, roundingInc, roundingMode] = refineDiffOptions(invert, options, 9, 9, 8);
    const firstOfMonth0 = moveToStartOfMonth(calendar, plainYearMonthSlots0);
    const firstOfMonth1 = moveToStartOfMonth(calendar, plainYearMonthSlots1);
    return compareIsoDate(firstOfMonth0, firstOfMonth1) ? diffDateLike(invert, calendar, checkIsoDateInBounds(firstOfMonth0), checkIsoDateInBounds(firstOfMonth1), largestUnit, smallestUnit, roundingInc, roundingMode, 8) : createDurationSlots(durationFieldDefaults);
  }
  function diffDateLike(invert, calendar, startIsoDate, endIsoDate, largestUnit, smallestUnit, roundingInc, roundingMode, smallestPrecision = 6) {
    const startEpochNano = isoDateToEpochNano(startIsoDate);
    const endEpochNano = isoDateToEpochNano(endIsoDate);
    let durationFields;
    return compareBigInts(endEpochNano, startEpochNano) ? 6 === largestUnit ? durationFields = diffEpochNanos(startEpochNano, endEpochNano, largestUnit, smallestUnit, roundingInc, roundingMode) : (durationFields = diffCalendarDates(calendar, startIsoDate, endIsoDate, largestUnit), 
    smallestUnit === smallestPrecision && 1 === roundingInc || (durationFields = roundRelativeDuration(durationFields, endEpochNano, largestUnit, smallestUnit, roundingInc, roundingMode, createMarkerMoveOps(startIsoDate, isoDateToEpochNano, bindArgs(moveDate, calendar))))) : durationFields = durationFieldDefaults, 
    createDurationSlots(invert ? negateDurationFields(durationFields) : durationFields);
  }
  function diffPlainTimes(invert, plainTimeSlots0, plainTimeSlots1, options) {
    const [largestUnit, smallestUnit, roundingInc, roundingMode] = refineDiffOptions(invert, options, 5, 5);
    const timeDiffNano = roundNumberToInc(timeFieldsToNano(plainTimeSlots1) - timeFieldsToNano(plainTimeSlots0), computeNanoInc(smallestUnit, roundingInc), roundingMode);
    const durationFields = {
      ...durationFieldDefaults,
      ...nanoToDurationTimeFields(timeDiffNano, largestUnit)
    };
    return createDurationSlots(invert ? negateDurationFields(durationFields) : durationFields);
  }
  function diffZonedEpochsExact(timeZone, calendar, slots0, slots1, largestUnit) {
    const sign = compareBigInts(slots1.epochNanoseconds, slots0.epochNanoseconds);
    if (!sign) {
      return durationFieldDefaults;
    }
    if (largestUnit < 6) {
      return {
        ...durationFieldDefaults,
        ...nanoToDurationDayTimeFields(slots1.epochNanoseconds - slots0.epochNanoseconds, largestUnit)
      };
    }
    if (!compareIsoDate(zonedEpochSlotsToIso(slots0), zonedEpochSlotsToIso(slots1))) {
      return {
        ...durationFieldDefaults,
        ...nanoToDurationDayTimeFields(slots1.epochNanoseconds - slots0.epochNanoseconds, 5)
      };
    }
    const [isoFields0, isoFields1, remainderNano] = ((timeZone, slots0, slots1, sign) => {
      const startIsoDate = zonedEpochSlotsToIso(slots0);
      const endIsoDate = zonedEpochSlotsToIso(slots1);
      const endEpochNano = slots1.epochNanoseconds;
      let dayCorrection = 0;
      const timeDiffNano = timeFieldsToNano(endIsoDate) - timeFieldsToNano(startIsoDate);
      Math.sign(timeDiffNano) === -sign && dayCorrection++;
      const maxDayCorrection = dayCorrection + (sign > 0 ? 1 : 0);
      for (;dayCorrection <= maxDayCorrection; dayCorrection++) {
        const midIsoDate = moveByDays(endIsoDate, dayCorrection * -sign);
        const midEpochNano = getSingleInstantFor(timeZone, combineDateAndTime(midIsoDate, startIsoDate));
        if (compareBigInts(endEpochNano, midEpochNano) !== -sign) {
          return [ startIsoDate, midIsoDate, Number(endEpochNano - midEpochNano) ];
        }
      }
    })(timeZone, slots0, slots1, sign);
    return {
      ...6 === largestUnit ? {
        ...durationFieldDefaults,
        days: diffDays(isoFields0, isoFields1)
      } : diffCalendarDates(calendar, isoFields0, isoFields1, largestUnit),
      ...nanoToDurationTimeFields(remainderNano)
    };
  }
  function diffDateTimesExact(calendar, startIsoDateTime, endIsoDateTime, largestUnit) {
    const startEpochNano = isoDateTimeToEpochNano(startIsoDateTime);
    const endEpochNano = isoDateTimeToEpochNano(endIsoDateTime);
    const sign = compareBigInts(endEpochNano, startEpochNano);
    return sign ? largestUnit <= 6 ? {
      ...durationFieldDefaults,
      ...nanoToDurationDayTimeFields(endEpochNano - startEpochNano, largestUnit)
    } : diffDateTimesBig(calendar, startIsoDateTime, endIsoDateTime, sign, largestUnit) : durationFieldDefaults;
  }
  function diffDateTimesBig(calendar, startIsoDateTime, endIsoDateTime, sign, largestUnit) {
    let diffEndDate = endIsoDateTime;
    let timeNano = timeFieldsToNano(endIsoDateTime) - timeFieldsToNano(startIsoDateTime);
    return Math.sign(timeNano) === -sign && (diffEndDate = moveByDays(endIsoDateTime, -sign), 
    timeNano += nanoInUtcDay * sign), {
      ...diffCalendarDates(calendar, startIsoDateTime, diffEndDate, largestUnit),
      ...nanoToDurationTimeFields(timeNano)
    };
  }
  function diffCalendarDates(calendar, startIsoDate, endIsoDate, largestUnit) {
    if (largestUnit <= 7) {
      const days = diffDays(startIsoDate, endIsoDate);
      return 7 === largestUnit ? {
        ...durationFieldDefaults,
        weeks: divTrunc(days, 7),
        days: modTrunc(days, 7)
      } : {
        ...durationFieldDefaults,
        days: days
      };
    }
    const yearMonthDayStart = computeCalendarDateFields(calendar, startIsoDate);
    const yearMonthDayEnd = computeCalendarDateFields(calendar, endIsoDate);
    if (8 === largestUnit) {
      const {year: year0, month: month0, day: day0} = yearMonthDayStart;
      const {year: year1, month: month1, day: day1} = yearMonthDayEnd;
      const sign = Math.sign(compareNumbers(year1, year0) || compareNumbers(month1, month0) || diffDays(startIsoDate, endIsoDate));
      let months = 0;
      let days = 0;
      if (sign) {
        months = calendar ? calendar.ne(year0, month0, year1, month1) : diffIsoMonthSlots(year0, month0, year1, month1);
        let anchorIsoDate = addDateMonths(calendar, startIsoDate, 0, months, 0);
        sign * compareNumbers(day0, day1) > 0 && (months -= sign, anchorIsoDate = addDateMonths(calendar, startIsoDate, 0, months, 0)), 
        days = diffDays(anchorIsoDate, endIsoDate);
      }
      return {
        ...durationFieldDefaults,
        months: months,
        days: days
      };
    }
    const {year: year0, month: month0, day: day0} = yearMonthDayStart;
    let {year: year1, month: month1, day: day1} = yearMonthDayEnd;
    let yearDiff = year1 - year0;
    let monthDiff = month1 - month0;
    let dayDiff = day1 - day0;
    if (yearDiff || monthDiff) {
      const sign = Math.sign(yearDiff || monthDiff);
      let daysInMonth1 = computeCalendarDaysInMonthForYearMonth(calendar, year1, month1);
      let dayCorrect = 0;
      if (Math.sign(day1 - day0) === -sign) {
        const origDaysInMonth1 = daysInMonth1;
        const yearMonthParts = calendar ? calendar.N(year1, month1, -sign) : addIsoMonths(year1, month1, -sign);
        ({year: year1, month: month1} = yearMonthParts), yearDiff = year1 - year0, monthDiff = month1 - month0, 
        daysInMonth1 = computeCalendarDaysInMonthForYearMonth(calendar, year1, month1), 
        dayCorrect = sign < 0 ? -origDaysInMonth1 : daysInMonth1;
      }
      if (dayDiff = day1 - Math.min(day0, daysInMonth1) + dayCorrect, yearDiff) {
        const [monthCodeNumber0, isLeapMonth0] = computeCalendarMonthCodeParts(calendar, year0, month0);
        const [monthCodeNumber1, isLeapMonth1] = computeCalendarMonthCodeParts(calendar, year1, month1);
        const leapMonthMeta = calendar ? calendar.m : void 0;
        if (monthDiff = void 0 !== leapMonthMeta && isLeapMonth0 && !isLeapMonth1 && (leapMonthMeta < 0 ? sign > 0 && monthCodeNumber1 === -leapMonthMeta : sign < 0 && monthCodeNumber1 === monthCodeNumber0) ? 0 : monthCodeNumber1 - monthCodeNumber0 || Number(isLeapMonth1) - Number(isLeapMonth0), 
        Math.sign(monthDiff) === -sign) {
          const monthCorrect = sign < 0 && -computeCalendarMonthsInYearForYear(calendar, year1);
          year1 -= sign, yearDiff = year1 - year0, monthDiff = month1 - computeYearMovedMonth(calendar, monthCodeNumber0, isLeapMonth0, calendar ? calendar.q(year1) : void 0, 0) + (monthCorrect || computeCalendarMonthsInYearForYear(calendar, year1));
        } else if (calendar) {
          const month0Projected = computeYearMovedMonth(calendar, monthCodeNumber0, isLeapMonth0, calendar.q(year1), 0);
          monthDiff = calendar.ne(year1, month0Projected, year1, month1);
        }
      }
    }
    return {
      ...durationFieldDefaults,
      years: yearDiff,
      months: monthDiff,
      days: dayDiff
    };
  }
  function compareIsoDate(isoDate0, isoDate1) {
    return compareNumbers(isoDate0.year, isoDate1.year) || compareNumbers(isoDate0.month, isoDate1.month) || compareNumbers(isoDate0.day, isoDate1.day);
  }
  function diffEpochNanos(startEpochNano, endEpochNano, largestUnit, smallestUnit, roundingInc, roundingMode) {
    return {
      ...durationFieldDefaults,
      ...nanoToDurationDayTimeFields(roundBigNanoToInc(endEpochNano - startEpochNano, computeBigNanoInc(smallestUnit, roundingInc), roundingMode), largestUnit)
    };
  }
  function diffDays(startIsoDate, endIsoDate) {
    return isoDateToEpochDays(endIsoDate) - isoDateToEpochDays(startIsoDate);
  }
  function createMarkerMoveOps(marker, markerToEpochNano, moveMarker) {
    return {
      i: marker,
      V: markerToEpochNano,
      G: moveMarker
    };
  }
  function createMarkerSpanOps(relativeToSlots) {
    const {calendar: calendar} = relativeToSlots;
    if (isZonedEpochSlots(relativeToSlots)) {
      const {timeZone: timeZone} = relativeToSlots;
      return {
        i: relativeToSlots,
        V: getEpochNano,
        G: moveZonedEpochSlots,
        re: bindArgs(diffZonedEpochsExact, timeZone, calendar)
      };
    }
    return {
      i: normalizeDateTimeMarker(relativeToSlots),
      V: isoDateTimeToEpochNano,
      G: bindArgs(moveDateTime, calendar),
      re: bindArgs(diffDateTimesExact, calendar)
    };
  }
  function moveMarkerToEpochNano(markerMoveOps, durationFields) {
    return markerMoveOps.V(markerMoveOps.G(markerMoveOps.i, durationFields));
  }
  function isZonedEpochSlots(marker) {
    return "timeZone" in marker;
  }
  function checkMarkerSpanInBounds(markerSpanOps, endMarker) {
    isZonedEpochSlots(markerSpanOps.i) || (checkMarkerInBounds(markerSpanOps.i), checkMarkerInBounds(endMarker));
  }
  function normalizeDateTimeMarker(marker) {
    return combineDateAndTime(marker, "hour" in marker ? marker : timeFieldDefaults);
  }
  function checkMarkerInBounds(marker) {
    checkIsoDateTimeInBounds(normalizeDateTimeMarker(marker));
  }
  function isUniformUnit(unit, marker) {
    return unit <= 6 - (marker && isZonedEpochSlots(marker) ? 1 : 0);
  }
  function nanoToGivenFields(nano, largestUnit, fieldNames) {
    const fields = {};
    for (let unit = largestUnit; unit >= 0; unit--) {
      const divisor = unitNanoMap[unit];
      fields[fieldNames[unit]] = divTrunc(nano, divisor), nano = modTrunc(nano, divisor);
    }
    return fields;
  }
  function addDurations(refineRelativeTo, doSubtract, slots, otherSlots, options) {
    const relativeToSlots = refineRelativeTo(normalizeOptions(options).relativeTo);
    const maxUnit = Math.max(getMaxDurationUnit(slots), getMaxDurationUnit(otherSlots));
    if (isUniformUnit(maxUnit, relativeToSlots)) {
      return ((doSubtract, slots, otherSlots, maxUnit) => createDurationSlots(validateDurationFields(((a, b, largestUnit, doSubtract) => {
        const combined = durationDayTimeToBigNano(a) + durationDayTimeToBigNano(b) * BigInt(doSubtract ? -1 : 1);
        return Number.isFinite(Number(combined / bigNanoInUtcDay)) || throwRangeError(outOfBoundsDate), 
        {
          ...durationFieldDefaults,
          ...nanoToDurationDayTimeFields(combined, largestUnit)
        };
      })(slots, otherSlots, maxUnit, doSubtract))))(doSubtract, slots, otherSlots, maxUnit);
    }
    relativeToSlots || throwRangeError("Missing relativeTo"), doSubtract && (otherSlots = negateDurationFields(otherSlots));
    const markerSpanOps = createMarkerSpanOps(relativeToSlots);
    const midMarker = markerSpanOps.G(markerSpanOps.i, slots);
    const endMarker = markerSpanOps.G(midMarker, otherSlots);
    return createDurationSlots(markerSpanOps.re(markerSpanOps.i, endMarker, maxUnit));
  }
  function negateDuration(slots) {
    return createDurationSlots(negateDurationFields(slots));
  }
  function negateDurationFields(fields) {
    const res = {};
    for (const fieldName of durationFieldNamesAsc) {
      res[fieldName] = -1 * fields[fieldName] || 0;
    }
    return res;
  }
  function computeDurationSign(fields, fieldNames = durationFieldNamesAsc) {
    let sign = 0;
    for (const fieldName of fieldNames) {
      const fieldSign = Math.sign(fields[fieldName]);
      fieldSign && (sign && sign !== fieldSign && throwRangeError("Cannot mix duration signs"), 
      sign = fieldSign);
    }
    return sign;
  }
  function validateDurationFields(fields) {
    for (const calendarUnit of durationCalendarFieldNamesAsc) {
      clampEntity(calendarUnit, fields[calendarUnit], -4294967295, 4294967295, 1);
    }
    const bigNano = durationDayTimeToBigNano(fields);
    return validateDurationTimeUnit(Number(bigNano / bigNanoInSec)), fields;
  }
  function validateDurationTimeUnit(n) {
    Number.isSafeInteger(n) || throwRangeError("Out-of-bounds duration");
  }
  function durationDayTimeToBigNano(fields) {
    return BigInt(fields.days) * bigNanoInUtcDay + durationTimeToBigNano(fields);
  }
  function durationTimeToBigNano(fields) {
    return BigInt(fields.hours) * bigNanoInHour + BigInt(fields.minutes) * bigNanoInMinute + durationSubMinuteToBigNano(fields);
  }
  function durationSubMinuteToBigNano(fields) {
    return BigInt(fields.seconds) * bigNanoInSec + BigInt(fields.milliseconds) * bigNanoInMilli + BigInt(fields.microseconds) * bigNanoInMicro + BigInt(fields.nanoseconds);
  }
  function nanoToDurationDayTimeFields(bigNano, largestUnit = 6) {
    const days = Number(bigNano / bigNanoInUtcDay);
    const timeNano = Number(bigNano % bigNanoInUtcDay);
    const unitNano = unitNanoMap[largestUnit];
    const largestUnitVal = largestUnit <= 3 ? Number(bigNano / BigInt(unitNano)) : days * (nanoInUtcDay / unitNano) + divTrunc(timeNano, unitNano);
    Number.isFinite(largestUnitVal) || throwRangeError(outOfBoundsDate), largestUnit <= 3 && Math.abs(largestUnitVal) / (nanoInSec / unitNanoMap[largestUnit]) >= maxDurationSeconds && throwRangeError(outOfBoundsDate);
    const dayTimeFields = nanoToGivenFields(timeNano, largestUnit, durationFieldNamesAsc);
    return dayTimeFields[durationFieldNamesAsc[largestUnit]] = largestUnitVal, dayTimeFields;
  }
  function nanoToDurationTimeFields(nano, largestUnit = 5) {
    return nanoToGivenFields(nano, largestUnit, durationFieldNamesAsc);
  }
  function durationHasDateParts(fields) {
    return Boolean(computeDurationSign(fields, durationDateFieldNamesAsc));
  }
  function getMaxDurationUnit(fields) {
    let unit = 9;
    for (;unit > 0 && !fields[durationFieldNamesAsc[unit]]; unit--) {}
    return unit;
  }
  function compareInstants(instantSlots0, instantSlots1) {
    return compareBigInts(instantSlots0.epochNanoseconds, instantSlots1.epochNanoseconds);
  }
  function compareZonedDateTimes(zonedDateTimeSlots0, zonedDateTimeSlots1) {
    return compareBigInts(zonedDateTimeSlots0.epochNanoseconds, zonedDateTimeSlots1.epochNanoseconds);
  }
  function compareIsoDateTimeFields(isoDateTime0, isoDateTime1) {
    return compareIsoDateFields(isoDateTime0, isoDateTime1) || compareTimeFields(isoDateTime0, isoDateTime1);
  }
  function compareIsoDateFields(isoFields0, isoFields1) {
    return compareNumbers(isoDateToEpochDays(isoFields0), isoDateToEpochDays(isoFields1));
  }
  function compareTimeFields(isoFields0, isoFields1) {
    return compareNumbers(timeFieldsToNano(isoFields0), timeFieldsToNano(isoFields1));
  }
  function getCalendarEraOrigins(calendar) {
    return 0 === calendar ? gregoryEraOrigins : calendar ? calendar.l : void 0;
  }
  function getCalendarFieldNames(calendar, fieldNames, fieldNamesWithEra = fieldNames) {
    return getCalendarEraOrigins(calendar) ? fieldNamesWithEra : fieldNames;
  }
  function resolveCalendarYear(calendar, fields) {
    const exoticCalendar = calendar || void 0;
    const eraOrigins = getCalendarEraOrigins(calendar);
    let {era: era, eraYear: eraYear, year: year} = fields;
    if (void 0 !== year && (year = toIntegerWithTrunc(year, "year")), void 0 !== eraYear && (eraYear = toIntegerWithTrunc(eraYear, "eraYear")), 
    void 0 !== era || void 0 !== eraYear) {
      void 0 !== era && void 0 !== eraYear || throwTypeError("Mismatching era/eraYear"), 
      eraOrigins || throwRangeError("Forbidden era/eraYear");
      const normalizedEra = normalizeEraName(era);
      const eraOrigin = eraOrigins[normalizedEra];
      void 0 === eraOrigin && throwRangeError((era => `Invalid era: ${era}`)(era));
      const yearByEra = exoticCalendar?.te ? exoticCalendar.te(eraYear, normalizedEra, eraOrigin) : eraYearToYear(eraYear, eraOrigin);
      void 0 !== year && year !== yearByEra && throwRangeError("Mismatching year/eraYear"), 
      year = yearByEra;
    } else {
      void 0 === year && throwTypeError(missingYear(eraOrigins));
    }
    return year;
  }
  function resolveCalendarMonth(calendar, fields, year, overflow, monthCodeParts) {
    let {month: month, monthCode: monthCode} = fields;
    if (void 0 !== monthCode) {
      const monthByCode = ((calendar, monthCode, year, overflow, monthCodeParts = parseMonthCode(monthCode)) => {
        const leapMonth = calendar ? calendar.q(year) : void 0;
        const [monthCodeNumber, wantsLeapMonth] = monthCodeParts;
        let month = monthCodeNumberToMonth(monthCodeNumber, wantsLeapMonth, leapMonth);
        if (wantsLeapMonth) {
          const leapMonthMeta = calendar ? calendar.m : void 0;
          void 0 === leapMonthMeta && throwRangeError(invalidLeapMonth), leapMonthMeta > 0 ? (month > leapMonthMeta && throwRangeError(invalidLeapMonth), 
          leapMonth !== month && (1 === overflow && throwRangeError(invalidLeapMonth), month = monthCodeNumberToMonth(monthCodeNumber, 0, leapMonth))) : (month !== -leapMonthMeta && throwRangeError(invalidLeapMonth), 
          void 0 === leapMonth && 1 === overflow && throwRangeError(invalidLeapMonth));
        }
        return month;
      })(calendar, monthCode, year, overflow, monthCodeParts);
      void 0 !== month && month !== monthByCode && throwRangeError("Mismatching month/monthCode"), 
      month = monthByCode, overflow = 1;
    } else {
      void 0 === month && throwTypeError("Missing month/monthCode");
    }
    return clampEntity("month", month, 1, computeCalendarMonthsInYearForYear(calendar, year), overflow);
  }
  function resolveCalendarDay(calendar, fields, month, year, overflow) {
    return clampProp(fields, "day", 1, computeCalendarDaysInMonthForYearMonth(calendar, year, month), overflow);
  }
  function eraYearToYear(eraYear, eraOrigin) {
    return (eraOrigin + eraYear) * (Math.sign(eraOrigin) || 1) || 0;
  }
  function resolveTimeFields(fields, overflow) {
    return constrainTimeFields(pluckProps(timeFieldNamesAsc, {
      ...timeFieldDefaults,
      ...fields
    }), overflow);
  }
  function parseOffsetNano(s) {
    const offsetNano = parseOffsetNanoMaybe(s);
    return void 0 === offsetNano && throwRangeError(failedParse(s)), offsetNano;
  }
  function parseOffsetNanoMaybe(s, onlyHourMinute) {
    const parts = offsetRegExp.exec(s);
    if (parts && (s => (s => {
      "T" !== s[0] && "t" !== s[0] || (s = s.slice(1));
      const fractionIndex = s.search(/[.,]/);
      const main = fractionIndex < 0 ? s : s.slice(0, fractionIndex);
      const parts = main.split(":");
      return 1 === parts.length ? /^(?:\d{2}|\d{4}|\d{6})$/i.test(main) : (2 === parts.length || 3 === parts.length) && parts.every(part => 2 === part.length && /^\d{2}$/i.test(part));
    })(s.slice(1)))(parts[0])) {
      return ((parts, onlyHourMinute) => {
        const firstSubMinutePart = parts[4] || parts[5];
        return onlyHourMinute && firstSubMinutePart && throwRangeError(invalidSubstring(firstSubMinutePart)), 
        offsetNano = (parseInt0(parts[2]) * nanoInHour + parseInt0(parts[3]) * nanoInMinute + parseInt0(parts[4]) * nanoInSec + parseSubsecNano(parts[5] || "")) * parseSign(parts[1]), 
        Math.abs(offsetNano) >= nanoInUtcDay && throwRangeError("Out-of-bounds offset"), 
        offsetNano;
        var offsetNano;
      })(parts, onlyHourMinute);
    }
  }
  function readAndRefineBagFields(bag, validFieldNames, fieldRefiners, requiredFieldNames, disallowEmpty = !requiredFieldNames) {
    const res = {};
    let anyMatching = 0;
    for (const fieldName of validFieldNames) {
      let fieldVal = bag[fieldName];
      if (void 0 !== fieldVal) {
        anyMatching = 1;
        const refiner = fieldRefiners[fieldName];
        refiner && (fieldVal = refiner(fieldVal, fieldName)), res[fieldName] = fieldVal;
      } else {
        requiredFieldNames && requiredFieldNames.includes(fieldName) && throwTypeError(missingField(fieldName));
      }
    }
    return disallowEmpty && !anyMatching && throwTypeError(noValidFields(validFieldNames)), 
    res;
  }
  function createPlainDateTimeFromRefinedFields(isoDate, time = timeFieldDefaults, calendar) {
    const isoDateTime = combineDateAndTime(isoDate, time);
    return checkIsoDateTimeInBounds(isoDateTime), createDateTimeSlots(isoDateTime, calendar);
  }
  function createPlainDateFromFields(calendar, fields, options) {
    return createPlainDateFromPreparedFields(calendar, fields, prepareDateFields(calendar, fields), refineOverflowOptions(options));
  }
  function createPlainDateFromFieldsWithOptionsRefiner(calendar, fields, refineOptions) {
    const prepared = prepareDateFields(calendar, fields);
    const refinedOptions = refineOptions();
    return [ createPlainDateFromPreparedFields(calendar, fields, prepared, refinedOptions[0]), ...refinedOptions ];
  }
  function createPlainDateFromPreparedFields(calendar, fields, prepared, overflow) {
    const year = prepared[1];
    const month = resolveCalendarMonth(calendar, fields, year, overflow, prepared[0]);
    return createDateSlots(checkIsoDateInBounds(computeCalendarIsoFieldsFromParts(calendar, year, month, resolveCalendarDay(calendar, fields, month, year, overflow))), calendar);
  }
  function parseMonthCodeField(fields) {
    if (void 0 !== fields.monthCode) {
      return parseMonthCode(fields.monthCode);
    }
  }
  function prepareDateFields(calendar, fields) {
    const eraOrigins = getCalendarEraOrigins(calendar);
    return void 0 !== fields.year || void 0 !== fields.era && void 0 !== fields.eraYear || throwTypeError(missingYear(eraOrigins)), 
    void 0 === fields.monthCode && void 0 === fields.month && throwTypeError("Missing month/monthCode"), 
    void 0 === fields.day && throwTypeError(missingField("day")), [ parseMonthCodeField(fields), resolveCalendarYear(calendar, fields) ];
  }
  function createPlainYearMonthFromFields(calendar, fields, options) {
    const eraOrigins = getCalendarEraOrigins(calendar);
    void 0 !== fields.year || void 0 !== fields.era && void 0 !== fields.eraYear || throwTypeError(missingYear(eraOrigins)), 
    void 0 === fields.monthCode && void 0 === fields.month && throwTypeError("Missing month/monthCode");
    const monthCodeParts = parseMonthCodeField(fields);
    const year = resolveCalendarYear(calendar, fields);
    return createDateSlots(checkIsoYearMonthInBounds(computeCalendarIsoFieldsFromParts(calendar, year, resolveCalendarMonth(calendar, fields, year, refineOverflowOptions(options), monthCodeParts), 1)), calendar);
  }
  function createPlainMonthDayFromFields(calendar, fields, options) {
    const isIso = calendar === isoCalendarImpl;
    const eraOrigins = getCalendarEraOrigins(calendar);
    void 0 === fields.day && throwTypeError(missingField("day")), isIso || void 0 === fields.month || void 0 !== fields.year || void 0 !== fields.era && void 0 !== fields.eraYear || throwTypeError(missingYear(eraOrigins));
    const monthCodeParts = parseMonthCodeField(fields);
    let yearMaybe = void 0 !== fields.eraYear || void 0 !== fields.year ? resolveCalendarYear(calendar, fields) : void 0;
    const overflow = refineOverflowOptions(options);
    let day;
    let monthCodeNumber;
    let isLeapMonth;
    if (void 0 === yearMaybe && isIso && (yearMaybe = 1972), void 0 !== yearMaybe) {
      isIso || checkIsoDateInBounds(computeCalendarIsoFieldsFromParts(calendar, yearMaybe, 1, 1));
      const month = resolveCalendarMonth(calendar, fields, yearMaybe, overflow, monthCodeParts);
      day = resolveCalendarDay(calendar, fields, month, yearMaybe, overflow), [monthCodeNumber, isLeapMonth] = computeCalendarMonthCodeParts(calendar, yearMaybe, month);
    } else {
      void 0 === fields.monthCode && throwTypeError("Missing month/monthCode"), [monthCodeNumber, isLeapMonth] = monthCodeParts;
      const referenceYear = calendar ? calendar.ge : 1972;
      if (void 0 !== referenceYear) {
        day = resolveCalendarDay(calendar, fields, resolveCalendarMonth(calendar, fields, referenceYear, overflow, monthCodeParts), referenceYear, overflow);
      } else {
        const constrainedDay = 0 === overflow && calendar ? calendar.ke?.(monthCodeNumber, isLeapMonth, fields.day) : void 0;
        day = void 0 !== constrainedDay ? constrainedDay : fields.day;
      }
    }
    isLeapMonth && ((calendar && calendar.Z?.[monthCodeNumber]) ?? 1 / 0) < fields.day && (1 === overflow && throwRangeError(invalidLeapMonth), 
    isLeapMonth = 0, day = constrainToRange(fields.day, 1, (calendar && calendar.X) ?? 1 / 0));
    let res = calendar ? calendar.v(monthCodeNumber, Boolean(isLeapMonth), day) : computeIsoYearMonthFieldsForMonthDay(monthCodeNumber, Boolean(isLeapMonth));
    for (;!res && 0 === overflow && day > 1; ) {
      day--, res = calendar ? calendar.v(monthCodeNumber, Boolean(isLeapMonth), day) : computeIsoYearMonthFieldsForMonthDay(monthCodeNumber, Boolean(isLeapMonth));
    }
    res || throwRangeError("Cannot guess year");
    const {year: finalYear, month: finalMonth} = res;
    return createDateSlots(checkIsoDateInBounds(computeCalendarIsoFieldsFromParts(calendar, finalYear, finalMonth, day)), calendar);
  }
  function formatEpochMilliToPartsRecord(intlFormat, epochMilli) {
    epochMilli < -864e13 && throwRangeError(outOfBoundsDate);
    const parts = intlFormat.formatToParts(epochMilli);
    const hash = {};
    for (const part of parts) {
      hash[part.type] = part.value;
    }
    return hash;
  }
  function refineTimeDisplayTuple(options, maxSmallestUnit = 4) {
    const subsecDigits = coerceFractionalSecondDigits(options);
    const roundingMode = coerceRoundingMode(options, 4);
    const smallestUnit = coerceSmallestUnit(options);
    return [ roundingMode, ...resolveSmallestUnitAndSubsecDigits(validateUnitRange(smallestUnitStr, smallestUnit, 0, maxSmallestUnit), subsecDigits) ];
  }
  function refineDateDisplayOptions(options) {
    return coerceCalendarDisplay(normalizeOptions(options));
  }
  function refineTimeDisplayOptions(options, maxSmallestUnit) {
    return refineTimeDisplayTuple(normalizeOptions(options), maxSmallestUnit);
  }
  function resolveSmallestUnitAndSubsecDigits(smallestUnit, subsecDigits) {
    return null != smallestUnit ? [ unitNanoMap[smallestUnit], smallestUnit < 4 ? 9 - 3 * smallestUnit : -1 ] : [ void 0 === subsecDigits ? 1 : 10 ** (9 - subsecDigits), subsecDigits ];
  }
  function formatInstantIso(refineTimeZoneString, instantSlots, options) {
    const [timeZoneArg, roundingMode, nanoInc, subsecDigits] = (options => {
      const subsecDigits = coerceFractionalSecondDigits(options = normalizeOptions(options));
      const roundingMode = coerceRoundingMode(options, 4);
      const smallestUnit = coerceSmallestUnit(options);
      return [ options.timeZone, roundingMode, ...resolveSmallestUnitAndSubsecDigits(validateUnitRange(smallestUnitStr, smallestUnit, 0, 4), subsecDigits) ];
    })(options);
    const providedTimeZone = void 0 !== timeZoneArg;
    return ((providedTimeZone, timeZone, epochNano, roundingMode, nanoInc, subsecDigits) => {
      epochNano = roundBigNanoToDayOriginInc(epochNano, BigInt(nanoInc), roundingMode);
      const offsetNano = timeZone.C(epochNano);
      return formatIsoDateTimeFields(epochNanoToIsoDateTime(epochNano + BigInt(offsetNano)), subsecDigits) + (providedTimeZone ? formatOffsetNano(roundToMinute(offsetNano)) : "Z");
    })(providedTimeZone, queryTimeZone(providedTimeZone ? refineTimeZoneString(timeZoneArg) : "UTC"), instantSlots.epochNanoseconds, roundingMode, nanoInc, subsecDigits);
  }
  function formatZonedDateTimeIso(zonedDateTimeSlots0, options) {
    const displayOptions = (options => {
      options = normalizeOptions(options);
      const calendarDisplay = coerceCalendarDisplay(options);
      const subsecDigits = coerceFractionalSecondDigits(options);
      const offsetDisplay = coerceOffsetDisplay(options);
      const roundingMode = coerceRoundingMode(options, 4);
      const smallestUnit = coerceSmallestUnit(options);
      return [ calendarDisplay, coerceTimeZoneDisplay(options), offsetDisplay, roundingMode, ...resolveSmallestUnitAndSubsecDigits(validateUnitRange(smallestUnitStr, smallestUnit, 0, 4), subsecDigits) ];
    })(options);
    return ((calendar, timeZoneId, timeZone, epochNano, calendarDisplay, timeZoneDisplay, offsetDisplay, roundingMode, nanoInc, subsecDigits) => {
      epochNano = roundBigNanoToDayOriginInc(epochNano, BigInt(nanoInc), roundingMode);
      const offsetNano = timeZone.C(epochNano);
      return formatIsoDateTimeFields(epochNanoToIsoDateTime(epochNano + BigInt(offsetNano)), subsecDigits) + formatOffsetNano(roundToMinute(offsetNano), offsetDisplay) + ((timeZoneId, timeZoneDisplay) => 1 !== timeZoneDisplay ? "[" + (2 === timeZoneDisplay ? "!" : "") + timeZoneId + "]" : "")(timeZoneId, timeZoneDisplay) + formatCalendar(calendar, calendarDisplay);
    })(zonedDateTimeSlots0.calendar, zonedDateTimeSlots0.timeZone.id, zonedDateTimeSlots0.timeZone, zonedDateTimeSlots0.epochNanoseconds, ...displayOptions);
  }
  function formatPlainDateTimeIso(plainDateTimeSlots0, options) {
    const displayOptions = (options => (options = normalizeOptions(options), [ coerceCalendarDisplay(options), ...refineTimeDisplayTuple(options) ]))(options);
    return ((calendar, isoDateTime, calendarDisplay, roundingMode, nanoInc, subsecDigits) => formatIsoDateTimeFields(roundDateTimeToNano(isoDateTime, nanoInc, roundingMode), subsecDigits) + formatCalendar(calendar, calendarDisplay))(plainDateTimeSlots0.calendar, plainDateTimeSlots0, ...displayOptions);
  }
  function formatPlainDateIso(plainDateSlots, options) {
    return calendar = plainDateSlots.calendar, isoDate = plainDateSlots, calendarDisplay = refineDateDisplayOptions(options), 
    formatIsoDateFields(isoDate) + formatCalendar(calendar, calendarDisplay);
    var calendar, isoDate, calendarDisplay;
  }
  function formatPlainYearMonthIso(plainYearMonthSlots, options) {
    return formatDateLikeIso(plainYearMonthSlots.calendar, formatIsoYearMonthFields, plainYearMonthSlots, refineDateDisplayOptions(options));
  }
  function formatPlainMonthDayIso(plainMonthDaySlots, options) {
    return formatDateLikeIso(plainMonthDaySlots.calendar, formatIsoMonthDayFields, plainMonthDaySlots, refineDateDisplayOptions(options));
  }
  function formatDateLikeIso(calendar, formatSimple, isoDate, calendarDisplay) {
    const showCalendar = calendarDisplay > 1 || 0 === calendarDisplay && calendar !== isoCalendarImpl;
    return 1 === calendarDisplay ? calendar === isoCalendarImpl ? formatSimple(isoDate) : formatIsoDateFields(isoDate) : showCalendar ? formatIsoDateFields(isoDate) + formatCalendarId(getCalendarSlotId(calendar), 2 === calendarDisplay) : formatSimple(isoDate);
  }
  function formatPlainTimeIso(slots, options) {
    return ((fields, roundingMode, nanoInc, subsecDigits) => formatTimeFields(roundTimeToNano(fields, nanoInc, roundingMode)[0], subsecDigits))(slots, ...refineTimeDisplayOptions(options));
  }
  function formatDurationIso(slots, options) {
    const [roundingMode, nanoInc, subsecDigits] = refineTimeDisplayOptions(options, 3);
    return nanoInc > 1 && validateDurationFields(slots = {
      ...slots,
      ...roundDayTimeDurationByInc(slots, nanoInc, roundingMode)
    }), ((durationSlots, subsecDigits) => {
      const {sign: sign} = durationSlots;
      const abs = -1 === sign ? negateDurationFields(durationSlots) : durationSlots;
      const {hours: hours, minutes: minutes} = abs;
      const bigNano = durationSubMinuteToBigNano(abs);
      const wholeSec = Number(bigNano / bigNanoInSec);
      const subsecNano = Number(bigNano % bigNanoInSec);
      validateDurationTimeUnit(wholeSec);
      const subsecNanoString = formatSubsecNano(subsecNano, subsecDigits);
      const forceSec = subsecDigits >= 0 || !sign || subsecNanoString;
      return (sign < 0 ? "-" : "") + "P" + formatDurationFragments({
        Y: formatDurationNumber(abs.years),
        M: formatDurationNumber(abs.months),
        W: formatDurationNumber(abs.weeks),
        D: formatDurationNumber(abs.days)
      }) + (hours || minutes || wholeSec || forceSec ? "T" + formatDurationFragments({
        H: formatDurationNumber(hours),
        M: formatDurationNumber(minutes),
        S: formatDurationNumber(wholeSec, forceSec) + subsecNanoString
      }) : "");
    })(slots, subsecDigits);
  }
  function formatDurationFragments(fragObj) {
    const parts = [];
    for (const fragName in fragObj) {
      const fragVal = fragObj[fragName];
      fragVal && parts.push(fragVal, fragName);
    }
    return parts.join("");
  }
  function formatDurationNumber(n, force) {
    if (!n && !force) {
      return "";
    }
    const options = Object.create(null);
    return options.useGrouping = 0, n.toLocaleString("fullwide", options);
  }
  function formatIsoDateTimeFields(isoDateTime, subsecDigits) {
    return formatIsoDateFields(isoDateTime) + "T" + formatTimeFields(isoDateTime, subsecDigits);
  }
  function formatIsoDateFields(isoDateFields) {
    return formatIsoYearMonthFields(isoDateFields) + "-" + padNumber2(isoDateFields.day);
  }
  function formatIsoYearMonthFields(isoDateFields) {
    const {year: year} = isoDateFields;
    return (year < 0 || year > 9999 ? getSignStr(year) + padNumber(6, Math.abs(year)) : padNumber(4, year)) + "-" + padNumber2(isoDateFields.month);
  }
  function formatIsoMonthDayFields(isoDateFields) {
    return padNumber2(isoDateFields.month) + "-" + padNumber2(isoDateFields.day);
  }
  function formatTimeFields(timeFields, subsecDigits) {
    const parts = [ padNumber2(timeFields.hour), padNumber2(timeFields.minute) ];
    return -1 !== subsecDigits && parts.push(padNumber2(timeFields.second) + ((millisecond, microsecond, nanosecond, subsecDigits) => formatSubsecNano(millisecond * nanoInMilli + 1e3 * microsecond + nanosecond, subsecDigits))(timeFields.millisecond, timeFields.microsecond, timeFields.nanosecond, subsecDigits)), 
    parts.join(":");
  }
  function formatOffsetNano(offsetNano, offsetDisplay = 0) {
    if (1 === offsetDisplay) {
      return "";
    }
    const [hour, nanoRemainder0] = divModFloor(Math.abs(offsetNano), nanoInHour);
    const [minute, nanoRemainder1] = divModFloor(nanoRemainder0, nanoInMinute);
    const [second, nanoRemainder2] = divModFloor(nanoRemainder1, nanoInSec);
    return getSignStr(offsetNano) + padNumber2(hour) + ":" + padNumber2(minute) + (second || nanoRemainder2 ? ":" + padNumber2(second) + formatSubsecNano(nanoRemainder2) : "");
  }
  function formatCalendar(calendar, calendarDisplay) {
    return calendarDisplay > 1 || 0 === calendarDisplay && calendar !== isoCalendarImpl ? formatCalendarId(getCalendarSlotId(calendar), 2 === calendarDisplay) : "";
  }
  function formatCalendarId(calendarId, isCritical) {
    return "[" + (isCritical ? "!" : "") + "u-ca=" + calendarId + "]";
  }
  function formatSubsecNano(totalNano, subsecDigits) {
    let s = padNumber(9, totalNano);
    return s = void 0 === subsecDigits ? s.replace(trailingZerosRE, "") : s.slice(0, subsecDigits), 
    s ? "." + s : "";
  }
  function getSignStr(num) {
    return num < 0 ? "-" : "+";
  }
  function resolveTimeZoneId(rawId) {
    return resolveTimeZoneRecord(rawId).id;
  }
  function resolveTimeZoneRecord(rawId) {
    const upperRawId = rawId.toUpperCase();
    const offsetRecord = (upperRawId => {
      const offsetNano = parseOffsetNanoMaybe(upperRawId, 1);
      if (void 0 !== offsetNano) {
        return {
          id: formatOffsetNano(offsetNano),
          _: offsetNano,
          o: offsetNano
        };
      }
    })(upperRawId);
    if (offsetRecord) {
      return {
        kind: "fixed",
        ...offsetRecord
      };
    }
    const normId = "UTC" === upperRawId ? "UTC" : (rawId => (badCharactersRegExp.test(rawId) && throwRangeError(invalidTimeZone(rawId)), 
    icuRegExp.test(rawId) && throwRangeError("Forbidden ICU TimeZone"), rawId.toLowerCase().split("/").map((part, partI) => (part.length <= 3 || /\d/.test(part)) && !/etc|yap/.test(part) ? part.toUpperCase() : part.replace(/baja|dumont|[a-z]+/g, (a, i) => a.length <= 2 && !partI || "in" === a || "chat" === a ? a.toUpperCase() : a.length > 2 || !i ? capitalize(a).replace(/island|noronha|murdo|rivadavia|urville/, capitalize) : a)).join("/")))(rawId);
    return queryNamedTimeZoneRecord(normId);
  }
  function queryTimeZone(rawTimeZoneId) {
    const record = resolveTimeZoneRecord(rawTimeZoneId);
    return queryTimeZoneRecord(record.id, record);
  }
  function getCurrentEpochSec() {
    return Math.floor(Date.now() / 1e3);
  }
  function createSplitTuple(startEpochSec, endEpochSec) {
    return [ startEpochSec, endEpochSec ];
  }
  function computePeriod(epochSec, periodSec) {
    const startEpochSec = Math.floor(epochSec / periodSec) * periodSec;
    return [ startEpochSec, startEpochSec + periodSec ];
  }
  function clampIntlSampleEpochSec(epochSec) {
    return constrainToRange(epochSec, -1e10, 864e10);
  }
  function throwFailedParse(s) {
    throwRangeError(failedParse(s));
  }
  function requireIsoCalendar(organized) {
    "iso8601" !== organized.calendarId && throwRangeError(invalidSubstring(organized.calendarId));
  }
  function parsePlainDateLike(s) {
    const organized = parseDateTimeLike(s);
    return organized && !organized.F || throwFailedParse(s), organized;
  }
  function finalizeDateLike(organized, isoDateProjector, resolveCalendar) {
    return isoDateProjector && "iso8601" === organized.calendarId ? (validateIsoDateFields(organized), 
    organized.fe && validateTimeFields(organized), finalizeDate(isoDateProjector(organized), resolveCalendar)) : organized.fe ? finalizeDateTime(organized, resolveCalendar) : finalizeDate(organized, resolveCalendar);
  }
  function projectIsoYearMonthDate(organized) {
    const day = 12 * organized.year + organized.month === isoYearMonthIndexMin ? 20 : 1;
    return {
      ...organized,
      day: day
    };
  }
  function projectIsoMonthDayDate(organized) {
    return {
      ...organized,
      year: 1972
    };
  }
  function finalizeZonedDateTime(organized, resolveCalendar, options) {
    const timeZone = queryTimeZone(resolveTimeZoneId(organized.timeZoneId));
    let epochNano;
    if (validateIsoDateTimeFields(organized), organized.fe) {
      const offsetNano = organized.offset ? parseOffsetNano(organized.offset) : void 0;
      const [, offsetDisambig, epochDisambig] = refineZonedFieldOptions(options);
      epochNano = getMatchingInstantFor(timeZone, organized, offsetNano, offsetDisambig, epochDisambig, !(timeZone._ || void 0 === organized.offset || (offset = organized.offset, 
      offset.replace(/\D/g, "").length > 4)), organized.F);
    } else {
      refineZonedFieldOptions(options), epochNano = getStartOfDayInstantFor(timeZone, organized);
    }
    var offset;
    return checkEpochNanoInBounds(epochNano), createZonedEpochNanoSlots(epochNano, timeZone, resolveCalendar(organized.calendarId));
  }
  function finalizeDateTime(organized, resolveCalendar) {
    return validateIsoDateTimeFields(organized), checkIsoDateTimeInBounds(organized), 
    {
      ...combineDateAndTime(organized, organized),
      calendar: resolveCalendar(organized.calendarId)
    };
  }
  function finalizeDate(organized, resolveCalendar) {
    return validateIsoDateFields(organized), checkIsoDateInBounds(organized), {
      calendar: resolveCalendar(organized.calendarId),
      year: organized.year,
      month: organized.month,
      day: organized.day
    };
  }
  function timeRegExpStr(separatorIndex) {
    return `(\\d{2})(?:(:?)(\\d{2})(?:\\${separatorIndex}(\\d{2})(?:[.,](\\d{1,9}))?)?)?`;
  }
  function offsetRegExpStr(separatorIndex) {
    return "([+-])" + timeRegExpStr(separatorIndex);
  }
  function parseDateTimeLike(s) {
    const parts = dateTimeRegExp.exec(s);
    return parts ? (parts => {
      const zOrOffset = parts[12];
      const hasZ = "Z" === (zOrOffset || "").toUpperCase();
      return {
        year: organizeIsoYearParts(parts),
        month: parseInt(parts[5]),
        day: parseInt(parts[6]),
        ...organizeTimeParts(parts, 7),
        ...organizeAnnotationParts(parts[19]),
        fe: Boolean(parts[7]),
        F: hasZ,
        offset: hasZ ? void 0 : zOrOffset
      };
    })(parts) : void 0;
  }
  function parseYearMonthOnly(s) {
    const parts = yearMonthRegExp.exec(s);
    if (parts) {
      return (parts => ({
        year: organizeIsoYearParts(parts),
        month: parseInt(parts[4]),
        day: 1,
        ...organizeAnnotationParts(parts[5])
      }))(parts);
    }
  }
  function parseMonthDayOnly(s) {
    const parts = monthDayRegExp.exec(s);
    return parts ? (parts => ({
      year: 1972,
      month: parseInt(parts[1]),
      day: parseInt(parts[2]),
      ...organizeAnnotationParts(parts[3])
    }))(parts) : void 0;
  }
  function parseTimeOnlyParts(s) {
    const parts = timeRegExp.exec(s);
    if (parts) {
      return parts[6] && parseOffsetNano(parts[6]), parts;
    }
  }
  function organizeTimeParts(parts, hourIndex) {
    const second = parseInt0(parts[hourIndex + 3]);
    return {
      ...nanoToTimeAndDay(parseSubsecNano(parts[hourIndex + 4] || ""))[0],
      hour: parseInt0(parts[hourIndex]),
      minute: parseInt0(parts[hourIndex + 2]),
      second: 60 === second ? 59 : second
    };
  }
  function organizeIsoYearParts(parts) {
    const yearSign = parseSign(parts[1]);
    const year = parseInt(parts[2] || parts[3]);
    return yearSign < 0 && !year && throwRangeError(invalidSubstring(-0)), yearSign * year;
  }
  function organizeAnnotationParts(s) {
    let calendarIsCritical;
    let timeZoneId;
    const calendarIds = [];
    return s.replace(annotationRegExp, (whole, criticalStr, mainStr) => {
      const isCritical = Boolean(criticalStr);
      const [val, name] = mainStr.split("=").reverse();
      return name ? "u-ca" === name ? (calendarIds.push(val.toLowerCase()), calendarIsCritical || (calendarIsCritical = isCritical)) : (isCritical || /[A-Z]/.test(name)) && throwRangeError(invalidSubstring(whole)) : (timeZoneId && throwRangeError(invalidSubstring(whole)), 
      timeZoneId = val), "";
    }), calendarIds.length > 1 && calendarIsCritical && throwRangeError(invalidSubstring(s)), 
    {
      timeZoneId: timeZoneId,
      calendarId: calendarIds[0] || "iso8601"
    };
  }
  function mergeCalendarFields(calendar, baseFields, additionalFields) {
    const merged = Object.assign(Object.create(null), baseFields);
    return spliceFields(merged, additionalFields, monthFieldNames), getCalendarEraOrigins(calendar) && (spliceFields(merged, additionalFields, allYearFieldNames), 
    calendar && calendar.le && spliceFields(merged, additionalFields, monthDayFieldNames, eraYearFieldNames)), 
    merged;
  }
  function spliceFields(dest, additional, allPropNames, deletablePropNames) {
    let anyMatching = 0;
    const nonMatchingPropNames = [];
    for (const propName of allPropNames) {
      void 0 !== additional[propName] ? anyMatching = 1 : nonMatchingPropNames.push(propName);
    }
    if (Object.assign(dest, additional), anyMatching) {
      for (const deletablePropName of deletablePropNames || nonMatchingPropNames) {
        delete dest[deletablePropName];
      }
    }
  }
  function computeMonthCode(calendar, year, month) {
    const [monthCodeNumber, isLeapMonth] = computeCalendarMonthCodeParts(calendar, year, month);
    return formatMonthCode(monthCodeNumber, isLeapMonth);
  }
  function zonedDateTimeToPlainDateTime(zonedDateTimeSlots0) {
    return createDateTimeSlots(zonedEpochSlotsToIso(zonedDateTimeSlots0), zonedDateTimeSlots0.calendar);
  }
  function zonedDateTimeToPlainDate(zonedDateTimeSlots0) {
    return createDateSlots(zonedEpochSlotsToIso(zonedDateTimeSlots0), zonedDateTimeSlots0.calendar);
  }
  function zonedDateTimeToPlainTime(zonedDateTimeSlots0) {
    return createTimeSlots(zonedEpochSlotsToIso(zonedDateTimeSlots0));
  }
  function createPlainDateFromMergedFields(calendar, inputFields, extraFields) {
    const mergedFieldNames = getCalendarFieldNames(calendar, yearMonthCodeDayFieldNamesAlpha, yearMonthCodeDayFieldNamesWithEraAlpha);
    let mergedFields = mergeCalendarFields(calendar, inputFields, extraFields);
    return mergedFields = readAndRefineBagFields(mergedFields, mergedFieldNames, dateFieldRefiners, []), 
    createPlainDateFromFields(calendar, mergedFields);
  }
  function applyPlainFormatTimeZone(options) {
    return options.timeZone = "UTC", [ "full", "long" ].includes(options.timeStyle) && (options.timeStyle = "medium"), 
    options;
  }
  function checkResolvedCalendarCompatible(format, slots, strictCalendarCheck) {
    const resolvedCalendarId = format.resolvedOptions().calendar;
    !strictCalendarCheck && slots.calendar === isoCalendarImpl || getCalendarSlotId(slots.calendar) === resolvedCalendarId || throwRangeError("Mismatching Calendars");
  }
  function createOptionsTransformer(shapeFieldNames, invalidShapeFieldNames, ignoredFieldNames, defaultShapeFields, dateStyleReplacementFields) {
    const shapeFieldNameSet = new Set(shapeFieldNames);
    const invalidShapeFieldNameSet = new Set(invalidShapeFieldNames);
    const ignoredFieldNameSet = new Set(ignoredFieldNames);
    return (options, allowPartialOverlap) => {
      const analysis = ((options, shapeFieldNameSet, invalidShapeFieldNameSet, ignoredFieldNameSet) => {
        const analysis = {
          dateStyle: void 0,
          timeStyle: void 0,
          me: {},
          pe: {},
          xe: {},
          oe: 0,
          ue: 0
        };
        for (const name of Object.keys(options)) {
          const value = options[name];
          void 0 === value || ignoredFieldNameSet.has(name) || (shapeFieldNameSet.has(name) ? "dateStyle" === name ? analysis.dateStyle = value : "timeStyle" === name ? analysis.timeStyle = value : analysis.me[name] = value : "era" === name ? analysis.pe[name] = value : invalidShapeFieldNameSet.has(name) ? "dateStyle" === name || "timeStyle" === name ? analysis.ue = 1 : analysis.oe = 1 : analysis.xe[name] = value);
        }
        return analysis;
      })(options, shapeFieldNameSet, invalidShapeFieldNameSet, ignoredFieldNameSet);
      const hasDateStyle = void 0 !== analysis.dateStyle;
      const hasTimeStyle = void 0 !== analysis.timeStyle;
      const hasAnyStyle = hasDateStyle || hasTimeStyle;
      const hasGranularShapeFields = Object.keys(analysis.me).length > 0;
      const hasInvalids = analysis.oe || analysis.ue;
      const hasShapeFields = hasGranularShapeFields || hasDateStyle || hasTimeStyle;
      const hasModifierFields = Object.keys(analysis.pe).length > 0;
      const hasStyleConflictFields = hasGranularShapeFields || hasModifierFields || analysis.oe;
      (!allowPartialOverlap && hasInvalids || allowPartialOverlap && hasInvalids && !hasShapeFields || hasAnyStyle && hasStyleConflictFields) && throwTypeError("Invalid formatting options");
      const transformedOptions = {};
      return hasAnyStyle || hasShapeFields || Object.assign(transformedOptions, defaultShapeFields), 
      Object.assign(transformedOptions, analysis.me, analysis.pe, analysis.xe), hasDateStyle && (dateStyleReplacementFields ? Object.assign(transformedOptions, dateStyleReplacementFields[analysis.dateStyle]) : transformedOptions.dateStyle = analysis.dateStyle), 
      hasTimeStyle && (transformedOptions.timeStyle = analysis.timeStyle), transformedOptions;
    };
  }
  function getCurrentIsoDateTime(timeZone) {
    const epochNano = getCurrentEpochNano();
    const offsetNano = timeZone.C(epochNano);
    return epochNanoToIsoDateTime(epochNano + BigInt(offsetNano));
  }
  function getCurrentEpochNano() {
    return BigInt(Date.now()) * bigNanoInMilli;
  }
  function getCurrentTimeZoneId() {
    return (new RawDateTimeFormat).resolvedOptions().timeZone;
  }
  function defineTemporalClass(branding, cls, getSlots, ...getterMaps) {
    Object.defineProperties(cls, createPropDescriptors({
      name: branding
    }, 1)), Object.defineProperties(cls.prototype, createStringTagDescriptors("Temporal." + branding));
    for (const getterMap of getterMaps) {
      defineSlotGetters(cls.prototype, getSlots, getterMap);
    }
    return cls;
  }
  function defineSlotGetters(destPrototype, getSlots, getterMap) {
    Object.defineProperties(destPrototype, mapProps(getter => ({
      get() {
        return getter(getSlots(this));
      },
      configurable: 1
    }), getterMap));
  }
  function invalidRecordType() {
    throwTypeError("Invalid calling context");
  }
  function forbiddenValueOf() {
    throwTypeError("Cannot use valueOf");
  }
  function createNativeGetters(shimGetters) {
    return createPropGetters(Object.keys(shimGetters));
  }
  function createDateTimeFormatClass(getTemporalBrandingAndSlots) {
    return function(createArgsProvider, transformOptions = identity) {
      function getInternals(format) {
        const internals = internalsMap.get(format);
        return internals || throwTypeError("Invalid calling context"), internals;
      }
      function DateTimeFormat(locales, options) {
        return new ShimDateTimeFormat(locales, options);
      }
      const internalsMap = new WeakMap;
      class ShimDateTimeFormat {
        constructor(locales, options = Object.create(null)) {
          const transformedOptions = transformOptions(options);
          const baseFormat = new RawDateTimeFormat(locales, transformedOptions);
          const resolvedOptions = baseFormat.resolvedOptions();
          const copiedOptions = pluckProps(Object.keys(options), resolvedOptions);
          internalsMap.set(this, {
            ee: createArgsProvider({
              t: baseFormat,
              Ge: resolvedOptions.locale,
              I: copiedOptions,
              Je: transformedOptions
            }),
            t: baseFormat
          });
        }
        get format() {
          const internals = getInternals(this);
          return internals.ze || (internals.ze = record => {
            const [format, ...rest] = internals.ee.B(record);
            return format.format(...rest);
          });
        }
        formatToParts(record) {
          const {ee: argsProvider} = getInternals(this);
          const [format, ...rest] = argsProvider.B(record);
          return format.formatToParts(...rest);
        }
        resolvedOptions() {
          return getInternals(this).t.resolvedOptions();
        }
      }
      const {prototype: prototype} = ShimDateTimeFormat;
      RawDateTimeFormat.prototype.formatRange && Object.defineProperties(prototype, createPropDescriptors({
        formatRange(record0, record1) {
          const {ee: argsProvider} = getInternals(this);
          const [format, epochMilli0, epochMilli1] = argsProvider.A(record0, record1);
          return format.formatRange(epochMilli0, epochMilli1);
        },
        formatRangeToParts(record0, record1) {
          const {ee: argsProvider} = getInternals(this);
          const [format, epochMilli0, epochMilli1] = argsProvider.A(record0, record1);
          return format.formatRangeToParts(epochMilli0, epochMilli1);
        }
      }));
      const rawStaticDescriptors = Object.getOwnPropertyDescriptors(RawDateTimeFormat);
      return rawStaticDescriptors.prototype.value = prototype, Object.defineProperties(DateTimeFormat, rawStaticDescriptors), 
      prototype.constructor = DateTimeFormat, Object.defineProperties(prototype, createStringTagDescriptors("Intl.DateTimeFormat")), 
      DateTimeFormat;
    }(internals => {
      const getTemporalFormat = memoize(branding => ((internals, branding) => {
        let options;
        switch (branding) {
         case "Instant":
          options = transformInstantOptions(internals.I, 1);
          break;

         case "PlainDateTime":
          options = applyPlainFormatTimeZone(transformDateTimeOptions(internals.I, 1));
          break;

         case "PlainDate":
          options = applyPlainFormatTimeZone(transformDateOptions(internals.I, 1));
          break;

         case "PlainTime":
          options = applyPlainFormatTimeZone(transformTimeOptions(internals.I, 1));
          break;

         case "PlainYearMonth":
          options = applyPlainFormatTimeZone(transformYearMonthOptions(internals.I, 1));
          break;

         case "PlainMonthDay":
          options = applyPlainFormatTimeZone(transformMonthDayOptions(internals.I, 1));
          break;

         default:
          throwTypeError(invalidFormatType(branding));
        }
        return new RawDateTimeFormat(internals.Ge, options);
      })(internals, branding));
      return {
        B(formattable) {
          if (void 0 === formattable) {
            return [ internals.t ];
          }
          const brandingAndSlots = getTemporalBrandingAndSlots(formattable);
          if (!brandingAndSlots) {
            return [ internals.t, Number(formattable) ];
          }
          const [branding, slots] = brandingAndSlots;
          const format = getTemporalFormat(branding);
          return checkTemporalDateTimeFormatCompatible(format, branding, slots), [ format, temporalDateTimeToEpochMilli(branding, slots) ];
        },
        A(start, end) {
          void 0 !== start && void 0 !== end || throwTypeError("Mismatching types for formatting");
          const startBrandingAndSlots = getTemporalBrandingAndSlots(start);
          const startEpochMilli = startBrandingAndSlots ? void 0 : Number(start);
          const endBrandingAndSlots = getTemporalBrandingAndSlots(end);
          const endEpochMilli = endBrandingAndSlots ? void 0 : Number(end);
          if (!startBrandingAndSlots && !endBrandingAndSlots) {
            return [ internals.t, startEpochMilli, endEpochMilli ];
          }
          startBrandingAndSlots && endBrandingAndSlots || throwTypeError("Mismatching types for formatting");
          const [startBranding, startSlots] = startBrandingAndSlots;
          const [endBranding, endSlots] = endBrandingAndSlots;
          startBranding !== endBranding && throwTypeError("Mismatching types for formatting");
          const format = getTemporalFormat(startBranding);
          return checkTemporalDateTimeFormatCompatible(format, startBranding, startSlots), 
          checkTemporalDateTimeFormatCompatible(format, startBranding, endSlots), [ format, temporalDateTimeToEpochMilli(startBranding, startSlots), temporalDateTimeToEpochMilli(startBranding, endSlots) ];
        }
      };
    });
  }
  function checkTemporalDateTimeFormatCompatible(format, branding, slots) {
    switch (branding) {
     case "Instant":
     case "PlainTime":
      return;

     case "PlainDateTime":
     case "PlainDate":
      return void checkResolvedCalendarCompatible(format, slots);

     case "PlainYearMonth":
     case "PlainMonthDay":
      return void checkResolvedCalendarCompatible(format, slots, 1);

     default:
      throwTypeError(invalidFormatType(branding));
    }
  }
  function temporalDateTimeToEpochMilli(branding, slots) {
    switch (branding) {
     case "Instant":
      return getEpochMilli(slots);

     case "PlainDateTime":
      return isoDateTimeToEpochMilli(slots);

     case "PlainDate":
     case "PlainYearMonth":
     case "PlainMonthDay":
      return isoDateToEpochMilli(slots);

     case "PlainTime":
      return timeFieldsToMilli(slots);

     default:
      throwTypeError(invalidFormatType(branding));
    }
  }
  function createGregoryAlignedCalendar(config) {
    function calendarYearToIsoYear(year) {
      return year - isoYearOffset;
    }
    function isoYearToCalendarYear(year) {
      return year + isoYearOffset;
    }
    const isoYearOffset = config.ve || 0;
    return {
      l: config.l,
      ge: 1972 + isoYearOffset,
      le: config.le,
      ie(isoDate) {
        return {
          ...isoDate,
          year: isoYearToCalendarYear(isoDate.year)
        };
      },
      je(year, month, day) {
        return computeIsoFieldsFromParts(calendarYearToIsoYear(year), month, day);
      },
      se(year, month, day) {
        return isoArgsToEpochDays(calendarYearToIsoYear(year), month, day) * milliInUtcDay;
      },
      O(_year, month) {
        return computeIsoMonthCodeParts(month);
      },
      v(monthCodeNumber, isLeapMonth) {
        const yearMonth = computeIsoYearMonthFieldsForMonthDay(monthCodeNumber, isLeapMonth);
        return yearMonth && {
          year: isoYearToCalendarYear(yearMonth.year),
          month: yearMonth.month
        };
      },
      u(year) {
        return computeIsoInLeapYear(calendarYearToIsoYear(year));
      },
      k() {
        return 12;
      },
      p(year, month) {
        return computeIsoDaysInMonth(calendarYearToIsoYear(year), month);
      },
      j(year) {
        return computeIsoDaysInYear(calendarYearToIsoYear(year));
      },
      q() {},
      h(isoDate) {
        return config.h?.(isoDate, isoYearToCalendarYear(isoDate.year)) || {};
      },
      N(year, month, monthDelta) {
        const yearMonth = addIsoMonths(calendarYearToIsoYear(year), month, monthDelta);
        return {
          year: isoYearToCalendarYear(yearMonth.year),
          month: yearMonth.month
        };
      },
      ne(year0, month0, year1, month1) {
        return diffIsoMonthSlots(calendarYearToIsoYear(year0), month0, calendarYearToIsoYear(year1), month1);
      }
    };
  }
  function createIntlScrapedCalendarData(normCalendarId) {
    function rawEpochMilliToIntlFields(epochMilli) {
      return {
        ...parseIntlYear(intlParts = formatEpochMilliToPartsRecord(intlFormat, epochMilli)),
        month: 0,
        Fe: intlParts.month,
        day: parseInt(intlParts.day)
      };
      var intlParts;
    }
    const intlFormat = (normCalendarId => new RawDateTimeFormat("en-u-hc-h23", {
      calendar: normCalendarId,
      timeZone: "UTC",
      era: "short",
      year: "numeric",
      month: "short",
      day: "numeric"
    }))(normCalendarId);
    const queryYearData = (epochMilliToIntlFields => {
      const yearCorrection = epochMilliToIntlFields(0).year - 1970;
      return memoize(year => {
        let epochMilli = isoArgsToEpochDays(year - yearCorrection) * milliInUtcDay;
        let intlFields;
        let iterations = 0;
        const millisReversed = [];
        const monthStringsReversed = [];
        do {
          epochMilli += 3456e7;
        } while ((intlFields = epochMilliToIntlFields(epochMilli)).year <= year);
        do {
          epochMilli += (1 - intlFields.day) * milliInUtcDay, intlFields.year === year && (millisReversed.push(epochMilli), 
          monthStringsReversed.push(intlFields.Fe)), epochMilli -= milliInUtcDay, (++iterations > 500 || epochMilli < -864e13) && throwRangeError();
        } while ((intlFields = epochMilliToIntlFields(epochMilli)).year >= year);
        return {
          $: millisReversed.reverse(),
          we: monthStringsReversed.reverse()
        };
      });
    })(rawEpochMilliToIntlFields);
    const queryFields = ((epochMilliToIntlFields, queryYearData) => memoize(isoDateFields => {
      const epochMilli = isoDateToEpochMilli(isoDateFields);
      const intlFields = epochMilliToIntlFields(epochMilli);
      return {
        ...intlFields,
        month: computeIntlMonthIndex(queryYearData, intlFields.year, epochMilli)
      };
    }, WeakMap))(rawEpochMilliToIntlFields, queryYearData);
    return {
      he: queryFields,
      K: queryYearData
    };
  }
  function parseIntlYear(intlParts) {
    return {
      era: void 0,
      eraYear: void 0,
      year: parseInt(intlParts.relatedYear || intlParts.year)
    };
  }
  function computeIsoFieldsFromIntlParts(intlData, year, month, day) {
    return ((epochMilli, microsecond = 0, nanosecond = 0) => {
      const [epochDays, milliAfterDay] = divModFloor(epochMilli, 864e5);
      return {
        ...epochDaysToIsoDate(epochDays),
        ...milliToTimeFields(milliAfterDay, microsecond, nanosecond)
      };
    })(computeIntlEpochMilli(intlData, year, month, day));
  }
  function computeIntlEpochMilli(intlData, year, month = 1, day = 1) {
    return intlData.K(year).$[month - 1] + (day - 1) * milliInUtcDay;
  }
  function computeIntlMonthCodeParts(intlData, leapMonthMeta, year, month) {
    const leapMonth = computeIntlLeapMonth(intlData, leapMonthMeta, year);
    return [ monthToMonthCodeNumber(month, leapMonth), leapMonth === month ];
  }
  function computeIntlLeapMonth(intlData, leapMonthMeta, year) {
    if (void 0 === leapMonthMeta) {
      return;
    }
    const currentMonthStrings = intlData.K(year).we;
    if (currentMonthStrings.length <= 12) {
      return;
    }
    if (leapMonthMeta < 0) {
      return -leapMonthMeta;
    }
    for (let i = 1; i < currentMonthStrings.length; i++) {
      if (currentMonthStrings[i] === currentMonthStrings[i - 1]) {
        return i + 1;
      }
    }
    for (let i = 0; i < currentMonthStrings.length; i++) {
      if (/bis$/i.test(currentMonthStrings[i])) {
        return i + 1;
      }
    }
    const prevMonthStrings = intlData.K(year - 1).we;
    for (let i = 0; i < currentMonthStrings.length; i++) {
      if (currentMonthStrings[i] !== prevMonthStrings[i]) {
        return i + 1;
      }
    }
  }
  function computeIntlInLeapYear(intlData, leapMonthMeta, year) {
    if (void 0 !== leapMonthMeta) {
      return computeIntlMonthsInYear(intlData, year) > 12;
    }
    const daysInYear = computeIntlDaysInYear(intlData, year);
    return daysInYear > computeIntlDaysInYear(intlData, year - 1) || daysInYear > computeIntlDaysInYear(intlData, year + 1);
  }
  function computeIntlDaysInYear(intlData, year) {
    return diffEpochMilliDays(computeIntlEpochMilli(intlData, year), computeIntlEpochMilli(intlData, year + 1));
  }
  function computeIntlDaysInMonth(intlData, year, month) {
    const {$: monthEpochMillis} = intlData.K(year);
    let nextMonth = month + 1;
    let nextMonthEpochMilli = monthEpochMillis;
    return nextMonth > monthEpochMillis.length && (nextMonth = 1, nextMonthEpochMilli = intlData.K(year + 1).$), 
    diffEpochMilliDays(monthEpochMillis[month - 1], nextMonthEpochMilli[nextMonth - 1]);
  }
  function computeIntlMonthsInYear(intlData, year) {
    return intlData.K(year).$.length;
  }
  function computeIntlEraFields(intlData, isoDate) {
    const intlFields = intlData.he(isoDate);
    return {
      era: intlFields.era,
      eraYear: intlFields.eraYear
    };
  }
  function computeIntlYearMonthFieldsForMonthDay(intlData, leapMonthMeta, getMonthDaySearchStartYear, monthCodeNumber, isLeapMonth, day) {
    const startIsoYear = getMonthDaySearchStartYear?.(monthCodeNumber, isLeapMonth, day) || 1972;
    const startCalendarDateFields = intlData.he({
      year: startIsoYear,
      month: 12,
      day: 31
    });
    let {year: startYear, month: startMonth, day: startDay} = startCalendarDateFields;
    const startYearLeapMonth = computeIntlLeapMonth(intlData, leapMonthMeta, startYear);
    const startMonthIsLeap = startMonth === startYearLeapMonth;
    1 === (compareNumbers(monthCodeNumber, monthToMonthCodeNumber(startMonth, startYearLeapMonth)) || compareNumbers(Number(isLeapMonth), Number(startMonthIsLeap)) || compareNumbers(day, startDay)) && startYear--;
    for (let yearMove = 0; yearMove < 100; yearMove++) {
      const tryYear = startYear - yearMove;
      const tryLeapMonth = computeIntlLeapMonth(intlData, leapMonthMeta, tryYear);
      const tryMonth = monthCodeNumberToMonth(monthCodeNumber, isLeapMonth, tryLeapMonth);
      if (isLeapMonth === (tryMonth === tryLeapMonth) && day <= computeIntlDaysInMonth(intlData, tryYear, tryMonth)) {
        return {
          year: tryYear,
          month: tryMonth
        };
      }
    }
  }
  function addIntlMonths(intlData, year, month, monthDelta) {
    if (monthDelta) {
      if (Number.isSafeInteger(month += monthDelta) || throwRangeError(outOfBoundsDate), 
      monthDelta < 0) {
        for (;month < 1; ) {
          month += computeIntlMonthsInYear(intlData, --year);
        }
      } else {
        let monthsInYear;
        for (;month > (monthsInYear = computeIntlMonthsInYear(intlData, year)); ) {
          month -= monthsInYear, year++;
        }
      }
    }
    return {
      year: year,
      month: month
    };
  }
  function diffIntlMonthSlots(intlData, year0, month0, year1, month1) {
    const cmp = compareNumbers(year0, year1) || compareNumbers(month0, month1);
    if (!cmp) {
      return 0;
    }
    if (year0 === year1) {
      return month1 - month0;
    }
    if (cmp < 0) {
      let months = computeIntlMonthsInYear(intlData, year0) - month0 + month1;
      for (let year = year0 + 1; year < year1; year++) {
        months += computeIntlMonthsInYear(intlData, year);
      }
      return months;
    }
    return -diffIntlMonthSlots(intlData, year1, month1, year0, month0);
  }
  function computeIntlMonthIndex(queryYearData, year, epochMilli) {
    const {$: monthEpochMillis} = queryYearData(year);
    for (let i = monthEpochMillis.length - 1; i >= 0; i--) {
      if (epochMilli >= monthEpochMillis[i]) {
        return i + 1;
      }
    }
    throwRangeError();
  }
  function createArithmeticCalendar(ops) {
    function computeDefaultMonthCodeParts(year, month) {
      const leapMonth = ops.q?.(year);
      return [ monthToMonthCodeNumber(month, leapMonth), month === leapMonth ];
    }
    const monthDayReferenceDate = ops.J(2441683);
    const fromIsoDate = memoize(isoDate => ops.J(isoDateToEpochDays(isoDate) + 2440588), WeakMap);
    return {
      l: ops.l,
      m: ops.m,
      Z: ops.Z,
      X: ops.X,
      ge: ops.ge,
      te: ops.te,
      ke: ops.ke,
      ie: fromIsoDate,
      je(year, month, day) {
        return epochDaysToIsoDate(ops.L(year, month, day) - 2440588);
      },
      se(year, month = 1, day = 1) {
        return (ops.L(year, month, day) - 2440588) * milliInUtcDay;
      },
      O(year, month) {
        return (ops.O || computeDefaultMonthCodeParts)(year, month);
      },
      v(monthCodeNumber, isLeapMonth, day) {
        return ops.v?.(monthCodeNumber, isLeapMonth, day) || ((monthCodeNumber, isLeapMonth, day) => {
          isLeapMonth = Boolean(isLeapMonth);
          let referenceYear = ops.ge || monthDayReferenceDate.year;
          const [referenceMonthCodeNumber, referenceIsLeapMonth] = computeDefaultMonthCodeParts(monthDayReferenceDate.year, monthDayReferenceDate.month);
          1 === (compareNumbers(monthCodeNumber, referenceMonthCodeNumber) || compareNumbers(Number(isLeapMonth), Number(referenceIsLeapMonth)) || compareNumbers(day, monthDayReferenceDate.day)) && referenceYear--;
          for (let yearDelta = 0; yearDelta < 100; yearDelta++) {
            for (const year of [ referenceYear - yearDelta, referenceYear + yearDelta ]) {
              const leapMonth = ops.q?.(year);
              const month = monthCodeNumberToMonth(monthCodeNumber, isLeapMonth, leapMonth);
              if (month <= ops.k(year) && isLeapMonth === (month === leapMonth) && day <= ops.p(year, month)) {
                return {
                  year: year,
                  month: month
                };
              }
            }
          }
        })(monthCodeNumber, isLeapMonth, day);
      },
      u: ops.u,
      k: ops.k,
      p: ops.p,
      j: ops.j,
      q: ops.q || noop,
      h(isoDate) {
        const parts = fromIsoDate(isoDate);
        return ops.h ? ops.h(parts) : {
          era: parts.era,
          eraYear: parts.eraYear
        };
      },
      N(year, month, monthDelta) {
        return ((computeMonthsInYear, year, month, monthDelta) => {
          if (monthDelta) {
            if (Number.isSafeInteger(month += monthDelta) || throwRangeError(outOfBoundsDate), 
            monthDelta < 0) {
              for (;month < 1; ) {
                month += computeMonthsInYear(--year);
              }
            } else {
              let monthsInYear;
              for (;month > (monthsInYear = computeMonthsInYear(year)); ) {
                month -= monthsInYear, year++;
              }
            }
          }
          return {
            year: year,
            month: month
          };
        })(ops.k, year, month, monthDelta);
      },
      ne(year0, month0, year1, month1) {
        return diffArithmeticMonthSlots(ops.k, year0, month0, year1, month1);
      }
    };
  }
  function diffArithmeticMonthSlots(computeMonthsInYear, year0, month0, year1, month1) {
    const cmp = compareNumbers(year0, year1) || compareNumbers(month0, month1);
    if (!cmp) {
      return 0;
    }
    if (year0 === year1) {
      return month1 - month0;
    }
    if (cmp < 0) {
      let months = computeMonthsInYear(year0) - month0 + month1;
      for (let year = year0 + 1; year < year1; year++) {
        months += computeMonthsInYear(year);
      }
      return months;
    }
    return -diffArithmeticMonthSlots(computeMonthsInYear, year1, month1, year0, month0);
  }
  function createChineseDangiCalendar(canonicalId) {
    return ((normCalendarId, config) => {
      const intlData = createIntlScrapedCalendarData(normCalendarId);
      return {
        m: config.m,
        Z: config.Z,
        X: config.X,
        ie: intlData.he,
        je: bindArgs(computeIsoFieldsFromIntlParts, intlData),
        se: bindArgs(computeIntlEpochMilli, intlData),
        O: bindArgs(computeIntlMonthCodeParts, intlData, config.m),
        v: bindArgs(computeIntlYearMonthFieldsForMonthDay, intlData, config.m, config.Ce),
        u: bindArgs(computeIntlInLeapYear, intlData, config.m),
        k: bindArgs(computeIntlMonthsInYear, intlData),
        p: bindArgs(computeIntlDaysInMonth, intlData),
        j: bindArgs(computeIntlDaysInYear, intlData),
        q: bindArgs(computeIntlLeapMonth, intlData, config.m),
        h: bindArgs(computeIntlEraFields, intlData),
        N: bindArgs(addIntlMonths, intlData),
        ne: bindArgs(diffIntlMonthSlots, intlData)
      };
    })(canonicalId, commonScrapedCalendarConfig);
  }
  function createCopticFamilyCalendar(epoch, eraOrigins, ameteAlemYearDelta = 0, hasAmeteMihretEra = 0) {
    return createArithmeticCalendar({
      l: eraOrigins,
      te(eraYear, normalizedEra, eraOrigin) {
        return "aa" === normalizedEra && hasAmeteMihretEra ? eraYear - 5500 : eraYearToYear(eraYear, eraOrigin);
      },
      ke(monthCodeNumber, isLeapMonth, day) {
        return constrainToRange(day, 1, isLeapMonth || 13 !== monthCodeNumber ? 30 : 6);
      },
      J(julianDay) {
        const [year, month, day] = ((epoch, julianDay) => {
          const year = Math.floor((4 * (julianDay - epoch) + 3) / 1461);
          const month = 1 + Math.floor((julianDay - copticFamilyToJulianDay(epoch, year, 1, 1)) / 30);
          return [ year, month, julianDay + 1 - copticFamilyToJulianDay(epoch, year, month, 1) ];
        })(epoch, julianDay);
        return {
          year: year + ameteAlemYearDelta,
          month: month,
          day: day
        };
      },
      L(year, month, day) {
        return copticFamilyToJulianDay(epoch, year - ameteAlemYearDelta, month, day);
      },
      p(year, month) {
        return ((year, month) => month % 13 != 0 ? 30 : copticFamilyLeapDay(year) + 5)(year - ameteAlemYearDelta, month);
      },
      j(year) {
        return 365 + copticFamilyLeapDay(year - ameteAlemYearDelta);
      },
      k() {
        return 13;
      },
      u(year) {
        return this.j(year) > 365;
      },
      h({year: year}) {
        return ameteAlemYearDelta ? {
          era: "aa",
          eraYear: year
        } : hasAmeteMihretEra && year <= 0 ? {
          era: "aa",
          eraYear: year + 5500
        } : {
          era: "am",
          eraYear: year
        };
      }
    });
  }
  function copticFamilyToJulianDay(epoch, year, month, day) {
    return epoch + 365 * year + Math.floor(year / 4) + 30 * (month - 1) + day - 1;
  }
  function copticFamilyLeapDay(year) {
    return Math.floor(modFloor(year, 4) / 3);
  }
  function hebrewIsLeapYear(year) {
    return modFloor(7 * year + 1, 19) < 7;
  }
  function hebrewDelay1(year) {
    const months = Math.floor((235 * year - 234) / 19);
    let day = 29 * months + Math.floor((12084 + 13753 * months) / 25920);
    return modFloor(3 * (day + 1), 7) < 3 && (day += 1), day;
  }
  function hebrewStartOfYear(year) {
    return hebrewDelay1(year) + (year => {
      const last = hebrewDelay1(year - 1);
      const present = hebrewDelay1(year);
      return hebrewDelay1(year + 1) - present === 356 ? 2 : present - last === 382 ? 1 : 0;
    })(year);
  }
  function hebrewDaysInYear(year) {
    return hebrewStartOfYear(year + 1) - hebrewStartOfYear(year);
  }
  function hebrewDaysInMonth(year, month) {
    const normalizedMonth = month >= 6 && !hebrewIsLeapYear(year) ? month + 1 : month;
    if (4 === normalizedMonth || 7 === normalizedMonth || 9 === normalizedMonth || 11 === normalizedMonth || 13 === normalizedMonth) {
      return 29;
    }
    const yearType = (year => {
      let yearLength = hebrewDaysInYear(year);
      return yearLength > 380 && (yearLength -= 30), 353 === yearLength ? 0 : 354 === yearLength ? 1 : 2;
    })(year);
    return 2 === normalizedMonth ? 2 === yearType ? 30 : 29 : 3 === normalizedMonth ? 0 === yearType ? 29 : 30 : 6 === normalizedMonth ? hebrewIsLeapYear(year) ? 30 : 0 : 30;
  }
  function createIslamicCalendar(fromJulianDay, toJulianDay, intlUmalquraData) {
    return createArithmeticCalendar({
      l: {
        bh: -1,
        ah: 0
      },
      J: fromJulianDay,
      L: toJulianDay,
      p(year, month) {
        return intlUmalquraData && isUmalquraYear(year) ? computeIntlDaysInMonth(intlUmalquraData, year, month) : ((year, month) => 29 + month % 2 + (12 === month && islamicIsLeapYear(year) ? 1 : 0))(year, month);
      },
      j(year) {
        return intlUmalquraData && isUmalquraYear(year) ? computeIntlDaysInYear(intlUmalquraData, year) : islamicIsLeapYear(year) ? 355 : 354;
      },
      k() {
        return 12;
      },
      u(year) {
        return this.j(year) > 354;
      },
      v(monthCodeNumber, isLeapMonth, day) {
        const umalquraReferenceYear = intlUmalquraData && !isLeapMonth && 30 === day && umalquraPlainMonthDay30ReferenceYears[monthCodeNumber - 1];
        return intlUmalquraData && umalquraReferenceYear ? {
          year: umalquraReferenceYear,
          month: monthCodeNumber
        } : void 0;
      },
      h({year: year}) {
        return year < 1 ? {
          era: "bh",
          eraYear: 1 - year
        } : {
          era: "ah",
          eraYear: year
        };
      }
    });
  }
  function islamicToJulianDay(epoch, year, month, day) {
    return day + Math.ceil(29.5 * (month - 1)) + 354 * (year - 1) + Math.floor((3 + 11 * year) / 30) + epoch - 1;
  }
  function julianDayToIslamic(epoch, julianDay) {
    const year = Math.floor((30 * (julianDay - epoch) + 10646) / 10631);
    const month = Math.min(12, Math.ceil((julianDay - (29 + islamicToJulianDay(epoch, year, 1, 1))) / 29.5) + 1);
    return {
      year: year,
      month: month,
      day: julianDay - islamicToJulianDay(epoch, year, month, 1) + 1
    };
  }
  function islamicIsLeapYear(year) {
    return modFloor(14 + 11 * year, 30) < 11;
  }
  function isUmalquraYear(year) {
    return year >= 1300 && year <= 1600;
  }
  function julianDayToUmalqura(intlUmalquraData, julianDay) {
    const days = julianDay - 1948440;
    if (days < 460322 || days >= 566987) {
      return julianDayToIslamic(1948440, julianDay);
    }
    const {year: year, month: month, day: day} = intlUmalquraData.he(epochDaysToIsoDate(julianDay - 2440588));
    return {
      year: year,
      month: month,
      day: day
    };
  }
  function umalquraToJulianDay(intlUmalquraData, year, month, day) {
    return isUmalquraYear(year) ? computeIntlEpochMilli(intlUmalquraData, year, month, day) / milliInUtcDay + 2440588 : islamicToJulianDay(1948440, year, month, day);
  }
  function computeJapaneseEraFields(isoDate) {
    const epochDays = isoDateToEpochDays(isoDate);
    const era = epochDays >= 18017 ? "reiwa" : epochDays >= 6947 ? "heisei" : epochDays >= -15713 ? "showa" : epochDays >= -20974 ? "taisho" : epochDays >= -35428 ? "meiji" : void 0;
    return era ? {
      era: era,
      eraYear: isoDate.year - japaneseEraOrigins[era]
    } : computeGregoryEraFields(isoDate);
  }
  function persianIsLeapYear(year) {
    return modFloor(25 * year + 11, 33) < 8;
  }
  function resolveAnyCalendarId(rawCalendarId) {
    const lowerRawCalendarId = requireString(rawCalendarId).toLowerCase();
    return "iso8601" === lowerRawCalendarId ? isoCalendarImpl : "gregory" === lowerRawCalendarId ? 0 : function(lowerRawCalendarId) {
      const meta = (lowerRawCalendarId => {
        forbiddenExoticCalendarIdMap[lowerRawCalendarId] && throwRangeError(invalidCalendar(lowerRawCalendarId));
        const normCalendarId = deprecatedExoticCalendarIdMap[lowerRawCalendarId] || lowerRawCalendarId;
        const createCalendar = exoticCreatorMap.get(normCalendarId);
        return createCalendar && [ normCalendarId, createCalendar ];
      })(lowerRawCalendarId);
      return meta || throwRangeError(invalidCalendar(lowerRawCalendarId)), getOrCreateExoticCalendar(...meta);
    }(lowerRawCalendarId);
  }
  function resolveAnyCalendarArg(rawCalendarId = "iso8601") {
    return resolveAnyCalendarId(rawCalendarId);
  }
  function createZonedDateTime(slots) {
    return initZonedDateTime(Object.create(ZonedDateTime.prototype), slots);
  }
  function getZonedDateTimeSlots(obj) {
    return getZonedDateTimeSlotsIfPresent(obj) || invalidRecordType();
  }
  function getZonedDateTimeIsoSlots(obj) {
    const slots = getZonedDateTimeSlots(obj);
    return {
      ...zonedEpochSlotsToIso(slots),
      calendar: slots.calendar
    };
  }
  function getZonedDateTimeSlotsIfPresent(obj) {
    return zonedDateTimeSlotsMap.get(obj);
  }
  function toZonedDateTimeSlots(arg, options) {
    if (isObjectLike(arg)) {
      const ownSlots = getZonedDateTimeSlotsIfPresent(arg);
      return ownSlots ? (refineZonedFieldOptions(options), ownSlots) : ((refineTimeZoneString, calendar, bag, options) => {
        const fields = readAndRefineBagFields(bag, getCalendarFieldNames(calendar, dateTimeAndZoneFieldNamesAlpha, dateTimeAndZoneFieldNamesWithEraAlpha), zonedDateTimeFieldRefiners, timeZoneFieldNames, 0);
        const timeZoneId = refineTimeZoneString(fields.timeZone);
        const [isoDateFields, overflow, offsetDisambig, epochDisambig] = createPlainDateFromFieldsWithOptionsRefiner(calendar, fields, () => refineZonedFieldOptions(options));
        const timeFields = resolveTimeFields(fields, overflow);
        const timeZone = queryTimeZone(timeZoneId);
        return createZonedEpochNanoSlots(getMatchingInstantFor(timeZone, combineDateAndTime(isoDateFields, timeFields), fields.offset, offsetDisambig, epochDisambig), timeZone, calendar);
      })(refineTimeZoneArg, getCalendarFromBag(arg), arg, options);
    }
    return ((s, resolveCalendar, options) => {
      const organized = parseDateTimeLike(requireString(s));
      return organized && organized.timeZoneId || throwFailedParse(s), finalizeZonedDateTime(organized, resolveCalendar, options);
    })(arg, resolveAnyCalendarId, options);
  }
  function initZonedDateTime(instance, slots) {
    return zonedDateTimeSlotsMap.set(instance, slots), attachDebugString(instance), 
    instance;
  }
  function refineTimeZoneArg(arg) {
    if (isObjectLike(arg)) {
      const slots = getZonedDateTimeSlotsIfPresent(arg);
      return slots || throwTypeError(invalidTimeZone(arg)), slots.timeZone.id;
    }
    return (arg => resolveTimeZoneId((s => {
      const parsed = parseDateTimeLike(s);
      return parsed && (parsed.timeZoneId || parsed.F && "UTC" || parsed.offset) || s;
    })(requireString(arg))))(arg);
  }
  function createInstant(slots) {
    return initInstant(Object.create(Instant.prototype), slots);
  }
  function getInstantSlots(obj) {
    return getInstantSlotsIfPresent(obj) || invalidRecordType();
  }
  function getInstantSlotsIfPresent(obj) {
    return instantSlotsMap.get(obj);
  }
  function toInstantSlots(arg) {
    if (isObjectLike(arg)) {
      const ownSlots = getInstantSlotsIfPresent(arg);
      if (ownSlots) {
        return ownSlots;
      }
      const zonedDateTimeSlots = getZonedDateTimeSlotsIfPresent(arg);
      if (zonedDateTimeSlots) {
        return createEpochNanoSlots(zonedDateTimeSlots.epochNanoseconds);
      }
    }
    return (s => {
      const organized = parseDateTimeLike(s = toStringViaPrimitive(s));
      let offsetNano;
      return organized || throwFailedParse(s), organized.F ? offsetNano = 0 : organized.offset ? offsetNano = parseOffsetNano(organized.offset) : throwFailedParse(s), 
      organized.timeZoneId && parseOffsetNanoMaybe(organized.timeZoneId, 1), validateIsoDateTimeFields(organized), 
      createEpochNanoSlots(isoDateTimeAndOffsetToEpochNano(organized, offsetNano));
    })(arg);
  }
  function initInstant(instance, slots) {
    return instantSlotsMap.set(instance, slots), attachDebugString(instance), instance;
  }
  function createPlainMonthDay(slots) {
    return initPlainMonthDay(Object.create(PlainMonthDay.prototype), slots);
  }
  function getPlainMonthDaySlots(obj) {
    return getPlainMonthDaySlotsIfPresent(obj) || invalidRecordType();
  }
  function getPlainMonthDaySlotsIfPresent(obj) {
    return plainMonthDaySlotsMap.get(obj);
  }
  function toPlainMonthDaySlots(arg, options) {
    if (isObjectLike(arg)) {
      const ownSlots = getPlainMonthDaySlotsIfPresent(arg);
      if (ownSlots) {
        return refineOverflowOptions(options), ownSlots;
      }
      const calendarMaybe = extractCalendarFromBag(arg);
      return ((calendar, calendarAbsent, bag, options) => {
        const fields = readAndRefineBagFields(bag, getCalendarFieldNames(calendar, dateFieldNamesAlpha, dateFieldNamesWithEraAlpha), dateFieldRefiners, dayFieldNamesAsc, 0);
        return calendarAbsent && void 0 !== fields.month && void 0 === fields.monthCode && void 0 === fields.year && (fields.year = 1972), 
        createPlainMonthDayFromFields(calendar, fields, options);
      })(void 0 === calendarMaybe ? isoCalendarImpl : calendarMaybe, void 0 === calendarMaybe, arg, options);
    }
    const res = ((s, resolveCalendar) => {
      const organized = parseMonthDayOnly(requireString(s));
      if (organized) {
        return requireIsoCalendar(organized), createDateSlots(validateIsoDateFields(organized), resolveCalendar(organized.calendarId));
      }
      const dateSlots = finalizeDateLike(parsePlainDateLike(s), projectIsoMonthDayDate, resolveCalendar);
      const {calendar: calendar} = dateSlots;
      const {year: origYear, month: origMonth, day: day} = computeCalendarDateFields(calendar, dateSlots);
      const [monthCodeNumber, isLeapMonth] = computeCalendarMonthCodeParts(calendar, origYear, origMonth);
      const {year: year, month: month} = ((calendar, monthCodeNumber, isLeapMonth, day) => {
        const yearMonthFields = calendar ? calendar.v(monthCodeNumber, isLeapMonth, day) : computeIsoYearMonthFieldsForMonthDay(monthCodeNumber, isLeapMonth);
        return yearMonthFields || throwRangeError("Cannot guess year"), yearMonthFields;
      })(calendar, monthCodeNumber, isLeapMonth, day);
      return createDateSlots(checkIsoDateInBounds(computeCalendarIsoFieldsFromParts(calendar, year, month, day)), calendar);
    })(arg, resolveAnyCalendarId);
    return refineOverflowOptions(options), res;
  }
  function initPlainMonthDay(instance, slots) {
    return plainMonthDaySlotsMap.set(instance, slots), attachDebugString(instance), 
    instance;
  }
  function createPlainYearMonth(slots) {
    return initPlainYearMonth(Object.create(PlainYearMonth.prototype), slots);
  }
  function getPlainYearMonthSlots(obj) {
    return getPlainYearMonthSlotsIfPresent(obj) || invalidRecordType();
  }
  function getPlainYearMonthSlotsIfPresent(obj) {
    return plainYearMonthSlotsMap.get(obj);
  }
  function toPlainYearMonthSlots(arg, options) {
    if (isObjectLike(arg)) {
      const ownSlots = getPlainYearMonthSlotsIfPresent(arg);
      return ownSlots ? (refineOverflowOptions(options), ownSlots) : ((calendar, bag, options) => createPlainYearMonthFromFields(calendar, readAndRefineBagFields(bag, getCalendarFieldNames(calendar, yearMonthFieldNamesAlpha, yearMonthFieldNamesWithEraAlpha), dateFieldRefiners, void 0), options))(getCalendarFromBag(arg), arg, options);
    }
    const res = ((s, resolveCalendar) => {
      const organized = parseYearMonthOnly(requireString(s));
      if (organized) {
        return requireIsoCalendar(organized), createDateSlots(checkIsoYearMonthInBounds(validateIsoDateFields(organized)), resolveCalendar(organized.calendarId));
      }
      const dateSlots = finalizeDateLike(parsePlainDateLike(s), projectIsoYearMonthDate, resolveCalendar);
      const {calendar: calendar} = dateSlots;
      return createDateSlots(moveToStartOfMonth(calendar, dateSlots), calendar);
    })(arg, resolveAnyCalendarId);
    return refineOverflowOptions(options), res;
  }
  function initPlainYearMonth(instance, slots) {
    return plainYearMonthSlotsMap.set(instance, slots), attachDebugString(instance), 
    instance;
  }
  function getTemporalBrandingAndSlots(obj) {
    if (!isObjectLike(obj)) {
      return;
    }
    let slots = getInstantSlotsIfPresent(obj);
    return slots ? [ "Instant", slots ] : (slots = getZonedDateTimeSlotsIfPresent(obj), 
    slots ? [ "ZonedDateTime", slots ] : (slots = getPlainDateTimeSlotsIfPresent(obj), 
    slots ? [ "PlainDateTime", slots ] : (slots = getPlainDateSlotsIfPresent(obj), slots ? [ "PlainDate", slots ] : (slots = getPlainTimeSlotsIfPresent(obj), 
    slots ? [ "PlainTime", slots ] : (slots = getPlainYearMonthSlotsIfPresent(obj), 
    slots ? [ "PlainYearMonth", slots ] : (slots = getPlainMonthDaySlotsIfPresent(obj), 
    slots ? [ "PlainMonthDay", slots ] : (slots = getDurationSlotsIfPresent(obj), slots ? [ "Duration", slots ] : void 0)))))));
  }
  function validateBag(bag) {
    return (getTemporalBrandingAndSlots(bag) || void 0 !== bag.calendar || void 0 !== bag.timeZone) && throwTypeError("Invalid bag"), 
    bag;
  }
  function createPlainTime(slots) {
    return initPlainTime(Object.create(PlainTime.prototype), slots);
  }
  function getPlainTimeSlots(obj) {
    return getPlainTimeSlotsIfPresent(obj) || invalidRecordType();
  }
  function getPlainTimeSlotsIfPresent(obj) {
    return plainTimeSlotsMap.get(obj);
  }
  function toPlainTimeSlots(arg, options) {
    if (isObjectLike(arg)) {
      const ownSlots = getPlainTimeSlotsIfPresent(arg);
      if (ownSlots) {
        return refineOverflowOptions(options), ownSlots;
      }
      const dateTimeSlots = getPlainDateTimeSlotsIfPresent(arg);
      if (dateTimeSlots) {
        return refineOverflowOptions(options), createTimeSlots(dateTimeSlots);
      }
      const zonedDateTimeSlots = getZonedDateTimeSlotsIfPresent(arg);
      return zonedDateTimeSlots ? (refineOverflowOptions(options), zonedDateTimeToPlainTime(zonedDateTimeSlots)) : ((bag, options) => resolveTimeFields(readAndRefineBagFields(bag, timeFieldNamesAlpha, timeFieldRefiners, [], 1), refineOverflowOptions(options)))(arg, options);
    }
    const timeSlots = (s => {
      let organized = (s => {
        const parts = parseTimeOnlyParts(s);
        return parts ? (organizeAnnotationParts(parts[13]), organizeTimeParts(parts, 1)) : void 0;
      })(s = requireString(s));
      let altParsed;
      return organized || (organized = parseDateTimeLike(s), organized ? (organized.fe || throwFailedParse(s), 
      organized.F && throwRangeError(invalidSubstring("Z")), requireIsoCalendar(organized)) : throwFailedParse(s)), 
      (altParsed = parseYearMonthOnly(s)) && isIsoDateFieldsValid(altParsed) && throwFailedParse(s), 
      (altParsed = parseMonthDayOnly(s)) && isIsoDateFieldsValid(altParsed) && throwFailedParse(s), 
      createTimeSlots(validateTimeFields(organized));
    })(arg);
    return refineOverflowOptions(options), timeSlots;
  }
  function optionalToPlainTimeFields(timeArg) {
    return void 0 === timeArg ? void 0 : toPlainTimeSlots(timeArg);
  }
  function initPlainTime(instance, slots) {
    return plainTimeSlotsMap.set(instance, slots), attachDebugString(instance), instance;
  }
  function createPlainDateTime(slots) {
    return initPlainDateTime(Object.create(PlainDateTime.prototype), slots);
  }
  function getPlainDateTimeSlots(obj) {
    return getPlainDateTimeSlotsIfPresent(obj) || invalidRecordType();
  }
  function getPlainDateTimeSlotsIfPresent(obj) {
    return plainDateTimeSlotsMap.get(obj);
  }
  function toPlainDateTimeSlots(arg, options) {
    if (isObjectLike(arg)) {
      const ownSlots = getPlainDateTimeSlotsIfPresent(arg);
      if (ownSlots) {
        return refineOverflowOptions(options), ownSlots;
      }
      const dateSlots = getPlainDateSlotsIfPresent(arg);
      if (dateSlots) {
        return refineOverflowOptions(options), createDateTimeSlots(combineDateAndTime(dateSlots, timeFieldDefaults), dateSlots.calendar);
      }
      const zonedDateTimeSlots = getZonedDateTimeSlotsIfPresent(arg);
      return zonedDateTimeSlots ? (refineOverflowOptions(options), zonedDateTimeToPlainDateTime(zonedDateTimeSlots)) : ((calendar, bag, options) => {
        const fields = readAndRefineBagFields(bag, getCalendarFieldNames(calendar, dateTimeFieldNamesAlpha, dateTimeFieldNamesWithEraAlpha), dateTimeFieldRefiners, [], 0);
        const [isoDateInternals, overflow] = createPlainDateFromFieldsWithOptionsRefiner(calendar, fields, () => [ refineOverflowOptions(options) ]);
        return createPlainDateTimeFromRefinedFields(isoDateInternals, resolveTimeFields(fields, overflow), calendar);
      })(getCalendarFromBag(arg), arg, options);
    }
    const res = ((s, resolveCalendar) => {
      const organized = parseDateTimeLike(requireString(s));
      return organized && !organized.F || throwFailedParse(s), finalizeDateTime(organized, resolveCalendar);
    })(arg, resolveAnyCalendarId);
    return refineOverflowOptions(options), res;
  }
  function initPlainDateTime(instance, slots) {
    return plainDateTimeSlotsMap.set(instance, slots), attachDebugString(instance), 
    instance;
  }
  function createPlainDate(slots) {
    return initPlainDate(Object.create(PlainDate.prototype), slots);
  }
  function getPlainDateSlots(obj) {
    return getPlainDateSlotsIfPresent(obj) || invalidRecordType();
  }
  function getPlainDateSlotsIfPresent(obj) {
    return plainDateSlotsMap.get(obj);
  }
  function toPlainDateSlots(arg, options) {
    if (isObjectLike(arg)) {
      const ownSlots = getPlainDateSlotsIfPresent(arg);
      if (ownSlots) {
        return refineOverflowOptions(options), ownSlots;
      }
      const dateTimeSlots = getPlainDateTimeSlotsIfPresent(arg);
      if (dateTimeSlots) {
        return refineOverflowOptions(options), createDateSlots(dateTimeSlots, dateTimeSlots.calendar);
      }
      const zonedDateTimeSlots = getZonedDateTimeSlotsIfPresent(arg);
      return zonedDateTimeSlots ? (refineOverflowOptions(options), zonedDateTimeToPlainDate(zonedDateTimeSlots)) : ((calendar, bag, options, requireFields = []) => createPlainDateFromFields(calendar, readAndRefineBagFields(bag, getCalendarFieldNames(calendar, dateFieldNamesAlpha, dateFieldNamesWithEraAlpha), dateFieldRefiners, requireFields), options))(getCalendarFromBag(arg), arg, options);
    }
    const res = ((s, resolveCalendar) => {
      const slots = finalizeDateLike(parsePlainDateLike(requireString(s)), void 0, resolveCalendar);
      return createDateSlots(slots, slots.calendar);
    })(arg, resolveAnyCalendarId);
    return refineOverflowOptions(options), res;
  }
  function initPlainDate(instance, slots) {
    return plainDateSlotsMap.set(instance, slots), attachDebugString(instance), instance;
  }
  function getCalendarFromBag(bag) {
    const calendar = extractCalendarFromBag(bag);
    return void 0 === calendar ? isoCalendarImpl : calendar;
  }
  function extractCalendarFromBag(bag) {
    const {calendar: calendarArg} = bag;
    if (void 0 !== calendarArg) {
      return refineCalendarArg(calendarArg);
    }
  }
  function refineCalendarArg(arg) {
    if (isObjectLike(arg)) {
      const slots = getPlainDateSlotsIfPresent(arg) || getPlainDateTimeSlotsIfPresent(arg) || getZonedDateTimeSlotsIfPresent(arg) || getPlainMonthDaySlotsIfPresent(arg) || getPlainYearMonthSlotsIfPresent(arg);
      return slots || throwTypeError(invalidCalendar(arg)), slots.calendar;
    }
    return (arg => resolveAnyCalendarId((s => {
      const res = parseDateTimeLike(s) || parseYearMonthOnly(s) || parseMonthDayOnly(s);
      if (res) {
        return res.calendarId;
      }
      const timeParts = parseTimeOnlyParts(s);
      return timeParts ? organizeAnnotationParts(timeParts[13]).calendarId : s;
    })(requireString(arg))))(arg);
  }
  function createDuration(slots) {
    return initDuration(Object.create(Duration.prototype), slots);
  }
  function getDurationSlots(obj) {
    return getDurationSlotsIfPresent(obj) || invalidRecordType();
  }
  function getDurationSlotsIfPresent(obj) {
    return durationSlotsMap.get(obj);
  }
  function toDurationSlots(arg) {
    return isObjectLike(arg) ? getDurationSlotsIfPresent(arg) || (bag => {
      const durationFields = readAndRefineBagFields(bag, durationFieldNamesAlpha, durationFieldRefiners);
      return createDurationSlots(validateDurationFields({
        ...durationFieldDefaults,
        ...durationFields
      }));
    })(arg) : (s => {
      const parsed = (s => {
        const parts = durationRegExp.exec(s);
        return parts ? (parts => {
          function parseUnit(wholeStr, fracStr, timeUnit) {
            let leftoverUnits = 0;
            let wholeUnits = 0;
            return timeUnit && ([leftoverUnits, leftoverNano] = divModFloor(leftoverNano, unitNanoMap[timeUnit])), 
            void 0 !== wholeStr && (hasAnyFrac && throwRangeError(invalidSubstring(wholeStr)), 
            wholeUnits = (s => {
              const n = parseInt(s);
              return Number.isFinite(n) || throwRangeError(invalidSubstring(s)), n;
            })(wholeStr), hasAny = 1, fracStr && (leftoverNano = parseSubsecNano(fracStr) * (unitNanoMap[timeUnit] / nanoInSec), 
            hasAnyFrac = 1)), leftoverUnits + wholeUnits;
          }
          let hasAny = 0;
          let hasAnyFrac = 0;
          let leftoverNano = 0;
          let durationFields = {
            years: parseUnit(parts[2]),
            months: parseUnit(parts[3]),
            weeks: parseUnit(parts[4]),
            days: parseUnit(parts[5]),
            hours: parseUnit(parts[6], parts[7], 5),
            minutes: parseUnit(parts[8], parts[9], 4),
            seconds: parseUnit(parts[10], parts[11], 3),
            ...nanoToGivenFields(leftoverNano, 2, durationFieldNamesAsc)
          };
          return hasAny || throwRangeError(noValidFields(durationFieldNamesAsc)), parseSign(parts[1]) < 0 && (durationFields = negateDurationFields(durationFields)), 
          durationFields;
        })(parts) : void 0;
      })(requireString(s));
      return parsed || throwFailedParse(s), createDurationSlots(validateDurationFields(parsed));
    })(arg);
  }
  function refinePublicRelativeTo(relativeTo) {
    if (void 0 !== relativeTo) {
      if (isObjectLike(relativeTo)) {
        const zonedDateTimeSlots = getZonedDateTimeSlotsIfPresent(relativeTo);
        if (zonedDateTimeSlots) {
          return zonedDateTimeSlots;
        }
        const dateSlots = getPlainDateSlotsIfPresent(relativeTo);
        if (dateSlots) {
          return dateSlots;
        }
        const dateTimeSlots = getPlainDateTimeSlotsIfPresent(relativeTo);
        return dateTimeSlots ? createDateSlots(dateTimeSlots, dateTimeSlots.calendar) : ((refineTimeZoneString, calendar, bag) => {
          const fields = readAndRefineBagFields(bag, getCalendarFieldNames(calendar, dateTimeAndZoneFieldNamesAlpha, dateTimeAndZoneFieldNamesWithEraAlpha), zonedDateTimeFieldRefiners, [], 0);
          if (void 0 !== fields.timeZone) {
            const isoDateFields = createPlainDateFromFields(calendar, fields);
            const timeFields = resolveTimeFields(fields);
            const timeZone = queryTimeZone(refineTimeZoneString(fields.timeZone));
            return {
              epochNanoseconds: getMatchingInstantFor(timeZone, combineDateAndTime(isoDateFields, timeFields), fields.offset),
              timeZone: timeZone,
              calendar: calendar
            };
          }
          return createPlainDateFromFields(calendar, fields);
        })(refineTimeZoneArg, getCalendarFromBag(relativeTo), relativeTo);
      }
      return ((s, resolveCalendar) => {
        const organized = parseDateTimeLike(requireString(s));
        return organized || throwFailedParse(s), organized.timeZoneId ? finalizeZonedDateTime(organized, resolveCalendar, void 0) : (organized.F && throwFailedParse(s), 
        finalizeDate(organized, resolveCalendar));
      })(relativeTo, resolveAnyCalendarId);
    }
  }
  function initDuration(instance, slots) {
    return durationSlotsMap.set(instance, slots), attachDebugString(instance), instance;
  }
  const numberOutOfRange = (entityName, val, min, max) => invalidEntity$1(entityName, val) + `; must be between ${min}-${max}`;
  const invalidEntity$1 = (fieldName, val) => `Invalid ${fieldName}: ${val}`;
  const invalidEntity = invalidEntity$1;
  const missingField = fieldName => `Missing ${fieldName}`;
  const noValidFields = validFields => "No valid fields: " + validFields.join();
  const invalidChoice = (fieldName, val, choiceMap) => invalidEntity$1(fieldName, val) + "; must be " + Object.keys(choiceMap).join();
  const missingYear = allowEra => "Missing year" + (allowEra ? "/era/eraYear" : "");
  const invalidLeapMonth = "Invalid leap month";
  const invalidCalendar = calendarId => invalidEntity$1("Calendar", calendarId);
  const invalidTimeZone = calendarId => invalidEntity$1("TimeZone", calendarId);
  const outOfBoundsDate = "Out-of-bounds date";
  const failedParse = s => `Cannot parse: ${s}`;
  const invalidSubstring = substring => `Invalid substring: ${substring}`;
  const invalidFormatType = branding => `Cannot format ${branding}`;
  const constrainToRange = (num, min, max) => Math.min(Math.max(num, min), max);
  const isObjectLike = isObjectLike$1;
  const createPropDescriptors = (propVals, readonly) => mapProps(value => ({
    value: value,
    configurable: 1,
    writable: !readonly
  }), propVals);
  const createStringTagDescriptors = value => ({
    [Symbol.toStringTag]: {
      value: value,
      configurable: 1
    }
  });
  const padNumber2 = bindArgs(padNumber, 2);
  const gregoryEraOrigins = {
    bce: -1,
    ce: 0
  };
  const isoCalendarImpl = void 0;
  const monthCodeRegExp = /^M(\d{2})(L?)$/;
  const unitNameMap = {
    nanosecond: 0,
    microsecond: 1,
    millisecond: 2,
    second: 3,
    minute: 4,
    hour: 5,
    day: 6,
    week: 7,
    month: 8,
    year: 9
  };
  const unitNamesAsc = Object.keys(unitNameMap);
  const milliInUtcDay = 864e5;
  const nanoInMilli = 1e6;
  const nanoInSec = 1e9;
  const nanoInMinute = 6e10;
  const nanoInHour = 36e11;
  const nanoInUtcDay = 864e11;
  const unitNanoMap = [ 1, 1e3, 1e6, nanoInSec, 6e10, nanoInHour, nanoInUtcDay ];
  const bigNanoInMicro = BigInt(1e3);
  const bigNanoInMilli = BigInt(1e6);
  const bigNanoInSec = BigInt(nanoInSec);
  const bigNanoInMinute = BigInt(6e10);
  const bigNanoInHour = BigInt(nanoInHour);
  const bigNanoInUtcDay = BigInt(nanoInUtcDay);
  const timeFieldNamesAsc = unitNamesAsc.slice(0, 6);
  const timeGetters = createPropGetters(timeFieldNamesAsc);
  const yearFieldNamesAsc = [ "year" ];
  const dayFieldNamesAsc = [ "day" ];
  const calendarDateFieldNamesAsc = [ "day", "month", "year" ];
  const offsetFieldNames = [ "offset" ];
  const timeZoneFieldNames = [ "timeZone" ];
  const eraYearFieldNames = [ "era", "eraYear" ];
  const allYearFieldNames = [ "era", "eraYear", "year" ];
  const monthFieldNames = [ "month", "monthCode" ];
  const monthDayFieldNames = [ "day", "month", "monthCode" ];
  const timeFieldNamesAlpha = sortStrings(timeFieldNamesAsc);
  const yearFieldNamesWithEraAlpha = sortStrings(eraYearFieldNames, yearFieldNamesAsc);
  const yearMonthFieldNamesAlpha = sortStrings(monthFieldNames, yearFieldNamesAsc);
  const yearMonthFieldNamesWithEraAlpha = sortStrings(eraYearFieldNames, yearMonthFieldNamesAlpha);
  const yearMonthCodeFieldNamesAlpha = sortStrings([ "monthCode" ], yearFieldNamesAsc);
  const yearMonthCodeFieldNamesWithEraAlpha = sortStrings(eraYearFieldNames, yearMonthCodeFieldNamesAlpha);
  const monthCodeDayFieldNamesAlpha = sortStrings(dayFieldNamesAsc, [ "monthCode" ]);
  const dateFieldNamesAlpha = sortStrings(dayFieldNamesAsc, yearMonthFieldNamesAlpha);
  const dateFieldNamesWithEraAlpha = sortStrings(dayFieldNamesAsc, eraYearFieldNames, yearMonthFieldNamesAlpha);
  const dateTimeFieldNamesAlpha = sortStrings(dateFieldNamesAlpha, timeFieldNamesAsc);
  const dateTimeFieldNamesWithEraAlpha = sortStrings(dateFieldNamesWithEraAlpha, timeFieldNamesAsc);
  const dateTimeAndOffsetFieldNamesAlpha = sortStrings(dateFieldNamesAlpha, timeFieldNamesAsc, offsetFieldNames);
  const dateTimeAndOffsetFieldNamesWithEraAlpha = sortStrings(dateFieldNamesWithEraAlpha, timeFieldNamesAsc, offsetFieldNames);
  const dateTimeAndZoneFieldNamesAlpha = sortStrings(dateFieldNamesAlpha, timeFieldNamesAsc, offsetFieldNames, timeZoneFieldNames);
  const dateTimeAndZoneFieldNamesWithEraAlpha = sortStrings(dateFieldNamesWithEraAlpha, timeFieldNamesAsc, offsetFieldNames, timeZoneFieldNames);
  const yearMonthCodeDayFieldNamesAlpha = sortStrings(dayFieldNamesAsc, yearMonthCodeFieldNamesAlpha);
  const yearMonthCodeDayFieldNamesWithEraAlpha = sortStrings(dayFieldNamesAsc, eraYearFieldNames, yearMonthCodeFieldNamesAlpha);
  const timeFieldDefaults = zipPropsConst(timeFieldNamesAsc, 0);
  const maxValues = {
    hour: 23,
    minute: 59,
    second: 59
  };
  const durationFieldNamesAsc = unitNamesAsc.map(unitName => unitName + "s");
  const durationGetters = createPropGetters(durationFieldNamesAsc);
  const durationFieldNamesAlpha = sortStrings(durationFieldNamesAsc);
  const durationTimeFieldNamesAsc = durationFieldNamesAsc.slice(0, 6);
  const durationDateFieldNamesAsc = durationFieldNamesAsc.slice(6);
  const durationCalendarFieldNamesAsc = durationDateFieldNamesAsc.slice(1);
  const durationFieldIndexes = durationFieldNamesAsc.reduce((indexes, fieldName, i) => (indexes[fieldName] = i, 
  indexes), {});
  const durationFieldDefaults = zipPropsConst(durationFieldNamesAsc, 0);
  const durationTimeFieldDefaults = zipPropsConst(durationTimeFieldNamesAsc, 0);
  const clearDurationFields = bindArgs(zeroOutProps, durationFieldNamesAsc);
  const requireString = bindArgs(requireType, "string");
  const smallestUnitStr = "smallestUnit";
  const overflowMap = {
    constrain: 0,
    reject: 1
  };
  const epochDisambigMap = {
    compatible: 0,
    reject: 1,
    earlier: 2,
    later: 3
  };
  const offsetDisambigMap = {
    reject: 0,
    use: 1,
    prefer: 2,
    ignore: 3
  };
  const calendarDisplayMap = {
    auto: 0,
    never: 1,
    critical: 2,
    always: 3
  };
  const timeZoneDisplayMap = {
    auto: 0,
    never: 1,
    critical: 2
  };
  const offsetDisplayMap = {
    auto: 0,
    never: 1
  };
  const roundingModeMap = {
    floor: 0,
    halfFloor: 1,
    ceil: 2,
    halfCeil: 3,
    trunc: 4,
    halfTrunc: 5,
    expand: 6,
    halfExpand: 7,
    halfEven: 8
  };
  const roundingModeFuncs = [ Math.floor, num => hasHalf(num) ? Math.floor(num) : Math.round(num), Math.ceil, num => hasHalf(num) ? Math.ceil(num) : Math.round(num), Math.trunc, num => hasHalf(num) ? Math.trunc(num) || 0 : Math.round(num), num => num < 0 ? Math.floor(num) : Math.ceil(num), num => Math.sign(num) * Math.round(Math.abs(num)) || 0, num => hasHalf(num) ? (num = Math.trunc(num) || 0) + num % 2 : Math.round(num) ];
  const directionMap = {
    previous: -1,
    next: 1
  };
  const coerceSmallestUnit = bindArgs(coerceUnitOption, smallestUnitStr);
  const coerceLargestUnit = bindArgs(coerceUnitOption, "largestUnit");
  const coerceTotalUnit = bindArgs(coerceUnitOption, "unit");
  const coerceOverflow = bindArgs(coerceChoiceOption, "overflow", overflowMap);
  const coerceEpochDisambig = bindArgs(coerceChoiceOption, "disambiguation", epochDisambigMap);
  const coerceOffsetDisambig = bindArgs(coerceChoiceOption, "offset", offsetDisambigMap);
  const coerceCalendarDisplay = bindArgs(coerceChoiceOption, "calendarName", calendarDisplayMap);
  const coerceTimeZoneDisplay = bindArgs(coerceChoiceOption, "timeZoneName", timeZoneDisplayMap);
  const coerceOffsetDisplay = bindArgs(coerceChoiceOption, "offset", offsetDisplayMap);
  const coerceRoundingMode = bindArgs(coerceChoiceOption, "roundingMode", roundingModeMap);
  const coerceDirection = bindArgs(coerceChoiceOption, "direction", directionMap);
  const epochNanoMax = BigInt(1e8) * bigNanoInUtcDay;
  const epochNanoMin = BigInt(-1e8) * bigNanoInUtcDay;
  const plainDateEpochNanoMin = epochNanoMin - bigNanoInUtcDay;
  const isoYearMonthIndexMin = -3261848;
  const zonedEpochSlotsToIso = memoize(_zonedEpochSlotsToIso, WeakMap);
  const maxDurationSeconds = 2 ** 53;
  const offsetRegExp = createRegExp("([+-])(\\d{2})(?::?(\\d{2})(?::?(\\d{2})(?:[.,](\\d{1,9}))?)?)?");
  const dateFieldRefiners = {
    era: toStringViaPrimitive,
    month: toPositiveIntegerWithTruncation,
    monthCode(monthCode, entityName = "monthCode") {
      return ((monthCode, entityName) => {
        if ("string" == typeof monthCode) {
          return monthCode;
        }
        if (monthCode && "object" == typeof monthCode) {
          const monthCodeToString = monthCode.toString;
          if ("function" == typeof monthCodeToString) {
            return requireString(monthCodeToString.call(monthCode), entityName);
          }
        }
        return requireString(monthCode, entityName);
      })(monthCode, entityName);
    },
    day: toPositiveIntegerWithTruncation
  };
  const timeFieldRefiners = zipPropsConst(timeFieldNamesAsc, toIntegerWithTrunc);
  const durationFieldRefiners = zipPropsConst(durationFieldNamesAsc, toStrictInteger);
  const offsetFieldRefiners = {
    offset(offsetString) {
      return parseOffsetNano(toStringViaPrimitive(offsetString));
    }
  };
  const dateTimeFieldRefiners = Object.assign({}, dateFieldRefiners, timeFieldRefiners);
  const zonedDateTimeFieldRefiners = Object.assign({}, dateTimeFieldRefiners, offsetFieldRefiners);
  const RawDateTimeFormat = Intl.DateTimeFormat;
  const timeZonePeriodDaysByName = {
    El_Aaiun: 17,
    Tucuman: 12,
    Tirane: 11,
    Riga: 10,
    Simferopol: 9,
    Vienna: 9,
    Tunis: 8,
    Boa_Vista: 6,
    Fortaleza: 6,
    Maceio: 6,
    Noronha: 6,
    Recife: 6,
    Gaza: 6,
    Hebron: 6,
    DeNoronha: 6
  };
  const minPossibleTransitionSec = -388152e4;
  const trailingZerosRE = /0+$/;
  const icuRegExp = /^(AC|AE|AG|AR|AS|BE|BS|CA|CN|CS|CT|EA|EC|IE|IS|JS|MI|NE|NS|PL|PN|PR|PS|SS|VS)T$/;
  const badCharactersRegExp = /[^\w\/:+-]+/;
  const queryNamedTimeZoneRecord = memoize(normId => {
    if ("UTC" === normId) {
      return {
        kind: "utc",
        id: normId,
        o: normId
      };
    }
    const upperNormId = normId.toUpperCase();
    const format = queryTimeZoneIntlFormat(upperNormId);
    return {
      kind: "named",
      id: normId,
      format: format,
      o: format.resolvedOptions().timeZone
    };
  });
  const queryTimeZoneIntlFormat = memoize(upperNormId => new RawDateTimeFormat("en-u-hc-h23", {
    calendar: "iso8601",
    timeZone: upperNormId,
    era: "short",
    year: "numeric",
    month: "numeric",
    day: "numeric",
    hour: "numeric",
    minute: "numeric",
    second: "numeric"
  }));
  const queryTimeZoneRecord = memoize((normTimeZoneId, record) => "named" === record.kind ? new IntlTimeZone(normTimeZoneId, record.o, record.format) : new FixedTimeZone(normTimeZoneId, record.o, "fixed" === record.kind ? record._ : 0));
  class FixedTimeZone {
    constructor(id, compareKey, offsetNano) {
      this.id = id, this.o = compareKey, this._ = offsetNano;
    }
    C() {
      return this._;
    }
    R(isoDateTime) {
      return [ isoDateTimeAndOffsetToEpochNano(isoDateTime, this._) ];
    }
    U() {}
  }
  class IntlTimeZone {
    constructor(id, compareKey, format) {
      this.id = id, this.o = compareKey, this.qe = ((computeOffsetSec, periodDays) => {
        function getOffsetSec(epochSec) {
          const [startEpochSec, endEpochSec] = computePeriod(epochSec, periodSec);
          const clampedStartEpochSec = clampIntlSampleEpochSec(startEpochSec);
          const clampedEndEpochSec = clampIntlSampleEpochSec(endEpochSec);
          const startOffsetSec = getSample(clampedStartEpochSec);
          const endOffsetSec = getSample(clampedEndEpochSec);
          return startOffsetSec === endOffsetSec ? startOffsetSec : pinch(getSplit(clampedStartEpochSec, clampedEndEpochSec), startOffsetSec, endOffsetSec, epochSec);
        }
        function pinch(split, startOffsetSec, endOffsetSec, forEpochSec) {
          let offsetSec;
          let splitDurSec;
          for (;(void 0 === forEpochSec || void 0 === (offsetSec = forEpochSec < split[0] ? startOffsetSec : forEpochSec >= split[1] ? endOffsetSec : void 0)) && (splitDurSec = split[1] - split[0]); ) {
            const middleEpochSec = split[0] + Math.floor(splitDurSec / 2);
            computeOffsetSec(middleEpochSec) === endOffsetSec ? split[1] = middleEpochSec : split[0] = middleEpochSec + 1;
          }
          return offsetSec;
        }
        const getSample = memoize(computeOffsetSec);
        const getSplit = memoize(createSplitTuple);
        const periodSec = 86400 * periodDays;
        return {
          Ee(zonedEpochSec) {
            const wideOffsetSec0 = getOffsetSec(zonedEpochSec - 86400);
            const wideOffsetSec1 = getOffsetSec(zonedEpochSec + 86400);
            const wideUtcEpochSec0 = zonedEpochSec - wideOffsetSec0;
            const wideUtcEpochSec1 = zonedEpochSec - wideOffsetSec1;
            if (wideOffsetSec0 === wideOffsetSec1) {
              return [ wideUtcEpochSec0 ];
            }
            const narrowOffsetSec0 = getOffsetSec(wideUtcEpochSec0);
            return narrowOffsetSec0 === getOffsetSec(wideUtcEpochSec1) ? [ zonedEpochSec - narrowOffsetSec0 ] : wideOffsetSec0 > wideOffsetSec1 ? [ wideUtcEpochSec0, wideUtcEpochSec1 ] : [];
          },
          De: getOffsetSec,
          U: function getTransition(epochSec, direction) {
            if (direction > 0 && epochSec >= 864e10) {
              return;
            }
            if (direction < 0) {
              if (epochSec <= minPossibleTransitionSec) {
                return;
              }
              const lookaheadEpochSec = getCurrentEpochSec() + 94867200;
              if (epochSec > lookaheadEpochSec) {
                return getTransition(lookaheadEpochSec, -1);
              }
            }
            const searchEpochSec = direction > 0 ? Math.max(epochSec, minPossibleTransitionSec) : epochSec;
            let [startEpochSec, endEpochSec] = computePeriod(searchEpochSec, periodSec);
            const inc = periodSec * direction;
            const searchLimit = direction > 0 ? Math.max(epochSec, getCurrentEpochSec()) + 94867200 : minPossibleTransitionSec;
            const inBounds = () => direction < 0 ? endEpochSec > searchLimit : startEpochSec < searchLimit;
            for (;inBounds(); ) {
              const clampedStartEpochSec = clampIntlSampleEpochSec(startEpochSec);
              const clampedEndEpochSec = clampIntlSampleEpochSec(endEpochSec);
              const startOffsetSec = getSample(clampedStartEpochSec);
              const endOffsetSec = getSample(clampedEndEpochSec);
              if (startOffsetSec !== endOffsetSec) {
                const split = getSplit(clampedStartEpochSec, clampedEndEpochSec);
                pinch(split, startOffsetSec, endOffsetSec);
                const transitionEpochSec = split[0];
                if ((compareNumbers(transitionEpochSec, epochSec) || 1) === direction) {
                  return transitionEpochSec;
                }
              }
              startEpochSec += inc, endEpochSec += inc;
            }
          }
        };
      })((format => epochSec => {
        const intlParts = formatEpochMilliToPartsRecord(format, 1e3 * epochSec);
        return 86400 * isoArgsToEpochDays((intlParts => {
          const relatedYear = intlParts.relatedYear;
          if (void 0 !== relatedYear) {
            return parseInt(relatedYear);
          }
          const year = parseInt(intlParts.year);
          return void 0 !== intlParts.era && "bce" === normalizeEraName(intlParts.era) ? 1 - year : year;
        })(intlParts), parseInt(intlParts.month), parseInt(intlParts.day)) + 3600 * parseInt(intlParts.hour) + 60 * parseInt(intlParts.minute) + parseInt(intlParts.second) - epochSec;
      })(format), (timeZoneId => {
        const timeZoneName = timeZoneId.split("/").pop();
        return timeZonePeriodDaysByName[timeZoneName] || 60;
      })(id));
    }
    C(epochNano) {
      return this.qe.De((epochNano => epochNanoToSecMod(epochNano)[0])(epochNano)) * nanoInSec;
    }
    R(isoDateTime) {
      const zonedEpochSec = 86400 * isoDateToEpochDays(isoDateTime) + timeFieldsToSec(isoDateTime);
      const subsecNano = timeFieldsToSubsecNano(isoDateTime);
      return this.qe.Ee(zonedEpochSec).map(epochSec => checkEpochNanoInBounds(BigInt(epochSec) * bigNanoInSec + BigInt(subsecNano)));
    }
    U(epochNano, direction) {
      const [epochSec, subsecNano] = epochNanoToSecMod(epochNano);
      const resEpochSec = this.qe.U(epochSec + (direction > 0 || subsecNano ? 1 : 0), direction);
      if (void 0 !== resEpochSec) {
        return BigInt(resEpochSec) * bigNanoInSec;
      }
    }
  }
  const dateTimeRegExpStr = "(?:(?:([+-])(\\d{6}))|(\\d{4}))(-?)(\\d{2})\\4(\\d{2})(?:[T ]" + timeRegExpStr(8) + "(Z|" + offsetRegExpStr(15) + ")?)?";
  const yearMonthRegExp = createRegExp("(?:(?:([+-])(\\d{6}))|(\\d{4}))-?(\\d{2})((?:\\[(!?)([^\\]]*)\\]){0,9})");
  const monthDayRegExp = createRegExp("(?:--)?(\\d{2})-?(\\d{2})((?:\\[(!?)([^\\]]*)\\]){0,9})");
  const dateTimeRegExp = createRegExp(dateTimeRegExpStr + "((?:\\[(!?)([^\\]]*)\\]){0,9})");
  const timeRegExp = createRegExp("T?" + timeRegExpStr(2) + `(${offsetRegExpStr(9)})?((?:\\[(!?)([^\\]]*)\\]){0,9})`);
  const annotationRegExp = new RegExp("\\[(!?)([^\\]]*)\\]", "g");
  const durationRegExp = createRegExp("([+-])?P(\\d+Y)?(\\d+M)?(\\d+W)?(\\d+D)?(?:T(?:(\\d+)(?:[.,](\\d{1,9}))?H)?(?:(\\d+)(?:[.,](\\d{1,9}))?M)?(?:(\\d+)(?:[.,](\\d{1,9}))?S)?)?");
  const dateDefaultShapeFields = {
    year: "numeric",
    month: "numeric",
    day: "numeric"
  };
  const timeDefaultShapeFields = {
    hour: "numeric",
    minute: "numeric",
    second: "numeric"
  };
  const dateTimeDefaultShapeFields = Object.assign({}, dateDefaultShapeFields, timeDefaultShapeFields);
  const zonedDateTimeDefaultShapeFields = Object.assign({}, dateTimeDefaultShapeFields, {
    timeZoneName: "short"
  });
  const yearMonthDefaultShapeFields = {
    year: "numeric",
    month: "numeric"
  };
  const monthDayDefaultShapeFields = {
    month: "numeric",
    day: "numeric"
  };
  const dateShapeFieldNames = [ "weekday", "year", "month", "day", "dateStyle" ];
  const timeShapeFieldNames = [ "dayPeriod", "hour", "minute", "second", "fractionalSecondDigits", "timeStyle" ];
  const dateTimeShapeFieldNames = dateShapeFieldNames.concat(timeShapeFieldNames);
  const yearMonthIgnoredFieldNames = [ "weekday", "day" ].concat(timeShapeFieldNames);
  const monthDayIgnoredFieldNames = [ "weekday", "year" ].concat(timeShapeFieldNames);
  const transformInstantOptions = createOptionsTransformer(dateTimeShapeFieldNames, [], [], dateTimeDefaultShapeFields);
  const transformZonedOptions = createOptionsTransformer(dateTimeShapeFieldNames, [], [], zonedDateTimeDefaultShapeFields);
  const transformDateTimeOptions = createOptionsTransformer(dateTimeShapeFieldNames, [], [ "timeZoneName" ], dateTimeDefaultShapeFields);
  const transformDateOptions = createOptionsTransformer(dateShapeFieldNames, timeShapeFieldNames, [ "timeZoneName" ], dateDefaultShapeFields);
  const transformTimeOptions = createOptionsTransformer(timeShapeFieldNames, dateShapeFieldNames, [ "timeZoneName", "era" ], timeDefaultShapeFields);
  const transformYearMonthOptions = createOptionsTransformer([ "year", "month", "dateStyle" ], yearMonthIgnoredFieldNames, [ "timeZoneName" ], yearMonthDefaultShapeFields, {
    full: {
      year: "numeric",
      month: "long"
    },
    long: {
      year: "numeric",
      month: "long"
    },
    medium: {
      year: "numeric",
      month: "short"
    },
    short: {
      year: "2-digit",
      month: "numeric"
    }
  });
  const transformMonthDayOptions = createOptionsTransformer([ "month", "day", "dateStyle" ], monthDayIgnoredFieldNames, [ "timeZoneName", "era" ], monthDayDefaultShapeFields, {
    full: {
      month: "long",
      day: "numeric"
    },
    long: {
      month: "long",
      day: "numeric"
    },
    medium: {
      month: "short",
      day: "numeric"
    },
    short: {
      month: "numeric",
      day: "numeric"
    }
  });
  const NativeTemporal = globalThis.Temporal;
  const attachDebugString = "noop" === noop.name ? instance => {
    Object.defineProperty(instance, "_str_", {
      value: instance.toJSON()
    });
  } : noop;
  const yearMonthFieldGetters$1 = {
    era(slots) {
      return computeCalendarEraFields(slots.calendar, slots).era;
    },
    eraYear(slots) {
      return computeCalendarEraFields(slots.calendar, slots).eraYear;
    },
    year(slots) {
      return computeCalendarDateFields(slots.calendar, slots).year;
    },
    month(slots) {
      return computeCalendarDateFields(slots.calendar, slots).month;
    },
    monthCode(slots) {
      return computeCalendarMonthCode(slots.calendar, slots);
    }
  };
  const dateFieldGetters$1 = {
    era(slots) {
      return computeCalendarEraFields(slots.calendar, slots).era;
    },
    eraYear(slots) {
      return computeCalendarEraFields(slots.calendar, slots).eraYear;
    },
    year(slots) {
      return computeCalendarDateFields(slots.calendar, slots).year;
    },
    month(slots) {
      return computeCalendarDateFields(slots.calendar, slots).month;
    },
    monthCode(slots) {
      return computeCalendarMonthCode(slots.calendar, slots);
    },
    day(slots) {
      return computeCalendarDateFields(slots.calendar, slots).day;
    }
  };
  const monthDayFieldGetters$1 = {
    monthCode(slots) {
      return computeCalendarMonthCode(slots.calendar, slots);
    },
    day(slots) {
      return computeCalendarDateFields(slots.calendar, slots).day;
    }
  };
  const yearMonthDerivedGetters = {
    daysInMonth(slots) {
      return computeCalendarDaysInMonth(slots.calendar, slots);
    },
    daysInYear(slots) {
      return computeCalendarDaysInYear(slots.calendar, slots);
    },
    monthsInYear(slots) {
      return computeCalendarMonthsInYear(slots.calendar, slots);
    },
    inLeapYear(slots) {
      return computeCalendarInLeapYear(slots.calendar, slots);
    }
  };
  const dateDerivedGetters = {
    dayOfWeek(slots) {
      return computeIsoDayOfWeek(slots);
    },
    dayOfYear(slots) {
      return ((calendar, isoDate) => {
        if (!calendar) {
          return computeIsoDayOfYear(isoDate);
        }
        const {year: year} = computeCalendarDateFields(calendar, isoDate);
        const yearStartIsoDate = computeCalendarIsoFieldsFromParts(calendar, year, 1, 1);
        return isoDateToEpochDays(isoDate) - isoDateToEpochDays(yearStartIsoDate) + 1;
      })(slots.calendar, slots);
    },
    weekOfYear: slots => slots.calendar === isoCalendarImpl ? computeIsoWeekFields(slots).weekOfYear : void 0,
    yearOfWeek: slots => slots.calendar === isoCalendarImpl ? computeIsoWeekFields(slots).yearOfWeek : void 0,
    daysInWeek() {
      return 7;
    },
    daysInMonth(slots) {
      return computeCalendarDaysInMonth(slots.calendar, slots);
    },
    daysInYear(slots) {
      return computeCalendarDaysInYear(slots.calendar, slots);
    },
    monthsInYear(slots) {
      return computeCalendarMonthsInYear(slots.calendar, slots);
    },
    inLeapYear(slots) {
      return computeCalendarInLeapYear(slots.calendar, slots);
    }
  };
  createNativeGetters(yearMonthDerivedGetters), createNativeGetters(dateDerivedGetters);
  const buddhistEraOrigins = {
    be: 0
  };
  const commonScrapedCalendarConfig = {
    m: 13,
    Z: {
      1: 0,
      2: 29,
      8: 29,
      9: 29,
      10: 29,
      11: 29,
      12: 0
    },
    X: 30,
    Ce(monthCodeNumber, isLeapMonth, day) {
      if (isLeapMonth) {
        switch (monthCodeNumber) {
         case 1:
          return 1651;

         case 2:
          return day < 30 ? 1947 : 1765;

         case 3:
          return day < 30 ? 1966 : 1955;

         case 4:
          return day < 30 ? 1963 : 1944;

         case 5:
          return day < 30 ? 1971 : 1952;

         case 6:
          return day < 30 ? 1960 : 1941;

         case 7:
          return day < 30 ? 1968 : 1938;

         case 8:
          return day < 30 ? 1957 : 1718;

         case 9:
          return 2014;

         case 10:
          return 1984;

         case 11:
          return day < 29 ? 2033 : 2034;

         case 12:
          return 1890;
        }
      }
      return 1972;
    }
  };
  const copticEraOrigins = {
    am: 0
  };
  const ethiopicEraOrigins = {
    am: 0,
    aa: 0
  };
  const ethioaaEraOrigins = {
    aa: 0
  };
  const hebrewEraOrigins = {
    am: 0
  };
  const indianEraOrigins = {
    shaka: 0
  };
  const umalquraPlainMonthDay30ReferenceYears = [ 1392, 1390, 1391, 1392, 1391, 1392, 1389, 1392, 1392, 1390, 1391, 1390 ];
  const japaneseEraOrigins = Object.assign({}, gregoryEraOrigins, {
    meiji: 1867,
    taisho: 1911,
    showa: 1925,
    heisei: 1988,
    reiwa: 2018
  });
  const persianEraOrigins = {
    ap: 0
  };
  const persianMonthStarts = [ 0, 31, 62, 93, 124, 155, 186, 216, 246, 276, 306, 336 ];
  const rocEraOrigins = {
    broc: -1,
    roc: 0
  };
  const exoticCreatorMap = new Map([ [ "buddhist", () => createGregoryAlignedCalendar({
    ve: 543,
    l: buddhistEraOrigins,
    h(_isoDate, calendarYear) {
      return {
        era: "be",
        eraYear: calendarYear
      };
    }
  }) ], [ "chinese", createChineseDangiCalendar ], [ "coptic", () => createCopticFamilyCalendar(1824665, copticEraOrigins) ], [ "dangi", createChineseDangiCalendar ], [ "ethiopic", () => createCopticFamilyCalendar(1723856, ethiopicEraOrigins, 0, 1) ], [ "ethioaa", () => createCopticFamilyCalendar(1723856, ethioaaEraOrigins, 5500) ], [ "hebrew", () => createArithmeticCalendar({
    l: hebrewEraOrigins,
    m: -6,
    J(julianDay) {
      const day = julianDay - 347997;
      let year = Math.floor((25920 * day / 765433 * 19 + 234) / 235) + 1;
      let yearStart = hebrewStartOfYear(year);
      let dayOfYear = Math.floor(day - yearStart);
      for (;dayOfYear < 1; ) {
        year--, yearStart = hebrewStartOfYear(year), dayOfYear = Math.floor(day - yearStart);
      }
      let month = 1;
      let monthStart = 0;
      for (;monthStart < dayOfYear; ) {
        monthStart += hebrewDaysInMonth(year, month), month++;
      }
      return month--, monthStart -= hebrewDaysInMonth(year, month), {
        year: year,
        month: month,
        day: dayOfYear - monthStart
      };
    },
    L(year, month, day) {
      let julianDay = hebrewStartOfYear(year);
      for (let i = 1; i < month; i++) {
        julianDay += hebrewDaysInMonth(year, i);
      }
      return julianDay + day + 347997;
    },
    p: hebrewDaysInMonth,
    j: hebrewDaysInYear,
    k(year) {
      return hebrewIsLeapYear(year) ? 13 : 12;
    },
    u: hebrewIsLeapYear,
    q(year) {
      return hebrewIsLeapYear(year) ? 6 : void 0;
    },
    O(year, month) {
      return hebrewIsLeapYear(year) && 6 === month ? [ 5, 1 ] : [ month - (hebrewIsLeapYear(year) && month > 6 ? 1 : 0), 0 ];
    },
    v(monthCodeNumber, isLeapMonth, day) {
      return isLeapMonth && 5 === monthCodeNumber && day <= 30 ? {
        year: 5730,
        month: 6
      } : void 0;
    },
    h({year: year}) {
      return {
        era: "am",
        eraYear: year
      };
    }
  }) ], [ "indian", function() {
    return createArithmeticCalendar({
      l: indianEraOrigins,
      J(julianDay) {
        const gregory = epochDaysToIsoDate(julianDay - 2440588);
        let year = gregory.year - 78;
        let dayOfGregorianYear = julianDay - (isoArgsToEpochDays(gregory.year, 1, 1) + 2440588);
        let firstMonthDays;
        if (dayOfGregorianYear < 80 ? (year--, firstMonthDays = computeIsoInLeapYear(gregory.year - 1) ? 31 : 30, 
        dayOfGregorianYear += firstMonthDays + 155 + 90 + 10) : (firstMonthDays = computeIsoInLeapYear(gregory.year) ? 31 : 30, 
        dayOfGregorianYear -= 80), dayOfGregorianYear < firstMonthDays) {
          return {
            year: year,
            month: 1,
            day: dayOfGregorianYear + 1
          };
        }
        let monthDay = dayOfGregorianYear - firstMonthDays;
        return monthDay < 155 ? {
          year: year,
          month: Math.floor(monthDay / 31) + 2,
          day: monthDay % 31 + 1
        } : (monthDay -= 155, {
          year: year,
          month: Math.floor(monthDay / 30) + 7,
          day: monthDay % 30 + 1
        });
      },
      L(year, month, day) {
        const gregoryYear = year + 78;
        let firstMonthDays;
        let julianDay;
        return computeIsoInLeapYear(gregoryYear) ? (firstMonthDays = 31, julianDay = isoArgsToEpochDays(gregoryYear, 3, 21) + 2440588) : (firstMonthDays = 30, 
        julianDay = isoArgsToEpochDays(gregoryYear, 3, 22) + 2440588), 1 === month || (julianDay += firstMonthDays + 31 * Math.min(month - 2, 5), 
        month >= 8 && (julianDay += 30 * (month - 7))), julianDay + day - 1;
      },
      p(year, month) {
        return 1 === month && computeIsoInLeapYear(year + 78) || month >= 2 && month <= 6 ? 31 : 30;
      },
      j(year) {
        return computeIsoInLeapYear(year + 78) ? 366 : 365;
      },
      k() {
        return 12;
      },
      u(year) {
        return this.j(year) > 365;
      },
      h({year: year}) {
        return {
          era: "shaka",
          eraYear: year
        };
      }
    });
  } ], [ "japanese", () => createGregoryAlignedCalendar({
    l: japaneseEraOrigins,
    le: 1,
    h: computeJapaneseEraFields
  }) ], [ "islamic-civil", () => createIslamicCalendar(bindArgs(julianDayToIslamic, 1948440), bindArgs(islamicToJulianDay, 1948440)) ], [ "islamic-tbla", () => createIslamicCalendar(bindArgs(julianDayToIslamic, 1948439), bindArgs(islamicToJulianDay, 1948439)) ], [ "islamic-umalqura", canonicalId => {
    const intlUmalquraData = createIntlScrapedCalendarData(canonicalId);
    return createIslamicCalendar(bindArgs(julianDayToUmalqura, intlUmalquraData), bindArgs(umalquraToJulianDay, intlUmalquraData), intlUmalquraData);
  } ], [ "persian", () => createArithmeticCalendar({
    l: persianEraOrigins,
    J(julianDay) {
      const daysSinceEpoch = julianDay - 1948320;
      const year = 1 + Math.floor((33 * daysSinceEpoch + 3) / 12053);
      const dayOfYear = daysSinceEpoch - (365 * (year - 1) + Math.floor((8 * year + 21) / 33));
      const month = Math.floor(dayOfYear < 216 ? dayOfYear / 31 : (dayOfYear - 6) / 30);
      return {
        year: year,
        month: month + 1,
        day: dayOfYear - persianMonthStarts[month] + 1
      };
    },
    L(year, month, day) {
      return 1948319 + 365 * (year - 1) + Math.floor((8 * year + 21) / 33) + persianMonthStarts[month - 1] + day;
    },
    p(year, month) {
      return month <= 6 ? 31 : month <= 11 || persianIsLeapYear(year) ? 30 : 29;
    },
    j(year) {
      return persianIsLeapYear(year) ? 366 : 365;
    },
    k() {
      return 12;
    },
    u: persianIsLeapYear,
    h({year: year}) {
      return {
        era: "ap",
        eraYear: year
      };
    }
  }) ], [ "roc", () => createGregoryAlignedCalendar({
    ve: -1911,
    l: rocEraOrigins,
    h(_isoDate, calendarYear) {
      return calendarYear < 1 ? {
        era: "broc",
        eraYear: 1 - calendarYear
      } : {
        era: "roc",
        eraYear: calendarYear
      };
    }
  }) ] ]);
  const forbiddenExoticCalendarIdMap = {
    islamic: 1,
    "islamic-rgsa": 1
  };
  const deprecatedExoticCalendarIdMap = {
    "ethiopic-amete-alem": "ethioaa",
    islamicc: "islamic-civil"
  };
  const getOrCreateExoticCalendar = memoize((canonicalId, createExoticCalendar) => {
    const calendar = createExoticCalendar(canonicalId);
    return calendar.id = canonicalId, calendar;
  });
  const zonedDateTimeSlotsMap = new WeakMap;
  const ZonedDateTime = defineTemporalClass("ZonedDateTime", class {
    constructor(epochNanoseconds, timeZoneId, calendar = void 0) {
      initZonedDateTime(this, createZonedEpochNanoSlots(checkEpochNanoInBounds(toBigInt(epochNanoseconds)), queryTimeZone(resolveTimeZoneId(requireString(timeZoneId))), resolveAnyCalendarArg(calendar)));
    }
    static from(arg, options = void 0) {
      return createZonedDateTime(toZonedDateTimeSlots(arg, options));
    }
    static compare(arg0, arg1) {
      return compareZonedDateTimes(toZonedDateTimeSlots(arg0), toZonedDateTimeSlots(arg1));
    }
    get calendarId() {
      return getCalendarSlotId(getZonedDateTimeSlots(this).calendar);
    }
    get timeZoneId() {
      return getZonedDateTimeSlots(this).timeZone.id;
    }
    get epochMilliseconds() {
      return getEpochMilli(getZonedDateTimeSlots(this));
    }
    get epochNanoseconds() {
      return getEpochNano(getZonedDateTimeSlots(this));
    }
    get offset() {
      return formatOffsetNano(zonedEpochSlotsToIso(getZonedDateTimeSlots(this)).offsetNanoseconds);
    }
    get offsetNanoseconds() {
      return zonedEpochSlotsToIso(getZonedDateTimeSlots(this)).offsetNanoseconds;
    }
    get hoursInDay() {
      return (slots => {
        const {timeZone: timeZone} = slots;
        const isoFields0 = combineDateAndTime(zonedEpochSlotsToIso(slots), timeFieldDefaults);
        const isoFields1 = combineDateAndTime(moveByDays(isoFields0, 1), timeFieldDefaults);
        const epochNano0 = getStartOfDayInstantFor(timeZone, isoFields0);
        return divideBigNanoToExactNumber(getStartOfDayInstantFor(timeZone, isoFields1) - epochNano0, nanoInHour);
      })(getZonedDateTimeSlots(this));
    }
    with(mod, options = void 0) {
      return createZonedDateTime(((zonedDateTimeSlots, modFields, options) => {
        const {calendar: calendar, timeZone: timeZone} = zonedDateTimeSlots;
        const validFieldNames = getCalendarFieldNames(calendar, dateTimeAndOffsetFieldNamesAlpha, dateTimeAndOffsetFieldNamesWithEraAlpha);
        const zonedSlots = zonedEpochSlotsToIso(zonedDateTimeSlots);
        const {year: year, month: month, day: day} = computeCalendarDateFields(calendar, zonedSlots);
        const origFields = {
          year: year,
          monthCode: computeMonthCode(calendar, year, month),
          day: day,
          hour: zonedSlots.hour,
          minute: zonedSlots.minute,
          second: zonedSlots.second,
          millisecond: zonedSlots.millisecond,
          microsecond: zonedSlots.microsecond,
          nanosecond: zonedSlots.nanosecond,
          offset: zonedSlots.offsetNanoseconds
        };
        const partialFields = readAndRefineBagFields(modFields, validFieldNames, zonedDateTimeFieldRefiners);
        const mergedCalendarFields = mergeCalendarFields(calendar, origFields, partialFields);
        const mergedAllFields = {
          ...origFields,
          ...partialFields
        };
        const [isoDateFields, overflow, offsetDisambig, epochDisambig] = createPlainDateFromFieldsWithOptionsRefiner(calendar, mergedCalendarFields, () => refineZonedFieldOptions(options, 2));
        return createZonedEpochNanoSlots(getMatchingInstantFor(timeZone, combineDateAndTime(isoDateFields, constrainTimeFields(mergedAllFields, overflow)), mergedAllFields.offset, offsetDisambig, epochDisambig), timeZone, calendar);
      })(getZonedDateTimeSlots(this), validateBag(mod), options));
    }
    withCalendar(calendarArg) {
      return createZonedDateTime({
        ...getZonedDateTimeSlots(this),
        calendar: refineCalendarArg(calendarArg)
      });
    }
    withTimeZone(timeZoneArg) {
      return createZonedDateTime({
        ...getZonedDateTimeSlots(this),
        timeZone: queryTimeZone(refineTimeZoneArg(timeZoneArg))
      });
    }
    withPlainTime(plainTimeArg = void 0) {
      return createZonedDateTime(((zonedDateTimeSlots, plainTimeFields) => {
        const {timeZone: timeZone} = zonedDateTimeSlots;
        const isoDateTime = zonedEpochSlotsToIso(zonedDateTimeSlots);
        const {offsetNanoseconds: offsetNanoseconds} = isoDateTime;
        const time = plainTimeFields || timeFieldDefaults;
        let epochNano;
        return epochNano = plainTimeFields ? getMatchingInstantFor(timeZone, combineDateAndTime(isoDateTime, time), offsetNanoseconds, 2) : getStartOfDayInstantFor(timeZone, combineDateAndTime(isoDateTime, time)), 
        createZonedEpochNanoSlots(epochNano, timeZone, zonedDateTimeSlots.calendar);
      })(getZonedDateTimeSlots(this), optionalToPlainTimeFields(plainTimeArg)));
    }
    add(durationArg, options = void 0) {
      return createZonedDateTime(moveZonedEpochSlots(getZonedDateTimeSlots(this), toDurationSlots(durationArg), options));
    }
    subtract(durationArg, options = void 0) {
      return createZonedDateTime(moveZonedEpochSlots(getZonedDateTimeSlots(this), negateDurationFields(toDurationSlots(durationArg)), options));
    }
    until(otherArg, options = void 0) {
      const slots = getZonedDateTimeSlots(this);
      const other = toZonedDateTimeSlots(otherArg);
      return createDuration(createDurationSlots(diffZonedDateTimes(0, getCommonCalendar(slots.calendar, other.calendar), slots, other, options)));
    }
    since(otherArg, options = void 0) {
      const slots = getZonedDateTimeSlots(this);
      const other = toZonedDateTimeSlots(otherArg);
      return createDuration(createDurationSlots(diffZonedDateTimes(1, getCommonCalendar(slots.calendar, other.calendar), slots, other, options)));
    }
    round(options) {
      const slots = getZonedDateTimeSlots(this);
      const [smallestUnit, roundingInc, roundingMode] = refineRoundingOptions(options);
      return createZonedDateTime(((slots, smallestUnit, roundingInc, roundingMode) => {
        let {epochNanoseconds: epochNanoseconds} = slots;
        const {timeZone: timeZone, calendar: calendar} = slots;
        if (0 === smallestUnit && 1 === roundingInc) {
          return {
            epochNanoseconds: epochNanoseconds,
            timeZone: timeZone,
            calendar: calendar
          };
        }
        if (6 === smallestUnit) {
          const isoFields0 = combineDateAndTime(zonedEpochSlotsToIso(slots), timeFieldDefaults);
          const isoFields1 = combineDateAndTime(moveByDays(isoFields0, 1), timeFieldDefaults);
          const epochNano0 = getStartOfDayInstantFor(timeZone, isoFields0);
          const epochNano1 = getStartOfDayInstantFor(timeZone, isoFields1);
          epochNanoseconds = roundWithMode(computeEpochNanoFrac(epochNanoseconds, epochNano0, epochNano1), roundingMode) ? epochNano1 : epochNano0;
        } else {
          const isoDateTime = zonedEpochSlotsToIso(slots);
          const offsetNano = isoDateTime.offsetNanoseconds;
          epochNanoseconds = getMatchingInstantFor(timeZone, roundDateTimeToNano(isoDateTime, computeNanoInc(smallestUnit, roundingInc), roundingMode), offsetNano, 2, 0, 1);
        }
        return {
          epochNanoseconds: epochNanoseconds,
          timeZone: timeZone,
          calendar: calendar
        };
      })(slots, smallestUnit, roundingInc, roundingMode));
    }
    startOfDay() {
      return createZonedDateTime((slots => {
        const {timeZone: timeZone, calendar: calendar} = slots;
        return createZonedEpochNanoSlots(getStartOfDayInstantFor(timeZone, combineDateAndTime(zonedEpochSlotsToIso(slots), timeFieldDefaults)), timeZone, calendar);
      })(getZonedDateTimeSlots(this)));
    }
    equals(otherArg) {
      return !compareZonedDateTimes(zonedDateTimeSlots0 = getZonedDateTimeSlots(this), zonedDateTimeSlots1 = toZonedDateTimeSlots(otherArg)) && zonedDateTimeSlots0.timeZone.o === zonedDateTimeSlots1.timeZone.o && zonedDateTimeSlots0.calendar === zonedDateTimeSlots1.calendar;
      var zonedDateTimeSlots0, zonedDateTimeSlots1;
    }
    toInstant() {
      return createInstant(createEpochNanoSlots(getZonedDateTimeSlots(this).epochNanoseconds));
    }
    toPlainDateTime() {
      return createPlainDateTime(zonedDateTimeToPlainDateTime(getZonedDateTimeSlots(this)));
    }
    toPlainDate() {
      return createPlainDate(zonedDateTimeToPlainDate(getZonedDateTimeSlots(this)));
    }
    toPlainTime() {
      return createPlainTime(zonedDateTimeToPlainTime(getZonedDateTimeSlots(this)));
    }
    toLocaleString(locales = void 0, options = {}) {
      const slots = getZonedDateTimeSlots(this);
      const format = new RawDateTimeFormat(locales, ((options, timeZoneId) => (void 0 !== options.timeZone && throwTypeError("Cannot specify TimeZone"), 
      options.timeZone = timeZoneId, options))(transformZonedOptions(options), (slots => slots.timeZone.id)(slots)));
      return checkResolvedCalendarCompatible(format, slots), format.format(getEpochMilli(slots));
    }
    toString(options = void 0) {
      return formatZonedDateTimeIso(getZonedDateTimeSlots(this), options);
    }
    toJSON() {
      return formatZonedDateTimeIso(getZonedDateTimeSlots(this));
    }
    getTimeZoneTransition(options) {
      const slots = getZonedDateTimeSlots(this);
      const newEpochNano = ((slots, options) => slots.timeZone.U(slots.epochNanoseconds, (options => {
        const normalizedOptions = normalizeOptionsOrString(options, "direction");
        const res = coerceDirection(normalizedOptions, 0);
        return res || throwRangeError(invalidEntity("direction", res)), res;
      })(options)))(slots, options);
      return newEpochNano ? createZonedDateTime({
        ...slots,
        epochNanoseconds: newEpochNano
      }) : null;
    }
    valueOf() {
      return forbiddenValueOf();
    }
  }, getZonedDateTimeIsoSlots, dateFieldGetters$1, dateDerivedGetters, timeGetters);
  const instantSlotsMap = new WeakMap;
  const Instant = defineTemporalClass("Instant", class {
    constructor(epochNanoseconds) {
      initInstant(this, createEpochNanoSlots(checkEpochNanoInBounds(toBigInt(epochNanoseconds))));
    }
    static from(arg) {
      return createInstant(toInstantSlots(arg));
    }
    static fromEpochMilliseconds(epochMilli) {
      return createInstant((epochMilli => createEpochNanoSlots(checkEpochNanoInBounds(BigInt(toStrictInteger(epochMilli)) * bigNanoInMilli)))(epochMilli));
    }
    static fromEpochNanoseconds(epochNano) {
      return createInstant((epochNano => createEpochNanoSlots(checkEpochNanoInBounds(toBigInt(epochNano))))(epochNano));
    }
    static compare(a, b) {
      return compareInstants(toInstantSlots(a), toInstantSlots(b));
    }
    get epochMilliseconds() {
      return getEpochMilli(getInstantSlots(this));
    }
    get epochNanoseconds() {
      return getEpochNano(getInstantSlots(this));
    }
    add(durationArg) {
      return createInstant(createEpochNanoSlots(moveEpochNano(getInstantSlots(this).epochNanoseconds, toDurationSlots(durationArg))));
    }
    subtract(durationArg) {
      return createInstant(createEpochNanoSlots(moveEpochNano(getInstantSlots(this).epochNanoseconds, negateDurationFields(toDurationSlots(durationArg)))));
    }
    until(otherArg, options = void 0) {
      return createDuration(diffInstants(0, getInstantSlots(this), toInstantSlots(otherArg), options));
    }
    since(otherArg, options = void 0) {
      return createDuration(diffInstants(1, getInstantSlots(this), toInstantSlots(otherArg), options));
    }
    round(options) {
      const slots = getInstantSlots(this);
      const [smallestUnit, roundingInc, roundingMode] = refineRoundingOptions(options, 5, 1);
      return createInstant(createEpochNanoSlots(roundBigNanoToDayOriginInc(slots.epochNanoseconds, computeBigNanoInc(smallestUnit, roundingInc), roundingMode)));
    }
    equals(otherArg) {
      return !compareInstants(getInstantSlots(this), toInstantSlots(otherArg));
    }
    toZonedDateTimeISO(timeZoneArg) {
      return createZonedDateTime((instantSlots = getInstantSlots(this), timeZone = queryTimeZone(refineTimeZoneArg(timeZoneArg)), 
      createZonedEpochNanoSlots(instantSlots.epochNanoseconds, timeZone, void 0)));
      var instantSlots, timeZone;
    }
    toLocaleString(locales = void 0, options = {}) {
      const slots = getInstantSlots(this);
      return new RawDateTimeFormat(locales, transformInstantOptions(options)).format(getEpochMilli(slots));
    }
    toString(options = void 0) {
      return formatInstantIso(refineTimeZoneArg, getInstantSlots(this), options);
    }
    toJSON() {
      return formatInstantIso(refineTimeZoneArg, getInstantSlots(this));
    }
    valueOf() {
      return forbiddenValueOf();
    }
  });
  const {toTemporalInstant: toTemporalInstant} = {
    toTemporalInstant() {
      const epochMilli = Date.prototype.valueOf.call(this);
      return createInstant(createEpochNanoSlots(BigInt(requireNumberIsInteger(epochMilli)) * bigNanoInMilli));
    }
  };
  const plainMonthDaySlotsMap = new WeakMap;
  const PlainMonthDay = defineTemporalClass("PlainMonthDay", class {
    constructor(isoMonth, isoDay, calendar = void 0, referenceIsoYear) {
      const isoMonthInt = toIntegerWithTrunc(isoMonth);
      const isoDayInt = toIntegerWithTrunc(isoDay);
      const calendarImpl = resolveAnyCalendarArg(calendar);
      initPlainMonthDay(this, createDateSlots(checkIsoDateInBounds(validateIsoDateFields({
        year: toIntegerWithTrunc(referenceIsoYear ?? 1972),
        month: isoMonthInt,
        day: isoDayInt
      })), calendarImpl));
    }
    static from(arg, options = void 0) {
      return createPlainMonthDay(toPlainMonthDaySlots(arg, options));
    }
    get calendarId() {
      return getCalendarSlotId(getPlainMonthDaySlots(this).calendar);
    }
    with(mod, options = void 0) {
      return createPlainMonthDay(((plainMonthDaySlots, modFields, options) => {
        const {calendar: calendar} = plainMonthDaySlots;
        const validFieldNames = getCalendarFieldNames(calendar, dateFieldNamesAlpha, dateFieldNamesWithEraAlpha);
        const {year: year, month: month, day: day} = computeCalendarDateFields(calendar, plainMonthDaySlots);
        return createPlainMonthDayFromFields(calendar, mergeCalendarFields(calendar, {
          monthCode: computeMonthCode(calendar, year, month),
          day: day
        }, readAndRefineBagFields(modFields, validFieldNames, dateFieldRefiners)), options);
      })(getPlainMonthDaySlots(this), validateBag(mod), options));
    }
    equals(otherArg) {
      return !compareIsoDateFields(plainMonthDaySlots0 = getPlainMonthDaySlots(this), plainMonthDaySlots1 = toPlainMonthDaySlots(otherArg)) && plainMonthDaySlots0.calendar === plainMonthDaySlots1.calendar;
      var plainMonthDaySlots0, plainMonthDaySlots1;
    }
    toPlainDate(bag) {
      return createPlainDate(((calendar, input, bag) => {
        const extraFieldNames = getCalendarFieldNames(calendar, yearFieldNamesAsc, yearFieldNamesWithEraAlpha);
        return createPlainDateFromMergedFields(calendar, pluckProps(monthCodeDayFieldNamesAlpha, input), readAndRefineBagFields(requireObjectLike(bag), extraFieldNames, dateFieldRefiners, []));
      })(getPlainMonthDaySlots(this).calendar, this, bag));
    }
    toLocaleString(locales = void 0, options = {}) {
      const slots = getPlainMonthDaySlots(this);
      const format = new RawDateTimeFormat(locales, applyPlainFormatTimeZone(transformMonthDayOptions(options)));
      return checkResolvedCalendarCompatible(format, slots, 1), format.format(isoDateToEpochMilli(slots));
    }
    toString(options = void 0) {
      return formatPlainMonthDayIso(getPlainMonthDaySlots(this), options);
    }
    toJSON() {
      return formatPlainMonthDayIso(getPlainMonthDaySlots(this));
    }
    valueOf() {
      return forbiddenValueOf();
    }
  }, getPlainMonthDaySlots, monthDayFieldGetters$1);
  const plainYearMonthSlotsMap = new WeakMap;
  const PlainYearMonth = defineTemporalClass("PlainYearMonth", class {
    constructor(isoYear, isoMonth, calendar = void 0, referenceIsoDay) {
      const isoYearInt = toIntegerWithTrunc(isoYear);
      const isoMonthInt = toIntegerWithTrunc(isoMonth);
      const calendarImpl = resolveAnyCalendarArg(calendar);
      initPlainYearMonth(this, createDateSlots(checkIsoYearMonthInBounds(validateIsoDateFields({
        year: isoYearInt,
        month: isoMonthInt,
        day: toIntegerWithTrunc(referenceIsoDay ?? 1)
      })), calendarImpl));
    }
    static from(arg, options = void 0) {
      return createPlainYearMonth(toPlainYearMonthSlots(arg, options));
    }
    static compare(arg0, arg1) {
      return compareIsoDateFields(toPlainYearMonthSlots(arg0), toPlainYearMonthSlots(arg1));
    }
    get calendarId() {
      return getCalendarSlotId(getPlainYearMonthSlots(this).calendar);
    }
    with(mod, options = void 0) {
      return createPlainYearMonth(((plainYearMonthSlots, modFields, options) => {
        const {calendar: calendar} = plainYearMonthSlots;
        const validFieldNames = getCalendarFieldNames(calendar, yearMonthFieldNamesAlpha, yearMonthFieldNamesWithEraAlpha);
        const {year: year, month: month} = computeCalendarDateFields(calendar, plainYearMonthSlots);
        return createPlainYearMonthFromFields(calendar, mergeCalendarFields(calendar, {
          year: year,
          monthCode: computeMonthCode(calendar, year, month)
        }, readAndRefineBagFields(modFields, validFieldNames, dateFieldRefiners)), options);
      })(getPlainYearMonthSlots(this), validateBag(mod), options));
    }
    add(durationArg, options = void 0) {
      const slots = getPlainYearMonthSlots(this);
      return createPlainYearMonth(createDateSlots(moveYearMonth(0, slots.calendar, slots, toDurationSlots(durationArg), options), slots.calendar));
    }
    subtract(durationArg, options = void 0) {
      const slots = getPlainYearMonthSlots(this);
      return createPlainYearMonth(createDateSlots(moveYearMonth(1, slots.calendar, slots, toDurationSlots(durationArg), options), slots.calendar));
    }
    until(otherArg, options = void 0) {
      const slots = getPlainYearMonthSlots(this);
      const other = toPlainYearMonthSlots(otherArg);
      return createDuration(diffPlainYearMonth(0, getCommonCalendar(slots.calendar, other.calendar), slots, other, options));
    }
    since(otherArg, options = void 0) {
      const slots = getPlainYearMonthSlots(this);
      const other = toPlainYearMonthSlots(otherArg);
      return createDuration(diffPlainYearMonth(1, getCommonCalendar(slots.calendar, other.calendar), slots, other, options));
    }
    equals(otherArg) {
      return !compareIsoDateFields(plainYearMonthSlots0 = getPlainYearMonthSlots(this), plainYearMonthSlots1 = toPlainYearMonthSlots(otherArg)) && plainYearMonthSlots0.calendar === plainYearMonthSlots1.calendar;
      var plainYearMonthSlots0, plainYearMonthSlots1;
    }
    toPlainDate(bag) {
      return createPlainDate(((calendar, input, bag) => createPlainDateFromMergedFields(calendar, pluckProps(getCalendarFieldNames(calendar, yearMonthCodeFieldNamesAlpha, yearMonthCodeFieldNamesWithEraAlpha), input), readAndRefineBagFields(requireObjectLike(bag), dayFieldNamesAsc, dateFieldRefiners, [])))(getPlainYearMonthSlots(this).calendar, this, bag));
    }
    toLocaleString(locales = void 0, options = {}) {
      const slots = getPlainYearMonthSlots(this);
      const format = new RawDateTimeFormat(locales, applyPlainFormatTimeZone(transformYearMonthOptions(options)));
      return checkResolvedCalendarCompatible(format, slots, 1), format.format(isoDateToEpochMilli(slots));
    }
    toString(options = void 0) {
      return formatPlainYearMonthIso(getPlainYearMonthSlots(this), options);
    }
    toJSON() {
      return formatPlainYearMonthIso(getPlainYearMonthSlots(this));
    }
    valueOf() {
      return forbiddenValueOf();
    }
  }, getPlainYearMonthSlots, yearMonthFieldGetters$1, yearMonthDerivedGetters);
  const plainTimeSlotsMap = new WeakMap;
  const PlainTime = defineTemporalClass("PlainTime", class {
    constructor(hour = 0, minute = 0, second = 0, millisecond = 0, microsecond = 0, nanosecond = 0) {
      initPlainTime(this, validateTimeFields(mapProps(toIntegerWithTrunc, {
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millisecond,
        microsecond: microsecond,
        nanosecond: nanosecond
      })));
    }
    static from(arg, options = void 0) {
      return createPlainTime(toPlainTimeSlots(arg, options));
    }
    static compare(arg0, arg1) {
      return compareTimeFields(toPlainTimeSlots(arg0), toPlainTimeSlots(arg1));
    }
    with(mod, options = void 0) {
      return createPlainTime(((initialFields, mod, options) => ((initialFields, modFields, options) => resolveTimeFields({
        ...pluckProps(timeFieldNamesAlpha, initialFields),
        ...readAndRefineBagFields(modFields, timeFieldNamesAlpha, timeFieldRefiners)
      }, refineOverflowOptions(options)))(initialFields, mod, options))(getPlainTimeSlots(this), validateBag(mod), options));
    }
    add(durationArg) {
      return createPlainTime(moveTime(getPlainTimeSlots(this), toDurationSlots(durationArg))[0]);
    }
    subtract(durationArg) {
      return createPlainTime(moveTime(getPlainTimeSlots(this), negateDurationFields(toDurationSlots(durationArg)))[0]);
    }
    until(otherArg, options = void 0) {
      return createDuration(diffPlainTimes(0, getPlainTimeSlots(this), toPlainTimeSlots(otherArg), options));
    }
    since(otherArg, options = void 0) {
      return createDuration(diffPlainTimes(1, getPlainTimeSlots(this), toPlainTimeSlots(otherArg), options));
    }
    round(options) {
      const slots = getPlainTimeSlots(this);
      const [smallestUnit, roundingInc, roundingMode] = refineRoundingOptions(options, 5);
      return createPlainTime(roundTimeToNano(slots, computeNanoInc(smallestUnit, roundingInc), roundingMode)[0]);
    }
    equals(other) {
      return !compareTimeFields(getPlainTimeSlots(this), toPlainTimeSlots(other));
    }
    toLocaleString(locales = void 0, options = {}) {
      const slots = getPlainTimeSlots(this);
      return new RawDateTimeFormat(locales, applyPlainFormatTimeZone(transformTimeOptions(options))).format(timeFieldsToMilli(slots));
    }
    toString(options = void 0) {
      return formatPlainTimeIso(getPlainTimeSlots(this), options);
    }
    toJSON() {
      return formatPlainTimeIso(getPlainTimeSlots(this));
    }
    valueOf() {
      return forbiddenValueOf();
    }
  }, getPlainTimeSlots, timeGetters);
  const plainDateTimeSlotsMap = new WeakMap;
  const PlainDateTime = defineTemporalClass("PlainDateTime", class {
    constructor(isoYear, isoMonth, isoDay, hour = 0, minute = 0, second = 0, millisecond = 0, microsecond = 0, nanosecond = 0, calendar = void 0) {
      initPlainDateTime(this, createDateTimeSlots(checkIsoDateTimeInBounds(validateIsoDateTimeFields(mapProps(toIntegerWithTrunc, {
        year: isoYear,
        month: isoMonth,
        day: isoDay,
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millisecond,
        microsecond: microsecond,
        nanosecond: nanosecond
      }))), resolveAnyCalendarArg(calendar)));
    }
    static from(arg, options = void 0) {
      return createPlainDateTime(toPlainDateTimeSlots(arg, options));
    }
    static compare(arg0, arg1) {
      return compareIsoDateTimeFields(toPlainDateTimeSlots(arg0), toPlainDateTimeSlots(arg1));
    }
    get calendarId() {
      return getCalendarSlotId(getPlainDateTimeSlots(this).calendar);
    }
    with(mod, options = void 0) {
      return createPlainDateTime(((plainDateTimeSlots, modFields, options) => {
        const {calendar: calendar} = plainDateTimeSlots;
        const validFieldNames = getCalendarFieldNames(calendar, dateTimeFieldNamesAlpha, dateTimeFieldNamesWithEraAlpha);
        const {year: year, month: month, day: day} = computeCalendarDateFields(calendar, plainDateTimeSlots);
        const origFields = {
          year: year,
          monthCode: computeMonthCode(calendar, year, month),
          day: day,
          hour: plainDateTimeSlots.hour,
          minute: plainDateTimeSlots.minute,
          second: plainDateTimeSlots.second,
          millisecond: plainDateTimeSlots.millisecond,
          microsecond: plainDateTimeSlots.microsecond,
          nanosecond: plainDateTimeSlots.nanosecond
        };
        const partialFields = readAndRefineBagFields(modFields, validFieldNames, dateTimeFieldRefiners);
        const mergedCalendarFields = mergeCalendarFields(calendar, origFields, partialFields);
        const mergedAllFields = {
          ...origFields,
          ...partialFields
        };
        const [plainDateSlots, overflow] = createPlainDateFromFieldsWithOptionsRefiner(calendar, mergedCalendarFields, () => [ refineOverflowOptions(options) ]);
        return createPlainDateTimeFromRefinedFields(plainDateSlots, constrainTimeFields(mergedAllFields, overflow), calendar);
      })(getPlainDateTimeSlots(this), validateBag(mod), options));
    }
    withCalendar(calendarArg) {
      return createPlainDateTime(createDateTimeSlots(getPlainDateTimeSlots(this), refineCalendarArg(calendarArg)));
    }
    withPlainTime(plainTimeArg = void 0) {
      const slots = getPlainDateTimeSlots(this);
      return createPlainDateTime(createPlainDateTimeFromRefinedFields(slots, optionalToPlainTimeFields(plainTimeArg), slots.calendar));
    }
    add(durationArg, options = void 0) {
      const slots = getPlainDateTimeSlots(this);
      return createPlainDateTime(createDateTimeSlots(moveDateTime(slots.calendar, slots, toDurationSlots(durationArg), options), slots.calendar));
    }
    subtract(durationArg, options = void 0) {
      const slots = getPlainDateTimeSlots(this);
      return createPlainDateTime(createDateTimeSlots(moveDateTime(slots.calendar, slots, negateDurationFields(toDurationSlots(durationArg)), options), slots.calendar));
    }
    until(otherArg, options = void 0) {
      const slots = getPlainDateTimeSlots(this);
      const other = toPlainDateTimeSlots(otherArg);
      return createDuration(diffPlainDateTimes(0, getCommonCalendar(slots.calendar, other.calendar), slots, other, options));
    }
    since(otherArg, options = void 0) {
      const slots = getPlainDateTimeSlots(this);
      const other = toPlainDateTimeSlots(otherArg);
      return createDuration(diffPlainDateTimes(1, getCommonCalendar(slots.calendar, other.calendar), slots, other, options));
    }
    round(options) {
      const slots = getPlainDateTimeSlots(this);
      const [smallestUnit, roundingInc, roundingMode] = refineRoundingOptions(options);
      return createPlainDateTime(createDateTimeSlots(roundDateTimeToNano(slots, computeNanoInc(smallestUnit, roundingInc), roundingMode), slots.calendar));
    }
    equals(otherArg) {
      return !compareIsoDateTimeFields(plainDateTimeSlots0 = getPlainDateTimeSlots(this), plainDateTimeSlots1 = toPlainDateTimeSlots(otherArg)) && plainDateTimeSlots0.calendar === plainDateTimeSlots1.calendar;
      var plainDateTimeSlots0, plainDateTimeSlots1;
    }
    toZonedDateTime(timeZoneArg, options = void 0) {
      return createZonedDateTime(((plainDateTimeSlots, timeZone, options) => {
        const epochNano = ((timeZone, isoDateTime, options) => {
          const epochDisambig = (options => coerceEpochDisambig(normalizeOptions(options)))(options);
          return getSingleInstantFor(timeZone, isoDateTime, epochDisambig);
        })(timeZone, plainDateTimeSlots, options);
        return createZonedEpochNanoSlots(checkEpochNanoInBounds(epochNano), timeZone, plainDateTimeSlots.calendar);
      })(getPlainDateTimeSlots(this), queryTimeZone(refineTimeZoneArg(timeZoneArg)), options));
    }
    toPlainDate() {
      const slots = getPlainDateTimeSlots(this);
      return createPlainDate(createDateSlots(slots, slots.calendar));
    }
    toPlainTime() {
      return createPlainTime(createTimeSlots(getPlainDateTimeSlots(this)));
    }
    toLocaleString(locales = void 0, options = {}) {
      const slots = getPlainDateTimeSlots(this);
      const format = new RawDateTimeFormat(locales, applyPlainFormatTimeZone(transformDateTimeOptions(options)));
      return checkResolvedCalendarCompatible(format, slots), format.format(isoDateTimeToEpochMilli(slots));
    }
    toString(options = void 0) {
      return formatPlainDateTimeIso(getPlainDateTimeSlots(this), options);
    }
    toJSON() {
      return formatPlainDateTimeIso(getPlainDateTimeSlots(this));
    }
    valueOf() {
      return forbiddenValueOf();
    }
  }, getPlainDateTimeSlots, dateFieldGetters$1, dateDerivedGetters, timeGetters);
  const plainDateSlotsMap = new WeakMap;
  const PlainDate = defineTemporalClass("PlainDate", class {
    constructor(isoYear, isoMonth, isoDay, calendar = void 0) {
      initPlainDate(this, createDateSlots(checkIsoDateInBounds(validateIsoDateFields(mapProps(toIntegerWithTrunc, {
        year: isoYear,
        month: isoMonth,
        day: isoDay
      }))), resolveAnyCalendarArg(calendar)));
    }
    static from(arg, options = void 0) {
      return createPlainDate(toPlainDateSlots(arg, options));
    }
    static compare(arg0, arg1) {
      return compareIsoDateFields(toPlainDateSlots(arg0), toPlainDateSlots(arg1));
    }
    get calendarId() {
      return getCalendarSlotId(getPlainDateSlots(this).calendar);
    }
    with(mod, options = void 0) {
      return createPlainDate(((plainDateSlots, modFields, options) => {
        const {calendar: calendar} = plainDateSlots;
        const validFieldNames = getCalendarFieldNames(calendar, dateFieldNamesAlpha, dateFieldNamesWithEraAlpha);
        const {year: year, month: month, day: day} = computeCalendarDateFields(calendar, plainDateSlots);
        return createPlainDateFromFields(calendar, mergeCalendarFields(calendar, {
          year: year,
          monthCode: computeMonthCode(calendar, year, month),
          day: day
        }, readAndRefineBagFields(modFields, validFieldNames, dateFieldRefiners)), options);
      })(getPlainDateSlots(this), validateBag(mod), options));
    }
    withCalendar(calendarArg) {
      return createPlainDate(createDateSlots(getPlainDateSlots(this), refineCalendarArg(calendarArg)));
    }
    add(durationArg, options = void 0) {
      const slots = getPlainDateSlots(this);
      return createPlainDate(createDateSlots(moveDate(slots.calendar, slots, toDurationSlots(durationArg), options), slots.calendar));
    }
    subtract(durationArg, options = void 0) {
      const slots = getPlainDateSlots(this);
      return createPlainDate(createDateSlots(moveDate(slots.calendar, slots, negateDurationFields(toDurationSlots(durationArg)), options), slots.calendar));
    }
    until(otherArg, options = void 0) {
      const slots = getPlainDateSlots(this);
      const other = toPlainDateSlots(otherArg);
      return createDuration(diffPlainDates(0, getCommonCalendar(slots.calendar, other.calendar), slots, other, options));
    }
    since(otherArg, options = void 0) {
      const slots = getPlainDateSlots(this);
      const other = toPlainDateSlots(otherArg);
      return createDuration(diffPlainDates(1, getCommonCalendar(slots.calendar, other.calendar), slots, other, options));
    }
    equals(otherArg) {
      return !compareIsoDateFields(plainDateSlots0 = getPlainDateSlots(this), plainDateSlots1 = toPlainDateSlots(otherArg)) && plainDateSlots0.calendar === plainDateSlots1.calendar;
      var plainDateSlots0, plainDateSlots1;
    }
    toZonedDateTime(options) {
      const optionsObj = isObjectLike(options) ? {
        timeZone: options.timeZone,
        plainTime: options.plainTime
      } : {
        timeZone: options
      };
      return createZonedDateTime(((refineTimeZoneString, refinePlainTimeArg, plainDateSlots, options) => {
        const timeZoneId = refineTimeZoneString(options.timeZone);
        const plainTimeArg = options.plainTime;
        const timeFields = void 0 !== plainTimeArg ? refinePlainTimeArg(plainTimeArg) : void 0;
        const timeZone = queryTimeZone(timeZoneId);
        let epochNano;
        return epochNano = timeFields ? getSingleInstantFor(timeZone, combineDateAndTime(plainDateSlots, timeFields)) : getStartOfDayInstantFor(timeZone, combineDateAndTime(plainDateSlots, timeFieldDefaults)), 
        createZonedEpochNanoSlots(epochNano, timeZone, plainDateSlots.calendar);
      })(refineTimeZoneArg, toPlainTimeSlots, getPlainDateSlots(this), optionsObj));
    }
    toPlainDateTime(plainTimeArg = void 0) {
      const slots = getPlainDateSlots(this);
      return createPlainDateTime(createPlainDateTimeFromRefinedFields(slots, optionalToPlainTimeFields(plainTimeArg), slots.calendar));
    }
    toPlainYearMonth() {
      return createPlainYearMonth(createPlainYearMonthFromFields(calendar = getPlainDateSlots(this).calendar, readAndRefineBagFields(this, getCalendarFieldNames(calendar, yearMonthCodeFieldNamesAlpha, yearMonthCodeFieldNamesWithEraAlpha), dateFieldRefiners), void 0));
      var calendar;
    }
    toPlainMonthDay() {
      return createPlainMonthDay(createPlainMonthDayFromFields(getPlainDateSlots(this).calendar, readAndRefineBagFields(this, monthCodeDayFieldNamesAlpha, dateFieldRefiners)));
    }
    toLocaleString(locales = void 0, options = {}) {
      const slots = getPlainDateSlots(this);
      const format = new RawDateTimeFormat(locales, applyPlainFormatTimeZone(transformDateOptions(options)));
      return checkResolvedCalendarCompatible(format, slots), format.format(isoDateToEpochMilli(slots));
    }
    toString(options = void 0) {
      return formatPlainDateIso(getPlainDateSlots(this), options);
    }
    toJSON() {
      return formatPlainDateIso(getPlainDateSlots(this));
    }
    valueOf() {
      return forbiddenValueOf();
    }
  }, getPlainDateSlots, dateFieldGetters$1, dateDerivedGetters);
  const durationSlotsMap = new WeakMap;
  const Duration = defineTemporalClass("Duration", class {
    constructor(years = 0, months = 0, weeks = 0, days = 0, hours = 0, minutes = 0, seconds = 0, milliseconds = 0, microseconds = 0, nanoseconds = 0) {
      initDuration(this, createDurationSlots(validateDurationFields(mapProps(toStrictInteger, {
        years: years,
        months: months,
        weeks: weeks,
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
        microseconds: microseconds,
        nanoseconds: nanoseconds
      }))));
    }
    static from(arg) {
      return createDuration(toDurationSlots(arg));
    }
    static compare(durationArg0, durationArg1, options = void 0) {
      return ((refineRelativeTo, durationSlots0, durationSlots1, options) => {
        const relativeToSlots = refineRelativeTo(normalizeOptions(options).relativeTo);
        const maxUnit = Math.max(getMaxDurationUnit(durationSlots0), getMaxDurationUnit(durationSlots1));
        if (allPropsEqual(durationFieldNamesAsc, durationSlots0, durationSlots1)) {
          return 0;
        }
        if (isUniformUnit(maxUnit, relativeToSlots)) {
          return compareBigInts(durationDayTimeToBigNano(durationSlots0), durationDayTimeToBigNano(durationSlots1));
        }
        relativeToSlots || throwRangeError("Missing relativeTo");
        const markerSpanOps = createMarkerSpanOps(relativeToSlots);
        return compareBigInts(moveMarkerToEpochNano(markerSpanOps, durationSlots0), moveMarkerToEpochNano(markerSpanOps, durationSlots1));
      })(refinePublicRelativeTo, toDurationSlots(durationArg0), toDurationSlots(durationArg1), options);
    }
    get sign() {
      return getDurationSlots(this).sign;
    }
    get blank() {
      return !getDurationSlots(this).sign;
    }
    with(mod) {
      return createDuration(createDurationSlots((initialFields = getDurationSlots(this), 
      modFields = mod, validateDurationFields({
        ...initialFields,
        ...readAndRefineBagFields(modFields, durationFieldNamesAlpha, durationFieldRefiners)
      }))));
      var initialFields, modFields;
    }
    negated() {
      return createDuration(negateDuration(getDurationSlots(this)));
    }
    abs() {
      return createDuration(-1 === (slots = getDurationSlots(this)).sign ? negateDuration(slots) : slots);
      var slots;
    }
    add(otherArg, options = void 0) {
      return createDuration(addDurations(refinePublicRelativeTo, 0, getDurationSlots(this), toDurationSlots(otherArg), options));
    }
    subtract(otherArg, options = void 0) {
      return createDuration(addDurations(refinePublicRelativeTo, 1, getDurationSlots(this), toDurationSlots(otherArg), options));
    }
    round(roundTo) {
      return createDuration(((refineRelativeTo, slots, options) => {
        const durationLargestUnit = getMaxDurationUnit(slots);
        const [largestUnit, smallestUnit, roundingInc, roundingMode, relativeToSlots] = ((options, defaultLargestUnit, refineRelativeTo) => {
          options = normalizeOptionsOrString(options, smallestUnitStr);
          let largestUnit = coerceLargestUnit(options);
          const relativeToInternals = refineRelativeTo(options.relativeTo);
          let roundingInc = coerceRoundingIncInteger(options);
          const roundingMode = coerceRoundingMode(options, 7);
          let smallestUnit = coerceSmallestUnit(options);
          return void 0 === largestUnit && void 0 === smallestUnit && throwRangeError("Required smallestUnit or largestUnit"), 
          null == smallestUnit && (smallestUnit = 0), null == largestUnit && (largestUnit = Math.max(smallestUnit, defaultLargestUnit)), 
          checkLargestSmallestUnit(largestUnit, smallestUnit), roundingInc = validateRoundingInc(roundingInc, smallestUnit, 1), 
          roundingInc > 1 && smallestUnit > 5 && largestUnit !== smallestUnit && throwRangeError("For calendar units with roundingIncrement > 1, use largestUnit = smallestUnit"), 
          [ largestUnit, smallestUnit, roundingInc, roundingMode, relativeToInternals ];
        })(options, durationLargestUnit, refineRelativeTo);
        if (!relativeToSlots && Math.max(durationLargestUnit, largestUnit) <= 6) {
          return createDurationSlots(validateDurationFields(((durationFields, largestUnit, smallestUnit, roundingInc, roundingMode) => {
            const roundedBigNano = roundBigNanoToInc(durationDayTimeToBigNano(durationFields), computeBigNanoInc(smallestUnit, roundingInc), roundingMode);
            return {
              ...durationFieldDefaults,
              ...nanoToDurationDayTimeFields(roundedBigNano, largestUnit)
            };
          })(slots, largestUnit, smallestUnit, roundingInc, roundingMode)));
        }
        const needsZonedDayLength = relativeToSlots && isZonedEpochSlots(relativeToSlots) && largestUnit >= 6 && smallestUnit < 6;
        if (!slots.sign && !needsZonedDayLength) {
          return slots;
        }
        relativeToSlots || throwRangeError("Missing relativeTo");
        const markerSpanOps = createMarkerSpanOps(relativeToSlots);
        const endMarker = markerSpanOps.G(markerSpanOps.i, slots);
        checkMarkerSpanInBounds(markerSpanOps, endMarker);
        let balancedDuration = markerSpanOps.re(markerSpanOps.i, endMarker, largestUnit);
        return balancedDuration = roundRelativeDuration(balancedDuration, markerSpanOps.V(endMarker), largestUnit, smallestUnit, roundingInc, roundingMode, markerSpanOps), 
        createDurationSlots(balancedDuration);
      })(refinePublicRelativeTo, getDurationSlots(this), roundTo));
    }
    total(totalOf) {
      return function(refineRelativeTo, slots, options) {
        const maxDurationUnit = getMaxDurationUnit(slots);
        const [totalUnit, relativeToSlots] = ((options, refineRelativeTo) => {
          const relativeToInternals = refineRelativeTo((options = normalizeOptionsOrString(options, "unit")).relativeTo);
          let totalUnit = coerceTotalUnit(options);
          return totalUnit = requirePropDefined("unit", totalUnit), [ totalUnit, relativeToInternals ];
        })(options, refineRelativeTo);
        if (!relativeToSlots && isUniformUnit(Math.max(totalUnit, maxDurationUnit), relativeToSlots)) {
          return totalDayTimeDuration(slots, totalUnit);
        }
        if (relativeToSlots || throwRangeError("Missing relativeTo"), !slots.sign && isUniformUnit(totalUnit, relativeToSlots)) {
          return 0;
        }
        const markerSpanOps = createMarkerSpanOps(relativeToSlots);
        const endMarker = markerSpanOps.G(markerSpanOps.i, slots);
        checkMarkerSpanInBounds(markerSpanOps, endMarker);
        const balancedDuration = markerSpanOps.re(markerSpanOps.i, endMarker, totalUnit);
        return isUniformUnit(totalUnit, relativeToSlots) ? totalDayTimeDuration(balancedDuration, totalUnit) : ((durationFields, endEpochNano, totalUnit, markerMoveOps) => {
          const sign = computeDurationSign(durationFields) || 1;
          const nudgeWindow = clampRelativeDuration(clearDurationFields(totalUnit, durationFields), totalUnit, sign, markerMoveOps, endEpochNano);
          const epochNano0 = nudgeWindow.ae;
          const epochNano1 = nudgeWindow.de;
          const denom = Number(epochNano1 - epochNano0);
          const numerator = Number(endEpochNano - epochNano0);
          return nudgeWindow.ye[durationFieldNamesAsc[totalUnit]] + numerator / denom * sign;
        })(balancedDuration, markerSpanOps.V(endMarker), totalUnit, markerSpanOps);
      }(refinePublicRelativeTo, getDurationSlots(this), totalOf);
    }
    toLocaleString(locales = void 0, options) {
      const slots = getDurationSlots(this);
      return Intl.DurationFormat ? new Intl.DurationFormat(locales, options).format(slots) : formatDurationIso(slots, options);
    }
    toString(options = void 0) {
      return formatDurationIso(getDurationSlots(this), options);
    }
    toJSON() {
      return formatDurationIso(getDurationSlots(this));
    }
    valueOf() {
      return forbiddenValueOf();
    }
  }, getDurationSlots, durationGetters);
  const Now = Object.defineProperties({}, {
    ...createStringTagDescriptors("Temporal.Now"),
    ...createPropDescriptors({
      timeZoneId() {
        return getCurrentTimeZoneId();
      },
      instant() {
        return createInstant(createEpochNanoSlots(getCurrentEpochNano()));
      },
      zonedDateTimeISO(timeZoneArg = getCurrentTimeZoneId()) {
        const timeZone = queryTimeZone(refineTimeZoneArg(timeZoneArg));
        return createZonedDateTime(createZonedEpochNanoSlots(getCurrentEpochNano(), timeZone));
      },
      plainDateTimeISO(timeZoneArg = getCurrentTimeZoneId()) {
        return createPlainDateTime(createDateTimeSlots(getCurrentIsoDateTime(queryTimeZone(refineTimeZoneArg(timeZoneArg)))));
      },
      plainDateISO(timeZoneArg = getCurrentTimeZoneId()) {
        return createPlainDate(createDateSlots(getCurrentIsoDateTime(queryTimeZone(refineTimeZoneArg(timeZoneArg)))));
      },
      plainTimeISO(timeZoneArg = getCurrentTimeZoneId()) {
        return createPlainTime(createTimeSlots(getCurrentIsoDateTime(queryTimeZone(refineTimeZoneArg(timeZoneArg)))));
      }
    })
  });
  const Temporal = Object.defineProperties({}, {
    ...createStringTagDescriptors("Temporal"),
    ...createPropDescriptors({
      PlainYearMonth: PlainYearMonth,
      PlainMonthDay: PlainMonthDay,
      PlainDate: PlainDate,
      PlainTime: PlainTime,
      PlainDateTime: PlainDateTime,
      ZonedDateTime: ZonedDateTime,
      Instant: Instant,
      Duration: Duration,
      Now: Now
    })
  });
  const DateTimeFormat = createDateTimeFormatClass(getTemporalBrandingAndSlots);
  NativeTemporal || (Object.defineProperties(globalThis, createPropDescriptors({
    Temporal: Temporal
  })), Object.defineProperties(Intl, createPropDescriptors({
    DateTimeFormat: DateTimeFormat
  })), Object.defineProperties(Date.prototype, createPropDescriptors({
    toTemporalInstant: toTemporalInstant
  })));
}();
