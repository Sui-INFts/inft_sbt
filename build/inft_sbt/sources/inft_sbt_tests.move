#[test_only]
module inft_sbt::inft_sbt_tests {
    use inft_sbt::inft_sbt::{Self, InftSbt, CreditInftSbt, CreditOracle, AdminCap};
    use sui::test_scenario::{Self, Scenario};
    use sui::clock::{Self, Clock};
    use std::string;

    // Test addresses
    const ADMIN: address = @0xAD;
    const USER1: address = @0xA1;
    const USER2: address = @0xA2;
    const UNAUTHORIZED: address = @0xBAD;

    // Test constants
    const INITIAL_CREDIT_SCORE: u64 = 150;
    const UPDATED_CREDIT_SCORE: u64 = 350;
    const MAX_CREDIT_SCORE: u64 = 1000;
    const INVALID_CREDIT_SCORE: u64 = 1001;
    const DEFAULT_UPDATE_INTERVAL: u64 = 86400; // 1 day in seconds
    const CUSTOM_UPDATE_INTERVAL: u64 = 43200; // 12 hours in seconds
    const LOAN_AMOUNT: u64 = 500;
    const REPAYMENT_TERMS: u64 = 1704067200; // Example timestamp

    // Helper function to initialize the test scenario
    fun init_test_scenario(): Scenario {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            inft_sbt::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        scenario
    }

    // Helper function to create a clock for testing
    fun create_test_clock(scenario: &mut Scenario): Clock {
        clock::create_for_testing(test_scenario::ctx(scenario))
    }

    #[test]
    fun test_init_contract() {
        let mut scenario = init_test_scenario();
        
        // Check that CreditOracle was created and shared
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            assert!(inft_sbt::get_default_interval(&oracle) == DEFAULT_UPDATE_INTERVAL, 0);
            assert!(inft_sbt::get_admin(&oracle) == ADMIN, 1);
            test_scenario::return_shared(oracle);
        };

