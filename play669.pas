Program Testout_Gus669_Unit;

 Uses Crt, GUS669;

 Begin

   If ParamCount > 0 then Load669(Paramstr(1))
     else
   Begin
     Writeln;
     Writeln('Please specify the name of the 669 module you wish to play');
     Writeln('from the command line.');
     Writeln;
     Writeln('eg :    Play669  Hardwired.669 ');
     Writeln;
     Halt(1);
   End;
   PlayMusic;
   If Playing then
   Begin
     Writeln('Playing ', ParamStr(1) );
     Writeln('Press any key to stop and return to DOS.');
     Repeat
     Until Keypressed
   End
     else
   Begin
     Writeln;
     Writeln('Couldn''t load or play the module for some reason!');
     Writeln;
     Writeln('Please check your GUS is working correctly, and that you have');
     Writeln('correctly specified the 669 filename.');
     Writeln;
   End;
   StopMusic;
 End.
