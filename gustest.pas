uses crt;

const
  base : word = $240;

procedure GUSPoke(loc : longint; b : byte);
var
  addlo : word;
  addhi : byte;
begin
  port [base+$103] := $43;
  portw[base+$104] := loc AND $FFFF;
  port [base+$103] := $44;
  port [base+$105] := (loc SHR 16) AND $FF;
  port [base+$107] := b;
end;

procedure GUSReset;
begin
   port[base+$103] := $4C;
   port[base+$105] := 1;
   asm
     mov   dx, 0300h
     in    al, dx
     in    al, dx
     in    al, dx
     in    al, dx
     in    al, dx
     in    al, dx
     in    al, dx
   end;
   port[base+$103] := $4C;
   port[base+$105] := 7;
   port[base+$103] := $0E;
   port[base+$105] := (14 OR $C0);
end;

procedure GUSSetVolume(voi : byte; vol : word);
begin
  port [base+$102] := voi;
  port [base+$102] := voi;
  port [base+$102] := voi;
  port [base+$103] := 9;
  portw[base+$104] := vol;
end;

procedure GUSSetBalance( v, b : byte);
Begin
  port[base+$102] := v;
  port[base+$102] := v;
  port[base+$102] := v;
  port[base+$103] := $C;
  port[base+$105] := b;
end;

procedure GUSSetFreq(v : byte; f : word);
begin
  port [base+$102] := v;
  port [base+$102] := v;
  port [base+$102] := v;
  port [base+$103] := 1;
  portw[base+$104] := f div 19;
end;

procedure GUSPlayVoice(v : byte; vbegin, vend : longint);
begin
  port [base+$102] := v;
  port [base+$102] := v;
  port [base+$103] := $0A;
  portw[base+$104] := (vbegin SHR 7) AND $1FFF;
  port [base+$103] := $0B;
  portw[base+$104] := (vbegin AND $127) SHL 8;
  port [base+$103] := $02;
  portw[base+$104] := (vbegin SHR 7) AND $1FFF;
  port [base+$103] := $03;
  portw[base+$104] := (vbegin AND $127) SHL 8;
  port [base+$103] := $04;
  portw[base+$104] := ((vend) SHR 7) AND $1FFF;
  port [base+$103] := $05;
  portw[base+$104] := ((vend) AND $127) SHL 8;
  port [base+$103] := 0;
  port [base+$105] := 0;
  port [base]      := 1;
  port [base+$103] := $4C;
  port [base+$105] := 3;
end;

var
  buf: array[0..14915] of byte;
  a : word;
  fromf : file;
begin
  assign(fromf, 'exit.raw');
  reset(fromf, 1);
  blockread(fromf, buf, 14916);
  close(fromf);

  GUSReset;
  for a := 0 to 14915 do
    GUSPoke(a, 127-buf[a]);

  GUSSetVolume(0, $FFFF);
  GUSSetFreq(0, 4000);
  GUSPlayVoice(0, 0, 14915);
end.