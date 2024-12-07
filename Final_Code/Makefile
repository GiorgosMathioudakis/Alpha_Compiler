all:
	@flex --outfile=scanner.cpp scanner.l
	@bison --output=parser.cpp -d -v --defines parser.y
	@mkdir -p dist
	@g++ -std=c++17 -g scanner.c parser.cpp symbol_Table.hpp intermediate_code.cpp target_code.hpp 
	@rm -f parser.cpp parser.h parser.output scanner.cpp

clean:
	rm -f parser.cpp scanner.cpp
	rm -f *.out
	rm -f parser.hpp