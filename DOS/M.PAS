uses crt;
begin
  writeln('Roland MT-32 enabled.');
  port[$332] := 0;
  delay(200);
  port[$332] := 2;
end.