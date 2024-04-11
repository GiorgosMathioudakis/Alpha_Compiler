all: alphaCompiler.out

alphaCompiler.out: scanner.cpp parser.cpp
	g++ -std=c++11 -g scanner.cpp parser.cpp -o alphaCompiler.out

scanner.cpp: scanner.l
	flex -o scanner.cpp scanner.l

parser.cpp parser.hpp: parser.y
	bison -d -v -o parser.cpp parser.y

clean:
	rm -f *.cpp
	rm -f *.out
	rm -f parser.hpp

