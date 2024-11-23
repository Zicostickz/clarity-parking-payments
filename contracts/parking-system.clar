;; Parking Payment System Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-payment (err u101))
(define-constant err-invalid-duration (err u102))
(define-constant err-already-parked (err u103))
(define-constant err-not-parked (err u104))
(define-constant err-parking-expired (err u105))

;; Data Variables
(define-data-var hourly-rate uint u5000000) ;; 5 STX per hour
(define-map parking-spots principal
  {
    start-time: uint,
    duration: uint,
    paid-amount: uint
  }
)

;; Public Functions
(define-public (park (duration uint))
    (let (
        (payment-amount (* duration (var-get hourly-rate)))
        (current-time block-height)
    )
    (asserts! (> duration u0) err-invalid-duration)
    (asserts! (is-none (map-get? parking-spots tx-sender)) err-already-parked)
    (try! (stx-transfer? payment-amount tx-sender contract-owner))
    (ok (map-set parking-spots tx-sender 
        {
            start-time: current-time,
            duration: duration,
            paid-amount: payment-amount
        }
    )))
)

(define-public (extend-parking (additional-hours uint))
    (let (
        (payment-amount (* additional-hours (var-get hourly-rate)))
        (current-spot (unwrap! (map-get? parking-spots tx-sender) err-not-parked))
        (current-time block-height)
    )
    (asserts! (> additional-hours u0) err-invalid-duration)
    (asserts! (<= (+ current-time u1) (+ (get start-time current-spot) (get duration current-spot))) err-parking-expired)
    (try! (stx-transfer? payment-amount tx-sender contract-owner))
    (ok (map-set parking-spots tx-sender
        {
            start-time: (get start-time current-spot),
            duration: (+ (get duration current-spot) additional-hours),
            paid-amount: (+ (get paid-amount current-spot) payment-amount)
        }
    )))
)

(define-public (end-parking)
    (begin
        (asserts! (is-some (map-get? parking-spots tx-sender)) err-not-parked)
        (ok (map-delete parking-spots tx-sender))
    )
)

;; Admin Functions
(define-public (set-hourly-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set hourly-rate new-rate))
    )
)

;; Read-only Functions
(define-read-only (get-parking-info (address principal))
    (ok (map-get? parking-spots address))
)

(define-read-only (get-hourly-rate)
    (ok (var-get hourly-rate))
)

(define-read-only (is-parking-valid (address principal))
    (let (
        (spot (map-get? parking-spots address))
    )
    (if (is-none spot)
        (ok false)
        (ok (<= block-height (+ (get start-time (unwrap-panic spot)) (get duration (unwrap-panic spot)))))
    ))
)
