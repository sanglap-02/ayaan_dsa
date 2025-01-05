import java.util.ArrayList;

public class class12 {

    static class myStack{
        int size;
        int[] stack;

        public myStack(){
            size=0;
            stack =new int[10];
        }
        public myStack(int size){
            this.size=0;
            stack=new int[size];
        }

        //size
        int size(){
            return size;
        }

        //add
        void add(int elm) throws Exception{
            if(size== stack.length){
                throw new Exception("stackOverFlow exception");
            }
            stack[size]=elm;
            size++;
        }

        //top
        int top() throws Exception {
            if(size()==0){
                throw new Exception("stackUnderFlow exception");
            }
            return stack[size-1];
        }

        //pop

        int pop() throws Exception{
            if(size()==0){
                throw new Exception("stack is empty");
            }
            int elm=stack[size-1];
            stack[size-1]=0;
            size--;
            return elm;
        }

        //is empty
        boolean isEmpty(){
//            if(size==0) return true;
//            else return false;

            return size==0;
        }

    }



    public static void main(String[] args) throws Exception {

        myStack st=new myStack(5);

        st.add(10);
        st.add(20);
        st.add(30);

        System.out.println(st.top());

        System.out.println(st.isEmpty());

        st.pop();
        System.out.println(st.top());

        st.pop();
        System.out.println(st.top());

        st.pop();

        if(!st.isEmpty()){
            System.out.println(st.top());
        }

        st.add(40);
        st.add(50);
        st.add(60);
        st.add(70);
        st.add(80);
        st.add(90);




    }
}
