.macro _dup
	leal -4(%esi), %esi
	movl %eax, (%esi)
.endm
.macro _nip
	leal 4(%esi), %esi
.endm
.macro _drop
	lodsl
.endm

.text	

.balign 4096
.global _start
_start:
# link with -N instead
#	movl $start, %eax
#	and $0xfffff000, %eax
#	call xpage
	orl  $0xffc, %esp
	movl %esp, %esi
	and  $0xfffff000, %esi
	call Drecur
	call main
	xorl %eax, %eax
	call exit

## os calls
exit:	#
	movl %eax, %ebx
	movl $1, %eax
	int $0x80
	ret
xpage:	#
	movl %eax, %ebx
	movl $125, %eax
	movl $0x1000, %ecx
	movl $0x7, %edx
	int $0x80
	ret

## io
iob:
.byte 0
sys3:	#
	movl %eax, %edx
	_drop
	movl %eax, %ecx
	_drop
	movl %eax, %ebx
	_drop
	int $0x80
	ret
out:	#
	movb %al, iob
	movl $4, %eax	# write(
	movl $1, %ebx	# fd,
	movl $iob, %ecx	# address,
	movl $1, %edx	# length)
	int $0x80
	_drop
	ret
in:	#
	_dup
	movl $3, %eax	# read(
	movl $0, %ebx	# fd,
	movl $iob, %ecx	# address,
	movl $1, %edx	# length)
	int $0x80
#	_dup
	movzb iob, %eax
	ret

## data stack ops
dup:	#	inline
	_dup
	ret
swap:	#	inline
	xchgl (%esi), %eax
	ret
#T:	#	push
drop:	#	inline
	_drop
	ret
#F:	#	push
nip:	#	inline
	_nip
	ret
over:	#	inline
	_dup
	movl 4(%esi), %eax
	ret
rot:	#	inline
	xchgl (%esi), %eax
	xchgl 4(%esi), %eax
	ret
rrot:	# -rot	inline
	xchgl 4(%esi), %eax
	xchgl (%esi), %eax
	ret
depth:	#
	_dup
	movl %esi, %eax
	or $0xffc, %eax
	sub %esi, %eax
	shrl $2, %eax
	ret
pick:	#
	shll $2, %eax
	add %esi, %eax
	movl (%eax), %eax
	ret

## return stack ops
ret:	# ;	semi
noop:	# 	drop
	ret
rdrop:	# rdrop	inline
	pop %edx
	ret
rdrop2:	# rdrop2	inline
	pop %edx
	pop %edx
	ret
tor:	# >r	inline
	push %eax
	_drop
	ret
frr:	# r>	inline
	_dup
	pop %eax
	ret
rdepth:	#
	_dup
	movl %esp, %eax
	or $0xffc, %eax
	sub %esp, %eax
	shrl $2, %eax
	ret
rpick:	#
	shll $2, %eax
	add %esp, %eax
	movl (%eax), %eax
	ret

## arithmetic
neg:	# ‐	inline
	negl %eax
	ret
inc:	# 1+	inline
	incl %eax
	ret
dec:	# 1-	inline
	decl %eax
	ret
add:	# +	inline
	addl (%esi), %eax
	_nip
	ret
sub:	# -	inline
	subl (%esi), %eax
	negl %eax
	_nip
	ret
mul:	# *	inline
	imull (%esi), %eax
	_nip
	ret
div:	# /
	xorl %edx, %edx
	movl %eax, %ebx
	_drop
	divl %ebx, %eax
	ret
divm:	# /m
	xorl %edx, %edx
	movl %eax, %ebx
	movl (%esi), %eax
	idivl %ebx, %eax
	movl %eax, (%esi)
	movl %edx, %eax
	ret
muldiv:	# */
	movl %eax, %ebx
	_drop
	imull (%esi)
	_nip
	idivl %ebx
	ret

## memory
get:	# @	inline
	movl (%eax),%eax	# @
	ret
