Unit  GUSUnit;

 {
   GUS DigiUnit  v1.0
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

   As of this release (Gus699 Unit), the Gus DigiUnit has moved to version
   1.0, and left the beta stage. I feel these routines are fairly sound,
   and I haven't made any changes to them in weeks.

   Notice the complete absence of comments here? Well, that's partially
   the fault of Gravis and their SDK, since it was so hard to follow, I
   was more worried about getting it working than commenting it. No offense
   to Gravis though, since they created this wonderful card! :-) It helps
   a lot if you have the SDK as a reference when you read this code,
   otherwise you might as well not bother reading it.

 }

 INTERFACE

 Procedure GUSPoke(Loc : Longint; B : Byte);
 Function  GUSPeek(Loc : Longint) : Byte;
 Procedure GUSSetFreq( V : Byte; F : Word);
 Procedure GUSSetBalance( V, B : Byte);
 Procedure GUSSetVolume( Voi : Byte; Vol : Word);
 Procedure GUSPlayVoice( V, Mode : Byte;VBegin, VStart, VEnd : Longint);
 Procedure GUSVoiceControl( V, B : Byte);
 Procedure GUSReset;
 Function VoicePos( V : Byte) : Longint;

 Const
   Base : Word = $200;
   Mode : Byte = 0;

 IMPLEMENTATION

 Uses Crt;

 Function Hex( W : Word) : String;
 Var
   I, J : Word;
   S : String;
   C : Char;
 Const
   H : Array[0..15] of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
 Begin
   S := '';
   S := S + H[(W DIV $1000) MOD 16];
   S := S + H[(W DIV $100 ) MOD 16];
   S := S + H[(W DIV $10  ) MOD 16];
   S := S + H[(W DIV $1   ) MOD 16];
   Hex := S+'h';
 End;

 Procedure GUSDelay; Assembler;
 ASM
   mov   dx, 0300h
   in    al, dx
   in    al, dx
   in    al, dx
   in    al, dx
   in    al, dx
   in    al, dx
   in    al, dx
 End;

 Function VoicePos( V : Byte) : Longint;
 Var
   P : Longint;
   I, Temp0, Temp1 : Word;
 Begin
   Port [Base+$102] := V;
   Port [Base+$103] := $8A;
   Temp0 := Portw[Base+$104];
   Port [Base+$103] := $8B;
   Temp1 := Portw[Base+$104];
   VoicePos := (Temp0 SHL 7)+ (Temp1 SHR 8);
   For I := 1 to 10 do GusDelay;
 End;

 Function  GUSPeek(Loc : Longint) : Byte;
 Var
   B : Byte;
   AddLo : Word;
   AddHi : Byte;
 Begin
   AddLo := Loc AND $FFFF;
   AddHi := LongInt(Loc AND $FF0000) SHR 16;

   Port [Base+$103] := $43;
   Portw[Base+$104] := AddLo;
   Port [Base+$103] := $44;
   Port [Base+$105] := AddHi;

   B := Port[Base+$107];
   GUSPeek := B;
 End;

 Procedure GUSPoke(Loc : Longint; B : Byte);
 Var
   AddLo : Word;
   AddHi : Byte;
 Begin
   AddLo := Loc AND $FFFF;
   AddHi := LongInt(Loc AND $FF0000) SHR 16;
 {  Write('POKE  HI :', AddHi:5, '  LO : ', AddLo:5, '    ');}
   Port [Base+$103] := $43;
   Portw[Base+$104] := AddLo;
   Port [Base+$103] := $44;
   Port [Base+$105] := AddHi;
   Port [Base+$107] := B;
 {  Writeln(B:3);}
 End;

 Function GUSProbe : Boolean;
 Var
   B : Byte;
 Begin
   Port [Base+$103] := $4C;
   Port [Base+$105] := 0;
   GUSDelay;
   GUSDelay;
   Port [Base+$103] := $4C;
   Port [Base+$105] := 1;
   GUSPoke(0, $AA);
   GUSPoke($100, $55);
   B := GUSPeek(0);
 {  Port [Base+$103] := $4C;
   Port [Base+$105] := 0;}
   { Above bit disabled since it appears to prevent the GUS from accessing
     it's memory correctly.. in some bizare way.... }

   If B = $AA then GUSProbe := True else GUSProbe := False;
 End;

 Procedure GUSFind;
 Var
   I : Word;
 Begin
   {for I := 1 to 8 do
   Begin
     Base := $200 + I*$10;
     If GUSProbe then I := 8;
   End;}
   Base := $240;
   If Base < $280 then
     Write('Found your GUS at ', Hex(Base), ' ');
 End;

 Function  GUSFindMem : Longint;
 { Returns how much RAM is available on the GUS }
 Var
   I : Longint;
   B : Byte;
 Begin
   GUSPoke($40000, $AA);
   If GUSPeek($40000) <> $AA then I := $3FFFF
     else
   Begin
     GUSPoke($80000, $AA);
     If GUSPeek($80000) <> $AA then I := $8FFFF
       else
     Begin
       GUSPoke($C0000, $AA);
       If GUSPeek($C0000) <> $AA then I := $CFFFF
         else I := $FFFFF;
     End;
   End;
   GUSFindMem := $FFFFF;
 End;

 Procedure GUSSetFreq( V : Byte; F : Word);
 Begin
   Port [Base+$102] := V;
   Port [Base+$102] := V;
   Port [Base+$102] := V;
   Port [Base+$103] := 1;
   Portw[Base+$104] := (F { DIV 19}); { actual frequency / 19.0579083837 }
 End;

 Procedure GUSVoiceControl( V, B : Byte);
 Begin
   Port [Base+$102] := V;
   Port [Base+$102] := V;
   Port [Base+$103] := $0;
   Port [Base+$105] := B;
 End;

 Procedure GUSSetBalance( V, B : Byte);
 Begin
   Port [Base+$102] := V;
   Port [Base+$102] := V;
   Port [Base+$102] := V;
   Port [Base+$103] := $C;
   Port [Base+$105] := B;
 End;

 Procedure GUSSetVolume( Voi : Byte; Vol : Word);
 Begin
   Port [Base+$102] := Voi;
   Port [Base+$102] := Voi;
   Port [Base+$102] := Voi;
   Port [Base+$103] := 9;
   Portw[Base+$104] := Vol;  { 0-0ffffh, log ... not linear }
 End;

 Procedure GUSSetLoopMode( V : Byte);
 Var
   Temp : Byte;
 Begin
   Port [Base+$102] := V;
   Port [Base+$102] := V;
   Port [Base+$102] := V;
   Port [Base+$103] := $80;
   Temp := Port[Base+$105];
   Port [Base+$103] := 0;
   Port [Base+$105] := (Temp AND $E7) OR Mode;
 End;

 Procedure GUSStopVoice( V : Byte);
 Var
   Temp : Byte;
 Begin
   Port [Base+$102] := V;
   Port [Base+$102] := V;
   Port [Base+$102] := V;
   Port [Base+$103] := $80;
   Temp := Port[Base+$105];
   Port [Base+$103] := 0;
   Port [Base+$105] := (Temp AND $df) OR 3;
   GUSDelay;
   Port [Base+$103] := 0;
   Port [Base+$105] := (Temp AND $df) OR 3;
 End;

 Procedure GUSPlayVoice( V, Mode : Byte;VBegin, VStart, VEnd : Longint);
 Var
   GUS_Register : Word;
 Begin
   Port [Base+$102] := V;
   Port [Base+$102] := V;
   Port [Base+$103] := $0A;
   Portw[Base+$104] := (VBegin SHR 7) AND 8191;
   Port [Base+$103] := $0B;
   Portw[Base+$104] := (VBegin AND $127) SHL 8;
   Port [Base+$103] := $02;
   Portw[Base+$104] := (VStart SHR 7) AND 8191;
   Port [Base+$103] := $03;
   Portw[Base+$104] := (VStart AND $127) SHL 8;
   Port [Base+$103] := $04;
   Portw[Base+$104] := ((VEnd)   SHR 7) AND 8191;
   Port [Base+$103] := $05;
   Portw[Base+$104] := ((VEnd)   AND $127) SHL 8;
   Port [Base+$103] := $0;
   Port [Base+$105] := Mode;

   { The below part isn't mentioned as necessary, but the card won't
     play anything without it! }

   Port[Base] := 1;
   Port[Base+$103] := $4C;
   Port[Base+$105] := 3;

 end;

 Procedure GUSReset;
 Begin
   port [Base+$103]   := $4C;
   port [Base+$105] := 1;
   GUSDelay;
   port [Base+$103]   := $4C;
   port [Base+$105] := 7;
   port [Base+$103]   := $0E;
   port [Base+$105] := (14 OR $0C0);
 End;

 Var
   I : Longint;
   F : File;
   Buf : Array[1..20000] of Byte;
   S : Word;

 Begin
   Clrscr;
   Writeln('GUS DigiUnit V1.0');
   Writeln('Copyright 1994 Mark Dixon.');
   Writeln;
   GUSFind;
   Writeln('with ', GUSFindMem, ' bytes onboard.');
   Writeln;
   GUSReset;
 End.
