import java.util.LinkedList;

public class Main {

    public static class linkedList{
        int data;
        linkedList next;

        public linkedList(int data){
            this.data=data;
            next=null;
        }
        public linkedList(){
            data=0;
            next=null;
        }

    }


    public static class stackWithLL{
        static linkedList head;
        static int size;
        public stackWithLL(){
            head=null;
            size=0;
        }


        // add elemnts
        public static void add(int elm){
                linkedList node=new linkedList(elm);
                node.next=head;
                head=node;
                size++;

        }

        // size
        public static int size(){

            return size;
        }

        // isEmpty
        public static boolean isEmpty(){

//            if(size==0) return true;
//            return false;

            return size==0;
        }

        //top
        public static int top(){

            if(size==0){
                System.out.println("stackEmpty execption");
                return -1;
            }
            return head.data;
        }

        //pop
        public static int pop(){
            if(size==0){
                System.out.println("stackEmpty execption");
                return -1;
            }
            linkedList node=head;

            head=head.next;

            return node.data;

        }

    }
    public static void main(String[] args) {

        stackWithLL stack=new stackWithLL();

        stack.add(10);
        stack.add(20);
        stack.add(30);
        stack.add(40);

        System.out.println(stack.size);

        System.out.println(stack.top());
        System.out.println(stack.pop());
        System.out.println(stack.top());

    }
}