getw:	# @w	inline
	movzxw (%eax),%eax	# @w
	ret
getb:	# @b	inline
	movzxb (%eax),%eax	# @b
	ret
sset:	# s!
	movl %eax, %ebx
	_drop
	movl %eax, (%ebx)	# !
	_drop
	ret
set:	# !
	movl (%esi), %ebx
	movl %eax, (%ebx)	# !
	_drop
	_drop
	ret
setw:	# !w
	movl (%esi), %ebx
	movw %ax, (%ebx)	# !
	_drop
	_drop
	ret
setb:	# !b
	movl (%esi), %ebx
	movb %al, (%ebx)	# !
	_drop
	_drop
	ret
toar:	# >a	inline
	movl %eax, %edi		# >a
	_drop
	ret
frar:	# a>	inline
	_dup			# a>
	movl %edi, %eax
	ret
aget:	# a@
	_dup			# @a+
	movl (%edi), %eax
	leal 4(%edi), %edi
	ret
agetw:	# a@w
	_dup			# @a+
	movzxw (%edi), %eax
	leal 2(%edi), %edi
	ret
agetb:	# a@b
	_dup			# @a+
	movzxb (%edi), %eax
	leal 1(%edi), %edi
	ret
aset:	# a!	inline
	stosl
	_drop
	ret
asetw:	# a!w	inline
	stosw
	_drop
	ret
asetb:	# a!b	inline
	stosb
	_drop
	ret
copy0:	#
# dup @b a!b 1+ ;
	_dup
	call getb
	call asetb
	jmp inc
copy:	#
# swap >a ' copy0 swap times drop
	call swap
	call toar
	_dup
	movl $copy0, %eax
	call swap
	call times
	jmp drop

## bits
and:	# &	inline
	andl (%esi), %eax
	_nip
	ret
or:	# |	inline
	orl (%esi), %eax
	_nip
	ret
xor:	# ^	inline
	xorl (%esi), %eax
	_nip
	ret
not:	# ~	inline
	notl %eax
	ret
shl:	# <<
	movb %al, %cl
	_drop
	shll %cl, %eax
	ret
shr:	# >>
	movb %al, %cl
	_drop
	shrl %cl, %eax
	ret
sar:	# >>s
	movb %al, %cl
	_drop
	sarl %cl, %eax
	ret
zero:	# 0	inline
	_dup
	xorl %eax, %eax
	ret

## comparison
ltz:	# -?
	test %eax, %eax
	movl $1, %eax
	jl 0f
	movl $0, %eax
0:	ret
eqz:	# 0?
	test %eax, %eax
	movl $1, %eax
	jz 0f
	movl $0, %eax
0:	ret
gtz:	# +?
	test %eax, %eax
	movl $1, %eax
	jg 0f
	movl $0, %eax
0:	ret
lt:	# <?
	cmp (%esi), %eax
	movl $1, %eax
	jg 0f
	movl $0, %eax
0:	_nip
	ret
lte:	# <=?
	cmp (%esi), %eax
	movl $1, %eax
	jge 0f
	movl $0, %eax
0:	_nip
	ret
# SF ZF xx AF xx PF xx CF
eq:	# =?
	cmp (%esi), %eax
	lahf
	shrl $14, %eax
	andl $1, %eax
	_nip
	ret
gte:	# >=?
	cmp (%esi), %eax
	movl $1, %eax
	jle 0f
	movl $0, %eax
0:	_nip
	ret
gt:	# >?
	cmp (%esi), %eax
	movl $1, %eax
	jl 0f
	movl $0, %eax
0:	_nip
	ret

## flow
x:	# x
	movl %eax, %ebx
	_drop
	jmp *%ebx
if:	# if
# rot pick nip nip x ;
	call rot
	call pick
	_nip
	_nip
	jmp x
tdone:	#
# drop rdrop rdrop
	pop %edx
	pop %edx
	pop %edx
	ret
