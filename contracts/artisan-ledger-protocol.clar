;; Artisan Ledger: Creative Works Management Protocol
;; 
;; A comprehensive system for documenting and tracking creative works
;; This contract establishes a decentralized ecosystem for creative works management


;; ------------------------------------------------------------
;; Data Structures and Mappings
;; ------------------------------------------------------------

;; Primary opus registry tracking all submitted creative works
(define-map opus-catalog
    {reference-id: uint}  ;; Key: Unique opus identifier
    {
        title: (string-ascii 64),           ;; Opus title (max 64 chars)
        creator: (string-ascii 32),         ;; Original creator name
        rights-owner: principal,            ;; Current rights owner address
        duration-measure: uint,             ;; Duration measurement
        registration-timestamp: uint,       ;; Block height at registration
        classification: (string-ascii 32),  ;; Style/genre classification
        tags: (list 8 (string-ascii 24))    ;; Descriptive tags for search
    }
)

;; Showcase collections registry
(define-map showcase-catalog
    {reference-id: uint}  ;; Key: Showcase ID
    {
        name: (string-ascii 64),           ;; Showcase name
        synopsis: (string-ascii 256),      ;; Showcase purpose
        curator: principal,                ;; Showcase originator
        theme: (string-ascii 32),          ;; Primary theme
        inception-timestamp: uint,         ;; Creation block
        last-updated-timestamp: uint,      ;; Last modification block
        works-count: uint,                 ;; Number of works included
        open-participation: bool           ;; Collaboration setting
    }
)

;; Showcase participants tracking
(define-map showcase-participants
    {showcase-id: uint, participant: principal}  ;; Key: Showcase ID and participant
    {
        active-status: bool,           ;; Active participant status
        enrollment-timestamp: uint,    ;; Block when joined
        curator-status: bool           ;; Primary curator indicator
    }
)

;; Tracks works included in showcases
(define-map showcase-works
    {showcase-id: uint, opus-id: uint}  ;; Key: Showcase ID and opus ID
    {
        contributor: principal,     ;; Who added this work
        inclusion-timestamp: uint   ;; When added
    }
)

;; Viewing permissions mapping for each opus
(define-map viewing-permissions
    {opus-id: uint, viewer: principal}  ;; Key: Opus ID and viewer principal
    {permission-granted: bool}  ;; Whether viewing is permitted
)

;; User collections registry
(define-map personal-collections
    {owner: principal, collection-id: uint}  ;; Key: Collection owner and ID
    {
        name: (string-ascii 64),           ;; Collection name
        description: (string-ascii 128),   ;; Collection purpose
        creation-timestamp: uint,          ;; Creation block
        update-timestamp: uint,            ;; Last update block
        works-count: uint,                 ;; Number of works included
        visibility-public: bool            ;; Public visibility setting
    }
)

;; Tracks works within each collection
(define-map collection-works
    {owner: principal, collection-id: uint, opus-id: uint}  ;; Key: Owner, collection ID, and opus ID
    {
        added-timestamp: uint,  ;; Block when added
        position: uint          ;; Ordering position
    }
)

;; Tracks collection count for each user
(define-map collection-counters
    {owner: principal}  ;; Key: Owner principal
    {latest-id: uint}   ;; Most recent collection ID
)

;; Permission grant history
(define-map permission-history
    {opus-id: uint, grantor: principal, recipient: principal}  ;; Key: Opus ID, grantor, and recipient
    {
        grant-timestamp: uint,      ;; When access was granted
        revocation-timestamp: uint, ;; When access was revoked (0 if active)
        active-status: bool         ;; Current status
    }
)

;; Viewer response registry
(define-map viewer-responses
    {opus-id: uint, responder: principal}  ;; Key: Opus ID and responder
    {
        rating: uint,                          ;; Numeric rating (1-5)
        notes: (optional (string-ascii 256)),  ;; Optional comments
        last-updated: uint,                    ;; Last update block
        first-response: uint                   ;; First response block
    }
)

;; Aggregated response metrics
(define-map response-metrics
    {opus-id: uint}  ;; Key: Opus ID
    {
        total-responses: uint,     ;; Total responses received
        last-response-block: uint  ;; Most recent response block
    }
)




;; ------------------------------------------------------------
;; Global Registry Counters
;; ------------------------------------------------------------
(define-data-var opus-ledger-counter uint u0)    ;; Tracks total number of registered creative works
(define-data-var showcase-ledger-counter uint u0) ;; Tracks total number of thematic showcases

