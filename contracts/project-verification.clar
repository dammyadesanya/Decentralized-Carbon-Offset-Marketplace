;; Project Verification Contract
;; This contract validates carbon reduction initiatives

(define-data-var admin principal tx-sender)

;; Project status enum
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_REJECTED u2)

;; Project data structure
(define-map projects
  { project-id: uint }
  {
    owner: principal,
    name: (string-utf8 100),
    description: (string-utf8 500),
    location: (string-utf8 100),
    status: uint,
    verification-date: uint,
    verifier: (optional principal)
  }
)

;; Project counter
(define-data-var project-counter uint u0)

;; Register a new project
(define-public (register-project (name (string-utf8 100)) (description (string-utf8 500)) (location (string-utf8 100)))
  (let ((project-id (var-get project-counter)))
    (begin
      (map-set projects
        { project-id: project-id }
        {
          owner: tx-sender,
          name: name,
          description: description,
          location: location,
          status: STATUS_PENDING,
          verification-date: u0,
          verifier: none
        }
      )
      (var-set project-counter (+ project-id u1))
      (ok project-id)
    )
  )
)

;; Verify a project
(define-public (verify-project (project-id uint))
  (let ((project (unwrap! (map-get? projects { project-id: project-id }) (err u1))))
    (begin
      (asserts! (is-eq (var-get admin) tx-sender) (err u2))
      (map-set projects
        { project-id: project-id }
        (merge project {
          status: STATUS_VERIFIED,
          verification-date: block-height,
          verifier: (some tx-sender)
        })
      )
      (ok true)
    )
  )
)

;; Reject a project
(define-public (reject-project (project-id uint))
  (let ((project (unwrap! (map-get? projects { project-id: project-id }) (err u1))))
    (begin
      (asserts! (is-eq (var-get admin) tx-sender) (err u2))
      (map-set projects
        { project-id: project-id }
        (merge project {
          status: STATUS_REJECTED,
          verification-date: block-height,
          verifier: (some tx-sender)
        })
      )
      (ok true)
    )
  )
)

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Set admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq (var-get admin) tx-sender) (err u3))
    (var-set admin new-admin)
    (ok true)
  )
)

