import java.awt.*;  
import javax.swing.*;
import java.util.Scanner;
import java.io.File;
import java.io.FileNotFoundException;
import java.util.ArrayList;

enum ColorEnum{
	GREEN,
	WHITE,
	BLACK,
	RED
}

class MazeNode{
	String desc = ".";
	ColorEnum color = ColorEnum.WHITE;
	int x = 0;
	int y = 0;
	int thread = -1;
	int totalThreads = 0;

	public MazeNode(String desc, ColorEnum color, int x, int y){
		this.desc = desc;
		this.color = color;
		this.x = x;
		this.y = y;
	}
}
public class Visualizer extends Canvas{
	MazeNode[][] maze;
	int rows;
	int columns;
	int width = 10;
	int totalThreads = -1;

	public Visualizer(String mazePath, int width){
		this.width = width;
		File mazeFile = new File(mazePath);
		Scanner in;
		try {
			in = new Scanner(mazeFile);
			rows = Integer.valueOf(in.nextLine());
			columns = Integer.valueOf(in.nextLine());
			maze = new MazeNode[rows][columns];
			int x = 0;
			for(int i = 0; i < rows; i++){
				int y = 0;
				String descLine = in.nextLine();
				for(int j = 0; j < columns; j++){
					String currentDesc = String.valueOf(descLine.charAt(j));
					if(currentDesc.equals(".") || currentDesc.equals("s")){
						maze[i][j] = new MazeNode(currentDesc, ColorEnum.WHITE, y, x);
					}else if(currentDesc.equals("g")){
						maze[i][j] = new MazeNode(currentDesc, ColorEnum.GREEN, y, x);
					}else if(currentDesc.equals("w")){
						maze[i][j] = new MazeNode(currentDesc, ColorEnum.BLACK, y, x);
					}
					System.out.print(maze[i][j].desc + " ");
					y = y + width;
				}
				x = x + width;
				System.out.println();
			}
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	public void paint(Graphics g){
		super.paint(g);
		
		int xOff = (maze[0].length * width)/2;
		int yOff = (maze.length * width)/2;
		Graphics2D g2 = ((Graphics2D)g);
		g2.drawString("1", 0, 0);
		g2.setStroke(new BasicStroke(2f));
		Font font = new Font("Serif", Font.PLAIN, width/2);
		g2.setFont(font);
		for(int i = 0; i < rows; i++){
			for(int j = 0; j < columns; j++){
				if(maze[i][j].color == ColorEnum.WHITE){
					java.awt.Color myColor = new java.awt.Color(255, 255, 255);
					g.setColor(myColor);
					g.fillRect(maze[i][j].x + xOff, maze[i][j].y + yOff, width , width);
				}
				if(maze[i][j].color == ColorEnum.GREEN){
					java.awt.Color myColor = new java.awt.Color(0, 255, 0);
					g.setColor(myColor);
					g.fillRect(maze[i][j].x + xOff, maze[i][j].y + yOff, width , width);
				}
				if(maze[i][j].color == ColorEnum.BLACK){
					java.awt.Color myColor = new java.awt.Color(0, 0, 0);
					g.setColor(myColor);
					g.fillRect(maze[i][j].x + xOff, maze[i][j].y + yOff, width , width);
				}
				if(maze[i][j].color == ColorEnum.RED && !maze[i][j].desc.equals("g")){
					// Color opaqueness is dependent on number of threads. Less threads means less opaque color
					java.awt.Color myColor = new java.awt.Color(255, 200 - (int)Math.round((double) maze[i][j].totalThreads/totalThreads * 200), 200 - (int)Math.round((double) maze[i][j].totalThreads/totalThreads * 200));
					g.setColor(myColor);
					g.fillRect(maze[i][j].x + xOff, maze[i][j].y + yOff, width , width);
				}
				if(maze[i][j].color == ColorEnum.RED && maze[i][j].desc.equals("g")){ // To keep goal green
					java.awt.Color myColor = new java.awt.Color(0, 255, 0);
					g.setColor(myColor);
					g.fillRect(maze[i][j].x + xOff, maze[i][j].y + yOff, width , width);
				}

				g.setColor(java.awt.Color.BLACK);
				g.drawRect(maze[i][j].x + xOff,  maze[i][j].y + yOff, width , width);
				//if(maze[i][j].thread !=  -1){
				//	g2.drawString(String.valueOf(maze[i][j].thread), maze[i][j].x + xOff + (35 * width)/100, maze[i][j].y + yOff + (75 * width)/100);
				//}
			}
		}
	}

	public void simulateThreads(String pathsPath){
		File pathFile = new File(pathsPath);
		
		try {
			Scanner in = new Scanner(pathFile);
			ArrayList<String[]> paths = new ArrayList<String[]>();
			while(in.hasNext()){
				String[] path = in.nextLine().strip().split(" ");
				paths.add(path);				
			}

			totalThreads = paths.size();

			int globalIndex = 0;
			boolean noMoreThreads = false;
			while(!noMoreThreads){
				noMoreThreads = true;
				Thread.sleep(400);
				int currentThread = 1;
				for(String[] thread : paths){
					
					if(globalIndex <= thread.length - 1){
						//Thread.sleep(200);
						noMoreThreads = false;
						int row = Integer.valueOf(thread[globalIndex])/columns;
						int column = Integer.valueOf(thread[globalIndex]) % columns;
						
						maze[row][column].color = ColorEnum.RED;
						maze[row][column].thread = currentThread;
						maze[row][column].totalThreads++;
						
						repaint();
					}
					currentThread++;
				}
				globalIndex++;
			}
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		 catch (FileNotFoundException e) {
			e.printStackTrace();
		}

	
	}




	public static void main(String args[]){
		
		if(args.length != 3){
			System.out.println("Error: Enter file path with maze description, thread paths, and width");
			return;
		}
		Visualizer viz = new Visualizer(args[0], Integer.valueOf(args[2]));
		JFrame frame = new JFrame("Parallel Maze Solver");
		frame.setSize(viz.maze[0].length * viz.width * 2, viz.maze.length * viz.width * 2);
		frame.add(viz);
		frame.setLocationRelativeTo(null);
		frame.setVisible(true);
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

		
		viz.simulateThreads(args[1]);
		
	}
}