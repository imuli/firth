all: 4þ.new

4þ.new: 4þ.þ
	./4þ < 4þ.þ > 4þ.new
	chmod +x 4þ.new

clean:
	rm -f 4þ.new
