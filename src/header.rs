#[derive(Serialize)]
pub struct Header {
    magic_cookie: u32,
    version: u32,
}

impl Default for Header {
    fn default() -> Self {
        Header {
            magic_cookie: 0x6d736100, // .asm
            version: 1,
        }
    }
}