;; ------------------------------------------------------------
;; System Response Codes
;; ------------------------------------------------------------
(define-constant RESPONSE-UNAUTHORIZED-ACCESS (err u305))
(define-constant RESPONSE-GOVERNANCE-ONLY (err u307))
(define-constant NEXUS-GOVERNOR tx-sender)
(define-constant RESPONSE-ITEM-NONEXISTENT (err u301))
(define-constant RESPONSE-CONSTRAINT-VIOLATION (err u304))
(define-constant RESPONSE-INSUFFICIENT-RIGHTS (err u306))
(define-constant RESPONSE-PROHIBITED-ACTION (err u308))
(define-constant RESPONSE-DUPLICATE-ENTRY (err u302))
(define-constant RESPONSE-VALIDATION-FAILED (err u303))


;; ------------------------------------------------------------
;; Helper Functions (Private)
;; ------------------------------------------------------------

;; Verifies existence of an opus in the catalog
(define-private (opus-exists (opus-id uint))
    (is-some (map-get? opus-catalog {reference-id: opus-id}))
)

;; Verifies rights ownership for an opus
(define-private (is-rights-owner (opus-id uint) (user principal))
    (match (map-get? opus-catalog {reference-id: opus-id})
        opus-data (is-eq (get rights-owner opus-data) user)
        false
    )
)

;; Retrieves opus duration
(define-private (get-opus-duration (opus-id uint))
    (default-to u0 
        (get duration-measure 
            (map-get? opus-catalog {reference-id: opus-id})
        )
    )
)

;; Validates tag formatting requirements
(define-private (is-valid-tag (tag (string-ascii 24)))
    (and 
        (> (len tag) u0)
        (< (len tag) u25)
    )
)

;; Validates that all tags meet system requirements
(define-private (are-valid-tags (tags (list 8 (string-ascii 24))))
    (and
        (> (len tags) u0)
        (<= (len tags) u8)
        (is-eq (len (filter is-valid-tag tags)) (len tags))
    )
)

;; Retrieves user's most recent collection ID
(define-private (get-latest-collection-id (owner principal))
    (get latest-id (default-to {latest-id: u0} 
        (map-get? collection-counters {owner: owner})))
)

;; Prepares opus identifiers for batch processing
(define-private (prepare-opus-id (opus-id uint))
    {opus-id: opus-id}
)

;; Integrates opus into showcase during batch operations
(define-private (add-opus-to-showcase (opus-data {opus-id: uint}))
    (let
        ((opus-id (get opus-id opus-data)))
        (and 
            (opus-exists opus-id)
            (map-insert showcase-works
                {showcase-id: (var-get showcase-ledger-counter), opus-id: opus-id}
                {
                    contributor: tx-sender,
                    inclusion-timestamp: block-height
                }
            )
        )
    )
)

;; ------------------------------------------------------------
;; Public Interface Functions
;; ------------------------------------------------------------

;; Records a new creative work in the system
(define-public (register-opus 
        (title (string-ascii 64))
        (creator (string-ascii 32))
        (duration-measure uint)
        (classification (string-ascii 32))
        (tags (list 8 (string-ascii 24)))
    )
    (let
        ((new-opus-id (+ (var-get opus-ledger-counter) u1)))

        ;; Input validation
        (asserts! (and (> (len title) u0) (< (len title) u65)) RESPONSE-VALIDATION-FAILED)
        (asserts! (and (> (len creator) u0) (< (len creator) u33)) RESPONSE-VALIDATION-FAILED)
        (asserts! (and (> duration-measure u0) (< duration-measure u10000)) RESPONSE-CONSTRAINT-VIOLATION)
        (asserts! (and (> (len classification) u0) (< (len classification) u33)) RESPONSE-VALIDATION-FAILED)
        (asserts! (are-valid-tags tags) RESPONSE-VALIDATION-FAILED)

        ;; Record opus in catalog
        (map-insert opus-catalog
            {reference-id: new-opus-id}
            {
                title: title,
                creator: creator,
                rights-owner: tx-sender,
                duration-measure: duration-measure,
                registration-timestamp: block-height,
                classification: classification,
                tags: tags
            }
        )

        ;; Establish initial viewing permissions
        (map-insert viewing-permissions
            {opus-id: new-opus-id, viewer: tx-sender}
            {permission-granted: true}
        )

        ;; Update catalog counter and return new ID
        (var-set opus-ledger-counter new-opus-id)
        (ok new-opus-id)
    )
)

;; Removes a creative work from the system
(define-public (remove-opus (opus-id uint))
    (let
        ((opus-data (unwrap! (map-get? opus-catalog {reference-id: opus-id}) RESPONSE-ITEM-NONEXISTENT)))

        ;; Validate existence and ownership
        (asserts! (opus-exists opus-id) RESPONSE-ITEM-NONEXISTENT)
        (asserts! (is-eq (get rights-owner opus-data) tx-sender) RESPONSE-UNAUTHORIZED-ACCESS)

        ;; Remove opus data
        (map-delete opus-catalog {reference-id: opus-id})
        (map-delete viewing-permissions {opus-id: opus-id, viewer: tx-sender})
        (ok true)
    )
)

