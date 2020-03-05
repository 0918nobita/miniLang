extern crate bincode;
extern crate serde;
#[macro_use]
extern crate serde_derive;

use std::fs;

mod code_section;
mod func_section;
mod header;
mod import_section;
mod type_section;

use code_section::CodeSection;
use func_section::FuncSection;
use header::Header;
use import_section::{ImportContent, ImportKind, ImportSection};
use type_section::{FuncType, PrimitiveType, TypeSection};

fn main() {
    println!("Psyche compiler 0.1.0");

    let header: Header = Default::default();
    let mut type_section: TypeSection = Default::default();
    let mut import_section: ImportSection = Default::default();
    let func_section: FuncSection = Default::default();
    let code_section: CodeSection = Default::default();

    let signature_index = type_section.add_type(&FuncType {
        params: vec![
            PrimitiveType::I32,
            PrimitiveType::I32,
            PrimitiveType::I32,
            PrimitiveType::I32,
        ],
        result: Some(PrimitiveType::I32),
    });

    import_section.imports.push(ImportContent {
        module: String::from("wasi_unstable"),
        field: String::from("fd_write"),
        kind: ImportKind::Function,
        signature_index,
    });

    let mut encoded_header = bincode::serialize(&header).unwrap();
    let mut encoded_type_section = type_section.serialize();
    let mut encoded_import_section = import_section.serialize();
    let mut encoded_func_section = func_section.serialize();
    let mut encoded_code_section = code_section.serialize();

    encoded_header.append(&mut encoded_type_section);
    encoded_header.append(&mut encoded_import_section);
    encoded_header.append(&mut encoded_func_section);
    encoded_header.append(&mut encoded_code_section);

    fs::write("out.wasm", encoded_header).unwrap_or_else(|_| panic!("Failed to write .wasm file"));
}
