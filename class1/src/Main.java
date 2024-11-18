public class Main {

    public static class car{
        static int noWheels=10;

        public static int getnoWheel(){
            return noWheels;
        }
    }

    //function signature

    public static int sum(int a, int b){
        return (a+b);
    }

    public static void main(String[] args) {


        //function calling

        int sum=sum(1,2);
        System.out.println(sum);

        car cr=new car();

        int noWheels = cr.noWheels;
        cr.getnoWheel();



        System.out.println("Hello world!");

        // primitive vs no primitive
//        int i=12;
//        int j=i;
//        j=10;
//        System.out.println(i);

        int[] arr={1,2};
        int[] copy=arr;

        copy[1]=10;

        System.out.println(arr[1]);


        // arrays

        int[] intArray=new int[10];

        int[] intArray2 =new int[10];

        char[] charArray=new char[10];

        System.out.println(intArray[2]);
//        System.out.println(intArray[10]);

        intArray[3]=10;

        for(int ind=0 ; ind<intArray.length;ind++){
            intArray[ind]=ind+1;
        }

        for (int k : intArray) {
            System.out.print(k + " ");
        }

        for(int element : intArray){
            System.out.println(element);
        }

//        String str="Hello";
//        System.out.println(str.length());

        int[][] array_2d=new int[3][4];

        for(int i=0;i<array_2d.length;i++){
            for (int j=0;j<array_2d[0].length;j++){
                array_2d[i][j]=i+j;
            }
        }

        for (int[] ints2 : array_2d) {
            for (int j = 0; j < array_2d[0].length; j++) {
                System.out.print(ints2[j] + " ");
            }
            System.out.println();
        }



        int[] array= new int[3];

        array[0]=1;
        array[1]=3;
        array[2]=3;

        int[] ans=fun(array);

        System.out.println("first answer" + ans[0]);
        System.out.println("second answer" + ans[1]);


    }

    public static int[] fun(int[] arr){
        int sum=0;
        int multiply=1;
        for(int elm : arr){
            sum+=elm;
            multiply*=elm;
        }
        int[] ans=new int[2];
        ans[0]=sum;
        ans[1]=multiply;

        return ans;
    }


}