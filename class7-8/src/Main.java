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
        listNode fourth=new listNode(4);


        first.next=second;
        second.next=third;
        third.next=fourth;

        // Traversing through a linkedList

//        printList(first);

//        System.out.println(lenght(first));

//        addLast(first,new listNode(4));
//        printList(first);

//        listNode newHead=addFirst(first,new listNode(4));
//
//        printList(newHead);

//        printList(first);

        listNode newHead=insert(first,new listNode(5),2);
        printList(newHead);







    }

    static void printList(listNode head) {


        listNode point = head;

        while (point != null) {
            System.out.println(point.data);
            point = point.next;
        }

    }

    static int lenght(listNode head) {
        //the lenght of the list

        int count = 0;
        listNode point = head;
        while (point != null) {
            count++;

            point = point.next;
        }
        return count;
    }

    static void addLast(listNode head, listNode node) {
        // 1->2->3 , 4
        // 1->2->3->4

        if (head == null) {
            head = node;
            return;
        }

        listNode point = head;
        while (point.next != null) {
            point = point.next;
        }

        point.next = node;

    }

    static listNode addFirst(listNode head, listNode node) {
        // 1->2->3 , 4
        // 4->1->2->3

        if (head == null) {
            head = node;
            return head;
        }

        node.next =head;

        return node;

//        return point;

    }

    static listNode insert(listNode head, listNode node, int index){

        // if head is null
        if(head==null){
            if(index==0) return node;
            return null;
        }

        //index =0 ;
        if(index==0) {
            listNode newHaed=addFirst(head,node);
            return newHaed;
        }

        // index=length
        int length=lenght(head);
        if(index==length){
            addLast(head,node);
            return head;
        }

        listNode point=head;
        int ind=0;
        while (ind!=index-1){
//            System.out.println("the value of ind is "+ind);
            point=point.next;
            ind++;
        }

//        System.out.println(point.data);

        listNode temp=point.next;

        point.next=node;
        node.next=temp;

        return head;

    }

}