all: firth newfirth

newfirth: firth.fir firth
	./firth < firth.fir > newfirth
	chmod +x newfirth

firth: firth.þ
	./4þ < firth.þ > firth
	chmod +x firth

clean:
	rm -f firth newfirth
