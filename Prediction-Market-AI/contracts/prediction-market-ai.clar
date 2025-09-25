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