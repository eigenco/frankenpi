uses crt, dos;

procedure WriteDSP(b: byte);
begin
  while port[$22C] AND $80 <> 0 do;
  port[$22C] := b;
end;

procedure SBIRQ; interrupt;
var
  b : byte;
begin
  write('*');
  b := port[$22E];  { ACK  SB }
  port[$20] := $20; { ACK PIC }
  WriteDSP($14);
  WriteDSP(lo(14915 shr 4));
  WriteDSP(hi(14915 shr 4));
end;

var
  buf: array[0..14915] of byte;
  page, offset : word;
  fromf : file;

begin
  assign(fromf, 'exit.raw');
  reset(fromf, 1);
  blockread(fromf, buf, 14916);
  close(fromf);

  SetIntVec(8+7, addr(SBIRQ));         { IRQ 5 }
  port[$21] := 0;                      { enable all IRQs }

{  port[$226] := 1; delay(1);           { DSP reset port $226 }
{  port[$226] := 0; delay(1);
{  WriteDSP($D1);                       { DAC on }

  offset := seg(buf) shl 4 + ofs(buf);
  page := (seg(buf) + ofs(buf) shr 4) shr 12;

  port[$0B] := $49;
  port[$02] := lo(offset);
  port[$02] := hi(offset);
  port[$83] := page;
  port[$03] := lo(14915);              { DMA transfer size }
  port[$03] := hi(14915);
  port[$0A] := 1;                      { enable DMA channel 1 }

  WriteDSP($40);
  WriteDSP(256 - 1000000 div 8000);

  WriteDSP($14);
  WriteDSP(lo(14915 shr 4));
  WriteDSP(hi(14915 shr 4));

  readln;
end.