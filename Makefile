all: firth

firth: firth.þ
	./4þ < firth.þ > firth
	chmod +x firth

clean:
	rm -f firth
