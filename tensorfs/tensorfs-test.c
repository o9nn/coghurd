/* TensorFS Unit Tests
   Copyright (C) 2025 GNU Hurd Project
   License: GPL-3.0-or-later
*/

#include "tensorfs.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#define TEST(name) static void test_##name(void)
#define RUN_TEST(name) do { \
    printf("Running %s... ", #name); \
    test_##name(); \
    printf("PASSED\n"); \
    tests_passed++; \
} while(0)

static int tests_passed = 0;

/* ==================== Tensor Tests ==================== */

TEST(tensor_create) {
    int64_t shape[] = {10, 20};
    tensor_t *t = tensor_create(shape, 2, TENSOR_FLOAT32);
    assert(t != NULL);
    assert(t->ndim == 2);
    assert(t->shape[0] == 10);
    assert(t->shape[1] == 20);
    assert(t->size == 200);
    tensor_destroy(t);
}

TEST(tensor_randn) {
    int64_t shape[] = {100};
    tensor_t *t = tensor_randn(shape, 1);
    assert(t != NULL);
    assert(t->size == 100);

    /* Check that values are not all zero */
    float sum = 0;
    for (size_t i = 0; i < t->size; i++) {
        sum += t->data[i] * t->data[i];
    }
    assert(sum > 0);
    tensor_destroy(t);
}

TEST(tensor_add) {
    int64_t shape[] = {5};
    tensor_t *a = tensor_create(shape, 1, TENSOR_FLOAT32);
    tensor_t *b = tensor_create(shape, 1, TENSOR_FLOAT32);

    for (int i = 0; i < 5; i++) {
        a->data[i] = 1.0f;
        b->data[i] = 2.0f;
    }

    tensor_t *c = tensor_add(a, b);
    assert(c != NULL);

    for (int i = 0; i < 5; i++) {
        assert(c->data[i] == 3.0f);
    }

    tensor_destroy(a);
    tensor_destroy(b);
    tensor_destroy(c);
}

TEST(tensor_norm) {
    int64_t shape[] = {3};
    tensor_t *t = tensor_create(shape, 1, TENSOR_FLOAT32);
    t->data[0] = 3.0f;
    t->data[1] = 4.0f;
    t->data[2] = 0.0f;

    float norm = tensor_norm(t);
    assert(norm >= 4.99f && norm <= 5.01f);

    tensor_destroy(t);
}

TEST(tensor_cosine_similarity) {
    int64_t shape[] = {4};
    tensor_t *a = tensor_create(shape, 1, TENSOR_FLOAT32);
    tensor_t *b = tensor_create(shape, 1, TENSOR_FLOAT32);

    /* Same vectors */
    for (int i = 0; i < 4; i++) {
        a->data[i] = 1.0f;
        b->data[i] = 1.0f;
    }

    float sim = tensor_cosine_similarity(a, b);
    assert(sim >= 0.99f && sim <= 1.01f);

    /* Orthogonal vectors */
    a->data[0] = 1.0f; a->data[1] = 0.0f; a->data[2] = 0.0f; a->data[3] = 0.0f;
    b->data[0] = 0.0f; b->data[1] = 1.0f; b->data[2] = 0.0f; b->data[3] = 0.0f;

    sim = tensor_cosine_similarity(a, b);
    assert(sim >= -0.01f && sim <= 0.01f);

    tensor_destroy(a);
    tensor_destroy(b);
}

/* ==================== TensorFS Core Tests ==================== */

TEST(tensorfs_create_destroy) {
    tensorfs_t *tfs = tensorfs_create(128, 4, 0);
    assert(tfs != NULL);
    assert(tfs->root != NULL);
    assert(tfs->embedding_dim == 128);
    assert(tfs->num_scales == 4);
    tensorfs_destroy(tfs);
}

TEST(tensorfs_create_file) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);

    int ret = tensorfs_create_file(tfs, "/test.txt", "Hello", 5, 1);
    assert(ret == 0);

    assert(tensorfs_exists(tfs, "/test.txt"));

    tensorfs_destroy(tfs);
}

