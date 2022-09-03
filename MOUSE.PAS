uses crt;
var
  k : byte;
  i, j : word;
  x, y : word;

begin
  asm
    mov ax, 13h
    int 10h
  end;
  port[$172] := 0; { initialize mouse }
  repeat
    {write(port[$172]); write(' ');}
    k := port[$172];

    { my mouse is quite sensitive so I do shr 2 }
    x := ((port[$173] shl 8) or port[$173]);
    y := ((port[$173] shl 8) or port[$173]);
    if k = 0 then
      mem[$a000:x+(199-y)*320] := 9;
    if k = 1 then
      mem[$a000:x+(199-y)*320] := 15;
    if k = 2 then
      mem[$a000:x+(199-y)*320] := 12;
    if k = 3 then
      mem[$a000:x+(199-y)*320] := 10;

    {write(x); write(' ');
    writeln(y);}
  until keypressed;
  asm
    mov ax, 3
    int 10h
  end;
end.