times:	#
# dup >r +? swap dup >r ' tdone if r> r> 1- recur ;
	_dup
	push %eax
	_drop
	call gtz
	call swap
	_dup
	push %eax
	_drop
	_dup
	movl $tdone, %eax
	call if
	_dup
	pop %eax
	_dup
	pop %eax
	dec %eax
	jmp times

## indirect arthmetic
iadd:	# i+
# over @ + !
	call over
	call get
	call add
	jmp set

## number io
num0:	# num0
# swap 10 * swap 48 - + a@b dup +? ' drop ' recur if ;
# FIXME simplify and generalize
	call swap
	_dup
	movl $10, %eax
	call mul
	call swap
	_dup
	movl $48, %eax
	call sub
	call add
	call agetb
	_dup
	call gtz
	_dup
	movl $num0, %eax
	_dup
	movl $drop, %eax
	jmp if
num:	# num
# 0 a@b num0
	_dup
	xorl %eax, %eax
	call agetb
	jmp num0
_dotn0:	# dotn0
# out neg ;
	call out
	jmp neg
dotn:	# dotn
# 45 over 0 <? ' dotn0 ' out if ;
	_dup
	movl $45, %eax
	call over
	_dup
	xorl %eax, %eax
	call lt
	_dup
	movl $_dotn0, %eax
	_dup
	movl $drop, %eax
	jmp if
dot0:	# dot0
# 10 /m 48 + swap dup 0? ' drop ' recur if out ;
# FIXME simplify and generalize
	_dup
	movl $10, %eax
	call divm
	_dup
	movl $48, %eax
	call add
	call swap
	_dup
	call eqz
	_dup
	movl $drop, %eax
	_dup
	movl $dot0, %eax
	call if
	jmp out
dot:	# .
# dotn dot0 10 out
	call dotn
	call dot0
	_dup
	movl $32, %eax
	jmp out
sdot0:	# s.0
# dup pick . 1-
	_dup
	call pick
	call dot
	jmp dec
sdot:	# s.
# depth s.0 over times drop
	call depth
	_dup
	movl $sdot0, %eax
	call over
	call times
	_drop
	ret
rdot0:	# r.0
# dup rpick . 1-
	_dup
	call rpick
	call dot
	jmp dec
rdot:	# r.
# rdepth ' r.0 over times drop
	call rdepth
	_dup
	movl $rdot0, %eax
	call over
	call times
	_drop
	ret

zeros0:	# 0s0
# dup 0 !b 1+
	_dup
	_dup
	xorl %eax, %eax
	call setb
	jmp inc
zeros:	# 0s
# ' 0s0 swap times drop
	_dup
	movl $zeros0, %eax
	call swap
	call times
	_drop
	ret

## parsing
wordb:	# Wb	push
	.rep 16
	.byte 0
	.endr
words:	# Ws	push
	.byte 0
word0: # word0
# in dup 32 >? ' a!b ' rdrop if recur ;
	call in
	_dup
	_dup
	movl $32, %eax
	call gt
	_dup
	movl $asetb, %eax
	_dup
	movl $rdrop, %eax
	call if
	jmp word0
word:	#
# dup 16 0s >a word0 words swap !b Wb
	_dup
	movl $wordb, %eax
	_dup
	_dup
	movl $16, %eax
	call zeros
	call toar
	call word0
	_dup
	movl $words, %eax
	call swap
	call setb
	_dup
	movl $wordb, %eax
	ret

# dictionary
dnext0:	# dnext0
# 16 - ;
	_dup
	movl $16, %eax
	jmp sub
dnext:	# dnext
# dup D0 >? ' dnext0 ' rdrop if ;
	_dup
	_dup
	movl $D0, %eax
	call gt
	_dup
	movl $dnext0, %eax
	_dup
	movl $rdrop, %eax
	jmp if
