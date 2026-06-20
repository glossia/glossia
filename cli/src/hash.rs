use serde::Serialize;
use sha2::{Digest, Sha256};

pub fn hash_string(input: &str) -> String {
    hash_bytes(input.as_bytes())
}

pub fn hash_bytes(input: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input);
    format!("{:x}", hasher.finalize())
}

pub fn hash_json<T: Serialize>(value: &T) -> String {
    let encoded = serde_json::to_vec(value).expect("json serialization should not fail");
    hash_bytes(&encoded)
}

#[cfg_attr(not(test), allow(dead_code))]
pub fn hash_strings(parts: &[String]) -> String {
    if parts.is_empty() {
        return hash_string("");
    }
    hash_string(&parts.join("\n\n"))
}

#[cfg(test)]
mod tests {
    use super::{hash_json, hash_string, hash_strings};
    use serde::Serialize;

    #[test]
    fn stable_sha256() {
        assert_eq!(
            hash_string("hello"),
            "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        );
    }

    #[test]
    fn joins_with_blank_line() {
        assert_eq!(
            hash_strings(&["a".into(), "b".into()]),
            hash_string("a\n\nb")
        );
    }

    #[test]
    fn hashes_json_stably() {
        #[derive(Serialize)]
        struct Example<'a> {
            alpha: &'a str,
            beta: &'a str,
        }

        assert_eq!(
            hash_json(&Example {
                alpha: "one",
                beta: "two",
            }),
            hash_json(&Example {
                alpha: "one",
                beta: "two",
            })
        );
    }
}
