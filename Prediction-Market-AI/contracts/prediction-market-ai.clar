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

;; Enhanced buy shares with fee calculation
(define-public (buy-shares (market-id uint) (prediction bool) (amount uint))
  (let
    (
      (market (unwrap! (map-get? prediction-markets { market-id: market-id }) ERR-MARKET-NOT-FOUND))
      (existing-position (default-to 
        { yes-shares: u0, no-shares: u0, total-invested: u0, last-activity-block: u0 }
        (map-get? user-positions { market-id: market-id, user: tx-sender })))
      (platform-fee-amount (/ (* amount (var-get platform-fee)) u100))
      (net-amount (- amount platform-fee-amount))
      (existing-stats (default-to 
        { total-invested: u0, markets-participated: u0, successful-predictions: u0, total-winnings: u0 }
        (map-get? user-stats { user: tx-sender })))
    )
    (asserts! (not (var-get contract-paused)) ERR-MARKET-PAUSED)
    (asserts! (< block-height (get resolution-date market)) ERR-MARKET-CLOSED)
    (asserts! (not (get resolved market)) ERR-ALREADY-RESOLVED)
    (asserts! (not (get paused market)) ERR-MARKET-PAUSED)
    (asserts! (>= amount (get min-bet market)) ERR-INVALID-AMOUNT)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (if prediction
      ;; Buy YES shares
      (begin
        (map-set user-positions
          { market-id: market-id, user: tx-sender }
          (merge existing-position { 
            yes-shares: (+ (get yes-shares existing-position) net-amount),
            total-invested: (+ (get total-invested existing-position) amount),
            last-activity-block: block-height
          }))
        (map-set prediction-markets
          { market-id: market-id }
          (merge market { 
            yes-shares: (+ (get yes-shares market) net-amount),
            total-volume: (+ (get total-volume market) net-amount)
          }))
      )
      ;; Buy NO shares
      (begin
        (map-set user-positions
          { market-id: market-id, user: tx-sender }
          (merge existing-position { 
            no-shares: (+ (get no-shares existing-position) net-amount),
            total-invested: (+ (get total-invested existing-position) amount),
            last-activity-block: block-height
          }))
        (map-set prediction-markets
          { market-id: market-id }
          (merge market { 
            no-shares: (+ (get no-shares market) net-amount),
            total-volume: (+ (get total-volume market) net-amount)
          }))
      )
    )
    
    ;; Update user stats
    (map-set user-stats { user: tx-sender }
      (merge existing-stats {
        total-invested: (+ (get total-invested existing-stats) amount),
        markets-participated: (if (is-eq (get total-invested existing-position) u0)
          (+ (get markets-participated existing-stats) u1)
          (get markets-participated existing-stats))
      }))
    
    (var-set total-volume (+ (var-get total-volume) net-amount))
    (ok true)
  )
)

;; Enhanced resolve market with dispute period
(define-public (resolve-market (market-id uint) (outcome bool))
  (let
    (
      (market (unwrap! (map-get? prediction-markets { market-id: market-id }) ERR-MARKET-NOT-FOUND))
      (resolver-auth (default-to { authorized: false, resolved-count: u0, reputation-score: u0 } 
        (map-get? authorized-resolvers { resolver: tx-sender })))
    )
    (asserts! (get authorized resolver-auth) ERR-NOT-AUTHORIZED)
    (asserts! (>= block-height (get resolution-date market)) ERR-MARKET-CLOSED)
    (asserts! (not (get resolved market)) ERR-ALREADY-RESOLVED)
    (asserts! (not (get disputed market)) ERR-DISPUTE-PERIOD)
    
    (map-set prediction-markets
      { market-id: market-id }
      (merge market { 
        resolved: true, 
        outcome: (some outcome),
        resolver: (some tx-sender),
        resolution-block: block-height
      }))
    
    (map-set authorized-resolvers
      { resolver: tx-sender }
      (merge resolver-auth { 
        resolved-count: (+ (get resolved-count resolver-auth) u1),
        reputation-score: (+ (get reputation-score resolver-auth) u10)
      }))
    
    (ok true)
  )
)

;; Dispute market resolution
(define-public (dispute-resolution (market-id uint))
  (let
    (
      (market (unwrap! (map-get? prediction-markets { market-id: market-id }) ERR-MARKET-NOT-FOUND))
      (dispute-fee (* (var-get resolution-fee) u2))
    )
    (asserts! (get resolved market) ERR-INVALID-OUTCOME)
    (asserts! (< (- block-height (get resolution-block market)) (var-get dispute-period)) ERR-COOLDOWN-ACTIVE)
    (asserts! (not (get disputed market)) ERR-DISPUTE-PERIOD)
    
    (try! (stx-transfer? dispute-fee tx-sender (as-contract tx-sender)))
    
    (map-set market-disputes
      { market-id: market-id }
      {
        disputer: tx-sender,
        dispute-block: block-height,
        dispute-fee: dispute-fee,
        resolved: false
      })
    
    (map-set prediction-markets
      { market-id: market-id }
      (merge market { disputed: true }))
    
    (ok true)
  )
)

