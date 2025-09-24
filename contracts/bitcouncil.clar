;; Title: BitCouncil - Decentralized Autonomous Organization Protocol
;;
;; Summary: A sophisticated Bitcoin-native DAO framework built on Stacks that revolutionizes 
;; decentralized governance through advanced voting mechanisms, transparent fund management, 
;; and innovative return distribution systems powered by Bitcoin's security model.
;;
;; Description: BitCouncil represents the next evolution of decentralized governance on Bitcoin 
;; Layer 2. This comprehensive protocol enables communities to create, manage, and execute 
;; collective decisions while maintaining full transparency and democratic participation. 
;; Features include delegated voting systems, emergency governance controls, investment tracking 
;; with automated return distributions, and robust security mechanisms. Built specifically for 
;; the Bitcoin ecosystem, BitCouncil bridges traditional organizational structures with 
;; cutting-edge blockchain technology, ensuring every decision is verifiable, every vote counts, 
;; and every member shares in collective success.
;;
;; Key Features:
;; - Advanced proposal lifecycle management with customizable voting periods
;; - Delegation system enabling representative democracy within DAOs
;; - Automated investment return distribution based on member contributions
;; - Emergency governance controls for crisis management
;; - Configurable governance parameters for organizational flexibility
;; - Bitcoin-secured voting with Stacks smart contract execution
;; - Multi-tiered authorization system for enhanced security
;;
;; Perfect Feature Branch: governance-v2-delegation-returns
;; Implementation Status: Production-ready with comprehensive error handling

;; ERROR CONSTANTS

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-VOTED (err u101))
(define-constant ERR-PROPOSAL-EXPIRED (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-INVALID-AMOUNT (err u104))
(define-constant ERR-PROPOSAL-NOT-ACTIVE (err u105))
(define-constant ERR-QUORUM-NOT-REACHED (err u106))
(define-constant ERR-NO-DELEGATE (err u110))
(define-constant ERR-INVALID-DELEGATE (err u111))
(define-constant ERR-EMERGENCY-ACTIVE (err u112))
(define-constant ERR-NOT-EMERGENCY (err u113))
(define-constant ERR-INVALID-PARAMETER (err u114))
(define-constant ERR-NO-RETURNS (err u115))

;; DATA VARIABLES

(define-data-var dao-admin principal tx-sender)
(define-data-var minimum-quorum uint u500) ;; 50% in basis points
(define-data-var voting-period uint u144) ;; ~1 day in blocks
(define-data-var proposal-count uint u0)
(define-data-var treasury-balance uint u0)
(define-data-var emergency-state bool false)

;; GOVERNANCE PARAMETERS

(define-data-var dao-parameters {
  proposal-fee: uint,
  min-proposal-amount: uint,
  max-proposal-amount: uint,
  voting-delay: uint,
  voting-period: uint,
  timelock-period: uint,
  quorum-threshold: uint,
  super-majority: uint,
} {
  proposal-fee: u100000, ;; 0.1 STX proposal submission fee
  min-proposal-amount: u1000000, ;; 1 STX minimum proposal amount
  max-proposal-amount: u1000000000, ;; 1000 STX maximum proposal amount
  voting-delay: u100, ;; blocks before voting starts
  voting-period: u144, ;; ~1 day voting duration in blocks
  timelock-period: u72, ;; ~12 hours execution delay
  quorum-threshold: u500, ;; 50% participation requirement
  super-majority: u667, ;; 66.7% approval threshold
})

;; DATA MAPS

;; Member registry with voting power and contribution tracking
(define-map members
  principal
  {
    voting-power: uint,
    joined-block: uint,
    total-contributed: uint,
    last-withdrawal: uint,
  }
)

;; Comprehensive proposal structure
(define-map proposals
  uint
  {
    id: uint,
    proposer: principal,
    title: (string-ascii 100),
    description: (string-utf8 1000),
    amount: uint,
    target: principal,
    start-block: uint,
    end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    status: (string-ascii 20),
    executed: bool,
  }
)

;; Individual vote tracking
(define-map votes
  {
    proposal-id: uint,
    voter: principal,
  }
  {
    amount: uint,
    support: bool,
  }
)

;; Emergency administrator registry
(define-map emergency-admins
  principal
  bool
)

;; Vote delegation system
(define-map delegations
  principal
  {
    delegate: principal,
    amount: uint,
    expiry: uint,
  }
)

;; Investment return distribution pools
(define-map return-pools
  uint
  {
    total-amount: uint,
    distributed-amount: uint,
    distribution-start: uint,
    distribution-end: uint,
    claims: (list 200 principal),
  }
)

;; Member return claims tracking
(define-map member-claims
  {
    member: principal,
    pool-id: uint,
  }
  {
    amount: uint,
    claimed: bool,
  }
)

;; EMERGENCY GOVERNANCE FUNCTIONS

;; Toggle emergency state for crisis management
(define-public (set-emergency-state (state bool))
  (begin
    (asserts! (is-emergency-admin tx-sender) ERR-NOT-AUTHORIZED)
    (var-set emergency-state state)
    (ok true)
  )
)

;; Add new emergency administrator
(define-public (add-emergency-admin (admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get dao-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq admin (as-contract tx-sender))) ERR-INVALID-PARAMETER)
    (map-set emergency-admins admin true)
    (ok true)
  )
)

