# Quick Start: Multi-Tenant Neuro-Symbolic AtomSpace

## Installation

No installation needed - modules are ready to use in the cogkernel directory.

## Quick Examples

### 1. Multi-Tenant AtomSpace Fabric

```scheme
(use-modules (cogkernel multi-tenant-atomspace))

;; Create fabric
(define fabric (make-multi-tenant-fabric))

;; Create tenants
(fabric-create-tenant! fabric "customer-a" "Customer A")
(fabric-create-tenant! fabric "customer-b" "Customer B")

;; Add atoms with quota enforcement
(tenant-add-atom! fabric "customer-a" 'CONCEPT "neural-model")
(tenant-add-atom! fabric "customer-b" 'CONCEPT "ml-pipeline")

;; Create neuro-symbolic embeddings
(tenant-embed-concept! fabric "customer-a" "ai-service" 256)

;; Query within tenant namespace
(tenant-query fabric "customer-a" 'CONCEPT)

;; Check resource usage
(tenant-get-usage fabric "customer-a")
```

### 2. MIG-Space Distributed Architecture

```scheme
(use-modules (cogkernel mig-space))

;; Create MIG-space
(define mig-space (make-mig-space))

;; Create cognitive channel
(mig-space-create-channel! mig-space "auth-channel" 
                          "auth-server" "client")

;; Send cognitive message
(define message (make-cognitive-message-record
                 "msg-001" "sender" "receiver"
                 'QUERY #f '() 'HIGH (current-time) #f))
(mig-space-send-cognitive! mig-space "auth-channel" message)

;; Create constellation
(mig-space-create-constellation! mig-space "hurd-cluster")

;; Deploy microkernel nodes
(mig-space-deploy-microkernel! mig-space "hurd-cluster"
                              "node-1" "host1.local" "mach-port-1")

;; Sync atoms across distributed nodes
(mig-space-sync-atoms! mig-space "auth-channel" 
                      (list (make-atom 'CONCEPT "distributed-state")))
```

### 3. Agent-Zero Orchestration Workbench

```scheme
(use-modules (cogkernel agent-zero-workbench))

;; Create workbench
(define workbench (make-agent-zero-workbench))

;; Create autonomous agents
(workbench-create-agent! workbench "agent-1" "Monitor Agent" 'MONITOR
                        #:autonomy-level 'AUTO
                        #:strategy 'ADAPTIVE)

(workbench-create-agent! workbench "agent-2" "Repair Agent" 'REPAIR
                        #:autonomy-level 'AUTO
                        #:strategy 'PROACTIVE)

;; Deploy agents
(workbench-deploy-agent! workbench "agent-1"
                        #:deployment-strategy 'DISTRIBUTED)

;; Create team
(workbench-create-team! workbench "ops-team" "Operations Team")
(let ((team (hash-ref (workbench-teams workbench) "ops-team")))
  (team-add-agent! team "agent-1")
  (team-add-agent! team "agent-2"))

;; Autonomous decision making
(workbench-autonomous-decision workbench "agent-1" 
                              '((context . "high-load")))

;; Self-organize agents
(workbench-self-organize! workbench)

;; Monitor agents
(workbench-monitor-agents workbench)
```

### 4. Integrated System

```scheme
(use-modules (cogkernel multi-tenant-atomspace)
             (cogkernel mig-space)
             (cogkernel agent-zero-workbench))

;; Create integrated system
(define fabric (make-multi-tenant-fabric))
(define mig-space (make-mig-space))
(define workbench (make-agent-zero-workbench
                   #:multi-tenant-fabric fabric
                   #:mig-space mig-space))

;; Create production environment
(fabric-create-tenant! fabric "prod" "Production")
(mig-space-create-constellation! mig-space "prod-cluster")
(workbench-create-agent! workbench "prod-agent" "Prod Monitor" 'MONITOR)
(workbench-deploy-agent! workbench "prod-agent" #:tenant-id "prod")

;; Create development environment
(fabric-create-tenant! fabric "dev" "Development")
(workbench-create-agent! workbench "dev-agent" "Dev Builder" 'BUILD)
(workbench-deploy-agent! workbench "dev-agent" #:tenant-id "dev")

;; Create communication channel
(mig-space-create-channel! mig-space "prod-to-dev" "prod" "dev")

;; Deploy constellation
(workbench-deploy-constellation! workbench "prod-cluster"
                                '("prod-agent" "dev-agent"))
```

