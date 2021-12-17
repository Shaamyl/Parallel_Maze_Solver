#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <curand.h>
#include <curand_kernel.h>
#include <float.h>
#include <math.h>
#include <iostream>
#include <sstream>
#include <vector>
#include <fstream>
#include <iterator>
#include <string>
#include <stack>
#include <algorithm> 
using namespace std;
#include "utils.h"

#define N_THREADS 1024
#define N_BLOCKS 16

/*** GPU functions ***/
/*
 * Intiates random states for each thread
 */
__global__ void init_rand_kernel(curandState *state) {
 int idx = blockIdx.x * blockDim.x + threadIdx.x;
 curand_init(0, idx, 0, &state[idx]);
}
/*
 * Attempts to solve the maze and outputs a path
 * If the threads get stuck, they go back to the previous position
 * If the thread gets back to the start with nowhere left to go, then it can't go anywhere else and returns
 */
__global__ void random_solve_path_kernel(char* maze, int rows, int cols, int start, int* path, bool* solved, int* final_pos, curandState *state) {
        *solved = false;
        int tid = threadIdx.x + blockIdx.x * blockDim.x;
        int curr_pos = start;
        final_pos[tid] = curr_pos;
        float rand_val;
        int old_pos;
        //return;
        //printf("%i", solved);
        path[(curr_pos) + rows * cols * tid] = curr_pos;
        while(*solved != true){

                /**
                 * This part is responsible for generating the legal moves and picking a random one
                 * In an ideal scenario we will have 4 moves, hence why the array is intialized to 4
                 * There are 8 edge cases that are accounted for: [top left corner, top right corner, bottom left corner, bottom right corner, first col but not first row, first row but not first col,
                 * last col but not first row, last row but not first col]
                 */
                 //Keeps track of how many legal_moves we have
            int legal_moves = 0;
                //Intialized to 4 since the max number of legal_moves we can have is 4
            int legal_movesarr[4];
                /**
                 * If the position is in bounds and it isn't the last element in a row (adding a 1 to the last element in a row would mean we zipped to (row + 1, 0), an invalid move)
                 * then it is a legal move to increase curr_pos by 1 (i.e got to the next col) and it is added to the array
                 */

                //printf("%c \n", maze[curr_pos]);
            if(curr_pos + 1 < (rows * cols) && (curr_pos + 1) % cols != 0 && path[(curr_pos + 1) + rows * cols * tid] == -1 && maze[curr_pos + 1] != 'w' ){
                        //printf("We are in loop\n");
                legal_movesarr[legal_moves] = curr_pos + 1;
                legal_moves++;
            }
                /*
                 * If the position is in bounds and it isn't the first element in a row (subtracting a 1 would mean zipping across to the last element in the previous row (row - 1, col - 1), an invalid move),
                 * then it is a legal move to decrease curr_pos by 1 (i.e go to the previous col) and it is added to the array
                 */
            if(curr_pos - 1 >= 0 && curr_pos % cols != 0 && path[(curr_pos - 1) + rows * cols * tid] == -1 && maze[curr_pos -1] != 'w'){
                legal_movesarr[legal_moves] = curr_pos - 1;
                legal_moves++;
            }
                //If it is in bounds, going to the next row (by adding cols) is always legal
            if( curr_pos + cols < rows * cols && path[(curr_pos + cols) + rows * cols * tid] == -1 && maze[curr_pos + cols] != 'w'){
                legal_movesarr[legal_moves] = curr_pos + cols;
                legal_moves++;
            }
                //If it is in bounds, going to the previous row (by subtracting cols) is always legal
            if(curr_pos - cols >= 0 && path[(curr_pos - cols) + rows * cols * tid] == -1 && maze[curr_pos - cols] != 'w'){
                legal_movesarr[legal_moves] = curr_pos - cols;
                legal_moves++;
            }
            //If you backtrack all the way to the start and there is no way to go then you are done
            if(legal_moves == 0 && curr_pos == start){
                return;
            }
            //If you don't have any legal moves, we should go back to where you came from and explore from there
            if(legal_moves == 0){
                curr_pos = path[curr_pos + (rows * cols *tid)];
                continue;
            }

            //Pick random legal move
            rand_val = curand_uniform(&state[tid]);
            rand_val *= ((legal_moves - 1) + 0.999999);
            old_pos = curr_pos;
            curr_pos = legal_movesarr[int(rand_val)];
            path[curr_pos + (rows * cols * tid)] = old_pos;
            final_pos[tid] = curr_pos;
	    //Goal found, set solved value to true to signal to all the other the threads that the maze has been solved
            if(maze[curr_pos] == 'g'){
                *solved = true;
            }
        }
}
/*
 * Solves the maze without outputting a path
 * Threads move randomly until they find a goal
 * If the maze is unsolvable, this will run forever
 * It was used as a sanity check to make sure our solving logic was correct
 */
