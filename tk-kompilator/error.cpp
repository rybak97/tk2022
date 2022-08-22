#include "global.hpp"

using namespace std;

bool checkSymbolExist(int id){
    if(id == -1) {
		yyerror("Niezadeklarowana zmienna/nazwa");
		return true;
    }
    else{
		return false;
	}
}