eighteq: # 8=?
# dup @ >a @ =? over 4 + @ >a 4 + @ =? &
	_dup
	call get
	call frar
	call get
	call eq
	call over
	_dup
	movl $4, %eax
	call add
	call get
	call frar
	_dup
	movl $4, %eax
	call add
	call get
	call eq
	jmp and
_find0:	# find0
# eighteq ' rdrop ' next if recur ;
	call eighteq
	_dup
	movl $rdrop, %eax
	_dup
	movl $dnext, %eax
	call if
	jmp _find0
find:	# find
# >a Dtop @ find0 8 +
	call toar
	_dup
	movl $Dtop, %eax
	call get
#	_dup
#	call dot
	call _find0
#	_dup
#	call get
#	_dup
#	mov $256, %eax
#	call divm
#	call out
#	_dup
#	mov $256, %eax
#	call divm
#	call out
#	_dup
#	mov $256, %eax
#	call divm
#	call out
#	call out
#	call space
#	call sdot
#	call cr
	_dup
	movl $8, %eax
	jmp add
_rfind0:	#
# dup @ a> <? ' rdrop ' next if recur ;
	_dup
	call get
	call frar
	call eq
	_dup
	movl $rdrop, %eax
	_dup
	movl $dnext, %eax
	call if
	jmp _rfind0
rfind:	#
# >a Dtop @ 8 + rfind0
	call toar
	_dup
	movl $Dtop, %eax
	call get
	_dup
	movl $8, %eax
	call add
	jmp _rfind0
#	_dup
#	movl $16, %eax
#	jmp add
fetch:	# fetch
# dup @ swap 4 + @
	_dup
	call get
	call swap
	_dup
	movl $4, %eax
	call add
	jmp get
Dinc:	# D+
# Dtop 16 i+
	_dup
	movl $Dtop, %eax
	_dup
	movl $16, %eax
	jmp iadd
Ddef:	# Ddef
# Dtop @ 8 copy
	_dup
	movl $Dtop, %eax
	call get
	_dup
	movl $8, %eax
	jmp copy
Dset:	# D!
# Dtop @ 8 + swap !
	_dup
	movl $Dtop, %eax
	call get
	_dup
	movl $8, %eax
	call add
	call swap
	jmp set
Dfset:	# Df!
# Dtop @ 12 + swap !
	_dup
	movl $Dtop, %eax
	call get
	_dup
	movl $12, %eax
	call add
	call swap
	jmp set
Cnew:	#
# Cbeg Cend @ !
	_dup
	movl $Cbeg, %eax
	_dup
	movl $Cend, %eax
	call get
	jmp set
#adot0:	# a.0
## dup @b dup 0? ' rdrop ' ret if out 1+ recur
#	_dup
#	call getb
#	_dup
#	call eqz
#	_dup
#	movl $rdrop, %eax
#	_dup
#	movl $ret, %eax
#	call if
#	call out
#	call inc
#	jmp adot0
#adot:	# a.
## adot0 drop drop
#	call adot0
#	_drop
#	_drop
#	ret
Dnew0:	#
## Ddef Df! Cbeg @ D!
#	_dup
#	call adot
#	call space
	call Ddef
	call Dfset
	_dup
	movl Cbeg, %eax
#	_dup
#	call dot
#	call cr
	jmp Dset
Rec:	#	push
.ascii	"recur\0\0\0"
Drecur:	#
# Rec ' call Dnew0
	_dup
	movl $call, %eax
	_dup
	movl $Rec, %eax
	jmp Dnew0
Dnew:	#
# Dnew0 Cnew D+ Drecur
	call Dnew0
	call Cnew
	call Dinc
	jmp Drecur
colon:	# :	x
# dup semi ' call word Dnew
	_dup
	call semi
	_dup
	movl $call, %eax
	call word
	jmp Dnew
colonm:	# :m	x
# dup semi ' x word Dnew
	_dup
	call semi
	_dup
	movl $x, %eax
	call word
	jmp Dnew
var:	# var	x
# ' push word Dnew
	_dup
	movl $push, %eax
	call word
	jmp Dnew

