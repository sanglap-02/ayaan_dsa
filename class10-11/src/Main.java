import java.util.ArrayList;

public class Main {

    public static class myStack{
        // variables
        static ArrayList<Integer> stack;
        static int size;
        // constructor

        public myStack(){
            size=0;
            stack=new ArrayList<>();
        }


        // functions

        static int size(){
            // returns the size of the stack
            return size;
        }
        static void add(int elm){
            // add an element to the stack
            stack.add(elm);
            size++;
        }

        static int pop(){
            //remove and return the top most element
            if (size()==0) {
                System.out.println("the stack is empty");
                return -1;
            }
            int elm=stack.get(size-1);
            size--;
            return elm;
        }
        static int peek(){
            // returns the top most element
            if(size()==0){
                System.out.println("The stack is empty");
                return -1;
            }
            return stack.get(size-1);
        }
    }

    public static class myQueue{
        static ArrayList<Integer> queue=new ArrayList<>();
        static int size=0;

        static int size(){
            // returns the size of the stack
            return size;
        }
        static void add(int elm){
            // add an element to the stack
            queue.add(elm);
            size++;
        }

        static int pop(){
            //remove and return the top most element
            if (size()==0) {
                System.out.println("the stack is empty");
                return -1;
            }
            int elm=queue.get(0);
            size--;
            return elm;
        }
        static int peek(){
            // returns the top most element
            if(size()==0){
                System.out.println("The stack is empty");
                return -1;
            }
            return queue.get(0);
        }
    }

    public static void main(String[] args) {

        myStack stack=new myStack();
        System.out.println(myStack.size());

        stack.add(1);
        stack.add(2);
        stack.add(3);
        stack.add(4);

        System.out.println(stack.peek());

        System.out.println(stack.pop());
        System.out.println(stack.peek());
    }
}