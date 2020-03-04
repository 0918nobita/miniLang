extern crate bincode;
extern crate serde;
#[macro_use]
extern crate serde_derive;

use std::fs;

mod func_section;
mod header;
mod import_section;
mod type_section;

use func_section::FuncSection;
use header::Header;
use import_section::ImportSection;
use type_section::{FuncType, PrimitiveType, TypeSection};

fn main() {
    println!("Psyche compiler 0.1.0");

    let header: Header = Default::default();
    let mut type_section: TypeSection = Default::default();
    let import_section: ImportSection = Default::default();
    let func_section: FuncSection = Default::default();

    // type[0] (i32, i64) -> [f64]
    let i = type_section.add_type(FuncType {
        params: vec![PrimitiveType::I32, PrimitiveType::I64],
        result: Some(PrimitiveType::F64),
    });
    println!("(1) function index: {}", i);

    // type[1] (f32, i32) -> nil
    let i = type_section.add_type(FuncType {
        params: vec![PrimitiveType::F32, PrimitiveType::I32],
        result: None,
    });
    println!("(2) function index: {}", i);

    // shoud be ignored
    let i = type_section.add_type(FuncType {
        params: vec![PrimitiveType::I32, PrimitiveType::I64],
        result: Some(PrimitiveType::F64),
    });
    println!("(3) function index: {}", i);

    let mut encoded_header = bincode::serialize(&header).unwrap();
    let mut encoded_type_section = type_section.serialize();
    let mut encoded_import_section = bincode::serialize(&import_section).unwrap();
    let mut encoded_func_section = func_section.serialize();

    encoded_header.append(&mut encoded_type_section);
    encoded_header.append(&mut encoded_import_section);
    encoded_header.append(&mut encoded_func_section);

    fs::write("out.wasm", encoded_header).unwrap_or_else(|_| panic!("Failed to write .wasm file"));
}
