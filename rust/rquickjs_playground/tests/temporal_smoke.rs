use rquickjs_playground::host_runtime::AsyncHostRuntime;

#[test]
fn temporal_smoke() {
    let runtime = AsyncHostRuntime::new("temporal-smoke").expect("rt");
    let handle = runtime
        .spawn(
            r#"
          (async () => {
            const plainDate = Temporal.PlainDate.from("2024-03-15").toString();
            const instant = Temporal.Instant.from("2024-03-15T12:00:00Z").epochNanoseconds.toString();
            const zdt = Temporal.ZonedDateTime.from(
              "2024-03-15T12:00:00-04:00[America/New_York]"
            ).toString();
            const duration = Temporal.Duration.from({ days: 2, hours: 3 }).toString();
            const nowTz = Temporal.Now.timeZoneId();
            const fromDate = new Date("2024-03-15T00:00:00Z").toTemporalInstant().toString();
            return JSON.stringify({ plainDate, instant, zdt, duration, nowTz, fromDate });
          })()
        "#,
        )
        .expect("spawn");
    let raw = handle.wait().expect("wait");
    let v: serde_json::Value = serde_json::from_str(&raw).expect("json");
    assert_eq!(v["plainDate"], "2024-03-15");
    assert_eq!(v["instant"], "1710504000000000000");
    assert_eq!(v["zdt"], "2024-03-15T12:00:00-04:00[America/New_York]");
    assert_eq!(v["duration"], "P2DT3H");
    assert!(v["nowTz"].as_str().is_some_and(|s| !s.is_empty()));
    assert_eq!(v["fromDate"], "2024-03-15T00:00:00Z");
}
