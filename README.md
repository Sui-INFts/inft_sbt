# Overview
INFT (Intelligent NFT) is a next-generation Web3 protocol that transforms static NFTs into intelligent and interactive assets by integrating AI and blockchain. Unlike traditional NFTs, INFTs continuously learn, interact, and evolve based on user engagement. These NFTs go beyond digital collectibles and function as digital identities, interaction records, credit profiles, and more.

#### [Demo](https://www.infts.xyz/) | [Pitchdeck](https://www.figma.com/deck/WW9MfEyJ1nFPlyKZBWvTNM) | [Demovideo]() | [iO AI Model](https://github.com/Sui-INFts/inft_sbt/blob/main/README.md#how-is-the-io-ai-model-utilized)

## Background
As of mid-2025, the cryptocurrency industry is rapidly evolving and becoming more institutionalized:
- **Circle IPO**: Circle, the issuer of USDC, became the first crypto-native company to go public on NASDAQ in June 2025. Its stock surged over 70–80%, signaling strong investor confidence.
- **Regulatory Progress**: Approvals for Ethereum, Solana, and Ripple ETFs are increasingly likely, and stablecoin regulations are advancing rapidly.
- **Web2 × Web3 Convergence**: Stablecoins like USDC and USDT are being adopted in real-world finance (e.g., real estate, vehicles), leading to a demand for reliable on-chain identity and credit systems.
- **Infrastructure Boom**: Exchanges like Coinbase are offering developer SDKs for fiat on/off-ramps, and DeFi services are focusing on making crypto lending more accessible and regulated.

## Problem
* Traditional finance uses KYC, employment, income, and documentation to assess creditworthiness.
* DeFi is **pseudonymous** and **permissionless**, making it difficult to assess trust and credit.
* As **stablecoins** are adopted in real-world finance (real estate, car loans, commerce),
  there is an urgent need for **on-chain credit systems**.
* Without credit scoring, DeFi lending either requires overcollateralization or remains inaccessible to many users.

## Existing Solution
* **[3Jane](https://www.3jane.xyz/)**: Partners with banks to offer undercollateralized loans using traditional credit scores.
* **[Cred Protocol](https://www.credprotocol.com/)**: Assigns decentralized credit scores based on wallet transaction history.
* These are early examples of bridging **Web2 credit logic** into the **Web3 ecosystem**.

## Solution
* INFT issues **Soulbound Tokens (SBTs)** linked to user wallets.
* These tokens evolve by tracking:
  * **On-chain transaction history**
  * **AI-monitored tasks and engagement** (e.g., quiz completion, platform usage)
* Credit tiers are automatically assigned and updated via **smart contracts**.
* APIs enable **DeFi protocols** to access encrypted, real-time, and verifiable credit profiles.

## How to work
![image](https://github.com/user-attachments/assets/9f519cad-b293-42b5-ac78-06c91f691d6c)

### Flow Summary

- **User Interaction**
  - The user interacts with the platform or an AI model (e.g., iO model).
  - This interaction can include various activities like chatting, task completion, or payments.

- **Relayer Generates Interaction Score**
  - The relayer analyzes the user’s activity and produces key metrics such as credit scores and behavioral history.

- **Data Stored in Metadata**
  - The generated credit score and other status information are embedded into the INFT’s metadata.
  - Metadata may include:
    - Interaction count
    - Latest credit score
    - Quest or task completion history
    - Evolution state (Level, Stage, etc.)
    - Timestamp and activity logs

- **Metadata Encryption and Storage**
  - Sensitive information is encrypted using the Seal protocol and securely stored in Walrus (decentralized storage).

- **Reflected on Smart Contract**
  - Updating the metadata automatically updates the INFT state, which is recorded on-chain via smart contracts.
  - In essence, a change in metadata = a change in the INFT.

- **Results**
  - Users can view their real-time credit tier, evolution status, and more through a dashboard.
  - External services (e.g., DeFi lending platforms) can verify and utilize the INFT status via API access.

## Credit Rating System Overview

The INFT credit rating system is designed to generate trustworthy credit scores based on users’ on-chain activity and engagement within the platform. Without requiring centralized KYC (Know Your Customer) processes, the system analyzes digital wallet behavior and platform interactions to assign automated credit scores and tiers. This enhances access to financial services while maintaining a secure and transparent evaluation mechanism.

## How Is the Credit Score Generated?

The INFT protocol periodically collects on-chain transaction data from the Sui blockchain. For example, it monitors how frequently a user sends USDC, to which addresses, how much, and how quickly loans are repaid. This is combined with engagement data such as quizzes, daily check-ins, and referral activities performed on the INFT platform. Additionally, credit-specific SBTs (Soulbound Tokens) are minted to track loan agreements and repayment history.

All of this data is linked to a user's wallet address and encrypted to prevent unauthorized identification or manipulation. The data is analyzed in real time, and scores are updated daily or according to a user-defined schedule.

## How Is the iO AI Model Utilized?
| [Code #1](https://github.com/Sui-INFts/infts_client/tree/main/app/io) | [Code #2](https://github.com/Sui-INFts/infts_client/tree/main/app/api/chat) | [Code #3](https://github.com/Sui-INFts/infts_client/tree/main/hooks)

The **iO AI model** is the core engine that processes and analyzes all collected data to calculate a final credit score. It does this by evaluating three main categories:

1. **Transaction Behavior Analysis (60%)**

   * Measures frequency of payments, transaction volume, and repayment timeliness.
   * Users with stable, consistent financial behavior receive higher scores.

2. **Engagement Behavior Analysis (20%)**

   * Awards points for actions such as quiz participation, login streaks, and referrals.
   * Encourages the development of healthy financial habits.

3. **Credit History Analysis (20%)**

   * Tracks repayment success and delays via credit-specific SBTs.
   * This score reflects the user’s trustworthiness based on past borrowing behavior.

All analysis results are irreversibly encrypted and stored in Walrus storage.
The result is then referenced in the metadata URI of the user’s INFT SBT.
As the credit score and tier update, the associated SBT metadata is also automatically updated and reflected on-chain.

### Credit Score Calculation Formula

$$
\text{Credit Score} = (0.6 \times T_s) + (0.2 \times E_s) + (0.2 \times C_s)
$$

Where:
* $T_s$ = Transaction Score (0–600 points)
* $E_s$ = Engagement Score (0–200 points)
* $C_s$ = Credit History Score (0–200 points)

**Total Range: 0–1000**


## Key Benefits of INFT

| Users (B2C)                             | Developers & Protocols (B2B)                         |
| --------------------------------------- | ---------------------------------------------------- |
| Build a **Web3-native credit ID**       | Plug-and-play **credit scoring API**                 |
| No KYC or paperwork required            | Data is private, encrypted, and compliant            |
| Earn higher lending limits via activity | Unlock new use cases for undercollateralized lending |
| Maintain ownership and control          | Reduce risk with dynamic credit insights             |

## Why Now?

* **June 2025**: Circle became the first crypto-native IPO on NASDAQ (↑70–80% stock growth).
* **ETFs** for ETH, SOL, XRP are nearing approval in the U.S.
* **Stablecoin legislation** is progressing globally.
* **DeFi is maturing**, but needs **identity and trust frameworks** to grow.
* INFT offers that missing **on-chain identity + credit infrastructure** for the next phase of crypto adoption.

INFT SBT Smart Contract

-Mint INFT SBT (Primary Profile)
-Mint Credit-Specific INFT SBT
-Update Credit Score
-Query Credit Tier
