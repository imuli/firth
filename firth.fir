aget out def write
swap astore quote write swap times def write

tnum 0 tnum 1000 tnum 7 tnum 32 tnum 0 tnum 0 var page
page swap set num 90 page sysone def page

num 101000 page dup
tcell
var tbeg
tcell
var tend
num 110000 page dup
tcell
var dbot
tcell
var dtop

tend get swap setbyte tend num 1 iadd def tbyte
tend get swap set tend num 4 iadd def tcell
dup getbyte tbyte inc def tcopy
quote tcopy swap times drop def tcopy
tbeg tend get set def tupdate
tend tbeg get set def treset
num 8d tbyte num 76 tbyte num fc tbyte num 89 tbyte num 06 tbyte def tdup
num e8 tbyte tend get num 4 add sub tcell def tcall
tdup num b8 tbyte tcell def tpush
num c3 tbyte def tret
tend get num 5 sub num e9 setbyte def tjump
tend get num 5 sub getbyte num e8 isequal nip def iscall
iscall when tjump else tret then ret def semi
tend get over sub dec setbyte def toffset

word astore 0 number tcell macro tnum
num eb tbyte tend get 0 tbyte macro func
semi dup toffset inc tpush macro tion
num 9e tbyte num ad tbyte num 73 tbyte tend get 0 tbyte macro when
toffset macro then
call func swap toffset macro else
word astore 0 number tpush macro num
in tpush macro char

0 exit

