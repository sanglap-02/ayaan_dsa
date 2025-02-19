import java.io.*;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

class Node {
    int data;
    Node next;

    public Node(int data) {
        this.data = data;
        this.next = null;
    }
}

class CodeBookEntry {
    int count;
    Node head;

    public CodeBookEntry() {
        this.count = 0;
        this.head = null;
    }

    public void add(int code) {
        Node newNode = new Node(code);
        if (head == null) {
            head = newNode;
        } else {
            Node temp = head;
            while (temp.next != null) {
                temp = temp.next;
            }
            temp.next = newNode;
        }
        count++;
    }

    public int getRandomCode(Random rand) {
        if (count == 0) return -1;
        int index = rand.nextInt(count);
        Node temp = head;
        for (int i = 0; i < index; i++) {
            temp = temp.next;
        }
        return temp.data;
    }
}

public class BookCipher {
    static CodeBookEntry[] codeBook = new CodeBookEntry[128];

    public static void main(String[] args) throws IOException {
        Random rand = new Random();
        generateCodeBook(rand);
        printCodeBook();

        // Create a "files" directory if it doesn't exist
        File filesDir = new File("files");
        if (!filesDir.exists()) {
            filesDir.mkdir();
        }

        // Use relative paths with the "files" directory
        String inputFile = "files/Message.txt";
        String encryptedFile = "files/Encrypted.txt";
        String decryptedFile = "files/Decrypted.txt";

        // Create Message.txt with some sample text if it doesn't exist
        if (!new File(inputFile).exists()) {
            try (BufferedWriter writer = new BufferedWriter(new FileWriter(inputFile))) {
                writer.write("Hello, this is a test message!");
            }
            System.out.println("Created sample Message.txt file");
        }

        // Encode and decode the message
        encodeMessage(inputFile, encryptedFile, rand);
        System.out.println("Message encoded successfully.");
        decodeMessage(encryptedFile, decryptedFile);
        System.out.println("Message decoded successfully.");
    }

    private static void generateCodeBook(Random rand) {
        for (int i = 0; i < 128; i++) {
            codeBook[i] = new CodeBookEntry();
        }
        for (int i = 1; i <= 2000; i++) {
            int ascii = rand.nextInt(128);
            codeBook[ascii].add(i);
        }
    }

    private static void printCodeBook() {
        for (int i = 0; i < 128; i++) {
            System.out.print(i + "\t");
            Node temp = codeBook[i].head;
            while (temp != null) {
                System.out.print(temp.data + "\t");
                temp = temp.next;
            }
            System.out.println();
        }
    }

    private static void encodeMessage(String inputFile, String outputFile, Random rand) throws IOException {
        try (BufferedReader reader = new BufferedReader(new FileReader(inputFile));
             BufferedWriter writer = new BufferedWriter(new FileWriter(outputFile))) {
            int ch;
            while ((ch = reader.read()) != -1) {
                int encoded = codeBook[ch].getRandomCode(rand);
                writer.write(encoded + " ");
            }
        }
    }

    private static void decodeMessage(String inputFile, String outputFile) throws IOException {
        try (BufferedReader reader = new BufferedReader(new FileReader(inputFile));
             BufferedWriter writer = new BufferedWriter(new FileWriter(outputFile))) {
            StringTokenizer tokenizer = new StringTokenizer(reader.readLine());
            while (tokenizer.hasMoreTokens()) {
                int encodedValue = Integer.parseInt(tokenizer.nextToken());
                char decodedChar = findCharacter(encodedValue);
                writer.write(decodedChar);
            }
        }
    }

    private static char findCharacter(int encodedValue) {
        for (int i = 0; i < 128; i++) {
            Node temp = codeBook[i].head;
            while (temp != null) {
                if (temp.data == encodedValue) {
                    return (char) i;
                }
                temp = temp.next;
            }
        }
        return '?'; // Error case
    }
}