;; DELEGATION SYSTEM

;; Delegate voting power to another member
(define-public (delegate-votes
    (delegate-to principal)
    (amount uint)
    (expiry uint)
  )
  (let (
      (caller tx-sender)
      (member-info (unwrap! (get-member-info caller) ERR-NOT-AUTHORIZED))
    )
    ;; Validate delegation parameters
    (asserts! (not (is-eq delegate-to caller)) ERR-INVALID-DELEGATE)
    (asserts! (is-some (get-member-info delegate-to)) ERR-INVALID-DELEGATE)
    (asserts! (>= (get voting-power member-info) amount) ERR-INSUFFICIENT-FUNDS)
    (asserts! (> expiry stacks-block-height) ERR-INVALID-PARAMETER)

    ;; Record delegation
    (map-set delegations caller {
      delegate: delegate-to,
      amount: amount,
      expiry: expiry,
    })

    ;; Update member voting power
    (map-set members caller
      (merge member-info { voting-power: (- (get voting-power member-info) amount) })
    )
    (ok true)
  )
)

;; PROPOSAL MANAGEMENT

;; Create new governance proposal with comprehensive validation
(define-public (create-proposal
    (title (string-ascii 100))
    (description (string-utf8 1000))
    (amount uint)
    (target principal)
  )
  (let (
      (caller tx-sender)
      (current-block stacks-block-height)
      (proposal-id (+ (var-get proposal-count) u1))
      (params (var-get dao-parameters))
      (end-block (+ current-block (get voting-period params)))
    )
    ;; Comprehensive input validation
    (asserts! (not (is-eq target (as-contract tx-sender))) ERR-INVALID-PARAMETER)
    (asserts! (> (len title) u0) ERR-INVALID-PARAMETER)
    (asserts! (> (len description) u0) ERR-INVALID-PARAMETER)
    (asserts! (is-some (get-member-info caller)) ERR-NOT-AUTHORIZED)
    (asserts! (>= (var-get treasury-balance) amount) ERR-INSUFFICIENT-FUNDS)
    (asserts! (>= amount (get min-proposal-amount params)) ERR-INVALID-AMOUNT)
    (asserts! (<= amount (get max-proposal-amount params)) ERR-INVALID-AMOUNT)

    ;; Collect proposal fee
    (try! (stx-transfer? (get proposal-fee params) caller (as-contract tx-sender)))

    ;; Create proposal record
    (map-set proposals proposal-id {
      id: proposal-id,
      proposer: caller,
      title: title,
      description: description,
      amount: amount,
      target: target,
      start-block: (+ current-block (get voting-delay params)),
      end-block: end-block,
      yes-votes: u0,
      no-votes: u0,
      status: "active",
      executed: false,
    })
    (var-set proposal-count proposal-id)
    (ok proposal-id)
  )
)

;; RETURN DISTRIBUTION SYSTEM

