mtype = {i_card, conference_room_key, projector}
chan i_card_channel1 = [0] of {mtype};
chan i_card_channel2 = [0] of {mtype};
chan key_channel = [0] of {mtype};
chan projector_channel = [0] of {mtype};
chan exitclerkchan = [0] of {bool};
chan exitwatchmanchan = [0] of {bool};
bool has_icard=true,has_key=false,has_projector=false;


active proctype student(){
mtype proj;
mtype key;

do
::has_icard==true ->
  i_card_channel1!i_card;
  key_channel?conference_room_key;
  has_icard = false;
  has_key = true;
  key_channel!conference_room_key;
  has_key=false;
  //printf("\nkey channel received");
::has_icard==true ->
  i_card_channel2!i_card;
  projector_channel?projector;
  has_icard = false;
  has_projector = true;
  projector_channel!projector;
  has_projector = false;
  //printf("\nprojector channel received");
od;
}

active proctype watchman(){
mtype icard;
do
::i_card_channel1?icard ->
  key_channel!conference_room_key;
  key_channel?conference_room_key;
  has_icard=true;    
  //printf("\nkey channel send");
od;

}

active proctype office_clerk(){
mtype icard;
do
::i_card_channel2?icard ->
  projector_channel!projector;
  projector_channel?projector;    
  has_icard=true;
  //printf("\nProjector channel send");
od;

}

ltl { <>(has_key==true && has_projector==true) }
