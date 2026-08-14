use std::sync::mpsc;
use std::thread;
use std::time::Duration;

use rquickjs_playground::AsyncHostRuntime;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let runtime = AsyncHostRuntime::new("example-runtime-drop")?;

    let handle = runtime.spawn(
        r#"
      (async () => {
        await new Promise((resolve) => setTimeout(resolve, 5000));
        return "should_not_reach";
      })()
    "#,
    )?;

    println!("spawned task id={} and drop runtime now", handle.id());
    drop(runtime);

    let (tx, rx) = mpsc::channel();
    thread::spawn(move || {
        let _ = tx.send(handle.wait());
    });

    match rx.recv_timeout(Duration::from_secs(2)) {
        Ok(Ok(value)) => println!("unexpected success: {value}"),
        Ok(Err(err)) => println!("wait returned error as expected: {err}"),
        Err(_) => println!("wait timed out: pending waiter was not unblocked"),
    }

    Ok(())
}
