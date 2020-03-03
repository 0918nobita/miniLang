#[derive(Serialize)]
pub struct TypeSection {
    section_code: u8,
    section_size: u8, // (bytes)
    num_types: u8,
}

impl Default for TypeSection {
    fn default() -> Self {
        TypeSection {
            section_code: 1,
            section_size: 1,
            num_types: 0,
        }
    }
}
