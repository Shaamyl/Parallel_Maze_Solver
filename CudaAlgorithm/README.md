CUDA Parallel Maze Solver

First you need to set up a build directory for the cmake
Use mkdir build and then cd build
Inside the build directory run cmake .. to generate a makefile
Running the code is pretty simple, either have the maze file in the build directory or have its path copied
Assuming that the maze file is in the build directory. The code can be ran as follows:
./solve  maze.txt

You can also run rand.cu to test out the CUDA random number generator by running:
./rand

The path will be outputted to an output.txt which will be inside the build directory.

There are three possible messages:
1-Solved : the maze has been solved and the DFS solver also solved it
2-Unsolvable: the CUDA kernel failed to solve the maze and the DFS solver also failed, thus it is unsolvable
3-Error: The results of the CUDA kernel and the DFS solver do not match up (Was used as a sanity check during testing, won't pop up unless the code is altered)
