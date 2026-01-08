/* TensorFS - Multi-Entity & Multi-Scale Network-Aware Tensor-Enhanced Hurd FileSystem
   Copyright (C) 2025 GNU Hurd Project
   License: GPL-3.0-or-later

   Main C implementation for TensorFS integration with GNU Hurd.
*/

#include "tensorfs.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <pthread.h>
#include <errno.h>

/* ==================== Internal Helpers ==================== */

/* Hash function for path strings */
static uint64_t path_hash(const char *path) {
    uint64_t hash = 5381;
    int c;
    while ((c = *path++))
        hash = ((hash << 5) + hash) + c;
    return hash;
}

/* Duplicate a string */
static char *str_dup(const char *s) {
    if (!s) return NULL;
    size_t len = strlen(s) + 1;
    char *dup = malloc(len);
    if (dup) memcpy(dup, s, len);
    return dup;
}

/* Get parent path */
static char *get_parent_path(const char *path) {
    if (!path || strcmp(path, "/") == 0) return str_dup("/");
    char *parent = str_dup(path);
    char *last_slash = strrchr(parent, '/');
    if (last_slash == parent) {
        parent[1] = '\0';
    } else if (last_slash) {
        *last_slash = '\0';
    }
    return parent;
}

/* Get basename from path */
static char *get_basename(const char *path) {
    const char *last_slash = strrchr(path, '/');
    return str_dup(last_slash ? last_slash + 1 : path);
}

/* Random float in [0, 1] */
static float randf(void) {
    return (float)rand() / (float)RAND_MAX;
}

/* Random normal using Box-Muller */
static float randn_scalar(void) {
    float u1 = randf() * 0.9998f + 0.0001f;
    float u2 = randf() * 0.9998f + 0.0001f;
    return sqrtf(-2.0f * logf(u1)) * cosf(2.0f * M_PI * u2);
}

/* ==================== Tensor Functions ==================== */

tensor_t *tensor_create(const int64_t *shape, size_t ndim, tensor_dtype_t dtype) {
    tensor_t *t = malloc(sizeof(tensor_t));
    if (!t) return NULL;

    t->ndim = ndim;
    t->dtype = dtype;
    t->device = DEVICE_CPU;

    /* Copy shape */
    t->shape = malloc(ndim * sizeof(int64_t));
    if (!t->shape) {
        free(t);
        return NULL;
    }
    memcpy(t->shape, shape, ndim * sizeof(int64_t));

    /* Calculate total size */
    t->size = 1;
    for (size_t i = 0; i < ndim; i++) {
        t->size *= shape[i];
    }

    /* Allocate data */
    t->data = calloc(t->size, sizeof(float));
    if (!t->data) {
        free(t->shape);
        free(t);
        return NULL;
    }

    return t;
}

void tensor_destroy(tensor_t *t) {
    if (t) {
        free(t->shape);
        free(t->data);
        free(t);
    }
}

tensor_t *tensor_from_data(const float *data, const int64_t *shape, size_t ndim) {
    tensor_t *t = tensor_create(shape, ndim, TENSOR_FLOAT32);
    if (t && data) {
        memcpy(t->data, data, t->size * sizeof(float));
    }
    return t;
}

tensor_t *tensor_randn(const int64_t *shape, size_t ndim) {
    tensor_t *t = tensor_create(shape, ndim, TENSOR_FLOAT32);
    if (t) {
        for (size_t i = 0; i < t->size; i++) {
            t->data[i] = randn_scalar();
        }
    }
    return t;
}

tensor_t *tensor_add(const tensor_t *a, const tensor_t *b) {
    if (!a || !b || a->size != b->size) return NULL;

    tensor_t *result = tensor_create(a->shape, a->ndim, a->dtype);
    if (result) {
        for (size_t i = 0; i < a->size; i++) {
            result->data[i] = a->data[i] + b->data[i];
        }
    }
    return result;
}

tensor_t *tensor_mul(const tensor_t *a, const tensor_t *b) {
    if (!a || !b || a->size != b->size) return NULL;

    tensor_t *result = tensor_create(a->shape, a->ndim, a->dtype);
    if (result) {
        for (size_t i = 0; i < a->size; i++) {
            result->data[i] = a->data[i] * b->data[i];
        }
    }
    return result;
}

