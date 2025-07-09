# Overview
INFT (Intelligent NFT) is a next-generation Web3 protocol that transforms static NFTs into intelligent and interactive assets by integrating AI and blockchain. Unlike traditional NFTs, INFTs continuously learn, interact, and evolve based on user engagement. These NFTs go beyond digital collectibles and function as digital identities, interaction records, credit profiles, and more.

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
