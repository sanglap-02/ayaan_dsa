public class Main {
    public static void main(String[] args) {

//        System.out.println("Hello world!");

        int n=989;

//        System.out.println(sunDigit(n));


//        int[] arr={1,2,3,4};
//        System.out.println("Before reversing");
//        for(int elm:arr) System.out.print(elm+" ");
//        System.out.println("After reversing");
//        revArray(arr,0,arr.length-1);
//        for (int elm:arr) System.out.print(elm+" ");


        print(10);
    }

    public static int sunDigit(int n){
        int sum=0;

        while(n!=0){
            int r=n%10;
            sum+=r;
            n=n/10;
        }
        return sum;
    }

    public static void revArray(int[] arr,int i,int j){

        if(i>j) return;

        int temp=arr[i];
        arr[i]=arr[j];
        arr[j]=temp;

        revArray(arr,i+1,j-1);

    }
    public static void print(int n) {

        if (n == 0) {
            return;
        }
        System.out.println(n);

        print(n - 1);



    }




}