tensor_t *tensor_matmul(const tensor_t *a, const tensor_t *b) {
    if (!a || !b || a->ndim != 2 || b->ndim != 2) return NULL;
    if (a->shape[1] != b->shape[0]) return NULL;

    int64_t m = a->shape[0];
    int64_t k = a->shape[1];
    int64_t n = b->shape[1];

    int64_t result_shape[2] = {m, n};
    tensor_t *result = tensor_create(result_shape, 2, TENSOR_FLOAT32);
    if (!result) return NULL;

    for (int64_t i = 0; i < m; i++) {
        for (int64_t j = 0; j < n; j++) {
            float sum = 0.0f;
            for (int64_t l = 0; l < k; l++) {
                sum += a->data[i * k + l] * b->data[l * n + j];
            }
            result->data[i * n + j] = sum;
        }
    }
    return result;
}

float tensor_dot(const tensor_t *a, const tensor_t *b) {
    if (!a || !b) return 0.0f;
    size_t size = (a->size < b->size) ? a->size : b->size;
    float sum = 0.0f;
    for (size_t i = 0; i < size; i++) {
        sum += a->data[i] * b->data[i];
    }
    return sum;
}

float tensor_norm(const tensor_t *t) {
    if (!t) return 0.0f;
    float sum = 0.0f;
    for (size_t i = 0; i < t->size; i++) {
        sum += t->data[i] * t->data[i];
    }
    return sqrtf(sum);
}

float tensor_cosine_similarity(const tensor_t *a, const tensor_t *b) {
    float norm_a = tensor_norm(a);
    float norm_b = tensor_norm(b);
    if (norm_a == 0.0f || norm_b == 0.0f) return 0.0f;
    return tensor_dot(a, b) / (norm_a * norm_b);
}

/* ==================== TensorFS Node Functions ==================== */

static tensorfs_node_t *node_create(tensorfs_node_type_t type,
                                    const char *name, const char *path,
                                    size_t embedding_dim, int scale_level) {
    tensorfs_node_t *node = calloc(1, sizeof(tensorfs_node_t));
    if (!node) return NULL;

    node->type = type;
    node->name = str_dup(name);
    node->path = str_dup(path);
    node->attention = 0.5f;
    node->scale_level = scale_level;
    node->created = time(NULL);
    node->modified = node->created;
    node->mode = (type == TENSORFS_DIRECTORY) ? 0755 : 0644;

    /* Create random embedding */
    int64_t shape[1] = {embedding_dim};
    node->embedding = tensor_randn(shape, 1);

    /* Initialize children array for directories */
    if (type == TENSORFS_DIRECTORY) {
        node->children_capacity = 16;
        node->children = calloc(node->children_capacity,
                                sizeof(tensorfs_node_t *));
    }

    return node;
}

static void node_destroy(tensorfs_node_t *node) {
    if (!node) return;

    free(node->name);
    free(node->path);
    free(node->content);
    tensor_destroy(node->embedding);
    free(node->entity_permissions);
    free(node->replica_partitions);

    /* Recursively destroy children */
    for (size_t i = 0; i < node->num_children; i++) {
        node_destroy(node->children[i]);
    }
    free(node->children);

    free(node);
}

static int node_add_child(tensorfs_node_t *parent, tensorfs_node_t *child) {
    if (!parent || !child || parent->type != TENSORFS_DIRECTORY)
        return -ENOTDIR;

    /* Expand children array if needed */
    if (parent->num_children >= parent->children_capacity) {
        size_t new_cap = parent->children_capacity * 2;
        tensorfs_node_t **new_children = realloc(parent->children,
                                                  new_cap * sizeof(tensorfs_node_t *));
        if (!new_children) return -ENOMEM;
        parent->children = new_children;
        parent->children_capacity = new_cap;
    }

    parent->children[parent->num_children++] = child;
    child->parent = parent;
    return 0;
}

static tensorfs_node_t *node_find_child(tensorfs_node_t *parent, const char *name) {
    if (!parent || !name) return NULL;
    for (size_t i = 0; i < parent->num_children; i++) {
        if (strcmp(parent->children[i]->name, name) == 0) {
            return parent->children[i];
        }
    }
    return NULL;
}

