all: 4þ

4þ: core.o
	ld -N -o 4þ core.o

4þ.asm: 4þ
	objdump -d 4þ > 4þ.asm

core.o: core.s
	as -g -o core.o core.s

clean:
	rm -f 4þ
