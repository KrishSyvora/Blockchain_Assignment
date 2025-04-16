# 🗳️ Simple DAO Governance System (Compound-Inspired)

This is a smart contract system implementing a simplified DAO governance mechanism inspired by Compound Protocol. It includes proposal creation, voting, queuing via Timelock, and execution of governance decisions.

## 📁 Contracts Overview

### `GovToken.sol`
- ERC20-based governance token with vote delegation and checkpointing.
- Uses `getPastVotes()` for snapshot-based voting.

### `Governor.sol`
- Manages proposals and voting lifecycle.
- Handles:
  - Proposal creation (`propose`)
  - Voting (`vote`)
  - Queuing via Timelock (`queue`)
  - Execution of successful proposals (`execute`)
  
### `MyTimelock.sol`
- Custom Compound-style timelock.
- Enforces a delay between proposal queuing and execution.