/* ==================== TensorFS Core Functions ==================== */

tensorfs_t *tensorfs_create(size_t embedding_dim, int num_scales, int32_t partition_id) {
    tensorfs_t *tfs = calloc(1, sizeof(tensorfs_t));
    if (!tfs) return NULL;

    tfs->embedding_dim = embedding_dim;
    tfs->num_scales = num_scales;
    tfs->partition_id = partition_id;

    /* Create root node */
    tfs->root = node_create(TENSORFS_DIRECTORY, "/", "/", embedding_dim, 0);
    if (!tfs->root) {
        free(tfs);
        return NULL;
    }
    tfs->root->attention = 1.0f;  /* Root gets max attention */
    tfs->num_nodes = 1;

    /* Seed random number generator */
    srand(time(NULL) ^ (intptr_t)tfs);

    return tfs;
}

void tensorfs_destroy(tensorfs_t *tfs) {
    if (tfs) {
        node_destroy(tfs->root);
        free(tfs);
    }
}

/* Find node by path */
static tensorfs_node_t *tensorfs_lookup(tensorfs_t *tfs, const char *path) {
    if (!tfs || !path) return NULL;
    if (strcmp(path, "/") == 0) return tfs->root;

    tensorfs_node_t *current = tfs->root;
    char *path_copy = str_dup(path);
    char *saveptr;
    char *token = strtok_r(path_copy + 1, "/", &saveptr);  /* Skip leading / */

    while (token && current) {
        current = node_find_child(current, token);
        token = strtok_r(NULL, "/", &saveptr);
    }

    free(path_copy);
    return current;
}

/* ==================== File Operations ==================== */

int tensorfs_create_file(tensorfs_t *tfs, const char *path,
                         const void *content, size_t content_size,
                         int auto_embed) {
    if (!tfs || !path) return -EINVAL;

    char *parent_path = get_parent_path(path);
    tensorfs_node_t *parent = tensorfs_lookup(tfs, parent_path);
    free(parent_path);

    if (!parent) return -ENOENT;
    if (parent->type != TENSORFS_DIRECTORY) return -ENOTDIR;

    char *name = get_basename(path);
    if (node_find_child(parent, name)) {
        free(name);
        return -EEXIST;
    }

    tensorfs_node_t *node = node_create(TENSORFS_FILE, name, path,
                                        tfs->embedding_dim,
                                        parent->scale_level + 1);
    free(name);
    if (!node) return -ENOMEM;

    /* Set content */
    if (content && content_size > 0) {
        node->content = malloc(content_size);
        if (!node->content) {
            node_destroy(node);
            return -ENOMEM;
        }
        memcpy(node->content, content, content_size);
        node->content_size = content_size;

        /* Auto-embed content */
        if (auto_embed) {
            tensor_t *emb = tensorfs_content_to_embedding((const char *)content,
                                                          tfs->embedding_dim);
            if (emb) {
                tensor_destroy(node->embedding);
                node->embedding = emb;
            }
        }
    }

    int ret = node_add_child(parent, node);
    if (ret < 0) {
        node_destroy(node);
        return ret;
    }

    tfs->num_nodes++;
    return 0;
}

int tensorfs_create_directory(tensorfs_t *tfs, const char *path) {
    if (!tfs || !path) return -EINVAL;

    char *parent_path = get_parent_path(path);
    tensorfs_node_t *parent = tensorfs_lookup(tfs, parent_path);
    free(parent_path);

    if (!parent) return -ENOENT;
    if (parent->type != TENSORFS_DIRECTORY) return -ENOTDIR;

    char *name = get_basename(path);
    if (node_find_child(parent, name)) {
        free(name);
        return -EEXIST;
    }

    tensorfs_node_t *node = node_create(TENSORFS_DIRECTORY, name, path,
                                        tfs->embedding_dim,
                                        parent->scale_level + 1);
    free(name);
    if (!node) return -ENOMEM;

    int ret = node_add_child(parent, node);
    if (ret < 0) {
        node_destroy(node);
        return ret;
    }

    tfs->num_nodes++;
    return 0;
}

