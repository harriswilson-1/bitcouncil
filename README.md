# BitCouncil - Decentralized Autonomous Organization Protocol

[![Clarity](https://img.shields.io/badge/Clarity-3.0-blue.svg)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Stacks-Bitcoin%20L2-orange.svg)](https://stacks.co/)
[![License](https://img.shields.io/badge/License-ISC-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Vitest-yellow.svg)](https://vitest.dev/)

## Overview

BitCouncil is a sophisticated Bitcoin-native DAO framework built on Stacks that revolutionizes decentralized governance through advanced voting mechanisms, transparent fund management, and innovative return distribution systems powered by Bitcoin's security model.

This comprehensive protocol enables communities to create, manage, and execute collective decisions while maintaining full transparency and democratic participation. Built specifically for the Bitcoin ecosystem, BitCouncil bridges traditional organizational structures with cutting-edge blockchain technology.

## 🚀 Key Features

- **Advanced Proposal Lifecycle Management** - Customizable voting periods with comprehensive validation
- **Delegation System** - Representative democracy enabling vote delegation with expiry controls
- **Automated Return Distribution** - Investment tracking with proportional return sharing
- **Emergency Governance Controls** - Crisis management with emergency administrator roles
- **Configurable Parameters** - Flexible governance settings for organizational needs
- **Bitcoin-Secured Voting** - Leveraging Bitcoin's security through Stacks smart contracts
- **Multi-tiered Authorization** - Enhanced security with role-based access control

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Installation](#-installation)
- [Usage](#-usage)
- [Smart Contract API](#-smart-contract-api)
- [Governance Parameters](#-governance-parameters)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Security Considerations](#-security-considerations)
- [Contributing](#-contributing)

## 🏗 Architecture

BitCouncil follows a modular architecture with the following core components:

```
BitCouncil Protocol
├── Governance Core
│   ├── Proposal Management
│   ├── Voting System
│   └── Parameter Configuration
├── Delegation System
│   ├── Vote Delegation
│   ├── Delegation Tracking
│   └── Expiry Management
├── Return Distribution
│   ├── Investment Pools
│   ├── Claim Processing
│   └── Proportional Sharing
└── Emergency Controls
    ├── Emergency State
    ├── Admin Management
    └── Crisis Response
```

### Data Structures

#### Members

```clarity
{
  voting-power: uint,
  joined-block: uint,
  total-contributed: uint,
  last-withdrawal: uint,
}
```

#### Proposals

```clarity
{
  id: uint,
  proposer: principal,
  title: (string-ascii 100),
  description: (string-utf8 1000),
  amount: uint,
  target: principal,
  start-block: uint,
  end-block: uint,
  yes-votes: uint,
  no-votes: uint,
  status: (string-ascii 20),
  executed: bool,
}
```

#### Return Pools

```clarity
{
  total-amount: uint,
  distributed-amount: uint,
  distribution-start: uint,
  distribution-end: uint,
  claims: (list 200 principal),
}
```

## 🛠 Installation

### Prerequisites

- [Clarinet CLI](https://docs.hiro.so/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+
- [Stacks Wallet](https://www.hiro.so/wallet) for testing

### Setup

1. **Clone the repository**

```bash
git clone https://github.com/harriswilson-1/bitcouncil.git
cd bitcouncil
```

2. **Install dependencies**

```bash
npm install
```

3. **Initialize Clarinet**

```bash
clarinet check
```

## 📖 Usage

### Basic DAO Operations

#### 1. Create a Proposal

```clarity
(contract-call? .bitcouncil create-proposal
  "Treasury Allocation"
  u"Allocate 100 STX for community development initiatives"
  u100000000 ;; 100 STX in microSTX
  'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

#### 2. Delegate Voting Power

```clarity
(contract-call? .bitcouncil delegate-votes
  'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC ;; delegate address
  u50000000 ;; 50 voting power
  u1000) ;; expiry block
```

#### 3. Claim Investment Returns

```clarity
(contract-call? .bitcouncil claim-returns u1) ;; proposal-id
```

### Administrative Functions

#### Update Governance Parameters

```clarity
(contract-call? .bitcouncil update-dao-parameters {
  proposal-fee: u100000,
  min-proposal-amount: u1000000,
  max-proposal-amount: u1000000000,
  voting-delay: u100,
  voting-period: u144,
  timelock-period: u72,
  quorum-threshold: u500,
  super-majority: u667,
})
```

#### Emergency Controls

```clarity
;; Activate emergency state
(contract-call? .bitcouncil set-emergency-state true)

;; Add emergency administrator
(contract-call? .bitcouncil add-emergency-admin 'ST1EMERGENCY_ADMIN_ADDRESS)
```

## 📝 Smart Contract API

### Public Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `create-proposal` | Create new governance proposal | title, description, amount, target | `(response uint uint)` |
| `delegate-votes` | Delegate voting power to another member | delegate-to, amount, expiry | `(response bool uint)` |
| `claim-returns` | Claim proportional returns from investment | proposal-id | `(response bool uint)` |
| `set-emergency-state` | Toggle emergency governance state | state | `(response bool uint)` |
| `add-emergency-admin` | Add emergency administrator | admin | `(response bool uint)` |
| `update-dao-parameters` | Update governance parameters | new-params | `(response bool uint)` |
| `create-return-pool` | Create investment return pool | proposal-id, total-amount | `(response bool uint)` |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-member-info` | Retrieve member details | `(optional member-info)` |
| `get-proposal-by-id` | Get proposal information | `(optional proposal)` |
| `get-delegation` | Get delegation details | `(optional delegation)` |
| `get-return-pool` | Get return pool information | `(optional return-pool)` |
| `has-claimed` | Check if member claimed returns | `bool` |
| `is-emergency-admin` | Verify emergency admin status | `bool` |
| `get-dao-parameters` | Get current governance parameters | `(response parameters uint)` |
| `get-treasury-balance` | Get current treasury balance | `(response uint uint)` |

## ⚙️ Governance Parameters

BitCouncil uses configurable parameters for flexible governance:

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `proposal-fee` | 100,000 µSTX | Fee required to submit proposal |
| `min-proposal-amount` | 1,000,000 µSTX | Minimum proposal funding amount |
| `max-proposal-amount` | 1,000,000,000 µSTX | Maximum proposal funding amount |
| `voting-delay` | 100 blocks | Delay before voting starts |
| `voting-period` | 144 blocks | Duration of voting period (~1 day) |
| `timelock-period` | 72 blocks | Execution delay after passing (~12 hours) |
| `quorum-threshold` | 500 (50%) | Minimum participation requirement |
| `super-majority` | 667 (66.7%) | Required approval threshold |

## 🧪 Testing

The project includes comprehensive test coverage using Vitest and Clarinet SDK.

### Run Tests

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch

# Check contract syntax
clarinet check
```

### Test Structure

```
tests/
└── bitcouncil.test.ts       # Comprehensive test suite
    ├── Proposal Management
    ├── Voting Mechanisms
    ├── Delegation System
    ├── Return Distribution
    ├── Emergency Controls
    └── Parameter Updates
```

### Example Test

```typescript
import { describe, it, expect } from 'vitest';
import { Cl } from '@stacks/transactions';

describe('BitCouncil DAO', () => {
  it('should create proposal successfully', () => {
    const response = simnet.callPublicFn(
      'bitcouncil',
      'create-proposal',
      [
        Cl.stringAscii('Test Proposal'),
        Cl.stringUtf8('Test Description'),
        Cl.uint(1000000),
        Cl.principal('ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE')
      ],
      deployer
    );
    
    expect(response.result).toBeOk(Cl.uint(1));
  });
});
```

## 🚀 Deployment

### Local Deployment

1. **Start Clarinet Console**

```bash
clarinet console
```

2. **Deploy Contract**

```clarity
::deploy_contracts
```

3. **Interact with Contract**

```clarity
(contract-call? .bitcouncil get-dao-parameters)
```

### Testnet Deployment

1. **Configure Clarinet.toml**

```toml
[network.testnet]
stacks_node_rpc_address = "https://stacks-node-api.testnet.stacks.co"
deployment_fee_rate = 10
```

2. **Deploy to Testnet**

```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. **Security Audit** - Ensure comprehensive security review
2. **Parameter Validation** - Verify all governance parameters
3. **Multi-sig Setup** - Configure administrative controls
4. **Gradual Rollout** - Consider phased deployment approach

```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## 🔒 Security Considerations

### Access Control

- **Administrative Functions**: Restricted to DAO admin and emergency admins
- **Member Validation**: All operations require valid member status
- **Emergency Controls**: Multi-layered emergency response system

### Parameter Validation

- **Amount Limits**: Configurable min/max proposal amounts
- **Time Constraints**: Voting periods and delegation expiry
- **Quorum Requirements**: Minimum participation thresholds

### Best Practices

1. **Regular Security Audits**: Periodic contract reviews
2. **Parameter Updates**: Gradual changes through governance
3. **Emergency Procedures**: Clear crisis management protocols
4. **Member Education**: Training on delegation and voting

### Known Limitations

- Maximum 200 claimants per return pool
- Fixed string lengths for proposal titles/descriptions
- Block-based timing (subject to Bitcoin block time variations)

## 🤝 Contributing

We welcome contributions to BitCouncil! Please follow these guidelines:

### Development Process

1. **Fork the Repository**
2. **Create Feature Branch**

```bash
git checkout -b feature/your-feature-name
```

3. **Make Changes**
   - Follow Clarity best practices
   - Add comprehensive tests
   - Update documentation

4. **Test Thoroughly**

```bash
npm test
clarinet check
```

5. **Submit Pull Request**
   - Clear description of changes
   - Reference related issues
   - Include test coverage

### Code Standards

- **Clarity Style**: Follow official Clarity style guide
- **Documentation**: Comprehensive inline comments
- **Testing**: Minimum 90% test coverage
- **Security**: Security-first development approach

## 📄 License

This project is licensed under the ISC License. See [LICENSE](LICENSE) file for details.
