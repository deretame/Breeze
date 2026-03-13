use std::io::{Read, Write};

fn main() {
    if let Err(err) = run() {
        let _ = writeln!(std::io::stderr(), "segmentation failed: {err}");
        std::process::exit(1);
    }
}

fn run() -> anyhow::Result<()> {
    let mut args = std::env::args();
    let _program = args.next();

    let chapter_id: i32 = args
        .next()
        .ok_or_else(|| anyhow::anyhow!("missing argument: chapter_id"))?
        .parse()
        .map_err(|e| anyhow::anyhow!("invalid chapter_id: {e}"))?;
    let scramble_id: i32 = args
        .next()
        .ok_or_else(|| anyhow::anyhow!("missing argument: scramble_id"))?
        .parse()
        .map_err(|e| anyhow::anyhow!("invalid scramble_id: {e}"))?;
    let url = args
        .next()
        .ok_or_else(|| anyhow::anyhow!("missing argument: url"))?;

    let mut input = Vec::new();
    std::io::stdin().read_to_end(&mut input)?;

    let output = segmentation_wasi::segmentation_picture(input, chapter_id, scramble_id, &url)?;
    std::io::stdout().write_all(&output)?;
    Ok(())
}