ssize_t tensorfs_read(tensorfs_t *tfs, const char *path,
                      void *buffer, size_t size, off_t offset) {
    if (!tfs || !path || !buffer) return -EINVAL;

    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;
    if (node->type != TENSORFS_FILE) return -EISDIR;

    /* Boost attention on access */
    tensorfs_boost_attention(tfs, path, 0.1f);

    if (!node->content) return 0;
    if ((size_t)offset >= node->content_size) return 0;

    size_t available = node->content_size - offset;
    size_t to_read = (size < available) ? size : available;

    memcpy(buffer, (char *)node->content + offset, to_read);
    return to_read;
}

ssize_t tensorfs_write(tensorfs_t *tfs, const char *path,
                       const void *content, size_t size, off_t offset) {
    if (!tfs || !path) return -EINVAL;

    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;
    if (node->type != TENSORFS_FILE) return -EISDIR;

    /* Resize content if needed */
    size_t new_size = offset + size;
    if (new_size > node->content_size) {
        void *new_content = realloc(node->content, new_size);
        if (!new_content) return -ENOMEM;
        node->content = new_content;
        node->content_size = new_size;
    }

    if (content) {
        memcpy((char *)node->content + offset, content, size);
    }

    node->modified = time(NULL);

    /* Update embedding */
    if (node->content) {
        tensor_t *emb = tensorfs_content_to_embedding((const char *)node->content,
                                                      tfs->embedding_dim);
        if (emb) {
            tensor_destroy(node->embedding);
            node->embedding = emb;
        }
    }

    /* Boost attention */
    tensorfs_boost_attention(tfs, path, 0.2f);

    return size;
}

int tensorfs_delete(tensorfs_t *tfs, const char *path) {
    if (!tfs || !path || strcmp(path, "/") == 0) return -EINVAL;

    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;

    /* Check if directory is empty */
    if (node->type == TENSORFS_DIRECTORY && node->num_children > 0) {
        return -ENOTEMPTY;
    }

    /* Remove from parent */
    tensorfs_node_t *parent = node->parent;
    if (parent) {
        for (size_t i = 0; i < parent->num_children; i++) {
            if (parent->children[i] == node) {
                memmove(&parent->children[i], &parent->children[i + 1],
                        (parent->num_children - i - 1) * sizeof(tensorfs_node_t *));
                parent->num_children--;
                break;
            }
        }
    }

    node_destroy(node);
    tfs->num_nodes--;
    return 0;
}

int tensorfs_readdir(tensorfs_t *tfs, const char *path,
                     char ***names, tensorfs_node_type_t **types,
                     size_t *count) {
    if (!tfs || !path || !names || !types || !count) return -EINVAL;

    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;
    if (node->type != TENSORFS_DIRECTORY) return -ENOTDIR;

    *count = node->num_children;
    *names = malloc(node->num_children * sizeof(char *));
    *types = malloc(node->num_children * sizeof(tensorfs_node_type_t));

    if (!*names || !*types) {
        free(*names);
        free(*types);
        return -ENOMEM;
    }

    for (size_t i = 0; i < node->num_children; i++) {
        (*names)[i] = str_dup(node->children[i]->name);
        (*types)[i] = node->children[i]->type;
    }

    return 0;
}

int tensorfs_stat(tensorfs_t *tfs, const char *path,
                  tensorfs_node_type_t *type, size_t *size,
                  float *attention, int *scale_level) {
    if (!tfs || !path) return -EINVAL;

    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;

    if (type) *type = node->type;
    if (size) *size = node->content_size;
    if (attention) *attention = node->attention;
    if (scale_level) *scale_level = node->scale_level;

    return 0;
}

int tensorfs_exists(tensorfs_t *tfs, const char *path) {
    return tensorfs_lookup(tfs, path) != NULL;
}

/* ==================== Semantic Operations ==================== */

