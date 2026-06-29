use nam_tiny_hderive::bip32::ExtendedPrivKey;
use qp_poseidon_core::{hash_bytes, hash_to_bytes, serialization::bytes_to_digest};
use qp_rusty_crystals_dilithium::ml_dsa_87;
use qp_rusty_crystals_hdwallet::{derive_key_from_mnemonic, derive_wormhole_from_mnemonic, mnemonic_to_seed, SensitiveBytes32, SensitiveBytes64};
pub use qp_rusty_crystals_hdwallet::HDLatticeError;
use sp_core::crypto::{AccountId32, Ss58Codec};
use std::convert::AsRef;

type MlDsaKeypair = ml_dsa_87::Keypair;

#[flutter_rust_bridge::frb(sync)]
pub fn set_default_ss58_prefix(prefix: u16) {
    sp_core::crypto::set_default_ss58_version(sp_core::crypto::Ss58AddressFormat::custom(prefix));
}

#[flutter_rust_bridge::frb(sync)]
pub struct Keypair {
    pub public_key: Vec<u8>,
    pub secret_key: Vec<u8>,
}

impl Keypair {
    fn from_ml_dsa(ml_dsa_keypair: MlDsaKeypair) -> Self {
        Keypair {
            public_key: ml_dsa_keypair.public.to_bytes().to_vec(),
            secret_key: ml_dsa_keypair.secret.to_bytes().to_vec(),
        }
    }

    fn to_ml_dsa(&self) -> MlDsaKeypair {
        MlDsaKeypair {
            secret: ml_dsa_87::SecretKey::from_bytes(&self.secret_key)
                .expect("Failed to parse secret key"),
            public: ml_dsa_87::PublicKey::from_bytes(&self.public_key)
                .expect("Failed to parse public key"),
        }
    }
}

/// Convert public key to accountId32 in ss58check format
#[flutter_rust_bridge::frb(sync)]
pub fn to_account_id(obj: &Keypair) -> String {
    let hashed = hash_bytes(obj.public_key.as_slice());
    let account = AccountId32::new(hashed);
    account.to_ss58check()
}
/// Convert key in ss58check format to accountId32
/// 
/// Validates that the address uses the expected SS58 prefix set via set_default_ss58_prefix.
/// Returns an error if the prefix doesn't match or the address is invalid.
#[flutter_rust_bridge::frb(sync)]
pub fn ss58_to_account_id(s: &str) -> Result<Vec<u8>, String> {
    // Parse the address with the expected prefix validation
    let (account, format) = AccountId32::from_ss58check_with_version(s)
        .map_err(|e| format!("Invalid SS58 address: {:?}", e))?;
    
    // Get the expected prefix from the global default
    let expected_format = sp_core::crypto::default_ss58_version();
    
    // Validate that the address prefix matches our expected network prefix
    if format != expected_format {
        return Err(format!(
            "Address has incorrect network prefix. Expected prefix {}, got prefix {}. This address may be for a different network.",
            u16::from(expected_format),
            u16::from(format)
        ));
    }
    
    Ok(AsRef::<[u8]>::as_ref(&account).to_vec())
}

#[flutter_rust_bridge::frb(sync)]
pub fn generate_keypair(mnemonic_str: String) -> Keypair {
    let mut seed64 = mnemonic_to_seed(mnemonic_str, None).expect("Failed to convert mnemonic to seed");
    let mut seed_for_pair = [0u8; 32];
    seed_for_pair.copy_from_slice(&seed64[..32]);
    let _ = SensitiveBytes64::from(&mut seed64);
    let ml_dsa_keypair = MlDsaKeypair::generate(SensitiveBytes32::new(&mut seed_for_pair));
    Keypair::from_ml_dsa(ml_dsa_keypair)
}

#[flutter_rust_bridge::frb(sync)]
pub fn generate_derived_keypair(mnemonic_str: String, path: &str) -> Result<Keypair, HDLatticeError> {
    derive_key_from_mnemonic(&mnemonic_str, None, path).map(Keypair::from_ml_dsa)
}

#[flutter_rust_bridge::frb(sync)]
pub struct WormholeResult {
    pub address: String,
    pub first_hash: Vec<u8>,
    pub secret: Vec<u8>,
}

