pub struct TypeSection {
    types: Vec<FuncType>,
}

impl TypeSection {
    pub fn add_type(&mut self, func_type: &FuncType) -> u8 {
        if let Some(i) = self.types.iter().position(|x| *x == *func_type) {
            i as u8
        } else {
            self.types.push(func_type.clone());
            (self.types.len() - 1) as u8
        }
    }

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

impl Default for TypeSection {
    fn default() -> Self {
        TypeSection { types: Vec::new() }
    }
}

#[derive(Clone, PartialEq)]
pub struct FuncType {
    pub params: Vec<PrimitiveType>,
    pub result: Option<PrimitiveType>,
}

#[derive(Clone, Copy, PartialEq)]
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

#[cfg(test)]
mod test {
    use super::{FuncType, PrimitiveType, TypeSection};

    #[test]
    fn it_works() {
        let mut section: TypeSection = Default::default();
        let func_type_0 = FuncType {
            params: vec![PrimitiveType::I32, PrimitiveType::I64],
            result: Some(PrimitiveType::F64),
        };
        let func_type_1 = FuncType {
            params: vec![PrimitiveType::F32, PrimitiveType::I32],
            result: None,
        };
        assert_eq!(section.add_type(&func_type_0), 0);
        assert_eq!(section.add_type(&func_type_1), 1);
        assert_eq!(section.add_type(&func_type_0), 0);
    }
}