## Running Tests

```bash
cd cogkernel

# Run comprehensive test suite (requires Guile)
guile test-multi-tenant-integration.scm

# Run interactive demonstration (requires Guile)
guile demo-multi-tenant-neuro-symbolic.scm

# Validate implementation (Python)
cd ..
python3 validate-multi-tenant-implementation.py
```

## Common Operations

### Tenant Management

```scheme
;; List all tenants
(fabric-list-tenants fabric)

;; Delete tenant
(fabric-delete-tenant! fabric "tenant-id")

;; Set custom quota
(tenant-set-quota! fabric "tenant-id"
  (make-resource-quota 100000 50000 10000 10485760 300))

;; Get tenant statistics
(let ((tenant (fabric-get-tenant fabric "tenant-id")))
  (tenant-stats tenant))
```

### MIG Channel Operations

```scheme
;; List channels
(mig-space-list-channels mig-space)

;; Receive message
(mig-space-receive-cognitive mig-space "channel-id")

;; Route optimization
(mig-space-optimize-routes! mig-space)

;; Display statistics
(mig-space-stats mig-space)
```

### Agent Operations

```scheme
;; Get agent status
(workbench-get-agent-status workbench "agent-id")

;; Restart agent
(workbench-restart-agent! workbench "agent-id")

;; Terminate agent
(workbench-terminate-agent! workbench "agent-id")

;; Scale deployment
(workbench-scale-deployment! workbench "team-id" 2)

;; Health check
(workbench-health-check workbench)

;; Get metrics
(workbench-get-metrics workbench)

;; Display status
(workbench-status workbench)
```

## API Reference

### Multi-Tenant AtomSpace

- `make-multi-tenant-fabric` - Create fabric
- `fabric-create-tenant!` - Create tenant
- `fabric-delete-tenant!` - Delete tenant
- `fabric-get-tenant` - Get tenant by ID
- `fabric-list-tenants` - List all tenants
- `tenant-add-atom!` - Add atom with quota check
- `tenant-query` - Query tenant's atomspace
- `tenant-embed-concept!` - Create embedding
- `tenant-semantic-search` - Semantic search
- `tenant-set-quota!` - Set resource quota
- `tenant-get-usage` - Get resource usage

### MIG-Space

- `make-mig-space` - Create MIG-space
- `mig-space-create-channel!` - Create channel
- `mig-space-destroy-channel!` - Destroy channel
- `mig-space-send-cognitive!` - Send message
- `mig-space-receive-cognitive` - Receive message
- `mig-space-create-constellation!` - Create constellation
- `mig-space-deploy-microkernel!` - Deploy node
- `mig-space-sync-atoms!` - Sync atoms
- `mig-space-optimize-routes!` - Optimize routes

### Agent-Zero Workbench

- `make-agent-zero-workbench` - Create workbench
- `workbench-create-agent!` - Create agent
- `workbench-deploy-agent!` - Deploy agent
- `workbench-terminate-agent!` - Terminate agent
- `workbench-restart-agent!` - Restart agent
- `workbench-create-team!` - Create team
- `workbench-assign-mission!` - Assign mission
- `workbench-autonomous-decision` - Autonomous decision
- `workbench-self-organize!` - Self-organize
- `workbench-deploy-constellation!` - Deploy to constellation

## Documentation

- **Architecture Guide**: `cogkernel/MULTI_TENANT_ARCHITECTURE.md`
- **Implementation Summary**: `MULTI_TENANT_IMPLEMENTATION_SUMMARY.md`
- **Main README**: `README.md`
- **Module Source**: `cogkernel/multi-tenant-atomspace.scm`
- **Module Source**: `cogkernel/mig-space.scm`
- **Module Source**: `cogkernel/agent-zero-workbench.scm`

## Support

For issues and questions:
- **Bug Reports**: bug-hurd@gnu.org
- **Help**: help-hurd@gnu.org
- **IRC**: #hurd on libera.chat

## License

Copyright (C) 2026 GNU Hurd Project  
License: GPL-3.0-or-later
