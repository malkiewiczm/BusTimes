%option noyywrap

%{
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <algorithm>
#include <vector>

#define DIGIT(a)(yytext[a] - '0')
#define DIGIT2(a, b)((yytext[a] - '0') * 10 + (yytext[b] - '0'))

struct time_entry {
	int hour, minute;
	bool operator< (const time_entry &rhs) const {
		if (hour != rhs.hour)
			return hour < rhs.hour;
		return minute < rhs.minute;
	}
	void print() const {
		printf("%02d:%02d", hour, minute);
	}
};

static bool PM = false;
static bool IN = false;
static bool ALT = false;
static int ROUTE = 0;

struct triplet {
	time_entry t0, t1, t2;
	int route;
	triplet() = default;
	triplet(const time_entry &a, const time_entry &b, const time_entry &c)
		: t0(a), t1(b), t2(c), route(ROUTE) {}
	void print(char terminator) const {
		printf("[%3d] ", route);
		t0.print();
		putchar(' ');
		t1.print();
		putchar(' ');
		t2.print();
		putchar(terminator);
	}
};

static std::vector<triplet> inbound;
static std::vector<triplet> outbound;
static time_entry working[3];
static int count = 0;

%}

%%
ROUTE[ \t]+[0-9]+ {
	sscanf(yytext + 5, "%d", &ROUTE);
}
SET[ \t]IN {
	IN = true;
	ALT = false;
}
SET[ \t]OUT {
	IN = false;
	ALT = false;
}
SET[ \t]ALTERNATE[\t ]IN {
	IN = true;
	ALT = true;
}
SET[ \t]ALTERNATE[\t ]OUT {
	IN = false;
	ALT = true;
}
AM {
	PM = false;
}
PM {
	PM = true;
}
[0-9]?[0-9]:[0-5][0-9] {
	int len = strlen(yytext);
	time_entry &t = working[count];
	if (len == 4) {
		t.hour = DIGIT(0);
		t.minute = DIGIT2(2, 3);
	} else {
		t.hour = DIGIT2(0, 1);
		t.minute = DIGIT2(3, 4);
	}
	if (PM) {
		t.hour += 12;
	}
	++count;
	if (count == 3) {
		if (IN) {
			inbound.emplace_back(working[0], working[1], working[2]);
		} else {
			outbound.emplace_back(working[0], working[1], working[2]);
		}
		if (ALT) {
			IN = ! IN;
		}
		count = 0;
	}
}
[\r\n\t]+

%%

static bool inbound_cmp(const triplet &lhs, const triplet &rhs)
{
	return lhs.t2 < rhs.t2;
}

static bool outbound_cmp(const triplet &lhs, const triplet &rhs)
{
	return lhs.t0 < rhs.t0;
}

int main(int argc, char **argv)
{
	yylex();
	if (argc == 1) {
		std::sort(inbound.begin(), inbound.end(), inbound_cmp);
		std::sort(outbound.begin(), outbound.end(), outbound_cmp);
	}
	puts("-----------------------------------------------");
	puts("INBOUND                 OUTBOUND");
	puts("-----------------------------------------------");
	if (inbound.size() > outbound.size()) {
		size_t i;
		for (i = 0; i < outbound.size(); ++i) {
			inbound[i].print(' ');
			outbound[i].print('\n');
		}
		for ( ; i < inbound.size(); ++i) {
			inbound[i].print('\n');
		}
	} else {
		size_t i;
		for (i = 0; i < inbound.size(); ++i) {
			inbound[i].print(' ');
			outbound[i].print('\n');
		}
		for ( ; i < outbound.size(); ++i) {
			printf("                        ");
			outbound[i].print('\n');
		}
	}
	return 0;
}
