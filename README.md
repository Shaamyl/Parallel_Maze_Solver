CUDA Parallel Maze Solver (CudaAlgorithm)

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

Solution Visualizer (Visualizer)
- To compile the java code, run the command "javac *.java" inside the Visualizer directory.
- Then, to visualize a maze, the program needs three inputs. The maze file (describing the maze). There are three example maze files inside the directory. The path files (output from CudaAlgorithm). There are also 6 example path files, 2 corresponding to each maze describing old and new algorithm output. Then the width of the maze (50, 10, 5 recommended for Maze 1, 2, 3 respectively).
- An example command is "java Visualizer maze1.txt maze1_path.txt 50" to visualize maze 1, its solved path, and 50 width.
