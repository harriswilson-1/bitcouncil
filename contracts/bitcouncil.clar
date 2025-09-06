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