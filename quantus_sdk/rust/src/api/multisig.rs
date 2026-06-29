use parity_scale_codec::{Decode, Encode};
use sp_core::crypto::{AccountId32, Ss58Codec};
use sp_runtime::traits::{BlakeTwo256, Hash as HashT, TrailingZeroInput};

const PALLET_ID: [u8; 8] = *b"py/mltsg";
const SS58_PREFIX: u16 = 189;
const MAX_SIGNERS: usize = 100;
const MIN_SIGNERS: usize = 2;

fn derive_multisig_address(
    signers: Vec<AccountId32>,
    threshold: u32,
    nonce: u64,
) -> AccountId32 {
    let mut sorted_signers = signers;
    sorted_signers.sort();
    sorted_signers.dedup();

    let mut data = Vec::new();
    data.extend_from_slice(&PALLET_ID);
    data.extend_from_slice(&sorted_signers.encode());
    data.extend_from_slice(&threshold.encode());
    data.extend_from_slice(&nonce.encode());

    let hash = BlakeTwo256::hash(&data);
    AccountId32::decode(&mut TrailingZeroInput::new(hash.as_ref()))
        .expect("TrailingZeroInput provides sufficient bytes; qed")
}

/// Predicts the on-chain multisig address for the given signers, threshold, and nonce.
///
/// Address is computed as: hash(pallet_id || sorted_signers || threshold || nonce)
#[flutter_rust_bridge::frb(sync)]
pub fn predict_multisig_address(
    signers: Vec<String>,
    threshold: u32,
    nonce: u64,
) -> Result<String, String> {
    // Early validation before parsing addresses
    if signers.len() < MIN_SIGNERS {
        return Err(format!("At least {MIN_SIGNERS} unique signers are required"));
    }
    if signers.len() > MAX_SIGNERS {
        return Err(format!("At most {MAX_SIGNERS} signers are allowed"));
    }

    let account_ids: Vec<AccountId32> = signers
        .iter()
        .map(|s| {
            AccountId32::from_ss58check(s)
                .map_err(|e| format!("Invalid SS58 address '{s}': {e}"))
        })
        .collect::<Result<_, _>>()?;

    // Canonicalize and validate uniqueness
    let mut canonical_signers = account_ids;
    canonical_signers.sort();
    canonical_signers.dedup();

    if canonical_signers.len() < MIN_SIGNERS {
        return Err(format!("At least {MIN_SIGNERS} unique signers are required"));
    }
    if canonical_signers.len() != signers.len() {
        return Err("Duplicate signers are not allowed".to_string());
    }

    // Validate threshold
    if threshold == 0 {
        return Err("Threshold must be greater than zero".to_string());
    }
    if threshold as usize > canonical_signers.len() {
        return Err(format!(
            "Threshold must be between 1 and {}",
            canonical_signers.len()
        ));
    }

    let account_id = derive_multisig_address(canonical_signers, threshold, nonce);
    Ok(account_id.to_ss58check_with_version(sp_core::crypto::Ss58AddressFormat::custom(
        SS58_PREFIX,
    )))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn predict_multisig_address_is_order_independent() {
        let signer_a = "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY";
        let signer_b = "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty";

        let forward = predict_multisig_address(
            vec![signer_a.to_string(), signer_b.to_string()],
            2,
            0,
        )
        .expect("forward prediction should succeed");
        let reverse = predict_multisig_address(
            vec![signer_b.to_string(), signer_a.to_string()],
            2,
            0,
        )
        .expect("reverse prediction should succeed");

        assert_eq!(forward, reverse);
    }

    #[test]
    fn predict_multisig_address_golden_vector() {
        let address = predict_multisig_address(
            vec![
                "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY".to_string(),
                "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty".to_string(),
            ],
            2,
            0,
        )
        .expect("golden vector prediction should succeed");

        assert_eq!(
            address,
            "qzkvQ2YBa7RrvYKNCXxJw7hJZPBSi6GzZxXGN2fN6DddaH5HJ"
        );
    }

    #[test]
    fn predict_multisig_address_rejects_invalid_ss58() {
        let result = predict_multisig_address(
            vec!["not-an-address".to_string(), "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty".to_string()],
            1,
            0,
        );
        assert!(result.is_err());
    }

    #[test]
    fn predict_multisig_address_rejects_single_signer() {
        let result = predict_multisig_address(
            vec!["5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY".to_string()],
            1,
            0,
        );
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("At least 2 unique signers"));
    }

    #[test]
    fn predict_multisig_address_rejects_duplicate_signers() {
        let signer_a = "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY";
        let signer_b = "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty";

        let result = predict_multisig_address(
            vec![signer_a.to_string(), signer_b.to_string(), signer_b.to_string()],
            2,
            0,
        );
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Duplicate signers"));
    }

    #[test]
    fn predict_multisig_address_rejects_zero_threshold() {
        let signer_a = "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY";
        let signer_b = "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty";

        let result = predict_multisig_address(
            vec![signer_a.to_string(), signer_b.to_string()],
            0,
            0,
        );
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Threshold must be greater than zero"));
    }

    #[test]
    fn predict_multisig_address_rejects_threshold_exceeding_signers() {
        let signer_a = "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY";
        let signer_b = "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty";

        let result = predict_multisig_address(
            vec![signer_a.to_string(), signer_b.to_string()],
            3,
            0,
        );
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Threshold must be between"));
    }
}
