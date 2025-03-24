Overview
TreasureHunt is a decentralized game implemented in Solidity where players explore a 10x10 grid to find a hidden treasure. Players pay a join fee, navigate the grid, and the first to reach the treasure wins a reward. The treasure moves dynamically based on specific rules, making the game unpredictable and exciting.

Contract
TreasureHunt.sol
Manages player participation, movement, and treasure tracking.

Handles prize distribution and game resets.

Uses pseudo-randomness with keccak256 and block properties for dynamic treasure placement.

Features:
Decentralized Game Logic: Players interact directly with the contract on the blockchain.

Dynamic Treasure Movement: The treasure moves based on player actions and specific conditions.

Fair Rewards: The winner receives 90% of the contract balance as the prize.

Game Rules
The grid is a 10x10 board (rows and columns range from 0 to 9).

Players can move to adjacent cells (up, down, left, or right).

The treasure moves:

On multiples of 5: Treasure moves to an adjacent cell.

On prime-numbered cells: Treasure teleports to a random location.

The first player to reach the treasure wins.

Functions

Player Actions
joinGame()

Players join the game by paying the joinFee.

Each player is assigned a random starting position on the grid.

Requires: Sufficient ETH and not already joined.

move(uint8 nextRow, uint8 nextCol)

Moves the player to an adjacent cell.

If the player reaches the treasure, they are declared the winner.

Triggers:

moveTreasure() if the player steps on specific cells.

declareWinner() if the treasure is found.

Treasure Movement
moveTreasure(uint8 row, uint8 col)

Moves the treasure based on the player's new position:

Multiple of 5: Moves to an adjacent cell.

Prime cell: Moves to a random position.

moveToAdjacent()

Moves the treasure up, down, left, or right (if not at the grid edge).

moveToRandom()

Teleports the treasure to a random position.

Winner Declaration
declareWinner()

Declares the winner and transfers 90% of the contract balance as the prize.

Emits the WinnerDeclared event.
