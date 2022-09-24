uses crt;
begin
  writeln('AdLib enabled.');
  port[$332] := 0;
  delay(200);
  port[$332] := 1;
end.