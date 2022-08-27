UNIT Gus669;

 {
   GUS669 Unit  v0.2b
   Copyright 1994 Mark Dixon.

   This product is "Learnware".

   All contents of this archive, including source and executables, are the
   intellectual property of the author, Mark Dixon. Use of this product for
   commercial programs, or commercial gain in ANY way, is illegal. Private
   use, or non-commercial use (such as demos, PD games, etc) is allowed,
   provided you give credit to the author for these routines.

   Feel free to make any modifications to these routines, but I would
   appreciate it if you sent me these modifications, so that I can include
   them in the next version of the Gus669 Unit.

   If you wish to use these routines for commercial purposes, then you will
   need a special agreement. Please contact me, Mark Dixon, and we can work
   something out.

   What's "Learnware"? Well, I think I just made it up actually. What i'm
   getting at is that the source code is provided for LEARNING purposes only.
   I'd get really angry if someone ripped off my work and tried to make out
   that they wrote a mod player.

   Beta version? Yes, since the product is still slightly unstable, I feel
   it is right to keep it under beta status until I find and fix a few
   bugs.

   FEATURES
     - Only works with the GUS!
     - 8 channel, 669 music format.
     - That's about it really.
     - Oh, 100% Pascal high level source code = NO ASSEMBLER!
       (So if you want to learn about how to write your own MOD player, this
        should make it easier for you)
     - Tested & compiled with Turbo Pascal v7.0

   BUGS
     - Not yet, give me a chance!
       (If you find any, I would very much appreciate it if you could take
        the time to notify me)
     - Doesn't sound right with some modules, advice anyone??
     - Could do with some better I/O handling routines when loading the
       669 to give better feedback to the user about what went wrong
       if the module didn't load.

  You can contact me at any of the following :

  FidoNet  : Mark Dixon  3:620/243
  ItnerNet : markd@cairo.anu.edu.au         ( prefered )
             d9404616@karajan.anu.edu.au    ( might not work for mail :) )
             sdixonmj@cc.curtin.edu.au      ( Don't use this one often )
             sdixonmj01@cc.curtin.edu.au    ( Might not exist any more,
                                              that's how often it's used! )
             I collect internet accounts.... :)

  If you happen to live in the Australian Capital Territory, you can
  call me on  231-2000, but at respectable hours please.

  "Want more comments? Write em!"
  Sorry, I just had to quote that. I'm not in the mood for writing lots
  of comments just yet. The main reason for writing it in Pascal is so
  that it would be easy to understand. Comments may (or may not) come later
  on.

  Okay, enough of me dribbling, here's the source your after!

 }

 Interface

 Procedure Load669(N : String);
 Procedure PlayMusic;
 Procedure StopMusic;

 Type
   { This is so that we can keep a record of what each channel is
     currently doing, so that we can inc/dec the Frequency or volume,
     or pan left/right, etc }
   Channel_Type    = Record
                       Vol : Word;
                       Freq : Word;
                       Pan : Byte;
                     End;

 Var
   Channels : Array[1..8] of Channel_Type;
   Flags : Array[0..15] of Byte;
   { Programmer flags. This will be explained when it is fully implemented. }

 Const
   Loaded : Boolean = False;    { Is a module loaded? }
   Playing : Boolean = False;   { Is a module playing? }
   WaitState : Boolean = False; { Set to TRUE whenever a new note is played }
                                { Helpful for timing in with the player }

 Const
   NumChannels = 8;

   { Thanks to Tran for releasing the Hell demo source code, from which
     I managed to find these very helpfull volume and frequency value
     tables, without which this player would not have worked! }

   voltbl : Array[0..15] of Byte =
                      (  $004,$0a0,$0b0,$0c0,$0c8,$0d0,$0d8,$0e0,
                         $0e4,$0e8,$0ec,$0f1,$0f4,$0f6,$0fa,$0ff);
   freqtbl : Array[1..60] of Word = (
                         56,59,62,66,70,74,79,83,88,94,99,105,
                         112,118,125,133,141,149,158,167,177,188,199,211,
                         224,237,251,266,282,299,317,335,355,377,399,423,
                         448,475,503,532,564,598,634,671,711,754,798,846,
                         896,950,1006,1065,1129,1197,1268,1343,1423,1508,1597,1692 );

 Type
   Header_669_Type = Record
                       Marker      : Word;
                       Title       : Array[1..108] of Char;
                       NOS,                     { No of Samples  0 - 64 }
                       NOP         : Byte;      { No of Patterns 0 - 128 }
                       LoopOrder   : Byte;
                       Order       : Array[0..127] of Byte;
                       Tempo       : Array[0..127] of Byte;
                       Break       : Array[0..127] of Byte;
                     End;
   Sample_Type     = Record
                       FileName  : Array[1..13] of Char;
                       Length    : Longint;
                       LoopStart : Longint;
                       LoopLen   : Longint;
                     End;
   Sample_Pointer  = ^Sample_Type;
   Note_Type       = Record
                       Info,  { <- Don't worry about this little bit here }
                       Note,
                       Sample,
                       Volume,
                       Command,
                       Data    : Byte;
                     End;
   Event_Type      = Array[1..8] of Note_Type;
   Pattern_Type    = Array[0..63] of Event_Type;
   Pattern_Pointer = ^Pattern_Type;

 Var
   Header : Header_669_Type;
   Samples : Array[0..64] of Sample_Pointer;
   Patterns : Array[0..128] of Pattern_Pointer;
   GusTable : Array[0..64] of Longint;
   GusPos : Longint;
   Speed : Byte;
   Count : Word;
   OldTimer : Procedure;
   CurrentPat, CurrentEvent : Byte;

 Implementation

 Uses Dos, Crt, GUSUnit;

 Procedure Load669(N : String);
 Var
   F : File;
   I, J, K : Byte;
   T : Array[1..8,1..3] of Byte;

   Procedure LoadSample(No, Size : Longint);
   Var
     Buf : Array[1..1024] of Byte;
     I : Longint;
     J, K : Integer;
   Begin
     GusTable[No] := GusPos;

     I := Size;
     While I > 1024 do
     Begin
       BlockRead(F, Buf, SizeOf(Buf), J);
       For K := 1 to J do GusPoke(GusPos+K-1, Buf[K] XOR 127);
       Dec(I, J);
       Inc(GusPos, J);
     End;
     BlockRead(F, Buf, I, J);
     For K := 1 to J do GusPoke(GusPos+K-1, Buf[K] XOR 127);
     Inc(GusPos, J);
   End;

 Begin
   {$I-}
   Assign(F, N);
   Reset(F, 1);
   BlockRead(F, Header, SizeOf(Header));
   If Header.Marker = $6669 then
   Begin
     For I := 1 to Header.NOS do
     Begin
       New(Samples[I-1]);
       BlockRead(F, Samples[I-1]^, SizeOf(Samples[I-1]^));
     End;

     For I := 0 to Header.NOP-1 do
     Begin
       New(Patterns[I]);
       For J := 0 to 63 do
       Begin
         BlockRead(F, T, SizeOf(T));
         For K := 1 to 8 do
         Begin
           Patterns[I]^[J,K].Info    := t[K,1];
           Patterns[I]^[J,K].Note    := ( t[K,1] shr 2);
           Patterns[I]^[J,K].Sample  := ((t[K,1] AND 3) SHL 4) +  (t[K,2] SHR 4);
           Patterns[I]^[J,K].Volume  := ( t[K,2] AND 15);
           Patterns[I]^[J,K].Command := ( t[K,3] shr 4);
           Patterns[I]^[J,K].Data    := ( t[K,3] AND 15);
         End;
       End;
     End;

     For I := 1 to Header.NOS do
       LoadSample(I-1, Samples[I-1]^.Length);
   End;

   Close(F);
   {$I+}
   If (IOResult <> 0) OR (Header.Marker <> $6669) then
     Loaded := False else Loaded := True;

 End;

 Procedure UpDateNotes;
 Var
   I : Word;
   Inst : Byte;
   Note : Word;
 Begin
   WaitState := True;
   For I := 1 to NumChannels do
   With Patterns[Header.Order[CurrentPat]]^[CurrentEvent, I] do

   For I := 1 to NumChannels do
   If (Patterns[Header.Order[CurrentPat]]^[CurrentEvent, I].Info < $FE) then
   Begin
     Inst := Patterns[Header.Order[CurrentPat]]^[CurrentEvent, I].Sample;
     Note := Patterns[Header.Order[CurrentPat]]^[CurrentEvent, I].Note;
     Channels[I].Freq := FreqTbl[Note];
 {    Channels[I].Pan  := (1-(I AND 1)) * 15;}
     Channels[I].Vol  := $100*VolTbl[Patterns[Header.Order[CurrentPat]]^[CurrentEvent, I].Volume];
 {    Write(Note:3,Inst:3,' -');}

     GUSSetVolume    (I, 0);
     GUSVoiceControl (I, 1);
     GUSSetBalance   (I, Channels[I].Pan);
     GusSetFreq      ( I, Channels[I].Freq);
 {    GUSPlayVoice    ( I, 0, GusTable[Inst],
                             GusTable[Inst],
                             GusTable[Inst]+Samples[Inst]^.Length  );}

 {    Write(Samples[Inst]^.LoopLen:5);}
     If Samples[Inst]^.LoopLen < 1048575 then
     Begin
     GUSPlayVoice    ( I, 8, GusTable[Inst],
                             GusTable[Inst]+Samples[Inst]^.LoopStart,
                             GusTable[Inst]+Samples[Inst]^.LoopLen  );
     End
       Else
     Begin
     GUSPlayVoice    ( I, 0, GusTable[Inst],
                             GusTable[Inst],
                             GusTable[Inst]+Samples[Inst]^.Length  );
     End;

   End;

 {  Writeln;}

   For I := 1 to NumChannels do
     If (Patterns[Header.Order[CurrentPat]]^[CurrentEvent, I].Info < $FF) then
       GUSSetVolume (I, $100*VolTbl[Patterns[Header.Order[CurrentPat]]^[CurrentEvent, I].Volume]);

   For I := 1 to NumChannels do
   With Patterns[Header.Order[CurrentPat]]^[CurrentEvent, I] do
   Case Command of
     5 : Speed := Data;
     3 : Begin
           Channels[I].Freq := Channels[I].Freq + 10;
           GUSSetFreq(I, Channels[I].Freq);
         End;
     8 : Inc(Flags[Data]);
     6 : Case Data of
           0 : If Channels[I].Pan > 0 then
               Begin
                 Dec(Channels[I].Pan);
                 GusSetBalance(I, Channels[I].Pan);
               End;
           1 : If Channels[I].Pan < 15 then
               Begin
                 Inc(Channels[I].Pan);
                 GusSetBalance(I, Channels[I].Pan);
               End;
         End;
   End;

   Inc(CurrentEvent);
   If CurrentEvent > Header.Break[CurrentPat] then Begin CurrentEvent := 0; Inc(CurrentPat) End;
   If Header.Order[CurrentPat] > (Header.NOP) then Begin CurrentEvent := 0; CurrentPat := 0; End;

 End;

 Procedure UpDateEffects;
 Var
   I : Word;
 Begin
   For I := 1 to 4 do
   With Patterns[Header.Order[CurrentPat]]^[CurrentEvent, I] do
   Begin
     Case Command of
       0 : Begin
             Inc(Channels[I].Freq, Data);
             GusSetFreq(I, Channels[I].Freq);
           End;
       1 : Begin
             Dec(Channels[I].Freq, Data);
             GusSetFreq(I, Channels[I].Freq);
           End;
     End;
   End;
 End;

 { $ F+,S-,W-}
 Procedure ModInterrupt; Interrupt;
 Begin
   Inc(Count);
   If Count = Speed then
   Begin
     UpDateNotes;
     Count := 0;
   End;
   UpDateEffects;
   If (Count MOD 27) = 1 then
   Begin
     inline ($9C);
     OldTimer;
   End;
   Port[$20] := $20;
 End;
 { $ F-,S+}

 Procedure TimerSpeedup(Speed : Word);
 Begin
   Port[$43] := $36;
   Port[$40] := Lo(Speed);
   Port[$40] := Hi(Speed);
 end;

 Procedure PlayMusic;
 Begin
   If Loaded then
   Begin
     TimerSpeedUp( (1192755 DIV 32));
     GetIntVec($8, Addr(OldTimer));
     SetIntVec($8, Addr(ModInterrupt));
     Speed := Header.Tempo[0];
     Playing := True;
   End
   { If the module is not loaded, then the Playing flag will not be set,
     so your program should check the playing flag just after calling
     PlayMusic to see if everything was okay. }
 End;

 Procedure StopMusic;
 Var
   I : Byte;
 Begin
   If Playing then
   Begin
     SetIntVec($8, Addr(OldTimer));
     For I := 1 to NumChannels do GusSetVolume(I, 0);
   End;
   TimerSpeedUp($FFFF);
 End;

 Procedure Init;
 Var
   I : Byte;
 Begin
   GusPos := 1;
   Count := 0;
   Speed := 6;
   CurrentPat := 0;
   CurrentEvent := 0;
   For I := 1 to NumChannels do Channels[I].Pan  := (1-(I AND 1)) * 15;
   For I := 1 to NumChannels do GUSVoiceControl(I, 1);
   For I := 0 to 15 do Flags[I] := 0;
 End;

 Var
   I, J : Byte;

 Begin
   Init;
   Writeln('GUS669 Unit V0.2b');
   Writeln('Copyright 1994 Mark Dixon.');
   Writeln;
 End.
