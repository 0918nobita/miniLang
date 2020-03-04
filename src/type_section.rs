pub struct TypeSection {
    pub types: Vec<FuncType>,
}

impl Default for TypeSection {
    fn default() -> Self {
        TypeSection { types: Vec::new() }
    }
}

pub struct FuncType {
    pub params: Vec<PrimitiveType>,
    pub result: Option<PrimitiveType>,
}

#[derive(Clone, Copy)]
pub enum PrimitiveType {
    I32,
    I64,
    F32,
    F64,
}

impl Into<u8> for PrimitiveType {
    fn into(self) -> u8 {
        match self {
            PrimitiveType::I32 => 0x7f,
            PrimitiveType::I64 => 0x7e,
            PrimitiveType::F32 => 0x7d,
            PrimitiveType::F64 => 0x7c,
        }
    }
}

impl TypeSection {
    pub fn serialize(&self) -> Vec<u8> {
        let mut serialized: Vec<u8> = vec![
            1,                      // section code
            1,                      // section size (guess)
            self.types.len() as u8, // num types
        ];

        for func_type in self.types.iter() {
            serialized.push(0x60); // func
            serialized.push(func_type.params.len() as u8); // num params

            for t in func_type.params.iter() {
                let t: u8 = (*t as PrimitiveType).into();
                serialized.push(t);
            }

            if let Some(result_type) = func_type.result {
                serialized.push(1); // num results
                serialized.push(result_type.into());
            } else {
                serialized.push(0); // num results
            }
        }

        serialized[1] = serialized.len() as u8 - 2; // FIXUP section size

        serialized
    }
}
