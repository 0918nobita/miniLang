extern crate bincode;
extern crate serde;
#[macro_use]
extern crate serde_derive;

use std::fs;

mod header;
mod type_section;

use header::Header;
use type_section::TypeSection;

fn main() {
    println!("Psyche compiler 0.1.0");
    let header: Header = Default::default();
    let type_section: TypeSection = Default::default();

    let mut encoded_header = bincode::serialize(&header).unwrap();
    let mut encoded_type_section = bincode::serialize(&type_section).unwrap();
    encoded_header.append(&mut encoded_type_section);

    fs::write("out.wasm", encoded_header).unwrap_or_else(|_| panic!("Failed to write .wasm file"));
}
