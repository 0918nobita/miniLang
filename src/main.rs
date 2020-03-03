extern crate bincode;
extern crate serde;
#[macro_use]
extern crate serde_derive;

use std::fs;

mod header;

use header::Header;

fn main() {
    println!("Psyche compiler 0.1.0");
    let header: Header = Default::default();
    let encoded = bincode::serialize(&header).unwrap();
    fs::write("out.wasm", encoded).unwrap_or_else(|_| panic!("Failed to write .wasm file"));
}