__global__ void random_solve_kernel(char* maze, int rows, int cols, int start, bool* solved, curandState *state) {
        *solved = false;
        int tid = threadIdx.x + blockIdx.x * blockDim.x;
        int curr_pos = start;
        float rand_val;
        //return;
        //printf("%i", solved);
        while(*solved != true){
            /**
              * This part is responsible for generating the legal moves and picking a random one
              * In an ideal scenario we will have 4 moves, hence why the array is intialized to 4
              * There are 8 edge cases that are accounted for: [top left corner, top right corner, bottom left corner, bottom right corner, first col but not first row, first row but not first col,
              * last col but not first row, last row but not first col]
              */
            //Keeps track of how many legal_moves we have
            int legal_moves = 0;
            //Intialized to 4 since the max number of legal_moves we can have is 4
            int legal_movesarr[4];
            /**
              * If the position is in bounds and it isn't the last element in a row (adding a 1 to the last element in a row would mean we zipped to (row + 1, 0), an invalid move)
              * then it is a legal move to increase curr_pos by 1 (i.e got to the next col) and it is added to the array
              */

             if(curr_pos + 1 < (rows * cols) && (curr_pos + 1) % cols != 0 && maze[curr_pos + 1] != 'w' ){
                 legal_movesarr[legal_moves] = curr_pos + 1;
                 legal_moves++;
             }
             /*
              * If the position is in bounds and it isn't the first element in a row (subtracting a 1 would mean zipping across to the last element in the previous row (row - 1, col - 1), an invalid move),
              * then it is a legal move to decrease curr_pos by 1 (i.e go to the previous col) and it is added to the array
              */
              if(curr_pos - 1 >= 0 && curr_pos % cols != 0 && maze[curr_pos -1] != 'w'){
                  legal_movesarr[legal_moves] = curr_pos - 1;
                  legal_moves++;
               }
               //If it is in bounds, going to the next row (by adding cols) is always legal
               if( curr_pos + cols < rows * cols && maze[curr_pos + cols] != 'w'){
                   legal_movesarr[legal_moves] = curr_pos + cols;
                   legal_moves++;
                }
                //If it is in bounds, going to the previous row (by subtracting cols) is always legal
                if(curr_pos - cols >= 0 && maze[curr_pos - cols] != 'w'){
                    legal_movesarr[legal_moves] = curr_pos - cols;
                    legal_moves++;
                }
                //Pick random legal move
                rand_val = curand_uniform(&state[tid]);
                rand_val *= ((legal_moves - 1) + 0.999999);
                curr_pos = legal_movesarr[int(rand_val)];
                //printf("%i \n", curr_pos);

                if(maze[curr_pos] == 'g'){
                        //printf("%i \n", curr_pos);
                        *solved = true;
                }
        }
}

/*** CPU functions ***/

curandState* init_rand() {
  curandState *d_state;
  cudaMalloc(&d_state, N_BLOCKS * N_THREADS * sizeof(curandState));
  init_rand_kernel<<<N_BLOCKS, N_THREADS>>>(d_state);
  return d_state;
}

/**
 * Writes out each thread's path unto a line in an output file
 * The output file is used by the visualizer
 */
void writeOut(int* path, int* final_pos, int rows, int cols){
    string finalResult = "";

  //printf("%i\n", ans[0]);
    for(int i = 0; i < N_THREADS * N_BLOCKS; i++){
        vector<int> vec;
        int currIdx = final_pos[i];
        vec.push_back(currIdx);
        while(currIdx != path[currIdx + (rows * cols * i)]){
            vec.push_back(path[currIdx + (rows * cols * i)]);
            currIdx = path[currIdx + (rows * cols * i)];
        }
        reverse(vec.begin(), vec.end());
        stringstream result;
        copy(vec.begin(), vec.end(), ostream_iterator<int>(result, " "));
        string n = result.str();
        finalResult += n += "\n";
    }
    ofstream out("output.txt");
    out << finalResult;

}

/**
 * Classic CPU based DFS solver
 * Used to detetmine whether a maze was solvable or not
 * Used as a sanity check to make sure random_solve_path actually solved the maze
 */
