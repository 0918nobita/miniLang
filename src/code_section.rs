use crate::type_section::PrimitiveType;

pub struct CodeSection {
    functions: Vec<FuncDef>,
}

impl CodeSection {
    pub fn serialize(&self) -> Vec<u8> {
        let serialized = vec![
            0x0a,                       // section code
            1,                          // section size (guess)
            self.functions.len() as u8, // num functions
        ];

        // work in progress

        serialized
    }
}

impl Default for CodeSection {
    fn default() -> Self {
        CodeSection {
            functions: Vec::new(),
        }
    }
}

pub struct FuncDef {
    locals: Vec<PrimitiveType>,
    insts: Vec<Instruction>,
}

pub enum Instruction {
    GetLocal(u32),
    I32Const(u32),
    I32Store,
    SetLocal(u32),
}
