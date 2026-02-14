use sha2::{Digest, Sha256};

pub fn hash_string(input: &str) -> String {
    hash_bytes(input.as_bytes())
}

pub fn hash_bytes(input: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input);
    hex::encode(hasher.finalize())
}

pub fn hash_strings(parts: &[String]) -> String {
    hash_string(&parts.join("\n\n"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn returns_consistent_sha256_hex() {
        let result = hash_string("hello");
        assert_eq!(
            result,
            "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        );
    }

    #[test]
    fn different_inputs_produce_different_hashes() {
        assert_ne!(hash_string("a"), hash_string("b"));
    }

    #[test]
    fn joins_with_double_newline_before_hashing() {
        let result = hash_strings(&["a".to_string(), "b".to_string()]);
        assert_eq!(result, hash_string("a\n\nb"));
    }

    #[test]
    fn single_item_is_same_as_hash_string() {
        assert_eq!(hash_strings(&["hello".to_string()]), hash_string("hello"));
    }
}
