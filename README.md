# Blockchain Explorer Smart Contract

A comprehensive Clarity smart contract for indexing and querying blockchain data on the Stacks network. This contract provides a complete blockchain exploration solution with robust data management and query capabilities.

## Features

### 🔍 Core Functionality
- **Block Indexing**: Store and retrieve complete block metadata
- **Transaction Tracking**: Index transactions with detailed information
- **Address Analytics**: Track address statistics and transaction history
- **Bulk Operations**: Efficient batch processing of multiple transactions
- **Search Capabilities**: Find blocks by miner and query ranges

### 🛡️ Security & Administration
- Owner-only administrative functions
- Contract activation/deactivation controls
- Comprehensive input validation
- Duplicate prevention mechanisms
- Proper error handling with descriptive error codes

## Data Structures

### Block Information
```clarity
{
  block-hash: (buff 32),
  timestamp: uint,
  tx-count: uint,
  miner: principal,
  size: uint,
  indexed-at: uint
}
```

### Transaction Information
```clarity
{
  block-height: uint,
  sender: principal,
  recipient: (optional principal),
  amount: uint,
  fee: uint,
  status: (string-ascii 20),
  tx-type: (string-ascii 30)
}
```

### Address Statistics
```clarity
{
  tx-count: uint,
  total-sent: uint,
  total-received: uint,
  first-seen: uint,
  last-active: uint
}
```

## Public Functions

### Administrative Functions
- `index-block(height, hash, timestamp, tx-count, miner, size)` - Index a new block
- `index-transaction(tx-id, block-height, sender, recipient, amount, fee, status, tx-type)` - Index a transaction
- `bulk-index-transactions(tx-list)` - Index up to 10 transactions in one call
- `toggle-contract-status()` - Enable/disable contract functionality

### Query Functions (Read-Only)
- `get-block-info(height)` - Get block information by height
- `get-transaction-info(tx-id)` - Get transaction details by ID
- `get-address-stats(addr)` - Get address statistics
- `get-address-balance(addr)` - Calculate address balance
- `get-block-range(start, end)` - Get up to 10 blocks in range
- `search-blocks-by-miner(miner, start-height)` - Find blocks mined by specific address
- `get-latest-block()` - Get latest indexed block height
- `get-total-indexed-blocks()` - Get total number of indexed blocks
- `get-network-stats()` - Get overall network statistics
- `get-contract-info()` - Get contract metadata

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-NOT-AUTHORIZED | Caller is not authorized |
| 101 | ERR-INVALID-BLOCK | Invalid block data |
| 102 | ERR-BLOCK-NOT-FOUND | Referenced block doesn't exist |
| 103 | ERR-INVALID-INPUT | Invalid input parameters |
| 104 | ERR-DATA-EXISTS | Data already exists |

## Constants

- `MAX-BLOCKS`: 1,000,000 (maximum blocks supported)
- `MAX-TXS-PER-BLOCK`: 100 (maximum transactions per block)

## Usage Examples

### Indexing a Block
```clarity
(contract-call? .blockchain-explorer index-block
  u12345                    ;; height
  0x1234...                 ;; hash
  u1640995200              ;; timestamp
  u50                      ;; tx-count
  'SP1234...               ;; miner
  u1024)                   ;; size
```

### Querying Block Information
```clarity
(contract-call? .blockchain-explorer get-block-info u12345)
```

### Getting Address Statistics
```clarity
(contract-call? .blockchain-explorer get-address-stats 'SP1234...)
```

### Searching Blocks by Miner
```clarity
(contract-call? .blockchain-explorer search-blocks-by-miner 'SP1234... u1000)
```

## Deployment Requirements

1. **Network**: Stacks blockchain
2. **Clarity Version**: Compatible with Clarity 2.0+
3. **Contract Owner**: Set during deployment (immutable)

## Gas Optimization

- Bulk operations reduce transaction costs
- Limited query ranges prevent excessive gas usage
- Efficient data structures minimize storage costs
- Input validation prevents wasted computations

## Limitations

- Block range queries limited to 10 blocks per call
- Miner search returns up to 10 results per query
- Contract must be active for write operations
- Only contract owner can perform administrative functions

## Security Considerations

- All write functions require owner authorization
- Input validation prevents invalid data entry
- Contract can be deactivated in emergency situations
- No external dependencies reduce attack surface

## Development Notes

- Code is optimized for readability and maintainability
- All functions include comprehensive error handling
- Uses only native Clarity functions for maximum compatibility
- Designed to handle high-volume blockchain data efficiently
