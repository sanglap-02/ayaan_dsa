public class Main {
    static class listNode{
        int data;
        listNode next;

        public listNode(int data){
            this.data=data;
        }
    }

    static class doublyListNode{
        int data;
        doublyListNode next;
        doublyListNode prev;

        public doublyListNode(int data){
            this.data=data;
        }
    }
    public static void main(String[] args) {
//        System.out.println("Hello world!");
        doublyListNode varchar =new doublyListNode(340);
        int lenght=20;
        System.out.println("");



        //creating a DL

        doublyListNode head=new doublyListNode(10);
        head.prev=null;

        doublyListNode node1=new doublyListNode(20);
        head.next=node1;
        node1.prev=head;

        doublyListNode node2=new doublyListNode(30);
        node1.next=node2;
        node2.prev=node1;





//        listNode head=new listNode(1);
//        head.next=new listNode(2);
//        head.next.next=new listNode(3);
//        head.next.next.next=new listNode(4);
//        head.next.next.next.next=new listNode(5);

//        printlist(head);
//
//        listNode newHead=reverse(head);
//
//        System.out.println("The list is reversed");
//        printlist(newHead);

//        System.out.println(length(head));
//
//        System.out.println(midElm(head).data);




    }
    static listNode midElm(listNode head){
        int lenght=length(head);

        int mid=0;

        if(lenght % 2 ==0) {
            mid=lenght/2;
        }
        else{
            mid=(lenght+1)/2;
        }

        listNode temp=head;
        for(int i=0;i<mid-1;i++){
            temp=temp.next;
        }
        return temp;

    }

    static void printlist(listNode head){
        listNode temp=head;
        while (temp!=null){
            System.out.print(temp.data+" ");
            temp=temp.next;
        }
        System.out.println();;

    }

    static listNode reverse(listNode head){
        if(head==null || head.next==null) return head;

//        1->2->3->4

        listNode revHead=reverse(head.next); //4->3->2
//        System.out.println(head.data);
        listNode temp=revHead;
        while(temp.next!=null){
//            System.out.println(temp.data);
            temp=temp.next;
        }
        temp.next=head; // 4->3->2->1
        head.next=null;

        return revHead;




    }
    static int length(listNode head){
        if(head==null) return 0;

        listNode temp=head;
        int length=0;

        while(temp!=null){
            temp=temp.next;
            length++;
        }
        return length;
    }




}