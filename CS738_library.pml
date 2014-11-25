#define MAX_BOOKS 100
#define MAX_STUDENTS 10
#define MAX_CLAIMS_ON_BOOK 3
#define MAX_CLAIMS_BY_STUDENT 4
#define MAX_BOOK_ISSUED_TO_STUDENT 15
#define FINE_PER_DAY_STUDENT 5
#define FINE_THRESHOLD 100 //if a student fine exceeds threshold, he can't issue books
#define MAX_TRANSACTIONS_PER_DAY 50
#define MAX_ISSUE_DURATION 30
#define MAX_BOOKS_DAMAGED 5
//initializing number of books randomly gets damaged by library while initializing
int number_of_books_damaged_by_library=0;
typedef bookreq {
	int student_id; //student who is requesting the book
	int book_id; //book id whose request
};

typedef bookreq_resp{
	int student_id;
	int book_id;
	bool granted;
};


typedef book_return{
	int student_id; //student who returns the book
	int book_id; //book id 
};

typedef claim{
	int student_id; //student id who is claiming for the book
	int book_id; //book id on which claim is done 
};

typedef claim_resp{
	int student_id;
	int book_id;
	bool granted;
};


typedef Book{
	//a book can have maximum 4 claims
	int claim_queue[MAX_CLAIMS_ON_BOOK]; //all elements initialized to -1 (should store student ids)
	int book_id;
	bool damaged;
	bool issued;
	int borrower;//student id
	int issue_time;
	int expected_return_time;
	int num_claims;
};

typedef Student{
	int student_id;
	int total_books_issued;
	int books_issued[MAX_BOOK_ISSUED_TO_STUDENT];//book ids
	int renew_count[MAX_BOOK_ISSUED_TO_STUDENT];//book ids
	int books_claimed[MAX_CLAIMS_BY_STUDENT];
	int fine;
	int books_damaged_by_student;
};

int current_time = 0;
int current_student_count = 3;
int current_book_count = 10;
Book all_books[MAX_BOOKS]; //all books in the library
Student all_students[MAX_STUDENTS]; //all students in the institute 

chan book_request_channel = [0] of {bookreq}; //student to library
chan book_request_response_channel[MAX_STUDENTS] = [0] of {bookreq_resp}; //library to student
chan book_return_channel = [0] of {book_return}; //student to library
chan book_claim_channel[MAX_STUDENTS]= [0] of {claim}; //student to library
chan book_claim_response_channel[MAX_STUDENTS] = [0] of {claim_resp}; //library to student
chan timer_to_library_channel = [0] of {bool}; //timer sends current time to the library
chan library_to_timer_channel = [0] of {bool}; //library send to the timer that it has read and took appropriate actions at the time
chan timer_to_student_channel[MAX_STUDENTS] = [0] of {int}; //timer sends current time to the library
chan student_to_timer_channel[MAX_STUDENTS] = [0] of {bool}; //library send to the timer that it has read and took appropriate actions at the time

proctype timer(){//should communicate with all processes and increment time only when all processes have read the time
	do
	::current_time = current_time+1;//increase time and go ahead asking the students and library to do whatever they want to do before furthe stepping in time
		
		timer_to_library_channel!true; 	
		library_to_timer_channel?true;
		int i = 0;// send message to all the students
		do
		::i < current_student_count ->
			timer_to_student_channel[i]!true;
			i++;
		::else ->
			break;
		od
		
		//library_to_timer_channel?true;
		i = 0;// send message to all the students
		do
		::i < current_student_count ->
			student_to_timer_channel[i]?true;
			i++;
		::else ->
			break;
		od
	od
}