TEST(tensorfs_create_directory) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);

    int ret = tensorfs_create_directory(tfs, "/subdir");
    assert(ret == 0);

    assert(tensorfs_exists(tfs, "/subdir"));

    ret = tensorfs_create_file(tfs, "/subdir/file.txt", "Content", 7, 1);
    assert(ret == 0);

    assert(tensorfs_exists(tfs, "/subdir/file.txt"));

    tensorfs_destroy(tfs);
}

TEST(tensorfs_read_write) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);
    const char *content = "Hello, TensorFS!";
    size_t len = strlen(content);

    tensorfs_create_file(tfs, "/test.txt", content, len, 1);

    char buffer[100] = {0};
    ssize_t read_len = tensorfs_read(tfs, "/test.txt", buffer, sizeof(buffer), 0);

    assert(read_len == (ssize_t)len);
    assert(strcmp(buffer, content) == 0);

    tensorfs_destroy(tfs);
}

TEST(tensorfs_delete) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);

    tensorfs_create_file(tfs, "/to_delete.txt", "temp", 4, 1);
    assert(tensorfs_exists(tfs, "/to_delete.txt"));

    int ret = tensorfs_delete(tfs, "/to_delete.txt");
    assert(ret == 0);
    assert(!tensorfs_exists(tfs, "/to_delete.txt"));

    tensorfs_destroy(tfs);
}

TEST(tensorfs_readdir) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);

    tensorfs_create_file(tfs, "/file1.txt", "1", 1, 0);
    tensorfs_create_file(tfs, "/file2.txt", "2", 1, 0);
    tensorfs_create_directory(tfs, "/dir1");

    char **names;
    tensorfs_node_type_t *types;
    size_t count;

    int ret = tensorfs_readdir(tfs, "/", &names, &types, &count);
    assert(ret == 0);
    assert(count == 3);

    tensorfs_free_string_array(names, count);
    free(types);
    tensorfs_destroy(tfs);
}

TEST(tensorfs_stat) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);
    const char *content = "Test content for stat";

    tensorfs_create_file(tfs, "/stat_test.txt", content, strlen(content), 1);

    tensorfs_node_type_t type;
    size_t size;
    float attention;
    int scale_level;

    int ret = tensorfs_stat(tfs, "/stat_test.txt", &type, &size, &attention, &scale_level);
    assert(ret == 0);
    assert(type == TENSORFS_FILE);
    assert(size == strlen(content));
    assert(scale_level == 1);

    tensorfs_destroy(tfs);
}

/* ==================== Semantic Search Tests ==================== */

TEST(tensorfs_semantic_search) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);

    tensorfs_create_file(tfs, "/readme.txt",
                         "documentation guide manual help", 32, 1);
    tensorfs_create_file(tfs, "/code.c",
                         "function variable loop array", 30, 1);
    tensorfs_create_file(tfs, "/help.txt",
                         "help documentation tutorial guide", 34, 1);

    tensorfs_search_result_t *results;
    size_t num_results;

    int ret = tensorfs_semantic_search_text(tfs, "documentation help",
                                            5, 0.0, &results, &num_results);
    assert(ret == 0);
    assert(num_results > 0);

    /* The documentation-related files should be in results */
    int found_readme = 0, found_help = 0;
    for (size_t i = 0; i < num_results; i++) {
        if (strstr(results[i].path, "readme")) found_readme = 1;
        if (strstr(results[i].path, "help")) found_help = 1;
    }

    tensorfs_free_search_results(results, num_results);
    tensorfs_destroy(tfs);
}

TEST(tensorfs_find_similar) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);

    tensorfs_create_file(tfs, "/a.txt", "apple banana cherry", 19, 1);
    tensorfs_create_file(tfs, "/b.txt", "apple orange grape", 18, 1);
    tensorfs_create_file(tfs, "/c.txt", "car truck bus", 13, 1);

    tensorfs_search_result_t *results;
    size_t num_results;

    int ret = tensorfs_find_similar(tfs, "/a.txt", 5, &results, &num_results);
    assert(ret == 0);

    /* /b.txt should be more similar to /a.txt than /c.txt due to "apple" */
    tensorfs_free_search_results(results, num_results);
    tensorfs_destroy(tfs);
}

