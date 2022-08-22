#include "global.hpp"
#include "parser.hpp"

using namespace std;

int variablesCount = 0;
int labelsCount = 1;
vector<Symbol> SymbolTable;

int insert(string name, int token, int type) {
	Symbol symbol;
	symbol.token = token;
	symbol.name = name;
	symbol.type = type;
	symbol.isGlobal = isGlobal;
	symbol.isReference = false;
	symbol.address = 0;

	SymbolTable.push_back(symbol);
	return (int) (SymbolTable.size() - 1);
}

int insertNum(string val, int type) {
	int num = lookup(val);

	if (num == -1) {
		num = insert(val, NUM, type);
	}
	return num;
}

int insertTempSymbol(int type) {
	string name = "$t" + to_string(variablesCount++);
	int id = insert(name, VAR, type);
	SymbolTable[id].address = getSymbolAddress(name);
	return id;
}

int insertLabel() {
	string name = "lab" + to_string(labelsCount++);
	int id = insert(name, LABEL, NONE);
	return id;
}

void initSymbolTable() {
	Symbol read;
	read.name = ("read");
	read.isGlobal = true;
	read.isReference = false;
	read.token = PROC;
	SymbolTable.push_back(read);

	Symbol write;
	write.name = ("write");
	write.isGlobal = true;
	write.isReference = false;
	write.token = PROC;
	SymbolTable.push_back(write);

	Symbol lab0;
	lab0.name = ("lab0");
	lab0.isGlobal = true;
	lab0.isReference = false;
	lab0.token = LABEL;
	SymbolTable.push_back(lab0);
}

int lookup(string name) {
	int index = (int) (SymbolTable.size() - 1);

	for (; index >= 0; index--) {
		if (SymbolTable[index].name == name) {
			return index;
		}
	}
	return -1;
}

int lookupIfExist(string name) {
	int index = (int) (SymbolTable.size() - 1);

	if (isGlobal) {
		for (; index >= 0; index--) {
			if (SymbolTable[index].name == name) {
				return index;
			}
		}
	} else {
		for (; index >= 0; index--) {
			if (!SymbolTable[index].isGlobal && SymbolTable[index].name == name) {
				return index;
			}
		}
	}
	return -1;
}

int lookupIfExistAndInsert(string s, int token, int type) {
	int value = lookupIfExist(s);

	if (value == -1) {
		value = insert(s, token, type);
	}
	return value;
}

int lookupForFunction(string s) {
	int index = (int) (SymbolTable.size() - 1);

	for (; index >= 0; index--) {
		if (SymbolTable[index].name == s && (SymbolTable[index].token == FUN || SymbolTable[index].token == PROC)) {
			return index;
		}
	}
	return -1;
}

int getSymbolAddress(string symbolName) {
	int address = 0;

	if (isGlobal) {
		for (auto &symbol : SymbolTable) {
			if (symbol.isGlobal && symbol.name != symbolName) {
				address += getSymbolSize(symbol);
			}
		}
	} else {
		for (auto &symbol : SymbolTable) {
			if (!symbol.isGlobal && symbol.address <= 0) {
				address -= getSymbolSize(symbol);
			}
		}
	}
	return address;
}

int getSymbolSize(Symbol symbol) {
	const int intSizeElement = 4;
	const int realSizeElement = 8;
	const int referenceSizeElement = 4;
	const int nothingSizeElement = 0;

	if (symbol.token == VAR) {
		if (symbol.type == INTEGER) {
			return intSizeElement;
		} else if (symbol.type == REAL) {
			return realSizeElement;
		}
	} else if (symbol.token == ARRAY) {
		if (symbol.type == REAL) {
			return (symbol.arrayInfo.stopVal - symbol.arrayInfo.startVal + 1) * realSizeElement;
		} else {
			return (symbol.arrayInfo.stopVal - symbol.arrayInfo.startVal + 1) * intSizeElement;
		}
	} else if (symbol.isReference) {
		return referenceSizeElement;
	}
	return nothingSizeElement;
}

void clearLocalSymbols() {
	int address = 0;

	for (auto &element : SymbolTable) {
		if (element.isGlobal) {
			address++;
		}
	}
	SymbolTable.erase(SymbolTable.begin() + address, SymbolTable.end());
}

string tokenToString(int token) {
	switch (token) {
		case LABEL:
			return "label";
		case VAR:
			return "variable";
		case NUM:
			return "number";
		case ARRAY:
			return "array";
		case INTEGER:
			return "integer";
		case REAL:
			return "real";
		case PROC:
			return "procedure";
		case FUN:
			return "function";
		case ID:
			return "id";
		default:
			return "null";
	}
}

void printSymbolTable() {
	cout << "; Symbol table dump" << endl;
	int i = 0;

	for (auto &e : SymbolTable) {
		if (e.token != ID) {
			cout << "; " << i++;

			if (e.isGlobal) {
				cout << " Global ";
			} else {
				cout << " Local ";
			}

			if (e.isReference) {
				cout << "reference variable " << e.name << " ";
				if (e.token == ARRAY) {
					cout << tokenToString(e.token) << " [" << e.arrayInfo.startVal << ".." << e.arrayInfo.stopVal
						 << "] of ";
				}
				cout << tokenToString(e.type) << " offset=" << e.address << endl;
			} else if (e.token == NUM) {
				cout << tokenToString(e.token) << " " << e.name << " " << tokenToString(e.type) << endl;
			} else if (e.token == VAR) {
				cout << tokenToString(e.token) << " " << e.name << " " << tokenToString(e.type) << " offset="
					 << e.address << endl;
			} else if (e.token == ARRAY) {
				cout << "variable " << e.name << " array [" << e.arrayInfo.startVal << ".." << e.arrayInfo.stopVal
					 << "] of " << tokenToString(e.type) << " offset=" << e.address << endl;
			} else if (e.token == PROC  || e.token == LABEL) {
				cout << tokenToString(e.token) << " " << e.name << " " << endl;
			} else if (e.token == FUN ) {
				cout << tokenToString(e.token) << " " << e.name << " " << tokenToString(e.type) << endl;
			}
		}
	}
}

