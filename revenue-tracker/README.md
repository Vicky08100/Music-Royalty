# Music Royalty Distribution Smart Contract

## About
A robust smart contract built on the Stacks blockchain using Clarity language for managing and automating music royalty distributions. This contract enables transparent, efficient, and automated distribution of royalty payments among various stakeholders in the music industry.

## Features
- Song Registration and Management
- Automated Royalty Distribution
- Multiple Stakeholder Support
- Revenue Tracking
- Secure Access Control
- Historical Earnings Management
- Status Management for Songs

## Contract Structure

### Data Maps
1. **RegisteredSongs**
   - Tracks song information
   - Stores revenue data
   - Manages song status

2. **RoyaltyDistribution**
   - Manages royalty shares
   - Tracks participant roles
   - Records earnings

### Key Functions

#### Administrative Functions
```clarity
(define-public (register-new-song (song-title (string-ascii 50)) (primary-artist principal)))
(define-public (transfer-administrator-rights (new-administrator principal)))
(define-public (update-song-active-status (song-identifier uint) (new-active-status bool)))
```

#### Royalty Management
```clarity
(define-public (set-royalty-distribution 
    (song-identifier uint) 
    (royalty-recipient principal) 
    (royalty-percentage uint) 
    (participant-role (string-ascii 20))))
(define-public (process-royalty-payment (song-identifier uint) (royalty-payment-amount uint)))
```

#### Read-Only Functions
```clarity
(define-read-only (get-song-information (song-identifier uint)))
(define-read-only (get-royalty-distribution (song-identifier uint) (royalty-recipient principal)))
(define-read-only (get-total-registered-songs))
```

## Usage Guide

### 1. Initial Setup
```clarity
;; Deploy contract
;; Initial administrator will be the deploying address
```

### 2. Registering a Song
```clarity
;; Register a new song
(contract-call? .music-royalty-distribution register-new-song "Song Title" artist-address)
```

### 3. Setting Royalty Distributions
```clarity
;; Set royalty shares for participants
(contract-call? .music-royalty-distribution set-royalty-distribution 
    song-id 
    recipient-address 
    percentage 
    "Artist")
```

### 4. Processing Payments
```clarity
;; Process royalty payment for a song
(contract-call? .music-royalty-distribution process-royalty-payment 
    song-id 
    payment-amount)
```

## Error Codes
| Code | Description |
|------|-------------|
| u100 | Unauthorized Access |
| u101 | Invalid Royalty Percentage |
| u102 | Duplicate Song Entry |
| u103 | Song Does Not Exist |
| u104 | Insufficient Payment Funds |
| u105 | Invalid Royalty Recipient |

## Security Considerations
- Only contract administrator can register new songs
- Royalty percentages must be between 0-100
- Payment distribution requires sufficient funds
- Access control checks on sensitive operations
- Secure ownership transfer mechanism

## Best Practices
1. Always verify song existence before operations
2. Ensure royalty percentages sum to 100%
3. Maintain accurate recipient information
4. Regular auditing of distribution records
5. Keep track of historical transactions

## Contributing
1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request