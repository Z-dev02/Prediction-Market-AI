;; PredictionMarketAI - Enhanced prediction markets for AI milestones and breakthroughs
;; Community bets on AI developments, creating valuable forecasting data

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MARKET-NOT-FOUND (err u101))
(define-constant ERR-MARKET-CLOSED (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-INVALID-OUTCOME (err u104))
(define-constant ERR-ALREADY-RESOLVED (err u105))
(define-constant ERR-INVALID-AMOUNT (err u106))
(define-constant ERR-MARKET-PAUSED (err u107))
(define-constant ERR-INVALID-FEE (err u108))
(define-constant ERR-COOLDOWN-ACTIVE (err u109))
(define-constant ERR-DISPUTE-PERIOD (err u110))

(define-data-var market-count uint u0)
(define-data-var resolution-fee uint u50) ;; 50 STX fee for resolution
(define-data-var platform-fee uint u5) ;; 5% platform fee
(define-data-var min-bet-amount uint u10) ;; Minimum bet amount
(define-data-var dispute-period uint u144) ;; 24 hours in blocks
(define-data-var contract-paused bool false)
(define-data-var total-volume uint u0)
(define-data-var total-markets uint u0)

(define-map prediction-markets
  { market-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    creator: principal,
    resolution-date: uint,
    total-volume: uint,
    yes-shares: uint,
    no-shares: uint,
    resolved: bool,
    outcome: (optional bool),
    resolver: (optional principal),
    resolution-block: uint,
    disputed: bool,
    paused: bool,
    min-bet: uint
  }
)

(define-map user-positions
  { market-id: uint, user: principal }
  {
    yes-shares: uint,
    no-shares: uint,
    total-invested: uint,
    last-activity-block: uint
  }
)

(define-map market-categories
  { category: (string-ascii 50) }
  { active: bool, market-count: uint }
)

(define-map authorized-resolvers
  { resolver: principal }
  { authorized: bool, resolved-count: uint, reputation-score: uint }
)

(define-map market-disputes
  { market-id: uint }
  { 
    disputer: principal,
    dispute-block: uint,
    dispute-fee: uint,
    resolved: bool
  }
)

(define-map user-stats
  { user: principal }
  {
    total-invested: uint,
    markets-participated: uint,
    successful-predictions: uint,
    total-winnings: uint
  }
)

(define-map liquidity-providers
  { market-id: uint, provider: principal }
  { liquidity-amount: uint, shares: uint }
)

;; Initialize with AI milestone categories
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set market-categories { category: "agi-breakthrough" } { active: true, market-count: u0 })
    (map-set market-categories { category: "compute-milestone" } { active: true, market-count: u0 })
    (map-set market-categories { category: "model-capability" } { active: true, market-count: u0 })
    (map-set market-categories { category: "industry-adoption" } { active: true, market-count: u0 })
    (map-set market-categories { category: "regulation-policy" } { active: true, market-count: u0 })
    (map-set market-categories { category: "research-milestone" } { active: true, market-count: u0 })
    (map-set authorized-resolvers { resolver: CONTRACT-OWNER } 
      { authorized: true, resolved-count: u0, reputation-score: u100 })
    (ok true)
  )
)

;; Create prediction market with enhanced features
(define-public (create-market 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (resolution-blocks uint)
  (min-bet uint))
  (let
    (
      (market-id (+ (var-get market-count) u1))
      (category-data (unwrap! (map-get? market-categories { category: category }) ERR-INVALID-OUTCOME))
      (resolution-date (+ block-height resolution-blocks))
    )
    (asserts! (not (var-get contract-paused)) ERR-MARKET-PAUSED)
    (asserts! (get active category-data) ERR-INVALID-OUTCOME)
    (asserts! (>= min-bet (var-get min-bet-amount)) ERR-INVALID-AMOUNT)
    (asserts! (> resolution-blocks u144) ERR-INVALID-AMOUNT) ;; At least 24 hours
    (try! (stx-transfer? (var-get resolution-fee) tx-sender (as-contract tx-sender)))
    
    (map-set prediction-markets
      { market-id: market-id }
      {
        title: title,
        description: description,
        category: category,
        creator: tx-sender,
        resolution-date: resolution-date,
        total-volume: u0,
        yes-shares: u0,
        no-shares: u0,
        resolved: false,
        outcome: none,
        resolver: none,
        resolution-block: u0,
        disputed: false,
        paused: false,
        min-bet: min-bet
      }
    )
    
    (map-set market-categories { category: category }
      (merge category-data { market-count: (+ (get market-count category-data) u1) }))
    
    (var-set market-count market-id)
    (var-set total-markets (+ (var-get total-markets) u1))
    (ok market-id)
  )
)

;; Add liquidity to market
(define-public (add-liquidity (market-id uint) (amount uint))
  (let
    (
      (market (unwrap! (map-get? prediction-markets { market-id: market-id }) ERR-MARKET-NOT-FOUND))
      (existing-lp (default-to { liquidity-amount: u0, shares: u0 }
        (map-get? liquidity-providers { market-id: market-id, provider: tx-sender })))
    )
    (asserts! (< block-height (get resolution-date market)) ERR-MARKET-CLOSED)
    (asserts! (not (get resolved market)) ERR-ALREADY-RESOLVED)
    (asserts! (not (get paused market)) ERR-MARKET-PAUSED)
    (asserts! (>= amount u100) ERR-INVALID-AMOUNT)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set liquidity-providers
      { market-id: market-id, provider: tx-sender }
      { 
        liquidity-amount: (+ (get liquidity-amount existing-lp) amount),
        shares: (+ (get shares existing-lp) amount)
      })
    
    (ok true)
  )
)
