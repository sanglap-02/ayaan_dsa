public class Main {

    public interface intface{

        public void print() ;
        public void print2() ;
        public void prin3() ;
        public void prin4() ;

    }
    public interface intface2{

        public void print() ;
        public void print2() ;
        public void prin3() ;
        public void prin4() ;

    }

//    public class child extends parent implements intface, intface2{
//
//    }


    static class parent{
        int a;
        int b;

        //constructor overloading
        public  parent(int a, int b){
            this.a=a;
            this.b=b;
            System.out.println("the constructor of the parent is called");
        }

        public parent(){
            System.out.println("The second constructor is called");
        }

        public parent(int a){
            System.out.println("The third constructor is called");
        }


        //function overloading : you cant make the same named function with different return type
        public void display(){
            System.out.println("a="+a+" b="+b);
        }

        public void display(int a){
            System.out.println("a="+a);
        }

        public void printSome(){
            System.out.println("Hello world");
        }




    }

    static class child2 extends parent{
        public child2(){
            super(10,10);
            System.out.println("the constructor of the child is called");
        }

        // function overrriding
        public void printSome(){
            System.out.println("Hello child");
        }


    }

    public static class grandChild extends child2{

    }

    public static void main(String[] args) {

//        child ch=new child();
//
//        System.out.println(ch.a);

        parent p=new parent();

        parent p2=new parent(10);

        parent p3=new parent(10,20);

    }
}