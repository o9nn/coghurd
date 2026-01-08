# TensorFS - Tensor-Enhanced Hurd FileSystem

**Multi-Entity & Multi-Scale Network-Aware Tensor-Enhanced FileSystem**

TensorFS is a next-generation filesystem that combines the symbolic reasoning capabilities of OpenCog AtomSpace with neural tensor embeddings from ATen, creating an intelligent, semantic-aware file management system for GNU Hurd.

## Overview

TensorFS represents files and directories as nodes in a hypergraph knowledge base, each enhanced with tensor embeddings that capture semantic content. This enables:

- **Semantic Search**: Find files by meaning, not just filename patterns
- **Multi-Scale Navigation**: Browse the filesystem at different levels of abstraction
- **Multi-Entity Collaboration**: Fine-grained sharing and collaborative editing
- **Network-Aware Distribution**: Intelligent partitioning and replication
- **Attention-Based Caching**: Prioritize frequently accessed content
- **Cognitive Reasoning**: Infer relationships and suggest organization

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     TensorFS                                 │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Semantic   │  │ Multi-Scale │  │   Network   │         │
│  │   Search    │  │  Navigation │  │   Aware     │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│  ┌──────▼────────────────▼────────────────▼──────┐         │
│  │              ATenSpace Bridge                  │         │
│  │   (Neural-Symbolic Integration Layer)         │         │
│  └──────┬────────────────┬────────────────┬──────┘         │
│         │                │                │                 │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐         │
│  │  AtomSpace  │  │    ATen     │  │  Attention  │         │
│  │ (Hypergraph)│  │  (Tensors)  │  │    (ECAN)   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                    GNU Hurd / Mach                          │
└─────────────────────────────────────────────────────────────┘
```

## Features

### Tensor Logic

Files are represented with tensor embeddings that encode semantic content:

```scheme
;; Create a file with auto-embedding
(tensorfs-create-file! tfs "/docs/readme.txt"
                       #:content "Welcome to TensorFS"
                       #:auto-embed? #t)

;; Semantic search
(tensorfs-semantic-search tfs "filesystem documentation" #:k 5)
;; => (("/docs/readme.txt" FILE 0.87 0.6)
;;     ("/docs/manual.txt" FILE 0.72 0.4) ...)
```

### Multi-Scale Navigation

Navigate the filesystem at different abstraction levels:

```scheme
;; Browse at coarse scale (level 0 = root)
(tensorfs-browse-scale tfs 0)

;; Zoom into a directory
(tensorfs-zoom-in tfs "/projects")

;; Get hierarchical view
(tensorfs-hierarchical-view tfs #:max-depth 3)
```

### Multi-Entity Support

Share files with entities (users, processes, agents):

```scheme
;; Share with an entity
(tensorfs-share-with-entity! tfs "/shared/doc.txt"
                             entity-id
                             #:permissions '(read write))

;; Collaborative editing
(tensorfs-collaborative-edit! tfs "/shared/notes.txt"
                              entity-id
                              "New content"
                              #:merge-strategy 'append)
```

### Network-Aware Distribution

Support for distributed filesystems:

```scheme
;; Mark for replication
(tensorfs-replicate! tfs "/important.dat" target-partition)

;; Distributed search across partitions
(tensorfs-distributed-search tfs query #:partitions '(0 1 2 3))

;; Sync with remote
(tensorfs-sync-remote! tfs "/shared/data.txt" remote-content)
```

### Attention-Based Caching

ECAN-style attention allocation for intelligent caching:

```scheme
;; Boost attention (called automatically on access)
(tensorfs-boost-attention! tfs "/hot/data.txt" #:amount 0.2)

;; Get attention-ranked files
(tensorfs-attention-ranked-list tfs #:k 10)

;; Predict next access for prefetching
(tensorfs-prefetch-predicted tfs "/current/file.txt" #:k 3)
```

### Cognitive Operations

Intelligent reasoning about files:

```scheme
;; Infer relationships
(tensorfs-infer-relationships tfs "/a.txt" "/b.txt")
;; => ((similarity . 0.73) (relationship . related))

;; Suggest organization
(tensorfs-suggest-organization tfs #:num-suggestions 5)
```

## Installation

### Building from Source

```bash
cd tensorfs
make
sudo make install
```

### Dependencies

- GNU Guile 3.0+
- GCC with C11 support
- pthread library
- Math library (libm)

For GNU Hurd integration:
- GNU Hurd development headers
- libports, libfshelp, libdiskfs

## Usage

### C API

```c
#include <tensorfs/tensorfs.h>

// Create TensorFS instance
tensorfs_t *tfs = tensorfs_create(128, 4, 0);

// Create a file
tensorfs_create_file(tfs, "/hello.txt", "Hello, World!", 13, 1);

// Semantic search
tensorfs_search_result_t *results;
size_t num_results;
tensorfs_semantic_search_text(tfs, "greeting", 5, 0.3,
                              &results, &num_results);

// Cleanup
tensorfs_free_search_results(results, num_results);
tensorfs_destroy(tfs);
```

### Scheme API

```scheme
(use-modules (tensorfs tensorfs))

;; Create TensorFS
(define tfs (make-tensorfs #:embedding-dim 128 #:num-scales 4))

;; Create files and directories
(tensorfs-create-directory! tfs "/docs")
(tensorfs-create-file! tfs "/docs/guide.txt"
                       #:content "User guide content...")

;; Search semantically
(tensorfs-semantic-search tfs "guide help tutorial" #:k 5)

;; Find similar files
(tensorfs-find-similar tfs "/docs/guide.txt" #:k 3)
```

## Inspired By

- **ATen** ([github.com/o9nn/ATen](https://github.com/o9nn/ATen)): C++11 tensor library providing efficient tensor operations
- **ATenSpace** ([github.com/o9nn/ATenSpace](https://github.com/o9nn/ATenSpace)): Bridge between symbolic AI (AtomSpace) and neural tensor embeddings
- **OpenCog AtomSpace**: Hypergraph knowledge representation for AGI
- **ECAN**: Economic Attention Network for cognitive resource allocation

## Integration with HurdCog

TensorFS integrates with the HurdCog cognitive kernel:

```scheme
(use-modules (cogkernel atomspace)
             (cogkernel atenspace)
             (tensorfs tensorfs))

;; TensorFS uses ATenSpace internally
(define tfs (make-tensorfs))

;; Files are atoms in the AtomSpace
(define as (tensorfs-atenspace tfs))
(atomspace-query as (lambda (atom)
                      (eq? (atom-type atom) 'NODE)))
```

## Future Enhancements

- GPU acceleration via CUDA tensors
- Persistent storage backend
- Real-time embedding updates
- Federated learning for distributed embeddings
- Integration with PLN for probabilistic file relationships

## License

Copyright (C) 2025 GNU Hurd Project
License: GPL-3.0-or-later

## See Also

- `cogkernel/aten-tensors.scm` - ATen tensor operations
- `cogkernel/atenspace.scm` - ATenSpace neural-symbolic bridge
- `cogkernel/atomspace.scm` - Core AtomSpace implementation
- `docs/OPENCOG_HURD_INTEGRATION.md` - Architecture overview
