#[derive(Serialize)]
pub struct ImportSection {
    section_code: u8,
    section_size: u8, // (bytes)
    num_imports: u8,
}

impl Default for ImportSection {
    fn default() -> Self {
        ImportSection {
            section_code: 2,
            section_size: 1,
            num_imports: 0,
        }
    }
}
