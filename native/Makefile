
CXX = clang++ -std=c++11
CFLAGS = -g -O2
LFLAGS = -lm -lrt
pwd = $(shell pwd)

all: bin2c

bin2c: src/bin2c.cpp
	$(CXX) $(CFLAGS) $< -o $@ $(LFLAGS)


install:
	ln -sf $(pwd)/bin2c ~/bin/bin2c
