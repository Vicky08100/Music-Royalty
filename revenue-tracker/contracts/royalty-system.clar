;; Music Royalty Distribution Smart Contract
;; This contract manages music royalty distributions among artists, producers, and rights holders

;; Error codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INVALID-ROYALTY-PERCENTAGE (err u101))
(define-constant ERR-DUPLICATE-SONG-ENTRY (err u102))
(define-constant ERR-SONG-DOES-NOT-EXIST (err u103))
(define-constant ERR-INSUFFICIENT-PAYMENT-FUNDS (err u104))
(define-constant ERR-INVALID-ROYALTY-RECIPIENT (err u105))

;; Data structures
(define-map RegisteredSongs
    { song-identifier: uint }
    {
        song-title: (string-ascii 50),
        primary-artist: principal,
        accumulated-revenue: uint,
        publication-date: uint,
        song-status-active: bool
    }
)

(define-map RoyaltyDistribution
    { song-identifier: uint, royalty-recipient: principal }
    {
        royalty-percentage: uint,
        participant-role: (string-ascii 20),
        accumulated-earnings: uint
    }
)

;; Track total registered songs
(define-data-var registered-song-count uint u0)

;; Track contract administrator
(define-data-var contract-administrator principal tx-sender)

;; Read-only functions
(define-read-only (get-song-information (song-identifier uint))
    (map-get? RegisteredSongs { song-identifier: song-identifier })
)

(define-read-only (get-royalty-distribution (song-identifier uint) (royalty-recipient principal))
    (map-get? RoyaltyDistribution { song-identifier: song-identifier, royalty-recipient: royalty-recipient })
)

(define-read-only (get-total-registered-songs)
    (var-get registered-song-count)
)

;; Private functions
(define-private (verify-contract-administrator)
    (is-eq tx-sender (var-get contract-administrator))
)

(define-private (validate-royalty-percentage (royalty-percentage uint))
    (and (>= royalty-percentage u0) (<= royalty-percentage u100))
)

(define-private (distribute-royalty-payment (song-identifier uint) (payment-amount uint))
    (let (
        (royalty-distribution-list (get-royalty-shares-by-song song-identifier))
    )
    (fold process-individual-payment royalty-distribution-list (ok true)))
)

(define-private (process-individual-payment 
    (royalty-share {royalty-recipient: principal, royalty-percentage: uint}) 
    (previous-distribution-result (response bool uint)))
    (match previous-distribution-result
        success (if (is-ok success)
            (let (
                (recipient-payment-amount (/ (* royalty-share u100) u100))
            )
            (try! (stx-transfer? recipient-payment-amount tx-sender (get royalty-recipient royalty-share)))
            (ok true))
            previous-distribution-result)
        error previous-distribution-result
    )
)

;; Public functions
(define-public (register-new-song (song-title (string-ascii 50)) (primary-artist principal))
    (let (
        (new-song-identifier (+ (var-get registered-song-count) u1))
    )
    (if (verify-contract-administrator)
        (begin
            (map-set RegisteredSongs
                { song-identifier: new-song-identifier }
                {
                    song-title: song-title,
                    primary-artist: primary-artist,
                    accumulated-revenue: u0,
                    publication-date: block-height,
                    song-status-active: true
                }
            )
            (var-set registered-song-count new-song-identifier)
            (ok new-song-identifier))
        ERR-UNAUTHORIZED-ACCESS))
)

(define-public (set-royalty-distribution 
    (song-identifier uint) 
    (royalty-recipient principal) 
    (royalty-percentage uint) 
    (participant-role (string-ascii 20)))
    (let (
        (song-record (get-song-information song-identifier))
    )
    (if (and (is-some song-record) (validate-royalty-percentage royalty-percentage))
        (begin
            (map-set RoyaltyDistribution
                { song-identifier: song-identifier, royalty-recipient: royalty-recipient }
                {
                    royalty-percentage: royalty-percentage,
                    participant-role: participant-role,
                    accumulated-earnings: u0
                }
            )
            (ok true))
        ERR-INVALID-ROYALTY-PERCENTAGE))
)

(define-public (process-royalty-payment (song-identifier uint) (royalty-payment-amount uint))
    (let (
        (song-record (get-song-information song-identifier))
    )
    (if (and
            (is-some song-record)
            (>= (stx-get-balance tx-sender) royalty-payment-amount)
        )
        (begin
            (try! (distribute-royalty-payment song-identifier royalty-payment-amount))
            (map-set RegisteredSongs
                { song-identifier: song-identifier }
                (merge (unwrap-panic song-record)
                    { accumulated-revenue: (+ (get accumulated-revenue (unwrap-panic song-record)) royalty-payment-amount) }
                )
            )
            (ok true))
        ERR-INSUFFICIENT-PAYMENT-FUNDS))
)

(define-public (update-song-active-status (song-identifier uint) (new-active-status bool))
    (let (
        (song-record (get-song-information song-identifier))
    )
    (if (and (verify-contract-administrator) (is-some song-record))
        (begin
            (map-set RegisteredSongs
                { song-identifier: song-identifier }
                (merge (unwrap-panic song-record)
                    { song-status-active: new-active-status }
                )
            )
            (ok true))
        ERR-UNAUTHORIZED-ACCESS))
)

(define-public (transfer-administrator-rights (new-administrator principal))
    (if (verify-contract-administrator)
        (begin
            (var-set contract-administrator new-administrator)
            (ok true))
        ERR-UNAUTHORIZED-ACCESS)
)

;; Contract initialization
(begin
    (var-set registered-song-count u0)
)