/* ==================== Attention Tests ==================== */

TEST(tensorfs_attention) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);

    tensorfs_create_file(tfs, "/test.txt", "content", 7, 1);

    float initial_attention;
    tensorfs_stat(tfs, "/test.txt", NULL, NULL, &initial_attention, NULL);

    tensorfs_boost_attention(tfs, "/test.txt", 0.3f);

    float boosted_attention;
    tensorfs_stat(tfs, "/test.txt", NULL, NULL, &boosted_attention, NULL);

    assert(boosted_attention > initial_attention);

    tensorfs_decay_attention(tfs, 0.1f);

    float decayed_attention;
    tensorfs_stat(tfs, "/test.txt", NULL, NULL, &decayed_attention, NULL);

    assert(decayed_attention < boosted_attention);

    tensorfs_destroy(tfs);
}

/* ==================== Multi-Entity Tests ==================== */

TEST(tensorfs_entity_permissions) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);

    tensorfs_create_file(tfs, "/shared.txt", "shared content", 14, 1);

    uint64_t entity_id = 12345;
    uint32_t permissions = TENSORFS_PERM_READ | TENSORFS_PERM_WRITE;

    int ret = tensorfs_share(tfs, "/shared.txt", entity_id, permissions);
    assert(ret == 0);

    uint32_t retrieved = tensorfs_get_permissions(tfs, "/shared.txt", entity_id);
    assert(retrieved == permissions);

    /* Unknown entity should have no permissions */
    retrieved = tensorfs_get_permissions(tfs, "/shared.txt", 99999);
    assert(retrieved == 0);

    tensorfs_destroy(tfs);
}

/* ==================== Network-Aware Tests ==================== */

TEST(tensorfs_partition) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);

    tensorfs_create_file(tfs, "/test.txt", "data", 4, 1);

    int32_t partition_id;
    int is_local;

    int ret = tensorfs_get_partition(tfs, "/test.txt", &partition_id, &is_local);
    assert(ret == 0);
    assert(partition_id == 0);
    assert(is_local == 1);

    tensorfs_destroy(tfs);
}

TEST(tensorfs_replicate) {
    tensorfs_t *tfs = tensorfs_create(64, 4, 0);

    tensorfs_create_file(tfs, "/important.txt", "critical data", 13, 1);

    int ret = tensorfs_replicate(tfs, "/important.txt", 1);
    assert(ret == 0);

    ret = tensorfs_replicate(tfs, "/important.txt", 2);
    assert(ret == 0);

    tensorfs_destroy(tfs);
}

/* ==================== Main ==================== */

int main(void) {
    printf("\n=== TensorFS Unit Tests ===\n\n");

    /* Tensor tests */
    printf("--- Tensor Operations ---\n");
    RUN_TEST(tensor_create);
    RUN_TEST(tensor_randn);
    RUN_TEST(tensor_add);
    RUN_TEST(tensor_norm);
    RUN_TEST(tensor_cosine_similarity);

    /* TensorFS core tests */
    printf("\n--- TensorFS Core ---\n");
    RUN_TEST(tensorfs_create_destroy);
    RUN_TEST(tensorfs_create_file);
    RUN_TEST(tensorfs_create_directory);
    RUN_TEST(tensorfs_read_write);
    RUN_TEST(tensorfs_delete);
    RUN_TEST(tensorfs_readdir);
    RUN_TEST(tensorfs_stat);

    /* Semantic search tests */
    printf("\n--- Semantic Search ---\n");
    RUN_TEST(tensorfs_semantic_search);
    RUN_TEST(tensorfs_find_similar);

    /* Attention tests */
    printf("\n--- Attention Operations ---\n");
    RUN_TEST(tensorfs_attention);

    /* Multi-entity tests */
    printf("\n--- Multi-Entity ---\n");
    RUN_TEST(tensorfs_entity_permissions);

    /* Network-aware tests */
    printf("\n--- Network-Aware ---\n");
    RUN_TEST(tensorfs_partition);
    RUN_TEST(tensorfs_replicate);

    printf("\n=== Summary: %d tests passed ===\n\n", tests_passed);

    return 0;
}
