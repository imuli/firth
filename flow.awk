#!/usr/bin/awk -f

BEGIN {
	print "digraph flow { ranksep=0.25 nodesep=0.25 rankdir=LR"
	colors["i32"] = "green"
	colors["i64"] = "blue"
}

{ gsub("%", "n") }

$1 == "define" {
	name = gensub(/@([0-9A-Za-z_]+)\(.*/, "\\1", "1", $5);
	print "subgraph cluster_"  name "{"
}

function handle_arg(to, from, type){
	from = gensub(/,/, "", "g", from)
	if(from ~ /^[0-9]+$/){
		f = from
		from = name "_" gensub(/:[a-z]$/, "", "1", to) "_" from
		print from " [label=\"" f "\", color=" colors[type] "]"
	} else if(from ~ /^@/){
		sub(/^@/, "", from)
	} else {
		from = name "_" from
	}
	print from "->" name "_" to " [color=" colors[type] "]"
}

$3 == "lshr" {
	print name "_" $1 " [label=\"" "{{<a> n|<b> d}|lshr}" "\", shape=Mrecord, color=" colors[$4] "]"
	handle_arg($1 ":a", $5, $4)
	handle_arg($1 ":b", $6, $4)
}

$3 == "or" {
	print name "_" $1 " [label=\"" "{{<a> n₀|<b> n₁}|or}" "\", shape=Mrecord, color=" colors[$4] "]"
	handle_arg($1 ":a", $5, $4)
	handle_arg($1 ":b", $6, $4)
}

$3 == "mul" {
	print name "_" $1 " [label=\"" "{{<a> n₀|<b> n₁}|mul}" "\", shape=Mrecord, color=" colors[$4] "]"
	handle_arg($1 ":a", $5, $4)
	handle_arg($1 ":b", $6, $4)
}

$3 == "add" {
	print name "_" $1 " [label=\"" "{{<a> n₀|<b> n₁}|add}" "\", shape=Mrecord, color=" colors[$4] "]"
	handle_arg($1 ":a", $5, $4)
	handle_arg($1 ":b", $6, $4)
}

$3 == "and" {
	print name "_" $1 " [label=\"" "{{<a> n₀|<b> n₁}|and}" "\", shape=Mrecord, color=" colors[$4] "]"
	handle_arg($1 ":a", $5, $4)
	handle_arg($1 ":b", $6, $4)
}

$3 == "zext" {
	print name "_" $1 " [label=\"" "{{<a> n}|zext}" "\", shape=Mrecord, color=" colors[$7] "]"
	handle_arg($1 ":a", $5, $4)
}

$3 == "getelementptr" {
	print name "_" $1 " [label=\"" "{{<a> off|<b> base}|getelementptr}" "\", shape=Mrecord, color=" colors[$9] "]"
	handle_arg($1 ":a", $12, $9)
	handle_arg($1 ":b", $8, $9)
}

$3 == "load" {
	sub(/\*/, "", $4)
	print name "_" $1 " [label=\"" "{{<a> a}|load}" "\", shape=Mrecord, color=" colors[$4] "]"
	handle_arg($1 ":a", $5, $4)
}

$1 == "ret" {
	print name "_" $1 " [label=\"" "{ret}" "\", shape=Mrecord, color=" colors[$2] "]"
	handle_arg($1, $3, $2)
}

$1 == "}" {
	print "}"
}

END {
	print "}"
}
