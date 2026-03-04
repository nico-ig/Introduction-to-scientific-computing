#ifndef __LINEAR_H__
#define __LINEAR_H__

#include <stdlib.h>
#include <time.h>
#include <sys/time.h>

#include <stdio.h>
#include <string.h>
#include <math.h>

#include "utils.h"

void eliminacaoGauss(double **A, double *b, int n);
void retrossubs(double **A, double *b, double *x, int n);
void resolveSL(double **A, double *b, double *x, int n);

#endif // __LINEAR_H__

