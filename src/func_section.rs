pub struct FuncSection {
    section_code: u8,
    section_size: u8, // (bytes)
    num_functions: u8,
    func_signatures: Box<[u8]>,
}

impl Default for FuncSection {
    fn default() -> Self {
        FuncSection {
            section_code: 3,
            section_size: 1,
            num_functions: 0,
            func_signatures: Box::new([]),
        }
    }
}

impl FuncSection {
    pub fn serialize(&self) -> Vec<u8> {
        let mut serialized = Vec::new();
        serialized.push(self.section_code);
        serialized.push(self.section_size);
        serialized.push(self.num_functions);
        for element in self.func_signatures.iter() {
            serialized.push(*element);
        }
        serialized
    }
}
