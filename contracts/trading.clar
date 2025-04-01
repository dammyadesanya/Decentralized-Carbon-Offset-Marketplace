;; Trading Contract
;; This contract facilitates buying and selling of carbon offsets

(define-data-var admin principal tx-sender)

;; Token data structure
(define-map tokens
  { token-id: uint }
  {
    project-id: uint,
    owner: principal,
    tons: uint,
    price-per-ton: uint,
    for-sale: bool
  }
)

;; Token counter
(define-data-var token-counter uint u0)

;; Project verification contract
(define-constant project-verification-contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.project-verification)

;; Offset quantification contract
(define-constant offset-quantification-contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.offset-quantification)

;; Mint new offset tokens
(define-public (mint-tokens (project-id uint) (tons uint) (price-per-ton uint))
  (let ((token-id (var-get token-counter)))
    (begin
      (asserts! (is-eq (var-get admin) tx-sender) (err u4))

      (map-set tokens
        { token-id: token-id }
        {
          project-id: project-id,
          owner: tx-sender,
          tons: tons,
          price-per-ton: price-per-ton,
          for-sale: true
        }
      )
      (var-set token-counter (+ token-id u1))
      (ok token-id)
    )
  )
)

;; List token for sale
(define-public (list-for-sale (token-id uint) (price-per-ton uint))
  (let ((token (unwrap! (map-get? tokens { token-id: token-id }) (err u1))))
    (begin
      (asserts! (is-eq (get owner token) tx-sender) (err u2))
      (map-set tokens
        { token-id: token-id }
        (merge token {
          price-per-ton: price-per-ton,
          for-sale: true
        })
      )
      (ok true)
    )
  )
)

;; Delist token from sale
(define-public (delist-from-sale (token-id uint))
  (let ((token (unwrap! (map-get? tokens { token-id: token-id }) (err u1))))
    (begin
      (asserts! (is-eq (get owner token) tx-sender) (err u2))
      (map-set tokens
        { token-id: token-id }
        (merge token { for-sale: false })
      )
      (ok true)
    )
  )
)

;; Buy token
(define-public (buy-token (token-id uint))
  (let (
    (token (unwrap! (map-get? tokens { token-id: token-id }) (err u1)))
    (total-price (* (get price-per-ton token) (get tons token)))
  )
    (begin
      (asserts! (get for-sale token) (err u2))
      (asserts! (not (is-eq (get owner token) tx-sender)) (err u3))

      ;; Transfer STX from buyer to seller
      (try! (stx-transfer? total-price tx-sender (get owner token)))

      ;; Update token ownership
      (map-set tokens
        { token-id: token-id }
        (merge token {
          owner: tx-sender,
          for-sale: false
        })
      )
      (ok true)
    )
  )
)

;; Transfer token
(define-public (transfer-token (token-id uint) (recipient principal))
  (let ((token (unwrap! (map-get? tokens { token-id: token-id }) (err u1))))
    (begin
      (asserts! (is-eq (get owner token) tx-sender) (err u2))
      (map-set tokens
        { token-id: token-id }
        (merge token {
          owner: recipient,
          for-sale: false
        })
      )
      (ok true)
    )
  )
)

;; Get token details
(define-read-only (get-token (token-id uint))
  (map-get? tokens { token-id: token-id })
)

;; Set admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq (var-get admin) tx-sender) (err u4))
    (var-set admin new-admin)
    (ok true)
  )
)

