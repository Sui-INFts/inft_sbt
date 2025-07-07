// Copyright (c) Inft protocol.
/// Module: inft_sbt
module inft_sbt::inft_sbt {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::display;
    use sui::package;
    use std::string::{Self, String};
    use sui::address;

    // Error codes
    const ENotAuthorized: u64 = 0;
    const EInvalidTierChangeTime: u64 = 1;
    const EInvalidCreditScore: u64 = 2;

    // One Time Witness for the package
    public struct INFT_SBT has drop {}

    // Capability for admin to manage the oracle
    public struct AdminCap has key, store {
        id: UID
    }

    // Oracle for credit score updates (default settings)
    public struct CreditOracle has key {
        id: UID,
        // Default update interval in seconds (e.g., 1 day = 86400 seconds)
        update_interval: u64,
        // Admin address for oracle updates
        admin: address
    }

    // Primary INFT SBT representing the user’s credit profile
    public struct InftSbt has key, store {
        id: UID,
        // Current credit tier (0 = Level 1, 1 = Level 2, etc.)
        current_tier: u8,
        // Credit score (0-1000)
        credit_score: u64,
        // Metadata URI for off-chain data (stored in Walrus)
        metadata_uri: String,
        // Timestamp of last update
        last_updated: u64,
        // Update interval for this SBT (in seconds)
        update_interval: u64,
        // Owner address (non-transferable)
        owner: address
    }

    // Credit-specific INFT SBT for individual loan agreements
    public struct CreditInftSbt has key, store {
        id: UID,
        // Parent INFT SBT ID
        parent_id: address,
        // Loan amount (in SUI or stablecoin units)
        loan_amount: u64,
        // Repayment terms (e.g., due date in timestamp)
        repayment_terms: u64,
        // Metadata URI for loan details (stored in Walrus)
        metadata_uri: String,
        // Owner address (non-transferable)
        owner: address
    }

    // Event emitted when credit tier changes
    public struct TierChangeEvent has copy, drop {
        sbt_id: address,
        new_tier: u8,
        new_score: u64,
        timestamp: u64
    }

    // Event emitted when a credit-specific INFT SBT is minted
    public struct CreditSbtMintedEvent has copy, drop {
        sbt_id: address,
        parent_id: address,
        loan_amount: u64,
        timestamp: u64
    }

    // Event emitted when update interval changes
    public struct UpdateIntervalEvent has copy, drop {
        sbt_id: address,
        new_interval: u64,
        timestamp: u64
    }

    // ===== Module Initialization =====

    fun init(otw: INFT_SBT, ctx: &mut TxContext) {
        // Create and share the CreditOracle
        let oracle = CreditOracle {
            id: object::new(ctx),
            update_interval: 86400, // 1 day in seconds (default)
            admin: tx_context::sender(ctx)
        };
        transfer::share_object(oracle);

        // Create and transfer the admin capability to the deployer
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };
        transfer::transfer(admin_cap, tx_context::sender(ctx));

        // Setup the Publisher for the display
        let publisher = package::claim(otw, ctx);

