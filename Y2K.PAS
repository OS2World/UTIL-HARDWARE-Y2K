Program y2k;

{$G+}

uses newdelay, dos, crt;


const
  version : string[5] = '0.03á';


var
  awardid : string absolute $f000:$e060;
  award1  : string absolute $f000:$ec70;
  award2  : string absolute $f000:$e0c0;

  cy,
  cm,
  cd,
  cdow,
  chr,
  cmin,
  csec,
  csec100	: word;


  ny,
  nm,
  nd,
  ndow,
  nhr,
  nmin,
  nsec,
  nsec100	: word;
  ncent		: byte;



  cmhr,
  cmmin,
  cmsec,
  cmd,
  cmm,
  cmy,
  cmc		: byte;

  ocmhr,
  ocmmin,
  ocmsec,
  ocmd,
  ocmm,
  ocmy,
  ocmc		: byte;


  bad2kbios,
  bad2krtc,
  badrtc,
  badbios,
  badbiosleap,
  badrtcleap	: boolean;




procedure disp(yn:boolean);
begin
  if yn then
  begin
    textcolor(12+blink);
    write('FAILS ');
    textcolor(7);
  end else
  begin
    textcolor(10);
    write('passes');
    textcolor(7);
  end;
end;





function cvtb(b:byte) : char;
begin
  if b>9 then cvtb:=char(b+ord('A')-10) else cvtb:=char(b+ord('0'));
end;


function wrhex(byt:byte) : string;
begin
  wrhex:=cvtb((byt and $f0) shr 4)+cvtb(byt and $0f);
end;

procedure showstuff;
begin
  write('þ Get new date and time from BIOS : ');
  asm
    mov ah,2
    int 01ah

    mov cmhr,ch
    mov cmmin,cl
    mov cmsec,dh

    mov ah,4
    int 01ah

    mov cmy,cl
    mov cmm,dh
    mov cmd,dl
    mov cmc,ch
  end;
  writeln(wrhex(cmd),'/',wrhex(cmm),'/',wrhex(cmc),wrhex(cmy),'  ',wrhex(cmhr),':',wrhex(cmmin),':',wrhex(cmsec));


  write('þ Get new date and time from RTC  : ');
  port[$70]:=0;
  nsec:=port[$71];
  port[$70]:=2;
  nmin:=port[$71];
  port[$70]:=4;
  nhr:=port[$71];
  port[$70]:=9;
  ny:=port[$71];
  port[$70]:=8;
  nm:=port[$71];
  port[$70]:=7;
  nd:=port[$71];
  port[$70]:=$32;
  ncent:=port[$71];
  writeln(wrhex(nd),'/',wrhex(nm),'/',wrhex(ncent),wrhex(ny),'  ',wrhex(nhr),':',wrhex(nmin),':',wrhex(nsec));

end;

procedure restore_orig_datetime;
begin
  writeln('þ Restore original date and time with BIOS');

  asm
    mov ah,5
    mov ch,ocmc
    mov cl,ocmy
    mov dh,ocmm
    mov dl,ocmd
    int 01ah


    mov ah,3
    mov ch,ocmhr
    mov cl,ocmmin
    mov dh,ocmsec
    mov dl,0
    int 01ah
  end;
end;