;; Transfers opus ownership rights
(define-public (transfer-opus-rights (opus-id uint) (new-owner principal))
    (let
        ((opus-data (unwrap! (map-get? opus-catalog {reference-id: opus-id}) RESPONSE-ITEM-NONEXISTENT)))

        ;; Validate existence and ownership
        (asserts! (opus-exists opus-id) RESPONSE-ITEM-NONEXISTENT)
        (asserts! (is-eq (get rights-owner opus-data) tx-sender) RESPONSE-UNAUTHORIZED-ACCESS)

        ;; Update rights owner
        (map-set opus-catalog
            {reference-id: opus-id}
            (merge opus-data {rights-owner: new-owner})
        )
        (ok true)
    )
)

;; Updates opus metadata
(define-public (update-opus-metadata 
        (opus-id uint) 
        (new-title (string-ascii 64)) 
        (new-duration uint) 
        (new-classification (string-ascii 32)) 
        (new-tags (list 8 (string-ascii 24)))
    )
    (let
        ((opus-data (unwrap! (map-get? opus-catalog {reference-id: opus-id}) RESPONSE-ITEM-NONEXISTENT)))

        ;; Validate existence and ownership
        (asserts! (opus-exists opus-id) RESPONSE-ITEM-NONEXISTENT)
        (asserts! (is-eq (get rights-owner opus-data) tx-sender) RESPONSE-UNAUTHORIZED-ACCESS)
        (asserts! (and (> (len new-title) u0) (< (len new-title) u65)) RESPONSE-VALIDATION-FAILED)
        (asserts! (and (> new-duration u0) (< new-duration u10000)) RESPONSE-CONSTRAINT-VIOLATION)
        (asserts! (and (> (len new-classification) u0) (< (len new-classification) u33)) RESPONSE-VALIDATION-FAILED)
        (asserts! (are-valid-tags new-tags) RESPONSE-VALIDATION-FAILED)

        ;; Update opus metadata
        (map-set opus-catalog
            {reference-id: opus-id}
            (merge opus-data {
                title: new-title,
                duration-measure: new-duration,
                classification: new-classification,
                tags: new-tags
            })
        )
        (ok true)
    )
)

;; Adds an opus to personal collection
(define-public (add-to-collection 
        (collection-id uint)
        (opus-id uint)
    )
    (let
        ((collection-data (unwrap! (map-get? personal-collections {owner: tx-sender, collection-id: collection-id}) RESPONSE-ITEM-NONEXISTENT))
         (opus-data (unwrap! (map-get? opus-catalog {reference-id: opus-id}) RESPONSE-ITEM-NONEXISTENT))
         (viewer-permission (default-to {permission-granted: false} (map-get? viewing-permissions {opus-id: opus-id, viewer: tx-sender}))))

        ;; Validation
        (asserts! (opus-exists opus-id) RESPONSE-ITEM-NONEXISTENT)
        (asserts! (or 
                    (is-eq (get rights-owner opus-data) tx-sender)
                    (get permission-granted viewer-permission)
                  ) 
                RESPONSE-INSUFFICIENT-RIGHTS)

        ;; Check for duplicates
        (asserts! (is-none (map-get? collection-works {owner: tx-sender, collection-id: collection-id, opus-id: opus-id})) 
                 RESPONSE-DUPLICATE-ENTRY)

        (ok true)
    )
)

;; Grants viewing permission for an opus
(define-public (grant-opus-permission 
        (opus-id uint)
        (recipient principal)
    )
    (let
        ((opus-data (unwrap! (map-get? opus-catalog {reference-id: opus-id}) RESPONSE-ITEM-NONEXISTENT)))

        ;; Validation
        (asserts! (opus-exists opus-id) RESPONSE-ITEM-NONEXISTENT)
        (asserts! (is-eq (get rights-owner opus-data) tx-sender) RESPONSE-UNAUTHORIZED-ACCESS)
        (asserts! (not (is-eq tx-sender recipient)) RESPONSE-VALIDATION-FAILED)

        ;; Check for existing permission
        (asserts! (is-none (map-get? viewing-permissions {opus-id: opus-id, viewer: recipient})) 
                 RESPONSE-DUPLICATE-ENTRY)

        ;; Grant permission
        (map-insert viewing-permissions
            {opus-id: opus-id, viewer: recipient}
            {permission-granted: true}
        )

        ;; Record permission history
        (map-insert permission-history
            {opus-id: opus-id, grantor: tx-sender, recipient: recipient}
            {
                grant-timestamp: block-height,
                revocation-timestamp: u0,
                active-status: true
            }
        )

        (ok true)
    )
)

