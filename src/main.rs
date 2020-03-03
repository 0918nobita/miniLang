extern crate bincode;
extern crate serde;
#[macro_use]
extern crate serde_derive;

use std::fs;

mod header;
mod import_section;
mod type_section;

use header::Header;
use import_section::ImportSection;
use type_section::TypeSection;

fn main() {
    println!("Psyche compiler 0.1.0");

    let header: Header = Default::default();
    let type_section: TypeSection = Default::default();
    let import_section: ImportSection = Default::default();

    let mut encoded_header = bincode::serialize(&header).unwrap();
    let mut encoded_type_section = bincode::serialize(&type_section).unwrap();
    let mut encoded_import_section = bincode::serialize(&import_section).unwrap();

    encoded_header.append(&mut encoded_type_section);
    encoded_header.append(&mut encoded_import_section);

    fs::write("out.wasm", encoded_header).unwrap_or_else(|_| panic!("Failed to write .wasm file"));
}