tensor_t *tensorfs_content_to_embedding(const char *content, size_t dim) {
    if (!content) return NULL;

    int64_t shape[1] = {dim};
    tensor_t *embedding = tensor_create(shape, 1, TENSOR_FLOAT32);
    if (!embedding) return NULL;

    /* Simple bag-of-words hashing */
    const char *p = content;
    while (*p) {
        /* Skip whitespace */
        while (*p && (*p == ' ' || *p == '\n' || *p == '\t')) p++;
        if (!*p) break;

        /* Hash word */
        uint64_t hash = 5381;
        while (*p && *p != ' ' && *p != '\n' && *p != '\t') {
            char c = (*p >= 'A' && *p <= 'Z') ? (*p + 32) : *p;
            hash = ((hash << 5) + hash) + c;
            p++;
        }

        size_t idx = hash % dim;
        embedding->data[idx] += 1.0f;
    }

    /* Normalize */
    float norm = tensor_norm(embedding);
    if (norm > 0) {
        for (size_t i = 0; i < dim; i++) {
            embedding->data[i] /= norm;
        }
    }

    return embedding;
}

/* Helper struct for semantic search */
typedef struct {
    tensorfs_node_t *node;
    float similarity;
} search_entry_t;

static int compare_search_entries(const void *a, const void *b) {
    float sim_a = ((search_entry_t *)a)->similarity;
    float sim_b = ((search_entry_t *)b)->similarity;
    return (sim_b > sim_a) - (sim_b < sim_a);
}

/* Recursive search helper */
static void search_recursive(tensorfs_node_t *node, const tensor_t *query,
                             float threshold, search_entry_t **entries,
                             size_t *count, size_t *capacity) {
    if (!node || !node->embedding) return;

    float sim = tensor_cosine_similarity(query, node->embedding);
    if (sim >= threshold) {
        /* Add to results */
        if (*count >= *capacity) {
            *capacity *= 2;
            *entries = realloc(*entries, *capacity * sizeof(search_entry_t));
        }
        (*entries)[*count].node = node;
        (*entries)[*count].similarity = sim;
        (*count)++;
    }

    /* Search children */
    for (size_t i = 0; i < node->num_children; i++) {
        search_recursive(node->children[i], query, threshold,
                         entries, count, capacity);
    }
}

int tensorfs_semantic_search(tensorfs_t *tfs, const tensor_t *query,
                             int k, float threshold,
                             tensorfs_search_result_t **results,
                             size_t *num_results) {
    if (!tfs || !query || !results || !num_results) return -EINVAL;

    size_t capacity = 64;
    size_t count = 0;
    search_entry_t *entries = malloc(capacity * sizeof(search_entry_t));
    if (!entries) return -ENOMEM;

    search_recursive(tfs->root, query, threshold, &entries, &count, &capacity);

    /* Sort by similarity */
    qsort(entries, count, sizeof(search_entry_t), compare_search_entries);

    /* Return top k */
    size_t result_count = (count < (size_t)k) ? count : k;
    *results = malloc(result_count * sizeof(tensorfs_search_result_t));
    if (!*results) {
        free(entries);
        return -ENOMEM;
    }

    for (size_t i = 0; i < result_count; i++) {
        (*results)[i].path = str_dup(entries[i].node->path);
        (*results)[i].similarity = entries[i].similarity;
        (*results)[i].attention = entries[i].node->attention;
        (*results)[i].type = entries[i].node->type;
    }

    *num_results = result_count;
    free(entries);
    return 0;
}

int tensorfs_semantic_search_text(tensorfs_t *tfs, const char *query,
                                  int k, float threshold,
                                  tensorfs_search_result_t **results,
                                  size_t *num_results) {
    tensor_t *query_embedding = tensorfs_content_to_embedding(query, tfs->embedding_dim);
    if (!query_embedding) return -ENOMEM;

    int ret = tensorfs_semantic_search(tfs, query_embedding, k, threshold,
                                       results, num_results);
    tensor_destroy(query_embedding);
    return ret;
}

int tensorfs_find_similar(tensorfs_t *tfs, const char *path, int k,
                          tensorfs_search_result_t **results,
                          size_t *num_results) {
    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;

    int ret = tensorfs_semantic_search(tfs, node->embedding, k + 1, 0.0f,
                                       results, num_results);
    if (ret < 0) return ret;

    /* Remove self from results */
    for (size_t i = 0; i < *num_results; i++) {
        if (strcmp((*results)[i].path, path) == 0) {
            free((*results)[i].path);
            memmove(&(*results)[i], &(*results)[i + 1],
                    (*num_results - i - 1) * sizeof(tensorfs_search_result_t));
            (*num_results)--;
            break;
        }
    }

    return 0;
}

