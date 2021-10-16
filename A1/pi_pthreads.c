/*
============================================================================
Filename    : pi_pthreads.c
Author      : Weniqng Qu Jonathan Bereyziat
SCIPER		: 344589 282962
============================================================================
*/

#include <stdio.h>
#include <stdlib.h>
#include "utility.h"
#include <pthread.h>

int num_in_circle = 0;
int n_samples = 0;

void *calculate_pi(void *thread);

int main(int argc, const char *argv[])
{

    int num_threads, num_samples;
    double pi;

    if (argc != 3)
    {
        printf("Invalid input! Usage: ./pi <num_threads> <num_samples> \n");
        return 1;
    }
    else
    {
        num_threads = atoi(argv[1]);
        num_samples = atoi(argv[2]);
    }

    n_samples = num_samples / num_threads;
    int thread_list[num_threads];
    pthread_t mutex[num_threads];

    set_clock();

    for (int i = 0; i < num_threads; i++)
    {
        thread_list[i] = i;
        pthread_create(&mutex[i], NULL, calculate_pi, (void *)(thread_list + i));
    }
    /*create threads*/

    for (int i = 0; i < num_threads; i++)
    {
        pthread_join(mutex[i], NULL);
    }
    /*join threads*/

    pi = (double)4 * num_in_circle / num_samples;

    printf("- Using %d threads: pi = %.15g computed in %.4gs.\n", num_threads, pi, elapsed_time());

    return 0;
}

void *calculate_pi(void *thread)
{
    rand_gen gen = init_rand_pthreads(*(int *)thread);

    for (int i = 0; i < n_samples; i++)
    {
        // double x = (double)rand() / (double)RAND_MAX;
        // double y = (double)rand() / (double)RAND_MAX;
        double x = next_rand(gen);
        double y = next_rand(gen);
        if (x * x + y * y < 1)
        {
            num_in_circle++;
        }
    }
    free_rand(gen);
    return NULL;
}
