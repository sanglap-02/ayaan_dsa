public class Main {

    public static class linkedListNode {
        int data;
        linkedListNode next;

        public linkedListNode(int data) {
            this.data = data;
            next = null;
        }
    }


    public static void main(String[] args) {


        linkedListNode head = new linkedListNode(10);
        linkedListNode second = new linkedListNode(20);
        linkedListNode third = new linkedListNode(30);

        head.next = second;
        second.next = third;

        linkedListNode rev=reverseLinkedList(head);
        printlist(rev);

//        10->20->30
    }

    public static linkedListNode reverseLinkedList(linkedListNode head) {
        //reversed linked list ka head

       if(head==null || head.next==null) return head;

       linkedListNode rev_head=reverseLinkedList(head.next);

       linkedListNode temp=rev_head;
       while (temp.next!=null) temp=temp.next;

       temp.next=head;
       head.next=null;

       return rev_head;

    }

    public static void printlist(linkedListNode head) {

        linkedListNode curr = head;
        while (curr != null) {
            System.out.print(curr.data + " --> ");
            curr = curr.next;
  }

}
}