public class Main {

    static class listNode{
        int data;
        listNode next;

        public listNode(int data){
            this.data=data;
            next=null;
        }
        public listNode(){
            data=0;
            next=null;
        }

    }




    public static void main(String[] args) {

        System.out.println("Hello world!");

//         listNode<String> listNode=new listNode<>();
//         listNode.data="sanglap";


        // 1->2->3


        listNode first=new listNode(1);

        listNode second=new listNode(2);

        listNode third=new listNode(3);


        first.next=second;
        second.next=third;

        // Traversing through a linkedList






    }

    static void printList(listNode head){
        // print the Linked List

    }
}