chan FIR_Request_Chan = [0] of {bool};
chan FIR_Response_Chan = [0] of {bool};
chan Entry_Register_Write_Req_Chan = [0] of {bool};
chan Entry_Register_Write_Res_Chan = [0] of {bool};
chan Entry_Register_Read_Req_Chan = [0] of {bool};
chan Entry_Register_Read_Res_Chan = [0] of {bool};
chan Written_To_Register_Chan = [0] of {bool};
bool firresp=false;
bool write=false;
bool isWritten=false;

active proctype monitor() {
do
::Written_To_Register_Chan?isWritten ->
  isWritten=true;
od;
}

active proctype register() {
do
::Entry_Register_Write_Req_Chan?true ->
  atomic {
  write=true; 
  Written_To_Register_Chan!true;
  }
od;
}

active proctype policeman() {
bool firreq;
do
::FIR_Request_Chan?firreq ->
  FIR_Response_Chan!true;
::FIR_Request_Chan?firreq ->
  Entry_Register_Write_Req_Chan!true;
  FIR_Response_Chan!true;
od;
}

active proctype plaintiff() {
bool firres;
do
::FIR_Request_Chan!true ->
  atomic{
  firresp=false;
  write=false;
  isWritten=false;
  }
::FIR_Response_Chan?firres ->
  firresp=true;
od;
}

//ltl { <> (write==false -> isWritten==true) }
//ltl { [] ( write==true -> isWritten==true ) }
ltl { (firresp==true && isWritten==true) -> write==true }