;; Enhanced claim winnings with stats tracking
(define-public (claim-winnings (market-id uint))
  (let
    (
      (market (unwrap! (map-get? prediction-markets { market-id: market-id }) ERR-MARKET-NOT-FOUND))
      (user-position (unwrap! (map-get? user-positions { market-id: market-id, user: tx-sender }) ERR-NOT-AUTHORIZED))
      (market-outcome (unwrap! (get outcome market) ERR-INVALID-OUTCOME))
      (total-pool (get total-volume market))
      (winning-shares (if market-outcome (get yes-shares market) (get no-shares market)))
      (user-winning-shares (if market-outcome 
        (get yes-shares user-position) 
        (get no-shares user-position)))
      (payout (if (> winning-shares u0) 
        (/ (* user-winning-shares total-pool) winning-shares)
        u0))
      (existing-stats (default-to 
        { total-invested: u0, markets-participated: u0, successful-predictions: u0, total-winnings: u0 }
        (map-get? user-stats { user: tx-sender })))
    )
    (asserts! (get resolved market) ERR-MARKET-CLOSED)
    (asserts! (not (get disputed market)) ERR-DISPUTE-PERIOD)
    (asserts! (> user-winning-shares u0) ERR-INSUFFICIENT-FUNDS)
    (asserts! (>= (- block-height (get resolution-block market)) (var-get dispute-period)) ERR-DISPUTE-PERIOD)
    
    ;; Pay out winnings
    (try! (as-contract (stx-transfer? payout tx-sender tx-sender)))
    
    ;; Update user stats
    (map-set user-stats { user: tx-sender }
      (merge existing-stats {
        successful-predictions: (+ (get successful-predictions existing-stats) u1),
        total-winnings: (+ (get total-winnings existing-stats) payout)
      }))
    
    ;; Clear user position
    (map-delete user-positions { market-id: market-id, user: tx-sender })
    
    (ok payout)
  )
)

;; Admin functions
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

(define-public (pause-market (market-id uint))
  (let ((market (unwrap! (map-get? prediction-markets { market-id: market-id }) ERR-MARKET-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set prediction-markets { market-id: market-id }
      (merge market { paused: true }))
    (ok true)
  )
)

(define-public (update-fees (new-resolution-fee uint) (new-platform-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-platform-fee u10) ERR-INVALID-FEE) ;; Max 10% fee
    (var-set resolution-fee new-resolution-fee)
    (var-set platform-fee new-platform-fee)
    (ok true)
  )
)

(define-public (authorize-resolver (resolver principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-resolvers
      { resolver: resolver }
      { authorized: true, resolved-count: u0, reputation-score: u50 })
    (ok true)
  )
)

;; Enhanced read-only functions
(define-read-only (get-market (market-id uint))
  (map-get? prediction-markets { market-id: market-id })
)

(define-read-only (get-user-position (market-id uint) (user principal))
  (map-get? user-positions { market-id: market-id, user: user })
)

(define-read-only (get-market-odds (market-id uint))
  (let
    (
      (market (unwrap! (map-get? prediction-markets { market-id: market-id }) (err none)))
      (yes-shares (get yes-shares market))
      (no-shares (get no-shares market))
      (total-shares (+ yes-shares no-shares))
    )
    (if (> total-shares u0)
      (ok { yes-probability: (/ (* yes-shares u100) total-shares), 
            no-probability: (/ (* no-shares u100) total-shares) })
      (ok { yes-probability: u50, no-probability: u50 })
    )
  )
)

(define-read-only (get-user-stats (user principal))
  (default-to 
    { total-invested: u0, markets-participated: u0, successful-predictions: u0, total-winnings: u0 }
    (map-get? user-stats { user: user }))
)

(define-read-only (get-platform-stats)
  {
    total-volume: (var-get total-volume),
    total-markets: (var-get total-markets),
    resolution-fee: (var-get resolution-fee),
    platform-fee: (var-get platform-fee),
    contract-paused: (var-get contract-paused)
  }
)

(define-read-only (is-authorized-resolver (resolver principal))
  (default-to { authorized: false, resolved-count: u0, reputation-score: u0 } 
    (map-get? authorized-resolvers { resolver: resolver }))
)

(define-read-only (get-market-count)
  (var-get market-count)
)

(define-read-only (get-category-stats (category (string-ascii 50)))
  (map-get? market-categories { category: category })
)