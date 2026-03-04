#include <stdio.h>
#include <stdlib.h>

#define RUIDO(n) (((double)rand())/(n*(double)RAND_MAX))
#define PASSO(n) (1.0/(double)n)

static double f(double x, int G, long long int P, double *a) {
  double fx = a[0] + RUIDO(P);
  double px = 1;
  for (int i = 1; i <= G; ++i) {
    px *= x;
    fx += a[i]*px;
  }
  return fx;
}

int main(int argc, char **argv) {

  if (argc != 3) {
    printf("uso: %s <P> <G>, onde <P> é a quantidade de pontos e <G> é o grau do polinômio\n", argv[0]);
    return 1;
  }

  long long int P = atoll(argv[1]);
  int G = atoi(argv[2]);

  srand(20252);

  double *a = (double *)malloc(sizeof(double)*(G+1)); // G+1 coeficientes
  a[0] = 0.1;
  for (int i = 1; i <= G; ++i)
    a[i] = a[i-1]/2 + RUIDO(P);

  printf("%d\n", G);
  printf("%lld\n", P);
  double x = RUIDO(P);
  for (long long int i = 0; i < P; ++i) {
    printf("%1.15e %1.15e\n", x, f(x,G,P,a));
    x += PASSO(P);
  }

#ifdef DEBUG
  for (int i = 0; i <= G; ++i)
    fprintf(stderr, "a%d = %1.15e\n", i, a[i]);
#endif
}
