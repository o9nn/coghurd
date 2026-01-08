# CLAUDE.md - HurdCog Development Guide

## Project Overview

HurdCog is a cognitive AGI operating system that integrates OpenCog's AGI framework with GNU Hurd's microkernel architecture. This creates a self-learning, self-adapting OS that reasons about problems and optimizes itself.

**Status**: Phase 6 Complete - Production Ready

## Repository Structure

```
hurdcog/
├── cogkernel/           # Cognitive kernel components (Scheme/Guile)
│   ├── atomspace.scm    # Hypergraph knowledge base
│   ├── agents.scm       # Distributed agents
│   ├── attention.scm    # ECAN attention allocation
│   ├── cognitive-grip.scm  # 5-finger cognitive grip mechanism
│   ├── machspace.scm    # Distributed hypergraph for Mach
│   ├── aten-tensors.scm # ATen tensor operations
│   ├── atenspace.scm    # ATenSpace neural-symbolic bridge
│   ├── tests/           # Test suite
│   └── examples/        # Example implementations
├── tensorfs/            # Tensor-Enhanced FileSystem
│   ├── tensorfs.scm     # Scheme implementation
│   ├── tensorfs.c       # C implementation
│   └── tensorfs.h       # C header
├── lib*/                # GNU Hurd libraries (C)
├── ext2fs/, tmpfs/, etc # Filesystem implementations
├── proc/, exec/, init/  # Core Hurd servers
├── docs/                # Documentation
├── build/               # Build system docs
├── performance/         # Kokkos optimization
├── distributed/         # Plan9/Inferno integration
└── guix-build-system/   # GNU Guix integration
```

## Build Commands

```bash
# Configure (with cognitive features)
./configure --host=i686-gnu --enable-cognitive

# Build everything
make

# Build cognitive kernel only
make cogkernel

# Run cognitive bootstrap
make hurdcog-bootstrap

# Run cognitive demo
make cognitive-demo

# Run full cognitive test suite
make cognitive-test
```

## Testing

### Python Test Scripts
```bash
# Run Phase 6 comprehensive tests
python3 run-phase6-tests.py

# Validate production readiness
python3 validate-production-readiness.py

# Phase-specific validation
python3 validate-phase3-completion.py
python3 validate-documentation-finalization.py
python3 test_phase4_5_integration.py
```

### Scheme Tests (in cogkernel/)
```bash
cd cogkernel
guile test-simplified-cognitive.scm
guile comprehensive-test.scm
guile hurdcog-bootstrap.scm
```

### Master Control Dashboard
```bash
cd cogkernel
./start-dashboard.sh
# Or manually: python3 fusion-reactor-server.py
# Access at: http://localhost:8080/dashboard
```

## Key Technologies

| Component | Purpose |
|-----------|---------|
| GNU Hurd | Microkernel OS foundation |
| GNU Mach | Core microkernel |
| OpenCog AtomSpace | Hypergraph knowledge base |
| ECAN | Economic Attention Network for resources |
| PLN | Probabilistic Logic Networks for reasoning |
| GNU Guile | Scheme implementation for cognitive code |
| GNU Guix | Declarative package management |
| ATen | C++11 tensor library for neural computation |
| ATenSpace | Neural-symbolic bridge (AtomSpace + tensors) |
| TensorFS | Tensor-enhanced intelligent filesystem |

## Code Style

### Scheme (cogkernel/)
- Use descriptive function names with hyphens: `make-cognitive-grip`
- Document functions with docstrings
- Keep parentheses balanced (use editor support)
- Follow existing module structure with `define-module`

### C (lib*/, servers)
- Follow GNU coding standards
- Use Mach IPC conventions for inter-process communication
- Include copyright headers with GPL license

## Common Issues

### Unbalanced Parentheses in Scheme
The test suite checks for balanced parens. If tests report unbalanced parentheses:
```bash
# Check a specific file
guile -c "(load \"filename.scm\")" 2>&1 | head
```

### Build Dependencies
Required packages (Debian/Ubuntu):
```bash
sudo apt-get install build-essential mig gnumach-dev \
    guile-3.0 guile-3.0-dev git python3
```

## Architecture Notes

### The Five Fingers of Cognitive Grip
```scheme
(make-grip
  #:thumb (atomspace-add object)        ; Universal grip
  #:index (unique-signature object)     ; Identity pointing
  #:middle (pln:validate object)        ; Coherence strength
  #:ring (capability-ring object)       ; Trust binding
  #:pinky (ecan:allocate object))       ; Resource tracking
```

### Data Flow
```
Application Request
       ↓
Cognitive Services Layer (learns, reasons, optimizes)
       ↓
OpenCog AtomSpace (stores knowledge, patterns, state)
       ↓
GNU Hurd Microkernel (executes decisions)
       ↓
Hardware
```

## Important Files

| File | Purpose |
|------|---------|
| `cogkernel/hurdcog-bootstrap.scm` | Minimal bootstrap implementation |
| `cogkernel/atomspace.scm` | Core hypergraph data structure |
| `cogkernel/aten-tensors.scm` | ATen tensor operations |
| `cogkernel/atenspace.scm` | Neural-symbolic bridge |
| `cogkernel/hurd-atomspace-bridge.c` | C bridge to Hurd |
| `tensorfs/tensorfs.scm` | TensorFS Scheme implementation |
| `tensorfs/tensorfs.c` | TensorFS C implementation |
| `Makefile` | Main build configuration |
| `configure.ac` | Autoconf configuration |
| `run-phase6-tests.py` | Comprehensive test runner |

## Documentation

- `README.md` - Project overview
- `CONTRIBUTING.md` - Contribution guidelines
- `docs/AGI_OS_OVERVIEW.md` - What is a cognitive AGI-OS
- `docs/OPENCOG_HURD_INTEGRATION.md` - Technical architecture
- `docs/COGNITIVE_SERVICES_API.md` - Developer API guide
- `cogkernel/README.md` - Cognitive kernel details
- `tensorfs/README.md` - TensorFS documentation
- `DEVELOPMENT_ROADMAP.md` - Project roadmap

## Phase Documentation

- Phase 1: `cogkernel/PHASE1_IMPLEMENTATION_SUMMARY.md` - Foundation
- Phase 2: `cogkernel/PHASE2_MICROKERNEL_INTEGRATION.md` - Microkernel
- Phase 3: `cogkernel/PHASE3_IMPLEMENTATION_SUMMARY.md` - Build orchestration
- Phase 4: `cogkernel/PHASE4_COMPLETION_SUMMARY.md` - Cognitive layer
- Phase 5: `cogkernel/PHASE5_COMPLETION_SUMMARY.md` - Integration
- Phase 6: `PHASE6_COMPLETION_REPORT.md` - Testing & documentation

## Contact

- Bug Reports: bug-hurd@gnu.org
- Help: help-hurd@gnu.org
- IRC: #hurd on libera.chat
