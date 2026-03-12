#[derive(Debug, Clone)]
pub struct FrbError {
    pub message: String,
}

impl FrbError {
    pub fn new(message: impl Into<String>) -> Self {
        Self {
            message: message.into(),
        }
    }
}

impl std::fmt::Display for FrbError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl std::error::Error for FrbError {}

impl From<anyhow::Error> for FrbError {
    fn from(value: anyhow::Error) -> Self {
        Self::new(value.to_string())
    }
}

impl From<String> for FrbError {
    fn from(value: String) -> Self {
        Self::new(value)
    }
}

impl From<&str> for FrbError {
    fn from(value: &str) -> Self {
        Self::new(value)
    }
}