## compilation
# begin, end, and last end of compile buffer
.balign 4
Cbeg:	#	push
.int endtext
Cend:	#	push
.int endtext
Clast:	#	push
.int endtext
Cthis:	#	push
.int endtext

## commas
comma:	# ,
# Cend @ swap ! Cend 4 i+
	_dup
	movl $Cend, %eax
	call get
	call swap
	call set
	_dup
	movl $Cend, %eax
	_dup
	movl $4, %eax
	jmp iadd
commaw:	# ,w
# Cend @ swap !w Cend 2 i+
	_dup
	movl $Cend, %eax
	call get
	call swap
	call setw
	_dup
	movl $Cend, %eax
	_dup
	movl $2, %eax
	jmp iadd
commab:	# ,b
# Cend @ swap !b Cend 1 i+
	_dup
	movl $Cend, %eax
	call get
	call swap
	call setb
	_dup
	movl $Cend, %eax
	_dup
	movl $1, %eax
	jmp iadd
commacopy:	# ,copy
# dup @b ,b 1+
	_dup
	call getb
	call commab
	jmp inc

## code generation
call:	# call	nword
# 0xe8 ,b Cend @ 4 + - ,
	_dup
	movl $0xe8, %eax
	call commab
	_dup
	movl $Cend, %eax
	call get
	_dup
	movl $4, %eax
	call add
	call sub
	jmp comma
push:	# '	nword
# ' dup inline 0xb8 ,b ,
	_dup
	movl $dup, %eax
	call inline
	_dup
	movl $0xb8, %eax
	call commab
	jmp comma
Dlen:	#
# dup rfind 16 + @ over - nip
	_dup
	call rfind
	_dup
	movl $16, %eax
	call add
	call get
	call over
	call sub
	_nip
	ret
inline:	# inline	nword
# dup Dlen 1- ' ,copy swap times drop
	_dup
	call Dlen
	call dec
	_dup
	movl $commacopy, %eax
	call swap
	call times
	_drop
	ret
cret:	#
# 0xc3 ,b
	_dup
	movl $0xc3, %eax
	jmp commab
jump:	#
# Clast @ 0xe9 !b
	_dup
	movl $Clast, %eax
	call get
	_dup
	movl $0xe9, %eax
	jmp setb
semi:	# semi
# drop Clast @ @b 0xe8 =? ' jump ' cret if
	_drop
	_dup
	movl $Clast, %eax
	call get
	call getb
	_dup
	movl $0xe8, %eax
	call eq
	_dup
	movl $jump, %eax
	_dup
	movl $cret, %eax
	jmp if
# except this one
m:	#	nword
	jmp x
xpush:	#
# x push ;
	call x
	jmp push
getbdot:	# @b.
# @b . 1+
	_dup
	call getb
	call dot
	jmp inc
dump:	#
# ' Dlen 1- ' @b. swap times drop cr
	_dup
	call Dlen
	_dup
	movl $getbdot, %eax
	call swap
	call times
	_drop
	call cr
	ret

## macroish
rword:	#
# word find fetch ;
	call word
	call find
	jmp fetch
nword:	#
# rword drop swap x ;
	call rword
	_drop
	call swap
	jmp x
Cup:	#
# Clast Cthis @ ! Cthis Cend @ !
	_dup
	movl $Clast, %eax
	_dup
	movl $Cthis, %eax
	call get
	call set
	_dup
	movl $Cthis, %eax
	_dup
	movl $Cend, %eax
	call get
	jmp set
Creset: # Creset
# Cend Cbeg @ ! Cup ;
	_dup
	movl $Cend, %eax
	_dup
	movl $Cbeg, %eax
	call get
	call set
	jmp Cup
space:	#
# 0x20 out
	_dup
	movl $0x20, %eax
	jmp out
prompt:	#
# 0x3c out space s. 0x3e out space
#	_dup
#	movl $0x3c, %eax
#	call out
#	call space
#	call sdot
#	_dup
#	movl $0x3e, %eax
#	call out
#	jmp space
	ret
