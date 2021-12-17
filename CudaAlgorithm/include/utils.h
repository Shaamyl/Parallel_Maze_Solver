#ifndef _UTILS_H_
#define _UTILS_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFSIZE 12 * 8192

void read_bin(const char* filename, float** data, int* rows, int* cols) {
  FILE* fp = fopen(filename, "r");
  if (fp == NULL) {
    printf("Error opening file %s\n", filename);
    exit(1);
  }

  fread(rows, sizeof(int), 1, fp);
  fread(cols, sizeof(int), 1, fp);
  *data = (float*)malloc(sizeof(float) * (*rows) * (*cols));
  fread(*data, sizeof(float), (*rows) * (*cols), fp);
  fclose(fp);
}

#endif  // _UTILS_H_