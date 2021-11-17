/*
============================================================================
Filename    : algorithm.c
Author      : Bereyziat/Del Zio
SCIPER		: 282962/311240

============================================================================
*/
#include <math.h>

#define INPUT(I, J) input[(I)*length + (J)]
#define OUTPUT(I, J) output[(I)*length + (J)]

void copyRow(int row, int length, double *input, double *output);
void updateRow(int row, int length, double *input, double *output);

void simulate(double *input, double *output, int threads, int length, int iterations)
{
    //output(i, j) needs input arount him
    //we
    omp_set_num_threads(threads);
    int row = 0;

#pragma omp parallel private(row) shared(input, output)
    {
        for (int n = 0; n < iterations; n++)
        {
#pragma omp for
            for (row = 1; row < length - 1; ++row)
            {
                updateRow(row, length, input, output);
            }

#pragma omp for
            for (row = 1; row < length - 1; ++row)
            {
                copyRow(row, length, input, output);
            }
        }
    }
}

void updateRow(int row, int length, double *input, double *output)
{
    for (int col = 1; col < length - 1; col++)
    {
        if (((row == length / 2 - 1) || (row == length / 2)) && ((col == length / 2 - 1) || (col == length / 2)))
            continue;

        OUTPUT(row, col) = (INPUT(row - 1, col - 1) + INPUT(row - 1, col) + INPUT(row - 1, col + 1) +
                            INPUT(row, col - 1) + INPUT(row, col) + INPUT(row, col + 1) +
                            INPUT(row + 1, col - 1) + INPUT(row + 1, col) + INPUT(row + 1, col + 1)) /
                           9;
    }
}

void copyRow(int row, int length, double *input, double *output)
{
    for (int col = 1; col < length - 1; ++col)
        INPUT(row, col) = OUTPUT(row, col);
}