.balign 4
tempar:	#	push
.int 0
ateol:	# ateol
# cret Creset Cbeg @ tempar @ >a x tempar a> !
	_dup
	call semi
	call Creset
	_dup
	movl $Cbeg, %eax
	call get
	_dup
	movl $tempar, %eax
	call get
	call toar
	call x
	_dup
	movl $tempar, %eax
	call frar
	jmp set
linep:	# line?
# words @b 10 =? ;
	_dup
	movl $words, %eax
	call getb
	_dup
	movl $10, %eax
	jmp eq
cr:	#
# 10 out
	_dup
	movl $10, %eax
	jmp out
line:	#
# rword x Cup line? ' ateol ' recur if
	call rword
	call x
	call Cup
	call linep
	_dup
	movl $ateol, %eax
	_dup
	movl $line, %eax
	jmp if
main:	# main
# prompt line recur ;
	call line
	call prompt
	jmp main
Dtop:	# Dtop	push
.int	D1
## anything else
endtext:
.rept 4096
	.byte 0
.endr

.data
.balign 4096
D0:	# D0	push

.ascii "\0\0\0\0\0\0\0\0"
	.int num
	.int xpush
.ascii "exit\0\0\0\0"
	.int exit
	.int call
.ascii "xpage\0\0\0"
	.int xpage
	.int call
.ascii "sys3\0\0\0\0"
	.int sys3
	.int call
.ascii "out\0\0\0\0\0"
	.int out
	.int call
.ascii "in\0\0\0\0\0\0"
	.int in
	.int call
.ascii "dup\0\0\0\0\0"
	.int dup
	.int inline
.ascii "swap\0\0\0\0"
	.int swap
	.int inline
.ascii "drop\0\0\0\0"
	.int drop
	.int inline
.ascii "nip\0\0\0\0\0"
	.int nip
	.int inline
.ascii "over\0\0\0\0"
	.int over
	.int inline
.ascii "rot\0\0\0\0\0"
	.int rot
	.int inline
.ascii "-rot\0\0\0\0"
	.int rrot
	.int inline
.ascii "depth\0\0\0"
	.int depth
	.int call
.ascii "pick\0\0\0\0"
	.int pick
	.int call
.ascii ";\0\0\0\0\0\0\0"
	.int ret
	.int semi
.ascii "\0\0\0\0\0\0\0\0"
	.int noop
	.int drop
.ascii "rdrop\0\0\0"
	.int rdrop
	.int inline
.ascii "rdrop2\0\0"
	.int rdrop2
	.int inline
.ascii ">r\0\0\0\0\0\0"
	.int tor
	.int inline
.ascii "r>\0\0\0\0\0\0"
	.int frr
	.int inline
.ascii "rdepth\0\0"
	.int rdepth
	.int call
.ascii "rpick\0\0\0"
	.int rpick
	.int call
.ascii "‐\0\0\0\0\0"
	.int neg
	.int inline
.ascii "1+\0\0\0\0\0\0"
	.int inc
	.int inline
.ascii "1-\0\0\0\0\0\0"
	.int dec
	.int inline
.ascii "+\0\0\0\0\0\0\0"
	.int add
	.int inline
.ascii "-\0\0\0\0\0\0\0"
	.int sub
	.int inline
.ascii "*\0\0\0\0\0\0\0"
	.int mul
	.int inline
.ascii "/\0\0\0\0\0\0\0"
	.int div
	.int call
.ascii "/m\0\0\0\0\0\0"
	.int divm
	.int call
.ascii "*/\0\0\0\0\0\0"
	.int muldiv
	.int call
.ascii "@\0\0\0\0\0\0\0"
	.int get
	.int inline
.ascii "@w\0\0\0\0\0\0"
	.int getw
	.int inline
.ascii "@b\0\0\0\0\0\0"
	.int getb
	.int inline
