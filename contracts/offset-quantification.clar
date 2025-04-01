;; Offset Quantification Contract
;; This contract measures carbon impact of projects

(define-data-var admin principal tx-sender)

;; Offset data structure
(define-map offsets
  { project-id: uint }
  {
    total-tons: uint,
    verification-method: (string-utf8 100),
    verification-date: uint,
    expiration-date: uint
  }
)

;; Project verification contract
(define-constant project-verification-contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.project-verification)

;; Quantify carbon offsets for a project
(define-public (quantify-offsets (project-id uint) (tons uint) (method (string-utf8 100)) (expiration-date uint))
  (begin
    (asserts! (> expiration-date block-height) (err u3))
    (asserts! (is-eq (var-get admin) tx-sender) (err u2))

    (map-set offsets
      { project-id: project-id }
      {
        total-tons: tons,
        verification-method: method,
        verification-date: block-height,
        expiration-date: expiration-date
      }
    )
    (ok true)
  )
)

;; Update offset quantity
(define-public (update-offset-quantity (project-id uint) (new-tons uint))
  (let ((offset (unwrap! (map-get? offsets { project-id: project-id }) (err u1))))
    (begin
      (asserts! (is-eq (var-get admin) tx-sender) (err u2))
      (map-set offsets
        { project-id: project-id }
        (merge offset { total-tons: new-tons })
      )
      (ok true)
    )
  )
)

;; Get offset details
(define-read-only (get-offset (project-id uint))
  (map-get? offsets { project-id: project-id })
)

;; Check if offset is valid (not expired)
(define-read-only (is-offset-valid (project-id uint))
  (match (map-get? offsets { project-id: project-id })
    offset (< block-height (get expiration-date offset))
    false
  )
)

;; Set admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq (var-get admin) tx-sender) (err u3))
    (var-set admin new-admin)
    (ok true)
  )
)