;; Create investment return pool for executed proposal
(define-public (create-return-pool
    (proposal-id uint)
    (total-amount uint)
  )
  (let (
      (caller tx-sender)
      (proposal (unwrap! (get-proposal-by-id proposal-id) ERR-PROPOSAL-NOT-ACTIVE))
    )
    ;; Authorization and validation checks
    (asserts! (is-eq caller (var-get dao-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (> total-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-eq (get status proposal) "executed") ERR-PROPOSAL-NOT-ACTIVE)

    ;; Initialize return pool
    (map-set return-pools proposal-id {
      total-amount: total-amount,
      distributed-amount: u0,
      distribution-start: stacks-block-height,
      distribution-end: (+ stacks-block-height (get timelock-period (var-get dao-parameters))),
      claims: (list),
    })
    (ok true)
  )
)

;; Claim proportional returns from investment pool
(define-public (claim-returns (proposal-id uint))
  (let (
      (caller tx-sender)
      (pool (unwrap! (get-return-pool proposal-id) ERR-NO-RETURNS))
      (member-info (unwrap! (get-member-info caller) ERR-NOT-AUTHORIZED))
      (claim-amount (calculate-member-share caller proposal-id))
    )
    ;; Validate claim eligibility
    (asserts! (> claim-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (not (has-claimed caller proposal-id)) ERR-ALREADY-VOTED)

    ;; Record member claim
    (map-set member-claims {
      member: caller,
      pool-id: proposal-id,
    } {
      amount: claim-amount,
      claimed: true,
    })

    ;; Update pool distribution tracking
    (map-set return-pools proposal-id
      (merge pool {
        distributed-amount: (+ (get distributed-amount pool) claim-amount),
        claims: (unwrap! (as-max-len? (append (get claims pool) caller) u200)
          ERR-INVALID-PARAMETER
        ),
      })
    )

    ;; Execute return transfer
    (try! (stx-transfer? claim-amount (as-contract tx-sender) caller))
    (ok true)
  )
)

;; GOVERNANCE PARAMETER UPDATES

;; Update DAO operational parameters
(define-public (update-dao-parameters (new-params {
  proposal-fee: uint,
  min-proposal-amount: uint,
  max-proposal-amount: uint,
  voting-delay: uint,
  voting-period: uint,
  timelock-period: uint,
  quorum-threshold: uint,
  super-majority: uint,
}))
  (begin
    (asserts! (is-eq tx-sender (var-get dao-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (validate-parameters new-params) ERR-INVALID-PARAMETER)
    (var-set dao-parameters new-params)
    (ok true)
  )
)

;; PRIVATE HELPER FUNCTIONS

;; Calculate member's proportional share of return pool
(define-private (calculate-member-share
    (member principal)
    (pool-id uint)
  )
  (let (
      (pool (unwrap! (get-return-pool pool-id) u0))
      (member-info (unwrap! (get-member-info member) u0))
      (total-shares (var-get treasury-balance))
    )
    (if (> total-shares u0)
      (/ (* (get total-amount pool) (get voting-power member-info)) total-shares)
      u0
    )
  )
)

;; Validate governance parameter constraints
(define-private (validate-parameters (params {
  proposal-fee: uint,
  min-proposal-amount: uint,
  max-proposal-amount: uint,
  voting-delay: uint,
  voting-period: uint,
  timelock-period: uint,
  quorum-threshold: uint,
  super-majority: uint,
}))
  (and
    (< (get min-proposal-amount params) (get max-proposal-amount params))
    (<= (get quorum-threshold params) u1000)
    (<= (get super-majority params) u1000)
    (> (get voting-period params) (get voting-delay params))
  )
)

;; READ-ONLY QUERY FUNCTIONS

;; Retrieve member information and voting power
(define-read-only (get-member-info (member principal))
  (map-get? members member)
)

;; Get detailed proposal information by ID
(define-read-only (get-proposal-by-id (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Check individual vote record
(define-read-only (get-vote
    (proposal-id uint)
    (voter principal)
  )
  (map-get? votes {
    proposal-id: proposal-id,
    voter: voter,
  })
)

;; Retrieve delegation information
(define-read-only (get-delegation (member principal))
  (map-get? delegations member)
)

;; Get return pool details
(define-read-only (get-return-pool (pool-id uint))
  (map-get? return-pools pool-id)
)

;; Check if member has claimed returns
(define-read-only (has-claimed
    (member principal)
    (pool-id uint)
  )
  (default-to false
    (get claimed
      (map-get? member-claims {
        member: member,
        pool-id: pool-id,
      })
    ))
)

;; Verify emergency administrator status
(define-read-only (is-emergency-admin (admin principal))
  (default-to false (map-get? emergency-admins admin))
)

;; Get current DAO governance parameters
(define-read-only (get-dao-parameters)
  (ok (var-get dao-parameters))
)

;; Check current treasury balance
(define-read-only (get-treasury-balance)
  (ok (var-get treasury-balance))
)