proctype library(){

	
	
	

	
	//initializing claim queue of books, -1 book not claimed by anyone
	int bc=0;
	do
	:: bc < current_book_count ->
		all_books[bc].book_id = bc;
		
		//initializing books damaged randomly
		do
		::number_of_books_damaged_by_library<MAX_BOOKS_DAMAGED ->
			all_books[bc].damaged=true;
			number_of_books_damaged_by_library++;			
		::number_of_books_damaged_by_library<MAX_BOOKS_DAMAGED ->
			all_books[bc].damaged=false;
		::break;
		od	

		//all_books[bc].damaged = false;
		all_books[bc].issue_time = false;
		all_books[bc].borrower = -1;
		all_books[bc].issue_time = -1;
		all_books[bc].expected_return_time = -1;
		all_books[bc].num_claims = 0;
		int cl=0;
		do
		::cl < MAX_CLAIMS_ON_BOOK ->
			all_books[bc].claim_queue[cl] = -1;
			cl++;
		::else ->
			break;
		od
		bc++;
	::else ->
		break;
 	od

	bookreq book_req_msg;
	book_return book_ret_msg;
	
	
	do
		
	::timer_to_library_channel?true ->	
	
		//library_to_timer_channel!true;
		//fine calculation for each student
		printf("\n\nTimer to library received at time %d:",current_time);
		library_to_timer_channel!true;
		
	
	//library receives a book return message
		
	::book_return_channel?book_ret_msg ->
		if
		//if the book is not damaged update the database in accordance with return
		::book_ret_msg.book_id != -1 && all_books[book_ret_msg.book_id].damaged == false->
			printf("\nReceived return msg from %d at %d",book_ret_msg.student_id,current_time);
			all_books[book_ret_msg.book_id].issued  = false;	
			all_books[book_ret_msg.book_id].borrower  = -1;	
			all_books[book_ret_msg.book_id].issue_time = -1;	
			all_books[book_ret_msg.book_id].expected_return_time = -1;	
			
			if
			::all_students[book_ret_msg.student_id].total_books_issued > 0 -> 
				all_students[book_ret_msg.student_id].total_books_issued--;
			::else->
				skip
			fi
			
			//in student's array for issued books find the index of this book

			int arr_itr = 0;
			do
			::arr_itr < MAX_BOOK_ISSUED_TO_STUDENT ->
				if
				::all_students[book_ret_msg.student_id].books_issued[arr_itr] == book_ret_msg.book_id->
					//update database of student for issed books array	
					all_students[book_ret_msg.student_id].books_issued[arr_itr] = -1; 
					all_students[book_ret_msg.student_id].renew_count[arr_itr] = 0; 
				::else->
					arr_itr++;
				fi
			::else ->
				break;
			od
		::else 
			printf("\nReceived return msg(damaged book) from %d at %d",book_ret_msg.student_id,current_time); //else here means book is damaged (if required add code here)
		fi
	
	//library receives a book request message
	
		
	::book_request_channel?book_req_msg ->
		
		bookreq_resp bookreq_resp_msg;	
		bookreq_resp_msg.student_id = book_req_msg.student_id;
		bookreq_resp_msg.book_id = book_req_msg.book_id;
		printf("\nRequest received for %d from student %d at %d",bookreq_resp_msg.book_id,bookreq_resp_msg.student_id,current_time);

		if
		::all_books[book_req_msg.book_id].issued == false && //no one has borrowed the book
			all_students[book_req_msg.student_id].total_books_issued < MAX_BOOK_ISSUED_TO_STUDENT //books issued haven't exceeded the limit
			->
						
				bookreq_resp_msg.granted = true;
				all_books[book_req_msg.book_id].borrower = book_req_msg.student_id; //make this student the borrower in the database 
				all_students[book_req_msg.student_id].total_books_issued++; //increment num of books issued to the student
				all_books[book_req_msg.book_id].issued = true; 
				all_books[book_req_msg.book_id].issue_time = current_time; 
				all_books[book_req_msg.book_id].expected_return_time = current_time + MAX_ISSUE_DURATION - 1 ; 
			
				//update the students book issue data
				int i = 0;
				do
				::i < MAX_BOOK_ISSUED_TO_STUDENT ->
					if
					::(all_students[book_req_msg.student_id].books_issued[i] == -1) ->
						all_students[book_req_msg.student_id].books_issued[i] = book_req_msg.book_id;
					::else -> break;
					fi
					i++;
				::else -> break;
				od

		::else->
				bookreq_resp_msg.granted = false;
		fi
		
		book_request_response_channel[bookreq_resp_msg.student_id]!bookreq_resp_msg;
		printf("\nSent book response msg from library to %d at %d",bookreq_resp_msg.student_id,current_time);
		
	od
	
}

