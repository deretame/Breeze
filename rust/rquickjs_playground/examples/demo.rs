use rquickjs_playground::AsyncHostRuntime;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let host = AsyncHostRuntime::new("example-demo")?;

    let script = r#"
        (async () => {
          const inputId = await bridge.call("native.put", [1, 2, 3]);
          const outId = await bridge.call("native.exec", "invert", inputId, null, null);
          const out = await bridge.call("native.take", outId);

          return JSON.stringify({
            out,
          });
        })()
    "#;

    let result = host.spawn(script)?.wait()?;
    println!("{result}");
    Ok(())
}