begin
  textbackground(0);
  textcolor(7);
  write(' ');
  textmode(co80+font8x8);
  clrscr;
  textcolor(14);
  writeln('Y2K BIOS/RTC Compatability tester version ',version);
  textcolor(7);


  writeln;


  if copy(awardid,1,13)='Award Modular' then
  begin
    writeln('Bios Type : ',awardid);
    writeln('Bios ID 1 : ',award1);
    writeln('Bios ID 2 : ',award2);
  end;


  writeln;
  write('þ Get date and time from DOS  : ');
  getdate(cy,cm,cd,cdow);
  gettime(chr,cmin,csec,csec100);
  writeln(cd:2,'/',cm:2,'/',cy:4,'  ',chr:2,':',cmin:2,':',csec:2);
  if cy>1999 then
  begin
    writeln('The date is already beyond 1999! Cant test unless date is < 1/1/2000!');
    halt(1);
  end;
  write('þ Get date and time from BIOS : ');
  asm
    mov ah,2
    int 01ah

    mov cmhr,ch
    mov cmmin,cl
    mov cmsec,dh

    mov ah,4
    int 01ah

    mov cmy,cl
    mov cmm,dh
    mov cmd,dl
    mov cmc,ch
  end;
  writeln(wrhex(cmd),'/',wrhex(cmm),'/',wrhex(cmc),wrhex(cmy),'  ',wrhex(cmhr),':',wrhex(cmmin),':',wrhex(cmsec));


  ocmhr:=cmhr;		{ original values to be restored later }
  ocmmin:=cmmin;
  ocmsec:=cmsec;
  ocmy:=cmy;
  ocmm:=cmm;
  ocmd:=cmd;
  ocmc:=cmc;



  write('þ Get date and time from RTC  : ');
  port[$70]:=0;
  nsec:=port[$71];
  port[$70]:=2;
  nmin:=port[$71];
  port[$70]:=4;
  nhr:=port[$71];
  port[$70]:=9;
  ny:=port[$71];
  port[$70]:=8;
  nm:=port[$71];
  port[$70]:=7;
  nd:=port[$71];
  port[$70]:=$32;
  ncent:=port[$71];
  writeln(wrhex(nd),'/',wrhex(nm),'/',wrhex(ncent),wrhex(ny),'  ',wrhex(nhr),':',wrhex(nmin),':',wrhex(nsec));




  writeln;
  textcolor(11);
  writeln('Rollover Tests');
  textcolor(7);
  writeln;

  writeln('þ Set date and time with BIOS : 31/12/1999  23:59:58');

  asm
    mov ah,5
    mov ch,19h
    mov cl,99h
    mov dh,12h
    mov dl,31h
    int 01ah


    mov ah,3
    mov ch,23h
    mov cl,59h
    mov dh,58h
    mov dl,0
    int 01ah
  end;
  write('þ Wait 4 seconds for year to roll over...');
  delay(4000);
  writeln;
  showstuff;
  if (cmy<>$00) or (cmc<>$20) then badbios:=true else badbios:=false;
  if (ny<>$00) or (ncent<>$20) then badRTC:=true else badrtc:=false;
  restore_orig_datetime;


  writeln;
  textcolor(11);
  writeln('Is 2000 a valid date Test');
  textcolor(7);
  writeln;

  writeln('þ Set date and time with BIOS : 01/01/2000  09:00:00');

  asm
    mov ah,5
    mov ch,20h
    mov cl,00h
    mov dh,01h
    mov dl,01h
    int 01ah


    mov ah,3
    mov ch,09h
    mov cl,00h
    mov dh,00h
    mov dl,0
    int 01ah
  end;
  write('þ Wait 4 seconds...');
  delay(4000);
  writeln;
  showstuff;
  if (cmy<>$00) or (cmc<>$20) then bad2kbios:=true else bad2kbios:=false;
  if (ny<>$00) or (ncent<>$20) then bad2kRTC:=true else bad2krtc:=false;
  restore_orig_datetime;






  writeln;
  textcolor(11);
  writeln('Leap-year Tests');
  textcolor(7);
  writeln;
  writeln('þ set date and time with BIOS : 28/02/2000  23:59:58');
  asm
    mov ah,5
    mov ch,20h
    mov cl,00h
    mov dh,02h
    mov dl,28h
    int 01ah

    mov ah,3
    mov ch,23h
    mov cl,59h
    mov dh,58h
    mov dl,0
    int 01ah
  end;

  write('þ Wait 4 seconds for day to roll over...');
  delay(4000);
  writeln;
  showstuff;
  if (cmd=$29) and (cmm=$02) and (cmc=$20) and (cmy=$00) then badbiosleap:=false else badbiosleap:=true;
  if (nd=$29) and (nm=$02) and (ncent=$20) and (ny=$00) then badRTCleap:=false else badrtcleap:=true;
  restore_orig_datetime;





  writeln;
  writeln;
  textcolor(15);
  writeln('Conclusions:');
  textcolor(7);
  writeln;









  write('The BIOS ');
  disp(badbios);
  writeln(' the rollover test.');
  write('The RTC  ');
  disp(badrtc);
  writeln(' the rollover test.');
  write('The BIOS ');
  disp(badbiosleap);
  writeln(' the leap-year test.');
  write('The RTC  ');
  disp(badrtcleap);
  writeln(' the leap-year test.');
  write('The BIOS ');
  disp(bad2kbios);
  writeln(' the valid date test.');
  write('The RTC  ');
  disp(bad2krtc);
  writeln(' the valid date test.');





  writeln;

  if not badbios and not badrtc and not badbiosleap and not badrtcleap and not bad2kbios and not bad2krtc then
  begin
    textcolor(10);
    writeln('This PC appears to be fully year 2000 compliant.');
    textcolor(7);
    halt(10);
  end;

  if bad2kbios or bad2krtc then
  begin
    textcolor(12);
    writeln('This PC is unable to function with dates after 31/12/1999!!');
    textcolor(7);
    halt(11);
  end;


  if badbiosleap or badRTCleap then
  begin
    textcolor(12);
    writeln('This PC Fails to recognise 2000 as a yeap-year!');
    textcolor(7);
    writeln('þ The date will need manual adjustment on 29/02/2000');
  end;


  if badrtc and not badbios then
  begin
    textcolor(14);
    writeln('This PC has a year 2000 compliant BIOS, but a non-compliant RTC!');
    textcolor(7);
    halt(12);
  end;


  if badbios or badrtc then
  begin
    textcolor(14);
    writeln('This PC is not year 2000 compliant!');
    textcolor(7);
    writeln('þ The date will need manual adjustment on 01/01/2000');
  end;

end.

