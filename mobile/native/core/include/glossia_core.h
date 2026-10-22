#ifndef GLOSSIA_CORE_H
#define GLOSSIA_CORE_H
/* Blocking JSON interface: call on a background executor, never log credentials.
 * The caller borrows input and frees the owned result exactly once. */
char *glossia_core_execute(const char *input);
void glossia_core_free(char *output);
#endif
