uses crt;
begin
  writeln('Gravis Ultrasound enabled.');
  port[$332] := 0;
  delay(200);
  port[$332] := 3;
end.