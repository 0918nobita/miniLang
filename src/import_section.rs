pub struct ImportSection {
    pub imports: Vec<ImportContent>,
}

impl ImportSection {
    pub fn serialize(&self) -> Vec<u8> {
        let mut serialized = vec![
            2,                        // section code
            1,                        // section size (guess)
            self.imports.len() as u8, // num imports
        ];

        for elem in self.imports.iter() {
            serialized.push(elem.module.len() as u8);
            serialized.extend_from_slice(elem.module.as_bytes());
            serialized.push(elem.field.len() as u8);
            serialized.extend_from_slice(elem.field.as_bytes());
            serialized.push(elem.kind.into());
            serialized.push(elem.signature_index);
        }

        serialized[1] = serialized.len() as u8 - 2;

        serialized
    }
}

impl Default for ImportSection {
    fn default() -> Self {
        ImportSection {
            imports: Vec::new(),
        }
    }
}

pub struct ImportContent {
    pub module: String,
    pub field: String,
    pub kind: ImportKind,
    pub signature_index: u8,
}

#[derive(Clone, Copy)]
pub enum ImportKind {
    Function,
}

impl Into<u8> for ImportKind {
    fn into(self) -> u8 {
        match self {
            ImportKind::Function => 0,
        }
    }
}