#[flutter_rust_bridge::frb(sync)]
pub fn derive_wormhole(mnemonic_str: String, path: &str) -> Result<WormholeResult, HDLatticeError> {
    let pair = derive_wormhole_from_mnemonic(&mnemonic_str, None, path)?;
    let account = AccountId32::new(pair.address);
    Ok(WormholeResult {
        address: account.to_ss58check(),
        first_hash: pair.first_hash.to_vec(),
        secret: pair.secret.to_vec(),
    })
}

/// Convert a first_hash (rewards preimage) to its corresponding wormhole address.
///
/// Mirrors how the chain and ZK circuit derive the address from the preimage:
/// - Convert 32 bytes → 4 Poseidon field elements (8 bytes each)
/// - Hash once without padding
#[flutter_rust_bridge::frb(sync)]
pub fn first_hash_to_address(first_hash_hex: String) -> Result<String, String> {
    let hex_str = first_hash_hex.trim_start_matches("0x");
    let first_hash_bytes: [u8; 32] = hex::decode(hex_str)
        .map_err(|e| format!("Invalid hex string: {}", e))?
        .try_into()
        .map_err(|_| "First hash must be exactly 32 bytes".to_string())?;

    let first_hash_felts: [_; 4] = bytes_to_digest(&first_hash_bytes);
    let address_bytes = hash_to_bytes(&first_hash_felts);

    let account = AccountId32::from(address_bytes);
    Ok(account.to_ss58check())
}

#[flutter_rust_bridge::frb(sync)]
pub fn generate_keypair_from_seed(seed: Vec<u8>) -> Keypair {
    let mut seed_array: [u8; 32] = seed.try_into().expect("Seed must be 32 bytes");
    let ml_dsa_keypair = MlDsaKeypair::generate(SensitiveBytes32::new(&mut seed_array));
    Keypair::from_ml_dsa(ml_dsa_keypair)
}

#[flutter_rust_bridge::frb(sync)]
pub fn sign_message(keypair: &Keypair, message: &[u8], entropy: Option<[u8; 32]>) -> Vec<u8> {
    let ml_dsa_keypair = keypair.to_ml_dsa();
    let signature = ml_dsa_keypair.sign(message, None, entropy)
        .expect("Signing failed");
    signature.to_vec()
}

#[flutter_rust_bridge::frb(sync)]
pub fn sign_message_with_pubkey(keypair: &Keypair, message: &[u8], entropy: Option<[u8; 32]>) -> Vec<u8> {
    let signature = sign_message(keypair, message, entropy);
    let mut result = Vec::with_capacity(signature.len() + keypair.public_key.len());
    result.extend_from_slice(&signature);
    result.extend_from_slice(&keypair.public_key);
    result
}

#[flutter_rust_bridge::frb(sync)]
pub fn verify_message(keypair: &Keypair, message: &[u8], signature: &[u8]) -> bool {
    let ml_dsa_keypair = keypair.to_ml_dsa();
    ml_dsa_keypair.verify(&message, &signature, None)
}

#[flutter_rust_bridge::frb(sync)]
pub fn crystal_alice() -> Keypair {
    generate_keypair_from_seed(vec![0; 32])
}

#[flutter_rust_bridge::frb(sync)]
pub fn crystal_bob() -> Keypair {
    generate_keypair_from_seed(vec![1; 32])
}

#[flutter_rust_bridge::frb(sync)]
pub fn crystal_charlie() -> Keypair {
    generate_keypair_from_seed(vec![2; 32])
}

#[flutter_rust_bridge::frb(sync)]
pub fn derive_hd_path(seed: Vec<u8>, path: String) -> Vec<u8> {
    let seed = seed.as_slice();
    let path = path.as_str();
    let ext = ExtendedPrivKey::derive(seed, path).expect("Failed to derive HD path");
    return ext.secret().to_vec();
}

#[flutter_rust_bridge::frb(sync)]
pub fn public_key_bytes() -> usize {
    ml_dsa_87::PUBLICKEYBYTES
}

#[flutter_rust_bridge::frb(sync)]
pub fn secret_key_bytes() -> usize {
    ml_dsa_87::SECRETKEYBYTES
}

