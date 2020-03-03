extern crate bincode;
extern crate serde;
#[macro_use]
extern crate serde_derive;

use std::fs;

#[derive(Serialize)]
struct Header {
    magic_cookie: u32,
    version: u32,
}

impl Default for Header {
    fn default() -> Self {
        Header {
            magic_cookie: 0x6d736100, // .asm
            version: 1,
        }
    }
}

fn main() {
    println!("Psyche compiler 0.1.0");
    let header: Header = Default::default();
    let encoded = bincode::serialize(&header).unwrap();
    fs::write("out.wasm", encoded).unwrap_or_else(|_| panic!("Failed to write .wasm file"));
}
