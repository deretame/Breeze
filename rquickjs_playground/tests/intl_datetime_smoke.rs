use rquickjs_playground::host_runtime::AsyncHostRuntime;

#[test]
fn intl_datetime_locale_conventions() {
    let runtime = AsyncHostRuntime::new("intl-datetime-smoke").expect("rt");
    let handle = runtime
        .spawn(
            r#"
          (async () => {
            const epoch = Date.UTC(2024, 8, 10, 15, 37, 20); // 2024-09-10T15:37:20Z
            const enUS = new Intl.DateTimeFormat("en-US", {
              dateStyle: "short",
              timeZone: "UTC",
            }).format(epoch);
            const enGB = new Intl.DateTimeFormat("en-GB", {
              dateStyle: "short",
              timeZone: "UTC",
            }).format(epoch);
            const zhCN = new Intl.DateTimeFormat("zh-CN", {
              dateStyle: "long",
              timeZone: "UTC",
            }).format(epoch);
            const jaJP = new Intl.DateTimeFormat("ja-JP", {
              dateStyle: "short",
              timeZone: "UTC",
            }).format(epoch);
            const deDE = new Intl.DateTimeFormat("de-DE", {
              dateStyle: "short",
              timeZone: "UTC",
            }).format(epoch);
            const parts = new Intl.DateTimeFormat("en-US", {
              year: "numeric",
              month: "numeric",
              day: "numeric",
              hour: "numeric",
              minute: "numeric",
              second: "numeric",
              hourCycle: "h23",
              timeZone: "America/New_York",
            }).formatToParts(epoch);
            const types = parts.map((p) => p.type);
            const year = parts.find((p) => p.type === "year")?.value;
            const zones = Intl.supportedValuesOf("timeZone");
            const resolved = new Intl.DateTimeFormat("zh-CN", {
              timeZone: "Asia/Shanghai",
            }).resolvedOptions();

            // P0 checks
            const loneYear = new Intl.DateTimeFormat("en", {
              year: "numeric",
              timeZone: "UTC",
            }).format(epoch);
            const offsetTz = new Intl.DateTimeFormat("en", {
              timeZone: "+00:00",
              year: "numeric",
            }).resolvedOptions().timeZone;
            const calcutta = new Intl.DateTimeFormat("en", {
              timeZone: "Asia/Calcutta",
            }).resolvedOptions().timeZone;
            const kolkata = new Intl.DateTimeFormat("en", {
              timeZone: "Asia/Kolkata",
            }).resolvedOptions().timeZone;
            const etcGmt = new Intl.DateTimeFormat("en", {
              timeZone: "Etc/GMT",
            }).resolvedOptions().timeZone;
            let styleConflict = false;
            try {
              new Intl.DateTimeFormat("en", {
                dateStyle: "short",
                timeZoneName: "short",
              });
            } catch (e) {
              styleConflict = e instanceof TypeError;
            }
            const h24 = new Intl.DateTimeFormat("en", {
              hour: "numeric",
              minute: "numeric",
              second: "numeric",
              hourCycle: "h24",
              timeZone: "UTC",
            }).format(Date.UTC(2024, 0, 1, 0, 0, 0));
            // Extreme epoch should not throw
            const extremeOk = (() => {
              try {
                new Intl.DateTimeFormat("en-u-hc-h23", {
                  year: "numeric",
                  month: "numeric",
                  day: "numeric",
                  hour: "numeric",
                  minute: "numeric",
                  second: "numeric",
                  timeZone: "UTC",
                }).formatToParts(-8e15);
                return true;
              } catch (_) {
                return false;
              }
            })();

            return JSON.stringify({
              enUS,
              enGB,
              zhCN,
              jaJP,
              deDE,
              types,
              year,
              zoneCount: zones.length,
              hasShanghai: zones.includes("Asia/Shanghai"),
              resolvedTz: resolved.timeZone,
              resolvedLocale: resolved.locale,
              loneYear,
              offsetTz,
              calcutta,
              kolkata,
              etcGmt,
              styleConflict,
              h24,
              extremeOk,
            });
          })()
        "#,
        )
        .expect("spawn");
    let raw = handle.wait().expect("wait");
    let v: serde_json::Value = serde_json::from_str(&raw).expect("json");
    let en_us = v["enUS"].as_str().unwrap();
    let en_gb = v["enGB"].as_str().unwrap();
    let zh_cn = v["zhCN"].as_str().unwrap();
    let ja_jp = v["jaJP"].as_str().unwrap();
    let de_de = v["deDE"].as_str().unwrap();

    // Locale conventions should differ (US m/d/y vs GB d/m/y etc.).
    assert_ne!(en_us, en_gb, "en-US and en-GB short dates should differ");
    assert!(zh_cn.contains("2024"), "zh-CN long should include year: {zh_cn}");
    assert!(ja_jp.contains("2024") || ja_jp.contains("24"), "ja-JP: {ja_jp}");
    assert!(de_de.contains('.'), "de-DE short uses dots: {de_de}");

    assert_eq!(v["year"].as_str().unwrap(), "2024");
    assert!(v["types"].as_array().unwrap().iter().any(|t| t == "year"));
    assert!(v["zoneCount"].as_u64().unwrap() > 100);
    assert_eq!(v["hasShanghai"], true);
    assert_eq!(v["resolvedTz"].as_str().unwrap(), "Asia/Shanghai");

    // P0/P1
    assert_eq!(v["loneYear"].as_str().unwrap(), "2024");
    assert_eq!(v["offsetTz"].as_str().unwrap(), "UTC");
    assert_eq!(v["calcutta"].as_str().unwrap(), "Asia/Kolkata");
    assert_eq!(v["kolkata"].as_str().unwrap(), "Asia/Kolkata");
    assert_eq!(v["etcGmt"].as_str().unwrap(), "UTC");
    assert_eq!(v["styleConflict"], true);
    assert!(
        v["h24"].as_str().unwrap().contains("24"),
        "h24 midnight should contain 24: {}",
        v["h24"]
    );
    assert_eq!(v["extremeOk"], true);
}
