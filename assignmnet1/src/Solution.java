//import java.io.File;
//import java.io.FileNotFoundException;
//import java.util.Scanner;
//
//public class Solution {
//    private static final int BOARD_SIZE = 25;
//    private static final int NUM_WORDS = 21;
//    private char[][] board;
//    private char[][] output;
//    private char[][] words;
//    private int foundWords;
//
//    public Solution() {
//        board = new char[BOARD_SIZE][BOARD_SIZE];
//        output = new char[BOARD_SIZE][BOARD_SIZE];
//        words = new char[NUM_WORDS][];
//        foundWords = 0;
//        for (int i = 0; i < BOARD_SIZE; i++) {
//            for (int j = 0; j < BOARD_SIZE; j++) {
//                output[i][j] = ' ';
//            }
//        }
//    }
//
//    public void readData(String filename) throws FileNotFoundException {
//        Scanner scanner = new Scanner(new File(filename));
//
//        for (int i = 0; i < NUM_WORDS; i++) {
//            String word = scanner.nextLine().trim().toUpperCase();
//            words[i] = word.toCharArray();
//        }
//        for (int i = 0; i < BOARD_SIZE; i++) {
//            String line = scanner.nextLine().trim();
//            for (int j = 0; j < BOARD_SIZE; j++) {
//                board[i][j] = line.charAt(j);
//            }
//        }
//        scanner.close();
//    }
//
//    private char getChar(int row, int col) {
//        if (row >= 0 && row < BOARD_SIZE && col >= 0 && col < BOARD_SIZE) {
//            return board[row][col];
//        }
//        return '*';
//    }
//
//    private boolean findWordInDirection(int startRow, int startCol, char[] word,
//                                        int rowDelta, int colDelta) {
//        for (int i = 0; i < word.length; i++) {
//            char currentChar = getChar(startRow + (i * rowDelta),
//                    startCol + (i * colDelta));
//            if (currentChar != word[i]) {
//                return false;
//            }
//        }
//        return true;
//    }
//
//    private void markWord(int startRow, int startCol, char[] word,
//                          int rowDelta, int colDelta) {
//        for (int i = 0; i < word.length; i++) {
//            output[startRow + (i * rowDelta)][startCol + (i * colDelta)] = word[i];
//        }
//        foundWords++;
//    }
//
//    public void solvePuzzle() {
//        int[] rowDirections = {-1, -1, -1,  0,  0,  1,  1,  1};
//        int[] colDirections = {-1,  0,  1, -1,  1, -1,  0,  1};
//
//        for (int wordIndex = 0; wordIndex < NUM_WORDS; wordIndex++) {
//            char[] currentWord = words[wordIndex];
//            boolean wordFound = false;
//
//            for (int row = 0; row < BOARD_SIZE && !wordFound; row++) {
//                for (int col = 0; col < BOARD_SIZE && !wordFound; col++) {
//                    for (int dir = 0; dir < 8 && !wordFound; dir++) {
//                        if (findWordInDirection(row, col, currentWord,
//                                rowDirections[dir], colDirections[dir])) {
//                            markWord(row, col, currentWord,
//                                    rowDirections[dir], colDirections[dir]);
//                            wordFound = true;
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    public void printSolution() {
//        System.out.println("Found   " + foundWords);
//        for (int i = 0; i < BOARD_SIZE; i++) {
//            for (int j = 0; j < BOARD_SIZE; j++) {
//                System.out.print(output[i][j]);
//            }
//            System.out.println();
//        }
//    }
//
//    public static void main(String[] args) {
//        Solution wordSearch = new Solution();
//        try {
//            wordSearch.readData("wordsearch.dat");
//            wordSearch.solvePuzzle();
//            wordSearch.printSolution();
//        } catch (FileNotFoundException e) {
//            System.out.println("Error: Cannot find input file wordSearch.dat");
//            System.exit(1);
//        }
//    }
//}