tensor_t *tensorfs_get_embedding(tensorfs_t *tfs, const char *path) {
    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    return node ? node->embedding : NULL;
}

int tensorfs_update_embedding(tensorfs_t *tfs, const char *path,
                              const tensor_t *embedding) {
    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;

    tensor_destroy(node->embedding);
    node->embedding = tensor_from_data(embedding->data, embedding->shape,
                                       embedding->ndim);
    return node->embedding ? 0 : -ENOMEM;
}

/* ==================== Attention Operations ==================== */

int tensorfs_boost_attention(tensorfs_t *tfs, const char *path, float amount) {
    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;

    node->attention = fminf(1.0f, node->attention + amount);
    return 0;
}

static void decay_recursive(tensorfs_node_t *node, float decay_rate) {
    if (!node) return;
    node->attention *= (1.0f - decay_rate);
    for (size_t i = 0; i < node->num_children; i++) {
        decay_recursive(node->children[i], decay_rate);
    }
}

int tensorfs_decay_attention(tensorfs_t *tfs, float decay_rate) {
    if (!tfs) return -EINVAL;
    decay_recursive(tfs->root, decay_rate);
    return 0;
}

/* ==================== Multi-Entity Operations ==================== */

int tensorfs_share(tensorfs_t *tfs, const char *path,
                   uint64_t entity_id, uint32_t permissions) {
    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;

    /* Find or add entity permission */
    for (size_t i = 0; i < node->num_entity_permissions; i++) {
        if (node->entity_permissions[i].entity_id == entity_id) {
            node->entity_permissions[i].permissions = permissions;
            return 0;
        }
    }

    /* Add new permission */
    size_t new_count = node->num_entity_permissions + 1;
    void *new_perms = realloc(node->entity_permissions,
                              new_count * sizeof(node->entity_permissions[0]));
    if (!new_perms) return -ENOMEM;

    node->entity_permissions = new_perms;
    node->entity_permissions[node->num_entity_permissions].entity_id = entity_id;
    node->entity_permissions[node->num_entity_permissions].permissions = permissions;
    node->num_entity_permissions = new_count;

    return 0;
}

uint32_t tensorfs_get_permissions(tensorfs_t *tfs, const char *path,
                                  uint64_t entity_id) {
    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return 0;

    for (size_t i = 0; i < node->num_entity_permissions; i++) {
        if (node->entity_permissions[i].entity_id == entity_id) {
            return node->entity_permissions[i].permissions;
        }
    }
    return 0;
}

/* ==================== Network-Aware Operations ==================== */

int tensorfs_replicate(tensorfs_t *tfs, const char *path,
                       int32_t target_partition) {
    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;

    size_t new_count = node->num_replicas + 1;
    int32_t *new_replicas = realloc(node->replica_partitions,
                                    new_count * sizeof(int32_t));
    if (!new_replicas) return -ENOMEM;

    new_replicas[node->num_replicas] = target_partition;
    node->replica_partitions = new_replicas;
    node->num_replicas = new_count;

    return 0;
}

int tensorfs_get_partition(tensorfs_t *tfs, const char *path,
                           int32_t *partition_id, int *is_local) {
    if (!tfs || !path) return -EINVAL;

    tensorfs_node_t *node = tensorfs_lookup(tfs, path);
    if (!node) return -ENOENT;

    if (partition_id) *partition_id = tfs->partition_id;
    if (is_local) *is_local = 1;

    return 0;
}

/* ==================== Utility Functions ==================== */

void tensorfs_free_search_results(tensorfs_search_result_t *results,
                                  size_t num_results) {
    if (results) {
        for (size_t i = 0; i < num_results; i++) {
            free(results[i].path);
        }
        free(results);
    }
}

void tensorfs_free_string_array(char **strings, size_t count) {
    if (strings) {
        for (size_t i = 0; i < count; i++) {
            free(strings[i]);
        }
        free(strings);
    }
}
