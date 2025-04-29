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