        // Setup display for the primary INFT SBT
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"description"),
            string::utf8(b"metadata_uri"),
            string::utf8(b"credit_score"),
            string::utf8(b"credit_tier"),
            string::utf8(b"update_interval"),
        ];

        let values = vector[
            string::utf8(b"INFT SBT"),
            string::utf8(b"Soulbound token for credit profile"),
            string::utf8(b"{metadata_uri}"),
            string::utf8(b"{credit_score}"),
            string::utf8(b"{current_tier}"),
            string::utf8(b"{update_interval}"),
        ];

        let mut display = display::new_with_fields<InftSbt>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);
        transfer::public_transfer(display, tx_context::sender(ctx));
        transfer::public_transfer(publisher, tx_context::sender(ctx));
    }

    // ===== Entry Functions =====

    //  Mint a primary INFT SBT for a user’s credit profile
    public entry fun mint_primary_sbt(
        metadata_uri: vector<u8>,
        oracle: &CreditOracle,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let sbt = InftSbt {
            id: object::new(ctx),
            current_tier: 0, // Start at Level 1
            credit_score: 0, // Initial score
            metadata_uri: string::utf8(metadata_uri), // Walrus blob ID
            last_updated: clock::timestamp_ms(clock),
            update_interval: oracle.update_interval,
            owner: sender
        };

        // Enforce non-transferability by transferring to sender only
        transfer::transfer(sbt, sender);
    }

    /// Mint a credit-specific INFT SBT for a loan agreement
    public entry fun mint_credit_sbt(
        parent_sbt: &InftSbt,
        loan_amount: u64,
        repayment_terms: u64,
        metadata_uri: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        // Ensure the parent SBT belongs to the sender
        assert!(parent_sbt.owner == sender, ENotAuthorized);

        let credit_sbt = CreditInftSbt {
            id: object::new(ctx),
            parent_id: object::id_address(parent_sbt),
            loan_amount,
            repayment_terms,
            metadata_uri: string::utf8(metadata_uri), // Walrus blob ID
            owner: sender
        };

        // Emit event for credit SBT minting
        event::emit(CreditSbtMintedEvent {
            sbt_id: object::id_address(&credit_sbt),
            parent_id: object::id_address(parent_sbt),
            loan_amount,
            timestamp: clock::timestamp_ms(clock)
        });

        // Enforce non-transferability
        transfer::transfer(credit_sbt, sender);
    }

    /// Update credit score and tier based on off-chain AI model output
    public entry fun update_credit_score(
        sbt: &mut InftSbt,
        new_score: u64,
        oracle: &CreditOracle,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Only admin (oracle admin) can update the score
        assert!(tx_context::sender(ctx) == oracle.admin, ENotAuthorized);

        // Validate score (0-1000)
        assert!(new_score <= 1000, EInvalidCreditScore);

        let current_time = clock::timestamp_ms(clock);
        // Check if enough time has passed since last update
        assert!(current_time >= sbt.last_updated + (sbt.update_interval * 1000), EInvalidTierChangeTime);

        // Update score
        sbt.credit_score = new_score;

        // Update tier based on score
        let new_tier = if (new_score <= 200) { 0 } // Level 1: $50 loan
                      else if (new_score <= 400) { 1 } // Level 2: $200 loan
                      else if (new_score <= 600) { 2 } // Level 3: $500 loan
                      else if (new_score <= 800) { 3 } // Level 4: $1000 loan
                      else { 4 }; // Level 5: $2000 loan

        // Update tier if changed
        if (sbt.current_tier != new_tier) {
            sbt.current_tier = new_tier;
            sbt.last_updated = current_time;

            // Emit event for tier change
            event::emit(TierChangeEvent {
                sbt_id: object::id_address(sbt),
                new_tier,
                new_score,
                timestamp: current_time
            });
        };
    }

    /// Admin can change the default update interval for new SBTs
    public entry fun change_default_interval(
        _: &AdminCap,
        oracle: &mut CreditOracle,
        new_interval: u64,
        _ctx: &mut TxContext
    ) {
        oracle.update_interval = new_interval;
    }

    /// Owner can change their SBT’s update interval
    public entry fun change_sbt_interval(
        sbt: &mut InftSbt,
        new_interval: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Only the owner can change the interval
        assert!(tx_context::sender(ctx) == sbt.owner, ENotAuthorized);

        // Update the interval
        sbt.update_interval = new_interval;

        // Emit event for the interval change
        event::emit(UpdateIntervalEvent {
            sbt_id: object::id_address(sbt),
            new_interval,
            timestamp: clock::timestamp_ms(clock)
        });
    }

    // ===== View Functions =====

    /// Get the current credit tier
    public fun get_credit_tier(sbt: &InftSbt): u8 {
        sbt.current_tier
    }

    /// Get the current credit score
    public fun get_credit_score(sbt: &InftSbt): u64 {
        sbt.credit_score
    }

    /// Get the metadata URI
    public fun get_metadata_uri(sbt: &InftSbt): String {
        sbt.metadata_uri
    }

    /// Check if the SBT is due for an update
    public fun is_update_due(sbt: &InftSbt, clock: &Clock): bool {
        let current_time = clock::timestamp_ms(clock);
        current_time >= sbt.last_updated + (sbt.update_interval * 1000)
    }

    /// Get the update interval for an SBT
    public fun get_update_interval(sbt: &InftSbt): u64 {
        sbt.update_interval
    }

    /// Get the default update interval from the oracle
    public fun get_default_interval(oracle: &CreditOracle): u64 {
        oracle.update_interval
    }

    /// Get the admin address from the oracle
    public fun get_admin(oracle: &CreditOracle): address {
        oracle.admin
    }

    /// Get the owner address from the SBT
    public fun get_owner(sbt: &InftSbt): address {
        sbt.owner
    }

    /// Get the loan amount from the credit SBT
    public fun get_loan_amount(credit_sbt: &CreditInftSbt): u64 {
        credit_sbt.loan_amount
    }

    /// Get the repayment terms from the credit SBT
    public fun get_repayment_terms(credit_sbt: &CreditInftSbt): u64 {
        credit_sbt.repayment_terms
    }

    /// Get the metadata URI from the credit SBT
    public fun get_credit_metadata_uri(credit_sbt: &CreditInftSbt): String {
        credit_sbt.metadata_uri
    }

    /// Get the owner address from the credit SBT
    public fun get_credit_owner(credit_sbt: &CreditInftSbt): address {
        credit_sbt.owner
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        let otw = INFT_SBT {};
        init(otw, ctx);
    }
}