.ascii "s!\0\0\0\0\0\0"
	.int sset
	.int call
.ascii "!\0\0\0\0\0\0\0"
	.int set
	.int call
.ascii "!w\0\0\0\0\0\0"
	.int setw
	.int call
.ascii "!b\0\0\0\0\0\0"
	.int setb
	.int call
.ascii ">a\0\0\0\0\0\0"
	.int toar
	.int inline
.ascii "a>\0\0\0\0\0\0"
	.int frar
	.int inline
.ascii "a@\0\0\0\0\0\0"
	.int aget
	.int call
.ascii "a@w\0\0\0\0\0"
	.int agetw
	.int call
.ascii "a@b\0\0\0\0\0"
	.int agetb
	.int call
.ascii "a!\0\0\0\0\0\0"
	.int aset
	.int inline
.ascii "a!w\0\0\0\0\0"
	.int asetw
	.int inline
.ascii "a!b\0\0\0\0\0"
	.int asetb
	.int inline
.ascii "copy0\0\0\0"
	.int copy0
	.int call
.ascii "copy\0\0\0\0"
	.int copy
	.int call
.ascii "&\0\0\0\0\0\0\0"
	.int and
	.int inline
.ascii "|\0\0\0\0\0\0\0"
	.int or
	.int inline
.ascii "^\0\0\0\0\0\0\0"
	.int xor
	.int inline
.ascii "~\0\0\0\0\0\0\0"
	.int not
	.int inline
.ascii "<<\0\0\0\0\0\0"
	.int shl
	.int call
.ascii ">>\0\0\0\0\0\0"
	.int shr
	.int call
.ascii ">>s\0\0\0\0\0"
	.int sar
	.int call
.ascii "0\0\0\0\0\0\0\0"
	.int zero
	.int inline
.ascii "-?\0\0\0\0\0\0"
	.int ltz
	.int call
.ascii "0?\0\0\0\0\0\0"
	.int eqz
	.int call
.ascii "+?\0\0\0\0\0\0"
	.int gtz
	.int call
.ascii "<?\0\0\0\0\0\0"
	.int lt
	.int call
.ascii "<=?\0\0\0\0\0"
	.int lte
	.int call
.ascii "=?\0\0\0\0\0\0"
	.int eq
	.int call
.ascii ">=?\0\0\0\0\0"
	.int gte
	.int call
.ascii ">?\0\0\0\0\0\0"
	.int gt
	.int call
.ascii "x\0\0\0\0\0\0\0"
	.int x
	.int call
.ascii "if\0\0\0\0\0\0"
	.int if
	.int call
.ascii "tdone\0\0\0"
	.int tdone
	.int call
.ascii "times\0\0\0"
	.int times
	.int call
.ascii "i+\0\0\0\0\0\0"
	.int iadd
	.int call
.ascii "num0\0\0\0\0"
	.int num0
	.int call
.ascii "num\0\0\0\0\0"
	.int num
	.int call
.ascii "dotn0\0\0\0"
	.int _dotn0
	.int call
.ascii "dotn\0\0\0\0"
	.int dotn
	.int call
.ascii "dot0\0\0\0\0"
	.int dot0
	.int call
.ascii ".\0\0\0\0\0\0\0"
	.int dot
	.int call
.ascii "s.0\0\0\0\0\0"
	.int sdot0
	.int call
.ascii "s.\0\0\0\0\0\0"
	.int sdot
	.int call
.ascii "r.0\0\0\0\0\0"
	.int rdot0
	.int call
.ascii "r.\0\0\0\0\0\0"
	.int rdot
	.int call
.ascii "0s0\0\0\0\0\0"
	.int zeros0
	.int call
.ascii "0s\0\0\0\0\0\0"
	.int zeros
	.int call
.ascii "Wb\0\0\0\0\0\0"
	.int wordb
	.int push
.ascii "Ws\0\0\0\0\0\0"
	.int words
	.int push
