fastquery:

%: %.cpp
	clang++ --std=gnu++0x -W -Wall -Wno-sign-compare -Ofast -s -pipe -mmmx -msse -msse2 -msse3 -msse4 -mavx -mcmodel=medium -o $@ $< -pthread -D LOCAL

clean:
	rm -f fastquery
