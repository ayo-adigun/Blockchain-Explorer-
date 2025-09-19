;; Blockchain Explorer Contract
;; A comprehensive contract for exploring blockchain data

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-BLOCK (err u101))
(define-constant ERR-BLOCK-NOT-FOUND (err u102))
(define-constant ERR-INVALID-INPUT (err u103))
(define-constant ERR-DATA-EXISTS (err u104))
(define-constant MAX-BLOCKS u1000000)
(define-constant MAX-TXS-PER-BLOCK u100)

;; Data Variables
(define-data-var contract-active bool true)
(define-data-var total-blocks-indexed uint u0)
(define-data-var last-indexed-block uint u0)

;; Data Maps
(define-map block-info 
    { block-height: uint }
    { 
        block-hash: (buff 32),
        timestamp: uint,
        tx-count: uint,
        miner: principal,
        size: uint,
        indexed-at: uint
    }
)

(define-map transaction-info
    { tx-id: (buff 32) }
    {
        block-height: uint,
        sender: principal,
        recipient: (optional principal),
        amount: uint,
        fee: uint,
        status: (string-ascii 20),
        tx-type: (string-ascii 30)
    }
)

(define-map address-stats
    { address: principal }
    {
        tx-count: uint,
        total-sent: uint,
        total-received: uint,
        first-seen: uint,
        last-active: uint
    }
)

(define-map block-transactions
    { block-height: uint, tx-index: uint }
    { tx-id: (buff 32) }
)

;; Authorization Functions
(define-private (is-contract-owner)
    (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (is-contract-active)
    (var-get contract-active)
)

;; Block Management Functions
(define-public (index-block (height uint) (hash (buff 32)) (timestamp uint) 
                          (tx-count uint) (miner principal) (size uint))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (is-contract-active) ERR-NOT-AUTHORIZED)
        (asserts! (< height MAX-BLOCKS) ERR-INVALID-BLOCK)
        (asserts! (> tx-count u0) ERR-INVALID-INPUT)
        (asserts! (is-none (map-get? block-info { block-height: height })) ERR-DATA-EXISTS)
        
        (map-set block-info 
            { block-height: height }
            {
                block-hash: hash,
                timestamp: timestamp,
                tx-count: tx-count,
                miner: miner,
                size: size,
                indexed-at: block-height
            }
        )
        
        (var-set total-blocks-indexed (+ (var-get total-blocks-indexed) u1))
        (var-set last-indexed-block (if (> height (var-get last-indexed-block)) 
                                        height 
                                        (var-get last-indexed-block)))
        (ok height)
    )
)

(define-public (index-transaction (tx-id (buff 32)) (block-height uint) (sender principal)
                                 (recipient (optional principal)) (amount uint) (fee uint)
                                 (status (string-ascii 20)) (tx-type (string-ascii 30)))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (is-contract-active) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (map-get? block-info { block-height: block-height })) ERR-BLOCK-NOT-FOUND)
        
        (map-set transaction-info
            { tx-id: tx-id }
            {
                block-height: block-height,
                sender: sender,
                recipient: recipient,
                amount: amount,
                fee: fee,
                status: status,
                tx-type: tx-type
            }
        )
        
        (update-address-stats sender amount true block-height)
        (match recipient
            addr (update-address-stats addr amount false block-height)
            true
        )
        (ok true)
    )
)

;; Private helper for address statistics
(define-private (update-address-stats (addr principal) (amount uint) (is-sender bool) (height uint))
    (let ((existing-stats (default-to 
                            { tx-count: u0, total-sent: u0, total-received: u0, 
                              first-seen: height, last-active: height }
                            (map-get? address-stats { address: addr }))))
        (map-set address-stats
            { address: addr }
            {
                tx-count: (+ (get tx-count existing-stats) u1),
                total-sent: (if is-sender 
                              (+ (get total-sent existing-stats) amount)
                              (get total-sent existing-stats)),
                total-received: (if is-sender
                                  (get total-received existing-stats)
                                  (+ (get total-received existing-stats) amount)),
                first-seen: (if (< height (get first-seen existing-stats)) 
                              height 
                              (get first-seen existing-stats)),
                last-active: (if (> height (get last-active existing-stats)) 
                               height 
                               (get last-active existing-stats))
            }
        )
    )
)

;; Query Functions
(define-read-only (get-block-info (height uint))
    (map-get? block-info { block-height: height })
)

(define-read-only (get-transaction-info (tx-id (buff 32)))
    (map-get? transaction-info { tx-id: tx-id })
)

(define-read-only (get-address-stats (addr principal))
    (map-get? address-stats { address: addr })
)

(define-read-only (get-latest-block)
    (var-get last-indexed-block)
)