.ascii "word\0\0\0\0"
	.int word
	.int call
.ascii "dnext0\0\0"
	.int dnext0
	.int call
.ascii "dnext\0\0\0"
	.int dnext
	.int call
.ascii "find0\0\0\0"
	.int _find0
	.int call
.ascii "find\0\0\0\0"
	.int find
	.int call
.ascii "_rfind0\0"
	.int _rfind0
	.int call
.ascii "rfind\0\0\0"
	.int rfind
	.int call
.ascii "fetch\0\0\0"
	.int fetch
	.int call
.ascii "D+\0\0\0\0\0\0"
	.int Dinc
	.int call
.ascii "Ddef\0\0\0\0"
	.int Ddef
	.int call
.ascii "D!\0\0\0\0\0\0"
	.int Dset
	.int call
.ascii "Df!\0\0\0\0\0"
	.int Dfset
	.int call
.ascii "Cnew\0\0\0\0"
	.int Cnew
	.int call
.ascii "Dnew0\0\0\0"
	.int Dnew0
	.int call
.ascii "Rec\0\0\0\0\0"
	.int Rec
	.int push
.ascii "Drecur\0\0"
	.int Drecur
	.int call
.ascii "Dnew\0\0\0\0"
	.int Dnew
	.int call
.ascii ":\0\0\0\0\0\0\0"
	.int colon
	.int x
.ascii ":m\0\0\0\0\0\0"
	.int colonm
	.int x
.ascii "var\0\0\0\0\0"
	.int var
	.int x
.ascii "Cbeg\0\0\0\0"
	.int Cbeg
	.int push
.ascii "Cend\0\0\0\0"
	.int Cend
	.int push
.ascii "Clast\0\0\0"
	.int Clast
	.int push
.ascii "Cthis\0\0\0"
	.int Cthis
	.int push
.ascii ",\0\0\0\0\0\0\0"
	.int comma
	.int call
.ascii ",w\0\0\0\0\0\0"
	.int commaw
	.int call
.ascii ",b\0\0\0\0\0\0"
	.int commab
	.int call
.ascii ",copy\0\0\0"
	.int commacopy
	.int call
.ascii "call\0\0\0\0"
	.int call
	.int nword
.ascii "'\0\0\0\0\0\0\0"
	.int push
	.int nword
.ascii "Dlen\0\0\0\0"
	.int Dlen
	.int call
.ascii "inline\0\0"
	.int inline
	.int nword
.ascii "cret\0\0\0\0"
	.int cret
	.int call
.ascii "jump\0\0\0\0"
	.int jump
	.int call
.ascii "semi\0\0\0\0"
	.int semi
	.int call
.ascii "m\0\0\0\0\0\0\0"
	.int m
	.int nword
.ascii "xpush\0\0\0"
	.int xpush
	.int call
.ascii "@b.\0\0\0\0\0"
	.int getbdot
	.int call
.ascii "dump\0\0\0\0"
	.int dump
	.int call
.ascii "rword\0\0\0"
	.int rword
	.int call
.ascii "nword\0\0\0"
	.int nword
	.int call
.ascii "Cup\0\0\0\0\0"
	.int Cup
	.int call
.ascii "space\0\0\0"
	.int space
	.int call
.ascii "prompt\0\0"
	.int prompt
	.int call
.ascii "tempar\0\0"
	.int tempar
	.int push
.ascii "ateol\0\0\0"
	.int ateol
	.int call
.ascii "line?\0\0\0"
	.int linep
	.int call
.ascii "cr\0\0\0\0\0\0"
	.int cr
	.int call
.ascii "line\0\0\0\0"
	.int line
	.int call
.ascii "main\0\0\0\0"
	.int main
	.int call
.ascii "Dtop\0\0\0\0"
	.int Dtop
	.int push
.ascii "D0\0\0\0\0\0\0"
	.int D0
	.int push
D1:
.rept 376
	.rept 16
	.byte 0
	.endr
.endr