        // Check that AdminCap was created and sent to deployer
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            test_scenario::return_to_sender(&scenario, admin_cap);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_mint_primary_sbt() {
        let mut scenario = init_test_scenario();
        let clock = create_test_clock(&mut scenario);

        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://example-blob-id";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Check that the SBT was minted correctly
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let sbt = test_scenario::take_from_sender<InftSbt>(&scenario);
            
            assert!(inft_sbt::get_credit_tier(&sbt) == 0, 0); // Level 1
            assert!(inft_sbt::get_credit_score(&sbt) == 0, 1); // Initial score
            assert!(inft_sbt::get_metadata_uri(&sbt) == string::utf8(b"walrus://example-blob-id"), 2);
            assert!(inft_sbt::get_owner(&sbt) == USER1, 3);
            assert!(inft_sbt::get_update_interval(&sbt) == DEFAULT_UPDATE_INTERVAL, 4);
            
            test_scenario::return_to_sender(&scenario, sbt);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_mint_credit_sbt() {
        let mut scenario = init_test_scenario();
        let clock = create_test_clock(&mut scenario);

        // First mint a primary SBT
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Then mint a credit SBT
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let primary_sbt = test_scenario::take_from_sender<InftSbt>(&scenario);
            let credit_metadata_uri = b"walrus://credit-sbt";
            
            inft_sbt::mint_credit_sbt(
                &primary_sbt,
                LOAN_AMOUNT,
                REPAYMENT_TERMS,
                credit_metadata_uri,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_to_sender(&scenario, primary_sbt);
        };

        // Check that the credit SBT was minted correctly
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let credit_sbt = test_scenario::take_from_sender<CreditInftSbt>(&scenario);
            
            assert!(inft_sbt::get_loan_amount(&credit_sbt) == LOAN_AMOUNT, 0);
            assert!(inft_sbt::get_repayment_terms(&credit_sbt) == REPAYMENT_TERMS, 1);
            assert!(inft_sbt::get_credit_metadata_uri(&credit_sbt) == string::utf8(b"walrus://credit-sbt"), 2);
            assert!(inft_sbt::get_credit_owner(&credit_sbt) == USER1, 3);
            
            test_scenario::return_to_sender(&scenario, credit_sbt);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)] // ENotAuthorized
    fun test_mint_credit_sbt_unauthorized() {
        let mut scenario = init_test_scenario();
        let clock = create_test_clock(&mut scenario);

        // Mint primary SBT for USER1
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Try to mint credit SBT as USER2 using USER1's primary SBT (should fail)
        test_scenario::next_tx(&mut scenario, USER2);
        {
            let primary_sbt = test_scenario::take_from_address<InftSbt>(&scenario, USER1);
            let credit_metadata_uri = b"walrus://credit-sbt";
            
            inft_sbt::mint_credit_sbt(
                &primary_sbt,
                LOAN_AMOUNT,
                REPAYMENT_TERMS,
                credit_metadata_uri,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_to_sender(&scenario, primary_sbt);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_credit_score_and_tier() {
        let mut scenario = init_test_scenario();
        let mut clock = create_test_clock(&mut scenario);

        // Mint primary SBT
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Advance time to allow update
        clock::increment_for_testing(&mut clock, DEFAULT_UPDATE_INTERVAL * 1000 + 1);

        // Update credit score as admin
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let mut sbt = test_scenario::take_from_address<InftSbt>(&scenario, USER1);
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            
            assert!(inft_sbt::is_update_due(&sbt, &clock), 0);
            
            inft_sbt::update_credit_score(
                &mut sbt,
                UPDATED_CREDIT_SCORE,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            // Check that score and tier were updated
            assert!(inft_sbt::get_credit_score(&sbt) == UPDATED_CREDIT_SCORE, 1);
            assert!(inft_sbt::get_credit_tier(&sbt) == 1, 2); // Level 2 (score 350)
            
            test_scenario::return_to_sender(&scenario, sbt);
            test_scenario::return_shared(oracle);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_tier_levels() {
        let mut scenario = init_test_scenario();
        let mut clock = create_test_clock(&mut scenario);

        // Mint primary SBT
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Test different tier levels
        let test_scores = vector[150, 350, 550, 750, 950]; // Scores for tiers 0-4
        let expected_tiers = vector[0, 1, 2, 3, 4]; // Expected tiers

        let mut i = 0;
        while (i < std::vector::length(&test_scores)) {
            // Advance time to allow update
            clock::increment_for_testing(&mut clock, DEFAULT_UPDATE_INTERVAL * 1000 + 1);

            test_scenario::next_tx(&mut scenario, ADMIN);
            {
                let mut sbt = test_scenario::take_from_address<InftSbt>(&scenario, USER1);
                let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
                
                let score = *std::vector::borrow(&test_scores, i);
                let expected_tier = *std::vector::borrow(&expected_tiers, i);
                
                inft_sbt::update_credit_score(
                    &mut sbt,
                    score,
                    &oracle,
                    &clock,
                    test_scenario::ctx(&mut scenario)
                );
                
                assert!(inft_sbt::get_credit_score(&sbt) == score, i);
                assert!(inft_sbt::get_credit_tier(&sbt) == expected_tier, i + 100);
                
                test_scenario::return_to_sender(&scenario, sbt);
                test_scenario::return_shared(oracle);
            };
            
            i = i + 1;
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)] // ENotAuthorized
    fun test_update_credit_score_unauthorized() {
        let mut scenario = init_test_scenario();
        let mut clock = create_test_clock(&mut scenario);

        // Mint primary SBT
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Advance time to allow update
        clock::increment_for_testing(&mut clock, DEFAULT_UPDATE_INTERVAL * 1000 + 1);

        // Try to update as unauthorized user (should fail)
        test_scenario::next_tx(&mut scenario, UNAUTHORIZED);
        {
            let mut sbt = test_scenario::take_from_address<InftSbt>(&scenario, USER1);
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            
            inft_sbt::update_credit_score(
                &mut sbt,
                UPDATED_CREDIT_SCORE,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_to_sender(&scenario, sbt);
            test_scenario::return_shared(oracle);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)] // EInvalidTierChangeTime
    fun test_update_credit_score_too_early() {
        let mut scenario = init_test_scenario();
        let clock = create_test_clock(&mut scenario);

        // Mint primary SBT
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Try to update immediately (should fail)
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let mut sbt = test_scenario::take_from_address<InftSbt>(&scenario, USER1);
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            
            inft_sbt::update_credit_score(
                &mut sbt,
                UPDATED_CREDIT_SCORE,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_to_sender(&scenario, sbt);
            test_scenario::return_shared(oracle);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)] // EInvalidCreditScore
    fun test_update_credit_score_invalid_score() {
        let mut scenario = init_test_scenario();
        let mut clock = create_test_clock(&mut scenario);

        // Mint primary SBT
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Advance time to allow update
        clock::increment_for_testing(&mut clock, DEFAULT_UPDATE_INTERVAL * 1000 + 1);

        // Try to update with invalid score (should fail)
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let mut sbt = test_scenario::take_from_address<InftSbt>(&scenario, USER1);
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            
            inft_sbt::update_credit_score(
                &mut sbt,
                INVALID_CREDIT_SCORE,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_to_sender(&scenario, sbt);
            test_scenario::return_shared(oracle);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_change_default_interval() {
        let mut scenario = init_test_scenario();

        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            let mut oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            
            inft_sbt::change_default_interval(
                &admin_cap,
                &mut oracle,
                CUSTOM_UPDATE_INTERVAL,
                test_scenario::ctx(&mut scenario)
            );
            
            assert!(inft_sbt::get_default_interval(&oracle) == CUSTOM_UPDATE_INTERVAL, 0);
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(oracle);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_change_sbt_interval() {
        let mut scenario = init_test_scenario();
        let clock = create_test_clock(&mut scenario);

        // Mint primary SBT
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Change SBT interval
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let mut sbt = test_scenario::take_from_sender<InftSbt>(&scenario);
            
            inft_sbt::change_sbt_interval(
                &mut sbt,
                CUSTOM_UPDATE_INTERVAL,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            assert!(inft_sbt::get_update_interval(&sbt) == CUSTOM_UPDATE_INTERVAL, 0);
            
            test_scenario::return_to_sender(&scenario, sbt);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)] // ENotAuthorized
    fun test_change_sbt_interval_unauthorized() {
        let mut scenario = init_test_scenario();
        let clock = create_test_clock(&mut scenario);

        // Mint primary SBT for USER1
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Try to change interval as USER2 (should fail)
        test_scenario::next_tx(&mut scenario, USER2);
        {
            let mut sbt = test_scenario::take_from_address<InftSbt>(&scenario, USER1);
            
            inft_sbt::change_sbt_interval(
                &mut sbt,
                CUSTOM_UPDATE_INTERVAL,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_to_sender(&scenario, sbt);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_is_update_due() {
        let mut scenario = init_test_scenario();
        let mut clock = create_test_clock(&mut scenario);

        // Mint primary SBT
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Check that update is not due immediately
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let sbt = test_scenario::take_from_sender<InftSbt>(&scenario);
            
            assert!(!inft_sbt::is_update_due(&sbt, &clock), 0);
            
            test_scenario::return_to_sender(&scenario, sbt);
        };

        // Advance time and check that update is due
        clock::increment_for_testing(&mut clock, DEFAULT_UPDATE_INTERVAL * 1000 + 1);
        
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let sbt = test_scenario::take_from_sender<InftSbt>(&scenario);
            
            assert!(inft_sbt::is_update_due(&sbt, &clock), 1);
            
            test_scenario::return_to_sender(&scenario, sbt);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_view_functions() {
        let mut scenario = init_test_scenario();
        let clock = create_test_clock(&mut scenario);

        // Mint primary SBT
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            let metadata_uri = b"walrus://primary-sbt";
            
            inft_sbt::mint_primary_sbt(
                metadata_uri,
                &oracle,
                &clock,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(oracle);
        };

        // Test all view functions
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let sbt = test_scenario::take_from_sender<InftSbt>(&scenario);
            let oracle = test_scenario::take_shared<CreditOracle>(&scenario);
            
            // Test SBT view functions
            assert!(inft_sbt::get_credit_tier(&sbt) == 0, 0);
            assert!(inft_sbt::get_credit_score(&sbt) == 0, 1);
            assert!(inft_sbt::get_metadata_uri(&sbt) == string::utf8(b"walrus://primary-sbt"), 2);
            assert!(inft_sbt::get_owner(&sbt) == USER1, 3);
            assert!(inft_sbt::get_update_interval(&sbt) == DEFAULT_UPDATE_INTERVAL, 4);
            
            // Test oracle view functions
            assert!(inft_sbt::get_default_interval(&oracle) == DEFAULT_UPDATE_INTERVAL, 5);
            assert!(inft_sbt::get_admin(&oracle) == ADMIN, 6);
            
            test_scenario::return_to_sender(&scenario, sbt);
            test_scenario::return_shared(oracle);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}