(define-read-only (get-total-indexed-blocks)
    (var-get total-blocks-indexed)
)

;; Simple block range query (returns up to 10 blocks)
(define-read-only (get-block-range (start uint) (end uint))
    (begin
        (asserts! (<= start end) (err ERR-INVALID-INPUT))
        (asserts! (<= (- end start) u10) (err ERR-INVALID-INPUT))
        (ok {
            block-0: (if (>= start (+ start u0)) (map-get? block-info { block-height: start }) none),
            block-1: (if (>= end (+ start u1)) (map-get? block-info { block-height: (+ start u1) }) none),
            block-2: (if (>= end (+ start u2)) (map-get? block-info { block-height: (+ start u2) }) none),
            block-3: (if (>= end (+ start u3)) (map-get? block-info { block-height: (+ start u3) }) none),
            block-4: (if (>= end (+ start u4)) (map-get? block-info { block-height: (+ start u4) }) none),
            block-5: (if (>= end (+ start u5)) (map-get? block-info { block-height: (+ start u5) }) none),
            block-6: (if (>= end (+ start u6)) (map-get? block-info { block-height: (+ start u6) }) none),
            block-7: (if (>= end (+ start u7)) (map-get? block-info { block-height: (+ start u7) }) none),
            block-8: (if (>= end (+ start u8)) (map-get? block-info { block-height: (+ start u8) }) none),
            block-9: (if (>= end (+ start u9)) (map-get? block-info { block-height: (+ start u9) }) none)
        })
    )
)

;; Simple miner search (checks specific block heights)
(define-read-only (search-blocks-by-miner (miner principal) (start-height uint))
    (begin
        (asserts! (<= start-height (var-get last-indexed-block)) (err ERR-INVALID-INPUT))
        (let ((end-height (if (< (+ start-height u10) (var-get last-indexed-block))
                             (+ start-height u10)
                             (var-get last-indexed-block))))
            (ok {
                matches: (list 
                    (check-block-miner miner start-height)
                    (check-block-miner miner (+ start-height u1))
                    (check-block-miner miner (+ start-height u2))
                    (check-block-miner miner (+ start-height u3))
                    (check-block-miner miner (+ start-height u4))
                    (check-block-miner miner (+ start-height u5))
                    (check-block-miner miner (+ start-height u6))
                    (check-block-miner miner (+ start-height u7))
                    (check-block-miner miner (+ start-height u8))
                    (check-block-miner miner (+ start-height u9))
                ),
                search-range: { start: start-height, end: end-height }
            })
        )
    )
)

(define-private (check-block-miner (target-miner principal) (height uint))
    (match (map-get? block-info { block-height: height })
        block-data (if (is-eq (get miner block-data) target-miner)
                      (some height)
                      none)
        none
    )
)

(define-read-only (get-address-balance (addr principal))
    (match (get-address-stats addr)
        stats (ok (- (get total-received stats) (get total-sent stats)))
        (err ERR-INVALID-INPUT)
    )
)

(define-read-only (get-network-stats)
    (ok {
        total-blocks: (var-get total-blocks-indexed),
        latest-block: (var-get last-indexed-block),
        contract-active: (var-get contract-active)
    })
)

;; Administrative Functions
(define-public (toggle-contract-status)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set contract-active (not (var-get contract-active)))
        (ok (var-get contract-active))
    )
)

(define-public (bulk-index-transactions (tx-list (list 10 { tx-id: (buff 32), block-height: uint, 
                                                           sender: principal, recipient: (optional principal),
                                                           amount: uint, fee: uint, status: (string-ascii 20),
                                                           tx-type: (string-ascii 30) })))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (is-contract-active) ERR-NOT-AUTHORIZED)
        (ok (map process-bulk-tx tx-list))
    )
)

(define-private (process-bulk-tx (tx-data { tx-id: (buff 32), block-height: uint, sender: principal,
                                           recipient: (optional principal), amount: uint, fee: uint,
                                           status: (string-ascii 20), tx-type: (string-ascii 30) }))
    (index-transaction 
        (get tx-id tx-data)
        (get block-height tx-data)
        (get sender tx-data)
        (get recipient tx-data)
        (get amount tx-data)
        (get fee tx-data)
        (get status tx-data)
        (get tx-type tx-data)
    )
)

;; Utility Functions
(define-read-only (validate-block-height (height uint))
    (and (> height u0) (<= height MAX-BLOCKS))
)

(define-read-only (get-contract-info)
    (ok {
        owner: CONTRACT-OWNER,
        version: "1.0.0",
        active: (var-get contract-active),
        max-blocks: MAX-BLOCKS,
        max-txs-per-block: MAX-TXS-PER-BLOCK
    })
)