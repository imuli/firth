#!/usr/bin/awk -f
BEGIN{
FS=OFS="	"
print ".ascii \"\\0\\0\\0\\0\\0\\0\\0\\0\""
print "	.int num"
print "	.int xpush"
}
/^[a-zA-Z0-9_]+:	#/ {
	sub(":", "", $1)
	if($2 == "#"){ $2 = $1 }
	if($2 == "# "){ $2 = "" }
	sub("# ?", "", $2)
	if($3 == ""){ $3 = "call" }
	$2 = $2 substr("\\0\\0\\0\\0\\0\\0\\0\\0", 1 + 2*length($2))
	print ".ascii \"" $2 "\""
	print "", ".int " $1
	print "", ".int " $3
}

END{
print "D1:"
print ".rept 32"
print "	.rept 16"
print "	.byte 0"
print "	.endr"
print ".endr"
}
