/// UR API for parsing QR codes in the ur:.. standard
///
use quantus_ur::{decode, encode, is_complete};
use hex;

// Note decode_ur takes the list of QR Codes in any order and assembles them correctly. 
// It also deals with the weird elements that are created in the UR standard when we exceed the number 
// of segments. 
// For example if you have 3 segments, and the scanner scans all 3 but doesn't succeed, subsequent parts 
// are sent with strange numbers like /412-3/ which are encoded with pieces of the previous segments so that
// the algorithm recovers faster than just repeating the segments over and over. This is described in the UR 
// standard. FYI. 
#[flutter_rust_bridge::frb(sync)]
pub fn decode_ur(ur_parts: Vec<String>) -> Result<Vec<u8>, String> {
    let decoded_hex = decode(&ur_parts).map_err(|e| e.to_string())?;
    let decoded_bytes = hex::decode(decoded_hex).map_err(|e| format!("Failed to decode hex: {}", e))?;
    Ok(decoded_bytes)
}

#[flutter_rust_bridge::frb(sync)]
pub fn encode_ur(data: Vec<u8>) -> Result<Vec<String>, String> {
    let hex_data = hex::encode(data);
    encode(&hex_data).map_err(|e| e.to_string())
}

#[flutter_rust_bridge::frb(sync)]
pub fn is_complete_ur(ur_parts: Vec<String>) -> bool {
    is_complete(&ur_parts)
}
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_single_part_roundtrip() {
        // Small payload that fits in 200 bytes
        let hex_payload = "0200007416854906f03a9dff66e3270a736c44e15970ac03a638471523a03069f276ca0700e876481755010000007400000002000000";
        
        let encoded_parts = encode(hex_payload).expect("Encoding failed");
        assert_eq!(encoded_parts.len(), 1, "Should be single part");
        
        let decoded_hex = decode(&encoded_parts).expect("Decoding failed");
        assert_eq!(decoded_hex.to_lowercase(), hex_payload.to_lowercase());
    }

    #[test]
    fn test_multi_part_roundtrip() {
        let large_hex_payload = "0200007416854906f03a9dff66e3270a736c44e15970ac03a638471523a03069f276ca0700e876481755010000007400000002000000".repeat(10);
        
        let encoded_parts = encode(&large_hex_payload).expect("Encoding failed");
        assert!(encoded_parts.len() > 1, "Should be multiple parts");
        
        let decoded_hex = decode(&encoded_parts).expect("Decoding failed");
        assert_eq!(decoded_hex.to_lowercase(), large_hex_payload.to_lowercase());
    }

    #[test]
    fn test_is_complete_single_part() {
        let hex_payload = "0200007416854906f03a9dff66e3270a736c44e15970ac03a638471523a03069f276ca0700e876481755010000007400000002000000";
        let encoded_parts = encode(hex_payload).expect("Encoding failed");
        
        assert!(is_complete_ur(encoded_parts), "Single part should be complete");
    }

    #[test]
    fn test_is_complete_multi_part_complete() {
        let large_hex_payload = "0200007416854906f03a9dff66e3270a736c44e15970ac03a638471523a03069f276ca0700e876481755010000007400000002000000".repeat(10);
        let encoded_parts = encode(&large_hex_payload).expect("Encoding failed");
        
        assert!(is_complete_ur(encoded_parts), "All parts should be complete");
    }

    #[test]
    fn test_is_complete_multi_part_incomplete() {
        let large_hex_payload = "0200007416854906f03a9dff66e3270a736c44e15970ac03a638471523a03069f276ca0700e876481755010000007400000002000000".repeat(10);
        let encoded_parts = encode(&large_hex_payload).expect("Encoding failed");
        
        assert!(encoded_parts.len() > 1, "Should have multiple parts");
        
        let incomplete_parts = vec![encoded_parts[0].clone()];
        assert!(!is_complete_ur(incomplete_parts), "Incomplete parts should return false");
    }

    #[test]
    fn test_multi_part_out_of_order() {
        let large_hex_payload = "0200007416854906f03a9dff66e3270a736c44e15970ac03a638471523a03069f276ca0700e876481755010000007400000002000000".repeat(10);
        let encoded_parts = encode(&large_hex_payload).expect("Encoding failed");
        
        assert!(encoded_parts.len() > 1, "Should be multiple parts");
        
        let mut scrambled_parts = encoded_parts.clone();
        scrambled_parts.reverse();
        let mid = scrambled_parts.len() / 2;
        scrambled_parts.swap(0, mid);
        
        let decoded_hex = decode(&scrambled_parts).expect("Decoding failed");
        assert_eq!(decoded_hex.to_lowercase(), large_hex_payload.to_lowercase(), "Decoding should work regardless of part order");
        
        assert!(is_complete_ur(scrambled_parts), "Scrambled parts should still be complete");
    }

}
