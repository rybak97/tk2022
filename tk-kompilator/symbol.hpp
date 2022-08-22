#ifndef INCLUDE_H

#define INCLUDE_H

#include <string>
#include <iostream>
#include <list>

using namespace std;

class ArrayInfo {
public:
	int startId;
	int stopId;
	int startVal;
	int stopVal;
	int argType;
};

class Symbol {
public:
	bool isReference;
	bool isGlobal;
	int token;                                  // typ tokenu: FUN, PROC, ARRAY ...
	int type;                                   // rodzaj wartości INTEGER/REAL
	int address;
	string name;                                // numer dla liczb lub nazwa: lab0
	ArrayInfo arrayInfo;                        // informacje o tablicy
	list <pair<int, ArrayInfo>> parameters;     // typy parametrów dla funkcji procedury
};

#endif
