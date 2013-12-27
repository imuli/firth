all: firth fun

fun: firth.fun firth
	./firth < firth.fun > fun
	chmod +x fun

firth: firth.þ
	./4þ < firth.þ > firth
	chmod +x firth

clean:
	rm -f firth newfirth
