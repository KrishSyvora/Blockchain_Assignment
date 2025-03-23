# BingoGame Smart Contract

## Overview
BingoGame is a decentralized bingo game implemented in Solidity. Players can join games, pay an entry fee, and compete to win the pot. The game follows standard Bingo rules with random number draws and board tracking.

## Contracts
### 1. `BingoGame.sol`
- Manages game creation, player participation, and number drawing.
- Handles prize distribution and game resets.

### 2. `BingoBoard.sol`
- Generates Bingo boards for players.
- Tracks marked numbers and determines winners.

### 3. `BingoToken.sol`
- ERC-20 token used as in-game currency.

## Features
- **Decentralized**: Runs on Ethereum-compatible networks.
- **Fair Number Draws**: Uses blockhash for pseudo-randomness.
- **Automated Prize Distribution**: Rewards winners with the game pot.
- **Customizable Settings**: Admin can adjust entry fees and durations.
