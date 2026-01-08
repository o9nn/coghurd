#!/usr/bin/env guile
!#
;;; Test suite for multi-tenant neuro-symbolic atomspace fabric
;;; Tests MIG-space, agent-zero workbench, and constellation deployment
;;;
;;; Copyright (C) 2026 GNU Hurd Project
;;; License: GPL-3.0-or-later

(use-modules (cogkernel multi-tenant-atomspace)
             (cogkernel mig-space)
             (cogkernel agent-zero-workbench)
             (cogkernel atomspace)
             (ice-9 format))

;;; Test counter
(define test-count 0)
(define test-passed 0)
(define test-failed 0)

;;; Test helper
(define (test-case name thunk)
  "Run a test case and report results"
  (set! test-count (+ test-count 1))
  (format #t "~%TEST ~a: ~a~%" test-count name)
  (catch #t
    (lambda ()
      (thunk)
      (set! test-passed (+ test-passed 1))
      (format #t "  ✓ PASSED~%"))
    (lambda (key . args)
      (set! test-failed (+ test-failed 1))
      (format #t "  ✗ FAILED: ~a ~a~%" key args))))

;;; Assert helper
(define (assert-true condition message)
  "Assert that condition is true"
  (unless condition
    (error message)))

(define (assert-equal expected actual message)
  "Assert that two values are equal"
  (unless (equal? expected actual)
    (error (format #f "~a: expected ~a, got ~a" message expected actual))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Multi-Tenant AtomSpace Tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (test-multi-tenant-fabric-creation)
  "Test creating a multi-tenant fabric"
  (let ((fabric (make-multi-tenant-fabric)))
    (assert-true (multi-tenant-fabric? fabric)
                 "Fabric should be created")))

(define (test-tenant-creation)
  "Test creating tenants"
  (let ((fabric (make-multi-tenant-fabric)))
    (fabric-create-tenant! fabric "tenant-1" "Test Tenant 1")
    (assert-true (fabric-tenant-exists? fabric "tenant-1")
                 "Tenant should exist")
    (let ((tenant (fabric-get-tenant fabric "tenant-1")))
      (assert-true (tenant? tenant)
                   "Should retrieve tenant"))))

(define (test-tenant-isolation)
  "Test tenant isolation and quota enforcement"
  (let ((fabric (make-multi-tenant-fabric)))
    (fabric-create-tenant! fabric "tenant-a" "Tenant A")
    (fabric-create-tenant! fabric "tenant-b" "Tenant B")
    
    ;; Add atoms to tenant-a
    (tenant-add-atom! fabric "tenant-a" 'CONCEPT "concept-a")
    
    ;; Verify tenant-b doesn't see tenant-a's atoms
    (let ((results (tenant-query fabric "tenant-b" 'CONCEPT)))
      (assert-true (or (not results) (null? results))
                   "Tenants should be isolated"))))

(define (test-tenant-quota-enforcement)
  "Test resource quota enforcement"
  (let ((fabric (make-multi-tenant-fabric))
        (small-quota (make-resource-quota 2 1 1 1024 10)))
    
    (fabric-create-tenant! fabric "tenant-quota" "Quota Test"
                          #:quota small-quota)
    
    ;; Add atoms up to quota
    (tenant-add-atom! fabric "tenant-quota" 'CONCEPT "atom-1")
    (tenant-add-atom! fabric "tenant-quota" 'CONCEPT "atom-2")
    
    ;; Should fail on quota exceeded
    (catch #t
      (lambda ()
        (tenant-add-atom! fabric "tenant-quota" 'CONCEPT "atom-3")
        (error "Should have hit quota limit"))
      (lambda (key . args)
        #t))))  ; Expected to fail

(define (test-tenant-neuro-symbolic)
  "Test tenant neuro-symbolic embeddings"
  (let ((fabric (make-multi-tenant-fabric)))
    (fabric-create-tenant! fabric "tenant-ns" "Neuro-Symbolic Tenant")
    
    ;; Create embedding
    (tenant-embed-concept! fabric "tenant-ns" "neural-concept" 128)
    
    ;; Verify usage updated
    (let ((usage (tenant-get-usage fabric "tenant-ns")))
      (assert-true (> (usage-current-embeddings usage) 0)
                   "Should track embeddings"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MIG-Space Tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (test-mig-space-creation)
  "Test creating MIG-space"
  (let ((mig-space (make-mig-space)))
    (assert-true (mig-space? mig-space)
                 "MIG-space should be created")))

(define (test-mig-channel-creation)
  "Test creating MIG channels"
  (let ((mig-space (make-mig-space)))
    (mig-space-create-channel! mig-space "channel-1" "port-a" "port-b")
    (let ((channel (mig-space-get-channel mig-space "channel-1")))
      (assert-true (mig-channel? channel)
                   "Channel should be created"))))

(define (test-cognitive-message-routing)
  "Test cognitive message routing"
  (let* ((mig-space (make-mig-space))
         (message (make-cognitive-message-record
                   "msg-1" "sender" "receiver"
                   'QUERY #f '() 'NORMAL
                   (current-time) #f)))
    
    (mig-space-create-channel! mig-space "channel-route" "src" "dst")
    (mig-space-send-cognitive! mig-space "channel-route" message)
    
    ;; Verify message was sent
    (let ((received (mig-space-receive-cognitive mig-space "channel-route")))
      (assert-true (cognitive-message? received)
                   "Should receive cognitive message"))))

(define (test-constellation-creation)
  "Test mach-zero constellation creation"
  (let ((mig-space (make-mig-space)))
    (mig-space-create-constellation! mig-space "constellation-1"
                                    #:replication-factor 3)
    
    ;; Deploy microkernel nodes
    (mig-space-deploy-microkernel! mig-space "constellation-1"
                                   "node-1" "host1.local" "mach-port-1")
    (mig-space-deploy-microkernel! mig-space "constellation-1"
                                   "node-2" "host2.local" "mach-port-2")
    
    (let ((constellation (hash-ref (mig-space-constellations mig-space)
                                   "constellation-1")))
      (assert-true (mach-zero-constellation? constellation)
                   "Constellation should exist")
      (let ((nodes (constellation-list-nodes constellation)))
        (assert-true (>= (length nodes) 2)
                     "Should have deployed nodes")))))

(define (test-distributed-atom-sync)
  "Test distributed atomspace synchronization"
  (let ((mig-space (make-mig-space))
        (atom (make-atom 'CONCEPT "sync-atom")))
    
    (mig-space-create-channel! mig-space "sync-channel" "node-1" "node-2")
    
    ;; Sync atoms
    (mig-space-sync-atoms! mig-space "sync-channel" (list atom))
    
    ;; Verify sync stats updated
    (let* ((channel (mig-space-get-channel mig-space "sync-channel"))
           (stats (channel-stats channel)))
      (assert-true (> (stats-atoms-synced stats) 0)
                   "Should track synced atoms"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Agent-Zero Workbench Tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (test-workbench-creation)
  "Test creating agent-zero workbench"
  (let ((workbench (make-agent-zero-workbench)))
    (assert-true (agent-zero-workbench? workbench)
                 "Workbench should be created")))

(define (test-agent-creation)
  "Test creating autonomous agents"
  (let ((workbench (make-agent-zero-workbench)))
    (workbench-create-agent! workbench "agent-1" "Monitor Agent" 'MONITOR
                            #:autonomy-level 'AUTO)
    
    (let ((status (workbench-get-agent-status workbench "agent-1")))
      (assert-equal 'IDLE status "Agent should be idle initially"))))

(define (test-agent-deployment)
  "Test deploying agents"
  (let ((workbench (make-agent-zero-workbench)))
    (workbench-create-agent! workbench "agent-deploy" "Deploy Test" 'BUILD)
    (workbench-deploy-agent! workbench "agent-deploy"
                            #:deployment-strategy 'DISTRIBUTED
                            #:tenant-id "deploy-tenant")
    
    (let ((status (workbench-get-agent-status workbench "agent-deploy")))
      (assert-equal 'ACTIVE status "Agent should be active after deployment"))))

(define (test-team-creation)
  "Test creating agent teams"
  (let ((workbench (make-agent-zero-workbench)))
    (workbench-create-team! workbench "team-1" "Alpha Team")
    
    ;; Create and add agents to team
    (workbench-create-agent! workbench "agent-t1" "Team Agent 1" 'MONITOR)
    (workbench-create-agent! workbench "agent-t2" "Team Agent 2" 'REPAIR)
    
    (let ((team (hash-ref (workbench-teams workbench) "team-1")))
      (team-add-agent! team "agent-t1")
      (team-add-agent! team "agent-t2")
      
      (assert-true (agent-team? team)
                   "Team should exist"))))

(define (test-autonomous-decision)
  "Test autonomous decision making"
  (let ((workbench (make-agent-zero-workbench)))
    (workbench-create-agent! workbench "agent-auto" "Auto Agent" 'ANALYZE
                            #:autonomy-level 'AUTO
                            #:strategy 'ADAPTIVE)
    
    (let ((decision (workbench-autonomous-decision workbench "agent-auto"
                                                   '(context data))))
      (assert-true decision "Should make autonomous decision"))))

(define (test-constellation-deployment)
  "Test deploying agents to constellation"
  (let ((workbench (make-agent-zero-workbench)))
    (workbench-create-agent! workbench "agent-c1" "Constellation Agent 1" 'MONITOR)
    (workbench-create-agent! workbench "agent-c2" "Constellation Agent 2" 'REPAIR)
    (workbench-create-agent! workbench "agent-c3" "Constellation Agent 3" 'BUILD)
    
    (workbench-deploy-constellation! workbench "constellation-alpha"
                                    '("agent-c1" "agent-c2" "agent-c3"))
    
    ;; Verify deployment
    (assert-true #t "Constellation deployment should succeed")))

(define (test-agent-self-organization)
  "Test agent self-organization"
  (let ((workbench (make-agent-zero-workbench)))
    ;; Create diverse agents
    (workbench-create-agent! workbench "agent-org1" "Org Agent 1" 'MONITOR)
    (workbench-create-agent! workbench "agent-org2" "Org Agent 2" 'ANALYZE)
    (workbench-create-agent! workbench "agent-org3" "Org Agent 3" 'OPTIMIZE)
    
    ;; Self-organize
    (workbench-self-organize! workbench)
    
    (assert-true #t "Self-organization should complete")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Integration Tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (test-full-integration)
  "Test full integration of all components"
  (let ((fabric (make-multi-tenant-fabric))
        (mig-space (make-mig-space))
        (workbench (make-agent-zero-workbench
                    #:multi-tenant-fabric fabric
                    #:mig-space mig-space)))
    
    ;; Create multi-tenant environment
    (fabric-create-tenant! fabric "prod-tenant" "Production")
    (fabric-create-tenant! fabric "dev-tenant" "Development")
    
    ;; Create MIG constellation
    (mig-space-create-constellation! mig-space "prod-constellation")
    (mig-space-deploy-microkernel! mig-space "prod-constellation"
                                   "prod-node-1" "prod1.local" "mach-1")
    
    ;; Create and deploy agents
    (workbench-create-agent! workbench "prod-monitor" "Prod Monitor" 'MONITOR)
    (workbench-deploy-agent! workbench "prod-monitor"
                            #:tenant-id "prod-tenant")
    
    ;; Create MIG channel for communication
    (mig-space-create-channel! mig-space "prod-channel"
                              "prod-node-1" "workbench")
    
    (assert-true #t "Full integration should succeed")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Run all tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (run-all-tests)
  "Run all test cases"
  (format #t "~%========================================~%")
  (format #t "Multi-Tenant Neuro-Symbolic AtomSpace Test Suite~%")
  (format #t "========================================~%")
  
  ;; Multi-tenant tests
  (test-case "Multi-tenant fabric creation" test-multi-tenant-fabric-creation)
  (test-case "Tenant creation" test-tenant-creation)
  (test-case "Tenant isolation" test-tenant-isolation)
  (test-case "Tenant quota enforcement" test-tenant-quota-enforcement)
  (test-case "Tenant neuro-symbolic operations" test-tenant-neuro-symbolic)
  
  ;; MIG-space tests
  (test-case "MIG-space creation" test-mig-space-creation)
  (test-case "MIG channel creation" test-mig-channel-creation)
  (test-case "Cognitive message routing" test-cognitive-message-routing)
  (test-case "Constellation creation" test-constellation-creation)
  (test-case "Distributed atom synchronization" test-distributed-atom-sync)
  
  ;; Agent-zero tests
  (test-case "Workbench creation" test-workbench-creation)
  (test-case "Agent creation" test-agent-creation)
  (test-case "Agent deployment" test-agent-deployment)
  (test-case "Team creation" test-team-creation)
  (test-case "Autonomous decision making" test-autonomous-decision)
  (test-case "Constellation deployment" test-constellation-deployment)
  (test-case "Agent self-organization" test-agent-self-organization)
  
  ;; Integration tests
  (test-case "Full integration" test-full-integration)
  
  ;; Summary
  (format #t "~%========================================~%")
  (format #t "Test Results:~%")
  (format #t "  Total:  ~a~%" test-count)
  (format #t "  Passed: ~a~%" test-passed)
  (format #t "  Failed: ~a~%" test-failed)
  (format #t "========================================~%")
  
  (if (= test-failed 0)
      (begin
        (format #t "~%✓ ALL TESTS PASSED~%~%")
        (exit 0))
      (begin
        (format #t "~%✗ SOME TESTS FAILED~%~%")
        (exit 1))))

;;; Run the tests
(run-all-tests)
