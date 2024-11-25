public class Main {
    public static void main(String[] args) {

//        System.out.println("Hello world!");

        int number=10;

        int ans=fib(number);

        System.out.println(ans);


//        Math.pow(2,3);
    }


    public static int factorial(int n){
        // return the factorial of n

        // base case

//        if(n<0){
//            return -1;
//        }
//
//        if(n==1 || n==0){
//            return 1;
//        }

        int x=factorial(n-1); // small brother : recursion : Recursive call

        int ans =(n*x);

        return ans;
    }

    public static int fib(int n){
        // return the nth fibonacci number
        if(n<1){
            return -1;
        }
        if(n==1 || n==2) return 1;

        return fib(n-1)+fib(n-2);

    }
}