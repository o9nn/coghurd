/* TensorFS - Multi-Entity & Multi-Scale Network-Aware Tensor-Enhanced Hurd FileSystem
   Copyright (C) 2025 GNU Hurd Project
   License: GPL-3.0-or-later

   This header provides the C interface for integrating TensorFS with GNU Hurd.
   TensorFS combines AtomSpace hypergraph with ATen tensor embeddings for
   intelligent, semantic-aware file management.
*/

#ifndef _TENSORFS_H
#define _TENSORFS_H

#include <stdint.h>
#include <stddef.h>
#include <sys/types.h>
#include <mach/mach_types.h>

/* Tensor data types */
typedef enum {
    TENSOR_FLOAT32 = 0,
    TENSOR_FLOAT64 = 1,
    TENSOR_INT32 = 2,
    TENSOR_INT64 = 3,
    TENSOR_BOOL = 4
} tensor_dtype_t;

/* Device types for tensor computation */
typedef enum {
    DEVICE_CPU = 0,
    DEVICE_CUDA = 1
} tensor_device_t;

/* TensorFS node types */
typedef enum {
    TENSORFS_FILE = 0,
    TENSORFS_DIRECTORY = 1,
    TENSORFS_SYMLINK = 2,
    TENSORFS_DEVICE = 3,
    TENSORFS_SOCKET = 4
} tensorfs_node_type_t;

/* Tensor structure for embeddings */
typedef struct {
    int64_t *shape;          /* Shape dimensions array */
    size_t ndim;             /* Number of dimensions */
    float *data;             /* Tensor data (float32) */
    size_t size;             /* Total number of elements */
    tensor_dtype_t dtype;    /* Data type */
    tensor_device_t device;  /* Device (CPU/CUDA) */
} tensor_t;

/* Entity permission flags */
#define TENSORFS_PERM_READ   (1 << 0)
#define TENSORFS_PERM_WRITE  (1 << 1)
#define TENSORFS_PERM_EXEC   (1 << 2)
#define TENSORFS_PERM_SHARE  (1 << 3)

/* TensorFS node structure */
typedef struct tensorfs_node {
    tensorfs_node_type_t type;
    char *name;
    char *path;
    void *content;                    /* File content (for files) */
    size_t content_size;
    tensor_t *embedding;              /* Neural embedding */
    float attention;                  /* Attention weight [0,1] */
    int scale_level;                  /* Multi-scale level */

    /* Tree structure */
    struct tensorfs_node *parent;
    struct tensorfs_node **children;
    size_t num_children;
    size_t children_capacity;

    /* Multi-entity support */
    struct {
        uint64_t entity_id;
        uint32_t permissions;
    } *entity_permissions;
    size_t num_entity_permissions;

    /* Metadata */
    time_t created;
    time_t modified;
    uint32_t uid;
    uint32_t gid;
    mode_t mode;

    /* Network distribution */
    int32_t partition_id;
    int32_t *replica_partitions;
    size_t num_replicas;
} tensorfs_node_t;

/* TensorFS instance structure */
typedef struct {
    tensorfs_node_t *root;
    size_t num_nodes;
    size_t embedding_dim;
    int num_scales;
    int32_t partition_id;

    /* AtomSpace bridge handle (opaque) */
    void *atenspace_handle;

    /* Hurd-specific */
    mach_port_t control_port;
    mach_port_t fsys_port;
} tensorfs_t;

/* Semantic search result */
typedef struct {
    char *path;
    float similarity;
    float attention;
    tensorfs_node_type_t type;
} tensorfs_search_result_t;

/* ==================== Core Functions ==================== */

/* Initialize TensorFS */
tensorfs_t *tensorfs_create(size_t embedding_dim, int num_scales, int32_t partition_id);

/* Destroy TensorFS instance */
void tensorfs_destroy(tensorfs_t *tfs);

/* ==================== File Operations ==================== */

/* Create a file */
int tensorfs_create_file(tensorfs_t *tfs, const char *path,
                         const void *content, size_t content_size,
                         int auto_embed);

/* Create a directory */
int tensorfs_create_directory(tensorfs_t *tfs, const char *path);

/* Read file content */
ssize_t tensorfs_read(tensorfs_t *tfs, const char *path,
                      void *buffer, size_t size, off_t offset);

/* Write file content */
ssize_t tensorfs_write(tensorfs_t *tfs, const char *path,
                       const void *content, size_t size, off_t offset);

/* Delete file or empty directory */
int tensorfs_delete(tensorfs_t *tfs, const char *path);

/* List directory contents */
int tensorfs_readdir(tensorfs_t *tfs, const char *path,
                     char ***names, tensorfs_node_type_t **types,
                     size_t *count);

/* Get file/directory stats */
int tensorfs_stat(tensorfs_t *tfs, const char *path,
                  tensorfs_node_type_t *type, size_t *size,
                  float *attention, int *scale_level);

/* Check if path exists */
int tensorfs_exists(tensorfs_t *tfs, const char *path);

/* ==================== Tensor Operations ==================== */

