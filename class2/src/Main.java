public class Main {
    public static void main(String[] args) {
//        System.out.println("Hello world!");
        // input : 1,2,3,4
        // out : 4,3,2,1

        int[] arr={1,2,3,4};
        int[] revArr=reverse(arr);

        for(int elm:revArr){
            System.out.print(elm+" ");
        }

//        int a=10;
//        int temp=0;
//        int b=20;
//        temp=a;
//        a=b;
//        b=temp;


    }

    public static int[] reverse(int[] arr){
        int i=0;
        int j=arr.length-1;
        while(i<=j){
            int temp=arr[i];
            arr[i]=arr[j];
            arr[j]=temp;
            i++;
            j--;
        }
        return arr;
    }

    public static int getDuplicate(int[] arr){
        int ans=-1;
        for(int i=0;i<arr.length;i++){

        }
    }

}