#include <stdio.h>
#include <stdlib.h>
#include <float.h>
#include <fenv.h>
#include <math.h>
#include <stdint.h>

#include "linear.h"
#include "utils.h"

/////////////////////////////////////////////////////////////////////////////////////
//   AJUSTE DE CURVAS
/////////////////////////////////////////////////////////////////////////////////////

void montaSL(double **A, double *b, int n, long long int p, double *x, double *y) {
  for (int i = 0; i < n; ++i)
    for (int j = 0; j < n; ++j) {
      A[i][j] = 0.0;
      for (long long int k = 0; k < p; ++k) {
	      A[i][j] += pow(x[k], i+j);
      }
    }

  for (int i = 0; i < n; ++i) {
    b[i] = 0.0;
    for (long long int k = 0; k < p; ++k)
      b[i] += pow(x[k],i) * y[k];
  }
}

double Pol(double x, int G, double *alpha) {
  double Px = alpha[0];
  for (int i = 1; i <= G; ++i)
    Px += alpha[i]*pow(x,i);
  
  return Px;
}

int main() {

  int G, g; // G -> grau do polinomio
  long long int P, p; // P -> no. de pontos

  scanf("%d %lld", &G, &P);
  p = P;   // quantidade de pontos
  g = G+1; // tamanho do SL (G + 1)

  double *x = (double *) malloc(sizeof(double)*p);
  double *y = (double *) malloc(sizeof(double)*p);

  // ler numeros
  for (long long int i = 0; i < p; ++i)
    scanf("%lf %lf", x+i, y+i);

  double **A = (double **) malloc(sizeof(double *)*g);
  for (int i = 0; i < g; ++i)
    A[i] = (double *) malloc(sizeof(double)*g);
  
  double *b = (double *) malloc(sizeof(double)*g);
  double *alpha = (double *) malloc(sizeof(double)*g); // coeficientes ajuste
  
  // (A) Gera SL
  double tSL = timestamp();
  montaSL(A, b, g, p, x, y);
  tSL = timestamp() - tSL;

  // (B) Resolve SL
  double tEG = timestamp();
  resolveSL(A, b, alpha, g);
  tEG = timestamp() - tEG;

  // printf("Coeficientes: ");
  // // Imprime coeficientes
  // for (int i = 0; i < g; ++i)
  //   printf("%lf ", alpha[i]);
  // puts("");

  // Imprime polinômio
  printf("Polinômio: ");
  for (long long int i = 0; i < p; ++i)
    printf("%lf ", Pol(x[i],G,alpha));
  puts("");

  // Imprime os tempos
  printf("Tempos: ");
  printf("%lld %lf %lf\n", P, tSL, tEG);

  return 0;
}
