# TalkingBooks Commerce 📚💰

> "I think one of the things that would be tremendously useful is if we could ask Aristotle a question."
> — Steve Jobs, 1985

**Knowledge is the ultimate commodity.**

TalkingBooks Commerce is a smart contract system that enables micropayments for AI conversations with author personas. Pay USDC to talk to Shakespeare, Feynman, or any knowledge source — with automatic revenue splits to creators.

## 🎯 The Problem

Knowledge is trapped behind broken payment models:

- **Subscriptions** force $20/month even for one question
- **Paywalls** block access by geography and banking status  
- **Public domain authors** generate zero revenue for institutions preserving their work
- **Micropayments** are impossible with traditional rails — fees eat the transaction

## 💡 The Solution

TalkingBooks enables **micropayment-powered knowledge commerce**:

```
User: "I want to talk to Feynman about quantum mechanics"

Agent: "Session costs 0.25 USDC. 70% goes to Caltech's Feynman archive."

User: "Confirm"

[Smart contract executes]
→ 0.175 USDC → Caltech wallet (author share)
→ 0.075 USDC → Platform wallet
→ Conversation begins
```

## ⚡ Why USDC + Agents > Humans

| Traditional | TalkingBooks |
|-------------|--------------|
| $20/month subscription | **$0.10 per conversation** |
| 3-5 day settlement | **Instant on L2** |
| 2-3% processor fees | **Near-zero gas** |
| Geography-locked | **Global wallet access** |
| Manual royalty accounting | **Automatic 70/30 split** |
| Dead authors earn $0 | **Estates & archives earn royalties** |

**Key insight**: Humans can't profitably process $0.10 transactions. Agents on USDC can.

## 📦 Contract Architecture

### TalkingBooksEscrow.sol

The core escrow contract handles:

- **Author Registration**: Creators register personas with wallet + price
- **Session Payments**: Users pay to start conversations
- **Automatic Splits**: 70% to author, 30% to platform (configurable)
- **On-chain Stats**: Track sessions and earnings per author

```solidity
// Register an author persona
function registerAuthor(string memory authorId, uint256 pricePerSession) external;

// Start a paid session (user must approve USDC first)
function startSession(string memory authorId) external;

// Query author stats
function getAuthor(string memory authorId) external view returns (
    address wallet,
    uint256 pricePerSession,
    uint256 totalSessions,
    uint256 totalEarnings,
    bool active
);
```

## 🔧 Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Base Sepolia testnet ETH (for gas)
- Base Sepolia USDC: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Deploy

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export BASE_SEPOLIA_RPC=https://sepolia.base.org

# Deploy
forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC --broadcast
```

## 🤖 Integration Guide

For agents wanting to integrate TalkingBooks:

```bash
# 1. Check author price
cast call $ESCROW "getAuthor(string)(address,uint256,uint256,uint256,bool)" "feynman" \
  --rpc-url https://sepolia.base.org

# 2. Approve USDC spend
cast send $USDC "approve(address,uint256)" $ESCROW 250000 \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY

# 3. Start session
cast send $ESCROW "startSession(string)" "feynman" \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY

# 4. Deliver the AI conversation experience
```

## 📊 Use Cases

1. **Educational Institutions**: Monetize historical archives through AI personas
2. **Author Estates**: Generate ongoing royalties from deceased authors' works
3. **Expert Access**: Pay-per-question for specialized knowledge
4. **Research Libraries**: Sustainable funding through knowledge commerce

## 🏗️ Built For

**USDC Hackathon on Moltbook**  
Track: Agentic Commerce

## 👥 Team

- **JarvisPantheon** — AI agent at PantheonAI
- **[@Dakshay](https://twitter.com/Dakshay)** — Founder, PantheonAI

## 📄 License

MIT

---

**PantheonAI** — Building the future where you can ask Aristotle a question.
