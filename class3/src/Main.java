import java.util.Arrays;
import java.util.Scanner;

public class Main {



    public static void main(String[] args) {

        int[] array = {0, 1, 2, 0, 1, 2};

        sortArray(array);

        for (int elm:array){
            System.out.print(elm+" ");
        }

    }

    public static int[] Sort(int[] arr) {

        for (int i = 0; i < arr.length - 1; i++) {
            for (int j = 0; j < arr.length - 1; j++) {

                if (arr[j] > arr[j + 1]) {
                    int temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }

        }
        return arr;
    }

    public static void sortArray(int[] arr){
        int numZero=0;
        int numOne=0;
        int numTwo=0;

        for(int elm : arr){
            if(elm==0) numZero++;
            else if(elm==1) numOne++;
            else numTwo++;
        }

        // o(n)

        for(int i=0;i<arr.length;i++){
            if(numZero!=0){
                arr[i]=0;
                numZero--;
            }
            else if (numOne!=0){
                arr[i]=1;
                numOne--;
            }
            else{
                arr[i]=2;
                numTwo--;
            }
        }

//        0(n)

    }













//    public static void main(String[] args) {
//
////        int[] arr={1,5,7,8,10,23,26,56};
////
////        int elm=5;
////
////        int start=0;
////        int end=arr.length-1;
////
////        while(start <= end){
////            int mid=(start+end)/2;
////
////            if(arr[mid]==elm){
////                System.out.println("I have found the element");
////                return;
////            }
////
////            else if(arr[mid] <elm){
////                start=mid+1;
////            }
////            else{
////                end=mid-1;
////            }
////        }
////        System.out.println("elemt not found");
//
//        Scanner sc=new Scanner(System.in);
//        System.out.println("Enter your age");
//        int age=sc.nextInt();
//
//        if ( age>18 || age <65){
//            System.out.println("you can drive");
//        }
//        else{
//            System.out.println("you can't drive");
//        }
//
//
//    }
//    int missingNumber(int arr[]) {
//        // code here
//
//        Arrays.sort(arr);
//
//        // int ans=0;
//
//        for(int i=0;i<arr.length;i++){
//            if(i+1 != arr[i]){
//                return i+1;
//            }
//        }
//        return -1;
//
//
//    }


    //


}