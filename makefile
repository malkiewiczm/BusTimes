MAKEFLAGS += Rr
CC := g++
CFLAGS := -std=c++11 -Ofast -march=native
#LDLIBS := -lfl
LDLIBS :=

all: lex.yy.c
	$(CC) $(CFLAGS) $(LDLIBS) $< -o $@

lex.yy.c: main.l
	lex $<

.PHONY: clean run
clean:
	rm -f all lex.yy.c

run: all
	cat route*.txt | ./all