/* Create a tensor */
tensor_t *tensor_create(const int64_t *shape, size_t ndim, tensor_dtype_t dtype);

/* Destroy a tensor */
void tensor_destroy(tensor_t *t);

/* Create tensor from data */
tensor_t *tensor_from_data(const float *data, const int64_t *shape, size_t ndim);

/* Random normal tensor */
tensor_t *tensor_randn(const int64_t *shape, size_t ndim);

/* Tensor operations */
tensor_t *tensor_add(const tensor_t *a, const tensor_t *b);
tensor_t *tensor_mul(const tensor_t *a, const tensor_t *b);
tensor_t *tensor_matmul(const tensor_t *a, const tensor_t *b);
float tensor_dot(const tensor_t *a, const tensor_t *b);
float tensor_norm(const tensor_t *t);
float tensor_cosine_similarity(const tensor_t *a, const tensor_t *b);

/* ==================== Semantic Operations ==================== */

/* Semantic search by query tensor */
int tensorfs_semantic_search(tensorfs_t *tfs, const tensor_t *query,
                             int k, float threshold,
                             tensorfs_search_result_t **results,
                             size_t *num_results);

/* Semantic search by text query */
int tensorfs_semantic_search_text(tensorfs_t *tfs, const char *query,
                                  int k, float threshold,
                                  tensorfs_search_result_t **results,
                                  size_t *num_results);

/* Find similar files */
int tensorfs_find_similar(tensorfs_t *tfs, const char *path, int k,
                          tensorfs_search_result_t **results,
                          size_t *num_results);

/* Get embedding for a path */
tensor_t *tensorfs_get_embedding(tensorfs_t *tfs, const char *path);

/* Update embedding for a path */
int tensorfs_update_embedding(tensorfs_t *tfs, const char *path,
                              const tensor_t *embedding);

/* Convert content to embedding */
tensor_t *tensorfs_content_to_embedding(const char *content, size_t dim);

/* ==================== Multi-Scale Operations ==================== */

/* Browse at scale level */
int tensorfs_browse_scale(tensorfs_t *tfs, int scale_level,
                          char ***paths, size_t *count);

/* Get hierarchical view */
int tensorfs_hierarchical_view(tensorfs_t *tfs, int max_depth,
                               char ***paths, int **depths, size_t *count);

/* ==================== Multi-Entity Operations ==================== */

/* Share with entity */
int tensorfs_share(tensorfs_t *tfs, const char *path,
                   uint64_t entity_id, uint32_t permissions);

/* Get entity permissions */
uint32_t tensorfs_get_permissions(tensorfs_t *tfs, const char *path,
                                  uint64_t entity_id);

/* Collaborative edit */
int tensorfs_collaborative_edit(tensorfs_t *tfs, const char *path,
                                uint64_t entity_id,
                                const void *content, size_t size,
                                int merge_strategy);

/* ==================== Network-Aware Operations ==================== */

/* Mark for replication */
int tensorfs_replicate(tensorfs_t *tfs, const char *path,
                       int32_t target_partition);

/* Get partition info */
int tensorfs_get_partition(tensorfs_t *tfs, const char *path,
                           int32_t *partition_id, int *is_local);

/* Distributed search */
int tensorfs_distributed_search(tensorfs_t *tfs, const tensor_t *query,
                                const int32_t *partitions, size_t num_partitions,
                                tensorfs_search_result_t **results,
                                size_t *num_results);

/* ==================== Attention Operations ==================== */

/* Boost attention on path */
int tensorfs_boost_attention(tensorfs_t *tfs, const char *path, float amount);

/* Decay all attention values */
int tensorfs_decay_attention(tensorfs_t *tfs, float decay_rate);

/* Get attention-ranked list */
int tensorfs_attention_ranked(tensorfs_t *tfs, int k,
                              char ***paths, float **attentions,
                              size_t *count);

/* Predict next access */
int tensorfs_prefetch_predicted(tensorfs_t *tfs, const char *path, int k,
                                char ***predicted_paths, size_t *count);

/* ==================== Cognitive Operations ==================== */

/* Infer relationship between paths */
int tensorfs_infer_relationship(tensorfs_t *tfs,
                                const char *path1, const char *path2,
                                float *similarity, char **relationship);

/* Suggest organization */
int tensorfs_suggest_organization(tensorfs_t *tfs, int num_suggestions,
                                  char ***clusters, size_t **cluster_sizes,
                                  size_t *num_clusters);

/* ==================== Hurd Integration ==================== */

/* Initialize Hurd filesystem interface */
int tensorfs_hurd_init(tensorfs_t *tfs, mach_port_t bootstrap);

/* Start filesystem server */
int tensorfs_hurd_server_loop(tensorfs_t *tfs);

/* Handle file system request */
int tensorfs_hurd_handle_request(tensorfs_t *tfs, mach_msg_header_t *msg);

/* ==================== Utility Functions ==================== */

/* Free search results */
void tensorfs_free_search_results(tensorfs_search_result_t *results,
                                  size_t num_results);

/* Free string array */
void tensorfs_free_string_array(char **strings, size_t count);

#endif /* _TENSORFS_H */