#[flutter_rust_bridge::frb(sync)]
pub fn signature_bytes() -> usize {
    ml_dsa_87::SIGNBYTES
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sign_and_verify() {
        // Test with a simple message
        let message = b"Hello, World!";
        let keypair = crystal_alice();

        // Sign the message
        let signature = sign_message(&keypair, message, None);

        // Verify the signature
        let is_valid = verify_message(&keypair, message, &signature);
        assert!(is_valid, "Signature verification failed");
    }

    #[test]
    fn test_sign_and_verify_with_different_keypair() {
        // Test with a simple message
        let message = b"Hello, World!";
        let keypair = crystal_alice();

        // Sign the message
        let signature = sign_message(&keypair, message, None);

        // Try to verify with a different keypair
        let different_keypair = crystal_bob();
        let is_valid = verify_message(&different_keypair, message, &signature);
        assert!(
            !is_valid,
            "Signature should not be valid with different keypair"
        );
    }

    #[test]
    fn test_sign_and_verify_with_empty_message() {
        // Test with an empty message
        let message = b"";
        let keypair = crystal_alice();

        // Sign the message
        let signature = sign_message(&keypair, message, None);

        // Verify the signature
        let is_valid = verify_message(&keypair, message, &signature);
        assert!(is_valid, "Signature verification failed for empty message");
    }

    #[test]
    fn test_sign_and_verify_with_long_message() {
        // Test with a longer message
        let message = b"This is a longer message that should also work correctly with our signing and verification process.";
        let keypair = crystal_alice();

        // Sign the message
        let signature = sign_message(&keypair, message, None);

        // Verify the signature
        let is_valid = verify_message(&keypair, message, &signature);
        assert!(is_valid, "Signature verification failed for long message");
    }

    #[test]
    fn test_ss58_prefix_validation_accepts_matching_prefix() {
        // This test verifies that addresses with the CURRENT expected prefix are accepted.
        // Due to global state, we read what prefix is currently set rather than set our own.
        let current_format = sp_core::crypto::default_ss58_version();
        let prefix = u16::from(current_format);
        
        // Generate a valid address for the current prefix using Alice's account bytes
        let alice_bytes: [u8; 32] = [
            0xd4, 0x35, 0x93, 0xc7, 0x15, 0xfd, 0xd3, 0x1c,
            0x61, 0x14, 0x1a, 0xbd, 0x04, 0xa9, 0x9f, 0xd6,
            0x82, 0x2c, 0x85, 0x58, 0x85, 0x4c, 0xcd, 0xe3,
            0x9a, 0x56, 0x84, 0xe7, 0xa5, 0x6d, 0xa2, 0x7d,
        ];
        let account = AccountId32::new(alice_bytes);
        let address = account.to_ss58check_with_version(current_format);
        
        // Should succeed because prefix matches
        let result = ss58_to_account_id(&address);
        assert!(result.is_ok(), "Should accept address with correct prefix ({}): {:?}", prefix, result.err());
        assert_eq!(result.unwrap().len(), 32);
    }

    #[test]
    fn test_ss58_prefix_validation_rejects_different_prefix() {
        // Generate an address with a DIFFERENT prefix than the expected one
        let current_format = sp_core::crypto::default_ss58_version();
        let current_prefix = u16::from(current_format);
        
        // Use a different prefix
        let different_prefix = if current_prefix == 42 { 0 } else { 42 };
        let different_format = sp_core::crypto::Ss58AddressFormat::custom(different_prefix);
        
        // Generate address with the different prefix
        let alice_bytes: [u8; 32] = [
            0xd4, 0x35, 0x93, 0xc7, 0x15, 0xfd, 0xd3, 0x1c,
            0x61, 0x14, 0x1a, 0xbd, 0x04, 0xa9, 0x9f, 0xd6,
            0x82, 0x2c, 0x85, 0x58, 0x85, 0x4c, 0xcd, 0xe3,
            0x9a, 0x56, 0x84, 0xe7, 0xa5, 0x6d, 0xa2, 0x7d,
        ];
        let account = AccountId32::new(alice_bytes);
        let wrong_prefix_address = account.to_ss58check_with_version(different_format);
        
        // Should fail because prefix doesn't match
        let result = ss58_to_account_id(&wrong_prefix_address);
        assert!(result.is_err(), "Should reject address with wrong prefix");
        let err = result.unwrap_err();
        assert!(err.contains("incorrect network prefix"), "Error should mention prefix mismatch: {}", err);
    }

    #[test]
    fn test_ss58_rejects_invalid_address() {
        set_default_ss58_prefix(189);
        
        // Invalid address
        let invalid_address = "not-a-valid-address";
        
        let result = ss58_to_account_id(invalid_address);
        assert!(result.is_err(), "Should reject invalid address");
    }
}