proctype student(int student_id){
	//initialization starts
	//initialize student's database
	all_students[student_id].student_id = student_id;
	all_students[student_id].total_books_issued = 0;
	
	//-1 means book not issued, book no claimed
	int bi = 0;
	do
	::bi < MAX_BOOK_ISSUED_TO_STUDENT ->
		all_students[student_id].books_issued[bi] = -1;
		all_students[student_id].renew_count[bi] = 0;
		bi++;		
	::else->
		break;
	od

	int bc = 0;
	do
	::bc < MAX_CLAIMS_BY_STUDENT->
		all_students[student_id].books_claimed[bc] = -1;
		bc++;		
	::else->
		break;
	od
	
	all_students[student_id].fine = 0;
	all_students[student_id].books_damaged_by_student = 0;
	//initialization ends
	
	
	
	do
		
	::timer_to_student_channel[student_id]?true ->
		
		//all the transactions of a day go here
		//number of transactions in a day chosen randomly
		
		//random no generation starts
		printf("\nStudent received time from library at %d",current_time);
		int nr = 0; //nr holds how many transactions to be done
		do
		::nr < MAX_TRANSACTIONS_PER_DAY -> nr++;		// randomly increment
		:: break;	// or stop 
		od
		//random no genration ends
		
		
		do
		::nr > 0 ->
			//randomly generate the book id 
			
			//random no generation starts
			int brq = 0; //bi holds how many books can be requested or claimed 
			do
			::brq < MAX_BOOKS -> brq++;		//
			:: break;	//
			od
			//random no genration ends
			
			
			
			//create book request message
			bookreq book_req_msg;
			book_req_msg.student_id = student_id;
			book_req_msg.book_id = brq;
			
			//book request response message
			bookreq_resp book_req_resp_msg;
	
			
			//randomly generate the book number(offset) among the issued books that student will return
			int book_offset = 0;
			do
			:: book_offset < all_students[student_id].total_books_issued -> book_offset++;
			::break;
			od
			
			
			
			//pick the book to return
			
			
			int arr_itr = 0;
			do
			::arr_itr < MAX_BOOK_ISSUED_TO_STUDENT ->
				if
				::(all_students[student_id].books_issued[arr_itr] != -1)->
					break;
				::else->
					arr_itr++;
				fi
			::else->
				break;
			od
			
			
			
						
			
			
			bool book_to_return;
			if
			:: (arr_itr < MAX_BOOK_ISSUED_TO_STUDENT)->
				book_to_return = true;
			::else->
				book_to_return = false;
			fi

			
			
			
			//create book return message if  
			book_return book_ret_msg;
			if
			:: book_to_return == true->
				book_ret_msg.student_id = student_id;
				book_ret_msg.book_id = all_students[student_id].books_issued[arr_itr];
			:: else ->
				skip;
			fi
			
			printf("\nNumber of book issued:%d",all_students[student_id].total_books_issued);
			
			if
			//non-determinisically request a book
			::book_request_channel!book_req_msg->
				printf("\nSending book request msg of %d to library from %d at %d",book_req_msg.book_id,student_id,current_time);
				book_request_response_channel[student_id]?book_req_resp_msg;	
			
			//non-deterministically return a book
			::book_to_return==true ->
				printf("\nSending return msg to library of %d from %d at %d",book_ret_msg.book_id,student_id,current_time);
				book_return_channel!book_ret_msg;
			
			//non-deterministicaly damage a book with student
			
			//first choose a random number to between 0 and 10
			//if it is 3 damage the first issued book
			//else don't damage any book

			::int to_damage = 0; //nr holds how many transactions to be done
				do
					::to_damage < 10 -> to_damage++;		// randomly increment
					:: break;	// or stop 
				od
				
				if
					::to_damage == 3->
						int arr_i = 0;
						do
						::arr_i < MAX_BOOK_ISSUED_TO_STUDENT ->
							int curr_book_id = all_students[student_id].books_issued[arr_i];
							if
							:: curr_book_id  != -1 ->
								all_books[curr_book_id].damaged = true;
								all_students[student_id].books_damaged_by_student++;
								break;
							::else->
								arr_i++;
							fi
						::else ->
							break;
						od
					::else->
						skip;
				fi

			
			fi
			nr--;
		::else -> 
			break;
		od
		
		
		student_to_timer_channel[student_id]!true;
  	od
	
}

init
{
	run timer();
	int student_counter = 0;
	do
	::student_counter < current_student_count ->	
		run student(student_counter);
		student_counter++;
	:: else ->
		break;
	od
	
	run library();
}