;; Revokes previously granted viewing permission
(define-public (revoke-opus-permission 
        (opus-id uint)
        (recipient principal)
    )
    (let
        ((opus-data (unwrap! (map-get? opus-catalog {reference-id: opus-id}) RESPONSE-ITEM-NONEXISTENT))
         (permission-data (unwrap! (map-get? permission-history {opus-id: opus-id, grantor: tx-sender, recipient: recipient}) RESPONSE-ITEM-NONEXISTENT)))

        ;; Validation
        (asserts! (opus-exists opus-id) RESPONSE-ITEM-NONEXISTENT)
        (asserts! (is-eq (get rights-owner opus-data) tx-sender) RESPONSE-UNAUTHORIZED-ACCESS)
        (asserts! (get active-status permission-data) RESPONSE-INSUFFICIENT-RIGHTS)

        (ok true)
    )
)

;; Submits viewer response for an opus
(define-public (submit-opus-response 
        (opus-id uint)
        (rating uint)
        (notes (optional (string-ascii 256)))
    )
    (let
        ((opus-data (unwrap! (map-get? opus-catalog {reference-id: opus-id}) RESPONSE-ITEM-NONEXISTENT))
         (viewer-permission (default-to {permission-granted: false} (map-get? viewing-permissions {opus-id: opus-id, viewer: tx-sender})))
         (existing-response (map-get? viewer-responses {opus-id: opus-id, responder: tx-sender})))

        ;; Validation
        (asserts! (opus-exists opus-id) RESPONSE-ITEM-NONEXISTENT)
        (asserts! (or 
                    (is-eq (get rights-owner opus-data) tx-sender)
                    (get permission-granted viewer-permission)
                  ) 
                RESPONSE-INSUFFICIENT-RIGHTS)
        (asserts! (and (>= rating u1) (<= rating u5)) RESPONSE-VALIDATION-FAILED)

        ;; Validate notes length if provided
        (if (is-some notes)
            (asserts! (and 
                        (> (len (default-to "" notes)) u0) 
                        (< (len (default-to "" notes)) u257)
                      ) 
                    RESPONSE-VALIDATION-FAILED)
            true
        )

        ;; Store or update response
        (if (is-some existing-response)
            ;; Update existing response
            (map-set viewer-responses
                {opus-id: opus-id, responder: tx-sender}
                {
                    rating: rating,
                    notes: notes,
                    last-updated: block-height,
                    first-response: (get first-response (unwrap! existing-response RESPONSE-ITEM-NONEXISTENT))
                }
            )
            ;; Create new response
            (map-insert viewer-responses
                {opus-id: opus-id, responder: tx-sender}
                {
                    rating: rating,
                    notes: notes,
                    last-updated: block-height,
                    first-response: block-height
                }
            )
        )

        ;; Update response metrics
        (match (map-get? response-metrics {opus-id: opus-id})
            existing-metrics (map-set response-metrics
                {opus-id: opus-id}
                (merge existing-metrics {
                    total-responses: (if (is-some existing-response) 
                                      (get total-responses existing-metrics) 
                                      (+ (get total-responses existing-metrics) u1)),
                    last-response-block: block-height
                })
            )
            (map-insert response-metrics
                {opus-id: opus-id}
                {
                    total-responses: u1,
                    last-response-block: block-height
                }
            )
        )

        (ok true)
    )
)

;; Creates a thematic showcase of works
(define-public (create-thematic-showcase
        (showcase-name (string-ascii 64))
        (synopsis (string-ascii 256))
        (theme (string-ascii 32))
        (initial-works (list 20 uint))
        (open-participation bool)
    )
    (let
        ((new-showcase-id (+ (var-get showcase-ledger-counter) u1))
         (valid-works (filter opus-exists initial-works)))

        ;; Validation
        (asserts! (and (> (len showcase-name) u0) (< (len showcase-name) u65)) RESPONSE-VALIDATION-FAILED)
        (asserts! (and (> (len synopsis) u0) (< (len synopsis) u257)) RESPONSE-VALIDATION-FAILED)
        (asserts! (and (> (len theme) u0) (< (len theme) u33)) RESPONSE-VALIDATION-FAILED)

        ;; Register curator as participant
        (map-insert showcase-participants
            {showcase-id: new-showcase-id, participant: tx-sender}
            {
                active-status: true,
                enrollment-timestamp: block-height,
                curator-status: true
            }
        )

        ;; Add validated works to showcase
        (map add-opus-to-showcase (map prepare-opus-id valid-works))

        ;; Update showcase counter
        (var-set showcase-ledger-counter new-showcase-id)

        (ok new-showcase-id)
    )
)