bool dfsSolver(char* maze, int rows, int cols, int start){
   stack<int> myStack;
   //Not actually outputting the path, just using it to make sure we don't revisit nodes we already visited
   //Could use a node struct with a boolean member that determines whether it was visited or not
   //This seemed simpler however
   int* path;
   path = (int *) malloc(sizeof(int) * (rows * cols));
   for(int i = 0; i < (rows * cols); i++){
       path[i] = -1;
   }
   myStack.push(start);
   int curr_pos;
   path[start] = start;
   while(!myStack.empty()){
       //cout << myStack.size() << endl;
       if(maze[myStack.top()] == 'g'){
           return true;
       }
       curr_pos = myStack.top();
       myStack.pop();
       if(curr_pos + cols < rows * cols && path[curr_pos + cols] == -1 && maze[curr_pos + cols] != 'w'){
           myStack.push(curr_pos + cols);
           path[curr_pos + cols] = curr_pos;
       }
       if(curr_pos - cols >= 0 && path[curr_pos - cols] == -1 && maze[curr_pos - cols] != 'w'){
           myStack.push(curr_pos - cols);
           path[curr_pos - cols] = curr_pos;
       }
       if(curr_pos + 1 < rows * cols && path[curr_pos + 1] == -1 && maze[curr_pos + 1] != 'w'){
           myStack.push(curr_pos + 1);
           path[curr_pos + 1] = curr_pos;
       }
       if(curr_pos - 1 >= 0 && path[curr_pos - 1] == -1 && maze[curr_pos - 1] != 'w'){
           myStack.push(curr_pos - 1);
           path[curr_pos - 1] = curr_pos;
       }

   }
   free(path);
   return false;
}
void random_solve_maze(char* maze, int rows, int cols, int start) {
	curandState* d_state = init_rand();
	int *path;
	int *d_path;
	int *final_pos;
	int *d_final_pos;
	char *d_maze;
	bool *solved;
	bool *d_solved;
	
	//Allocate memory on CPU
	path = (int *) malloc(sizeof(int) * ((rows * cols) * (N_BLOCKS * N_THREADS)));
	solved = (bool *) malloc(sizeof(bool));
	final_pos = (int *) malloc(sizeof(int) * (N_BLOCKS * N_THREADS));
        //Allocate memory on GPU
	cudaMalloc(&d_path, sizeof(int) * ((rows * cols) * (N_BLOCKS * N_THREADS)));
	cudaMalloc(&d_maze, sizeof(char) * (rows * cols));
	cudaMalloc(&d_solved, sizeof(bool));
	cudaMalloc(&d_final_pos, sizeof(int) * (N_BLOCKS * N_THREADS));
	
	for(int i = 0; i < (rows * cols) * (N_BLOCKS * N_THREADS); i++){
		path[i] = -1;
	}

	
	*solved = false;

	//Copy maze over to GPU
	cudaMemcpy(d_maze, maze, sizeof(char) * (rows * cols), cudaMemcpyHostToDevice);
	cudaMemcpy(d_path, path, sizeof(int) * ((rows * cols) * (N_BLOCKS * N_THREADS)), cudaMemcpyHostToDevice);
	
        random_solve_path_kernel<<<N_BLOCKS, N_THREADS>>>(d_maze, rows, cols, start, d_path, d_solved, d_final_pos, d_state);

        //Uncomment to use. NOTE: MAZE NEEDS TO BE SOLVABLE
        //random_solve_kernel<<<N_BLOCKS, N_THREADS>>>(d_maze, rows, cols, start, d_solved, d_state);
	
  // After kernel call:
       // Need to copy data back to CPU and check if solved
        cudaMemcpy(path, d_path, sizeof(int) * ((rows * cols) * (N_BLOCKS * N_THREADS)), cudaMemcpyDeviceToHost);
	cudaMemcpy(solved, d_solved, sizeof(bool), cudaMemcpyDeviceToHost);
	cudaMemcpy(final_pos, d_final_pos, sizeof(int) * N_BLOCKS * N_THREADS, cudaMemcpyDeviceToHost);

        //Compares the kernel output with that of the DFS solver
        if(*solved == dfsSolver(maze, rows, cols, start) && *solved == true){
            cout << "Solved\n";
	}
        if(*solved == dfsSolver(maze, rows, cols, start) && *solved == false){
            cout << "Unsolvable\n";
        }
        //If the outputs don't match, then we have a problem was used as a sanity check early on
        if(*solved != dfsSolver(maze, rows, cols, start)){
            cout <<"Error, kernel not working correctly";
            return;
        }
        //Writes out the path
        writeOut(path, final_pos, rows, cols);
        //Frees memeory
	free(solved);
	free(final_pos);
	free(path);
	cudaFree(d_final_pos);
	cudaFree(d_path);
	cudaFree(d_solved);
	cudaFree(d_maze);
	cudaFree(d_state);

}


int main(int argc, char *argv[]) {
    if (argc != 2) {
       printf("Usage: %s <maze_file> \n", argv[0]);
       return 1;
     }
    //Reads maze file
    ifstream myfile(argv[1]);
    string line;
    getline(myfile, line);
    string space_delimiter = " ";
    vector<string> words;
    
    stringstream ss(line);
    int rows;
    ss >> rows;
    int cols;
    getline(myfile, line);
    stringstream sCols(line);
    sCols >> cols;
    string mazeStr;
    while (getline(myfile, line)){
        mazeStr += line;
    }
    //Gets rid of newline characters and spaces if they are present
    mazeStr.erase(remove(mazeStr.begin(), mazeStr.end(), '\n'),
            mazeStr.end());
    mazeStr.erase(remove(mazeStr.begin(), mazeStr.end(), ' '),
            mazeStr.end());
    char maze[rows * cols];
    strcpy(maze, mazeStr.c_str());
    int start;
    //Finds start position
    for(int i = 0; i < rows * cols; i++){
        if(maze[i] == 's'){
            start = i;
            break;
        }
    }
    random_solve_maze(maze, rows, cols, start);

    return 0;
}
