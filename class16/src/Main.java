import java.util.LinkedList;
import java.util.List;

public class Main {



    static abstract class vehical{
        String type;
        int speed;
        int weight;
        int year;

        public vehical(String type, int speed, int weight, int year) {}

        public abstract void startEngine();
        }



    static abstract class Car extends vehical{

        public Car(String type, int speed, int weight, int year) {
            super(type, speed, weight, year);
        }

    }

    static class LinkedList<T> {
        T data;
        LinkedList next;

        public LinkedList(T data) {
            this.data = data;
            next = null;
        }

        public void printLinkedList(){
            LinkedList<T> temp=this;
            while(temp!=null){
                System.out.print(temp.data+"->");
                temp=temp.next;
            }
            System.out.println("null");  // to print the last node as well
        }


    }

    public static <T> void printLinkedList(LinkedList head){
        LinkedList<T> temp=head;
        while(temp!=null){
            System.out.print(temp.data+"->");
            temp=temp.next;
        }
        System.out.println("null");  // to print the last node as well
    }

    public static void main(String[] args) {

        LinkedList<Integer> list=new LinkedList<>(10);

        list.next=new LinkedList<>(20);

        list.next.next=new LinkedList<>(30);

        // 10->20->30

        LinkedList<String> list2=new LinkedList<>("node1");

        list2.next=new LinkedList<>("node2");

        list2.next.next=new LinkedList<>("node3");


        printLinkedList(list);

        list2.printLinkedList();




        System.out.println("Hello world!");
    }
}