%{
	#include "global.hpp"

	using namespace std;

	int arrayElementTypeHelper;
	int startOffsertParamtersFunProcHelper = 8;	// 8 dla proc 12 dla fun
	ArrayInfo arrayInfoHelper;
	vector<int> argParamVectorHelper;
	list<pair<int, ArrayInfo> > paramHelper;
	list<int> funParamsHelper;

	void yyerror(char const* s);
%}

%token 	PROGRAM
%token 	BEGINN
%token 	END
%token 	VAR
%token 	INTEGER
%token  REAL
%token	ARRAY
%token 	OF
%token	FUN
%token 	PROC
%token	IF
%token	THEN
%token	ELSE
%token	DO
%token	WHILE
%token 	RELOP
%token 	MULOP
%token 	SIGN
%token 	ASSIGN
%token	OR
%token 	NOT
%token 	ID
%token 	NUM
%token 	NONE
%token 	DONE

%%

program:
		PROGRAM ID '(' start_identifiers ')' ';' declarations subprogram_declarations
			{
				writeToOutput("lab0:");
			}
		compound_statement
		'.'
			{
				writeToOutputExt("","exit","",";exit ","");
				writeToFile();
			}
		eof
	;

start_identifiers:
		ID
	| start_identifiers ',' ID
	;

identifier_list:
		ID
			{
				checkSymbolExist($1);
				argParamVectorHelper.push_back($1);
			}
	| identifier_list ',' ID
			{
				checkSymbolExist($3);
				argParamVectorHelper.push_back($3);
			}
	;

declarations:
	declarations VAR identifier_list ':' type ';'
		{
			for(auto &index : argParamVectorHelper)
			{
				if($5 == INTEGER || $5 == REAL)
				{
					SymbolTable[index].token = VAR;
					SymbolTable[index].type = $5;
					SymbolTable[index].address = getSymbolAddress(SymbolTable[index].name);
				}
				else if($5 == ARRAY)
				{
					SymbolTable[index].token = $5;
					SymbolTable[index].type = arrayElementTypeHelper;
					SymbolTable[index].arrayInfo = arrayInfoHelper;
					SymbolTable[index].address = getSymbolAddress(SymbolTable[index].name);
				}
				else
				{
					yyerror("Nieobslugiwany typ");
					YYERROR;
				}
			}
			argParamVectorHelper.clear();
		}
	| //empty
	;

type:
		standard_type
	| ARRAY '[' NUM '.' '.' NUM ']' OF standard_type
			{
				$$ = ARRAY;
				arrayElementTypeHelper = $9;
				arrayInfoHelper.startId = $3;
				arrayInfoHelper.stopId = $6;
				arrayInfoHelper.startVal = atoi(SymbolTable[$3].name.c_str());
				arrayInfoHelper.stopVal = atoi(SymbolTable[$6].name.c_str());
				arrayInfoHelper.argType = $9;
			}
	;

standard_type:
		INTEGER
	| REAL
	;

subprogram_declarations:
		subprogram_declarations subprogram_declaration ';'
	| //empty
	;

subprogram_declaration:
		subprogram_head declarations compound_statement
			{ 
				//end of fun/proc
				writeToOutputExt("","leave","",";leave ","");
				myGenCode(RETURN,-1,true,-1,true,-1,true);
				printSymbolTable();
				//reset
				clearLocalSymbols();
				isGlobal = true;
				startOffsertParamtersFunProcHelper = 8;
			}
	;

subprogram_head:
		FUN ID
			{	
				//writeToOutput("FUN ID-" + to_string($2));
				const int functionOffset = 12;
				checkSymbolExist($2);
				SymbolTable[$2].token = FUN;
				isGlobal = false;
				startOffsertParamtersFunProcHelper = functionOffset;
				myGenCode(FUN, $2 ,true ,-1 ,true ,-1 ,true);
			}
		arguments
			{	
				SymbolTable[$2].parameters = paramHelper;
				paramHelper.clear();
			}
		':' standard_type
			{	
				const int functionReturnOffset = 12;
				SymbolTable[$2].type = $7;
				int returnVarible = insert(SymbolTable[$2].name ,VAR ,$7); 	
				SymbolTable[returnVarible].isReference = true;
				SymbolTable[returnVarible].address = functionReturnOffset;
			}
		';'
	|	PROC ID
			{ 	
				const int procedureOffset = 8;
				checkSymbolExist($2);
				SymbolTable[$2].token = PROC;
				isGlobal = false;
				startOffsertParamtersFunProcHelper = procedureOffset;
				myGenCode(PROC ,$2 ,true ,-1 ,true ,-1 ,true);
			}
		arguments
			{	
				SymbolTable[$2].parameters = paramHelper;
				paramHelper.clear();
			}
		';'
	;

arguments:
		'(' parameter_list ')'
			{
				const int argumentSize = 4;
				for(auto &argument : funParamsHelper)
				{
					SymbolTable[argument].address = startOffsertParamtersFunProcHelper;
					startOffsertParamtersFunProcHelper += argumentSize;
				}
				funParamsHelper.clear();
			}
	| //empty
	;

parameter_list:
		identifier_list ':' type
			{	
				for(auto &index : argParamVectorHelper){
					SymbolTable[index].isReference = true;
					if($3 == ARRAY)
					{
						SymbolTable[index].token = ARRAY;
						SymbolTable[index].type = arrayElementTypeHelper;
						SymbolTable[index].arrayInfo = arrayInfoHelper;
					}
					else
					{
						SymbolTable[index].type = $3;
					}
					paramHelper.push_back(make_pair($3, arrayInfoHelper)); // interesuje mnie tylko w przypadku pojawienia sie tablicy inaczej jest 0
					//writeToOutput("$3-" + to_string($3) + "arrayInfoHelper.argType-" + to_string(arrayInfoHelper.argType));
					//writeToOutput("arrayInfoHelper.stopVal-" + to_string(arrayInfoHelper.stopVal));
					//writeToOutput("zapis parametrów funkcji");
					funParamsHelper.push_front(index);
				}
				argParamVectorHelper.clear();
			}
	| parameter_list ';' identifier_list ':' type
			{
				for(auto &index : argParamVectorHelper)
				{
					SymbolTable[index].isReference = true;
					if($5 == ARRAY)
					{
						SymbolTable[index].token = ARRAY;
						SymbolTable[index].type = arrayElementTypeHelper;
						SymbolTable[index].arrayInfo = arrayInfoHelper;
					}
					else
					{
						 SymbolTable[index].type = $5;
					}
					paramHelper.push_back(make_pair($5, arrayInfoHelper));
					funParamsHelper.push_front(index);
				}
				argParamVectorHelper.clear();
			}
	;

compound_statement:
		BEGINN optional_statement END
	;

optional_statement:
		statement_list
	| //empty
	;

statement_list:
 		statement
	| statement_list ';' statement
	;

statement:
		variable ASSIGN simple_expression
			{
				myGenCode(ASSIGN,$1,true,-1, true,$3,true);
			}
	| procedure_statement
	| compound_statement
	| IF expression
	 		{
				int label1 = insertLabel();
				int num = insertNum("0",INTEGER);
				myGenCode(EQ, label1, true, $2, true, num, true);
				$2 = label1;
			}
		THEN statement
		 	{
				int label2 = insertLabel();
				myGenCode(JUMP, label2, true, -1, true, -1, true);
				myGenCode(LABEL, $2, true, -1, true, -1, true);
				$5 = label2;
			}
		ELSE statement
			{
				myGenCode(LABEL, $5, true, -1, true, -1, true);
			}
	| WHILE
			{	
				int labelStop = insertLabel();
				int labelStart = insertLabel();
				$$ = labelStop;
				$1 = labelStart;
				myGenCode(LABEL, labelStart, true, -1, true, -1, true);
			}
		expression DO
			{	int id = insertNum("0",INTEGER);
				myGenCode(EQ, $2, true, $3, true, id, true);
			}
		statement
			{	
				myGenCode(JUMP, $1, true, -1, true, -1, true);
				myGenCode(LABEL, $2, true, -1, true, -1, true);
			}
	;

variable:
		ID
			{
				checkSymbolExist($1);
				$$ = $1;
			}
	| ID '[' simple_expression ']'
			{	
				if(SymbolTable[$3].type == REAL)
				{
					int t = insertTempSymbol(INTEGER);
					myGenCode(REALTOINT, t, true, $3, true, -1, true);
					$3 = t;
				}
				
				int startId = SymbolTable[$1].arrayInfo.startId;
				int t1 = insertTempSymbol(INTEGER);
				myGenCode(MINUS, t1, true, $3, true, startId, true);
				
				int arrayElementSize = 0;
				if(SymbolTable[$1].type == INTEGER)
				{
					arrayElementSize = insertNum("4",INTEGER);
				}
				else if(SymbolTable[$1].type == REAL)
				{
					arrayElementSize = insertNum("8",INTEGER);
				}
				
				myGenCode(MUL, t1, true, t1, true, arrayElementSize, true);
				int addressArray = insertTempSymbol(INTEGER);
				myGenCode(PLUS, addressArray, true, $1, false, t1, true);

				SymbolTable[addressArray].isReference = true;
				SymbolTable[addressArray].type = SymbolTable[$1].type;
				$$ = addressArray;
			}
	;

procedure_statement:
		ID
			{	
				checkSymbolExist($1);
				if(SymbolTable[$1].token == FUN || SymbolTable[$1].token == PROC)
				{
					if(SymbolTable[$1].parameters.size() > 0)
					{
						yyerror("Zla liczba parametrow.");
						YYERROR;
					}
					else
					{
						writeToOutput("\tcall.i #" + SymbolTable[$1].name);
					}
				}
				else
				{
					yyerror("Wymagana nazwa funkcji procedury");
					YYERROR;
				}
			}
	| ID '(' expression_list ')'
			{	
				int wId = lookup("write");
				int rId = lookup("read");
				if($1 == wId || $1 == rId)
				{
					for(auto &index : argParamVectorHelper)
					{
						if($1 == rId)
						{
							 myGenCode(READ, index, true, -1, true, -1, true );
						}
						if($1 == wId)
						{
							 myGenCode(WRITE, index, true, -1, true, -1, true );
						}
					}
				}
				else
				{
					string funName = SymbolTable[$1].name;
					int finId = lookupForFunction(funName);
					checkSymbolExist(finId);
					
					if(SymbolTable[finId].token == FUN || SymbolTable[finId].token == PROC)
					{
						if(argParamVectorHelper.size() < SymbolTable[finId].parameters.size())
						{
							yyerror("Nieprawidłowa liczba parametrów.");
							YYERROR;
						}
						
						int incspCount = 0;
						list<pair<int,ArrayInfo> >::iterator it = SymbolTable[finId].parameters.begin();
						int startPoint = argParamVectorHelper.size() - SymbolTable[finId].parameters.size();
						
						for(int i = startPoint; i < argParamVectorHelper.size(); i++)
						{
							int id = argParamVectorHelper[i];
							int argumentType = (*it).first;
							if(argumentType == ARRAY)
							{
								argumentType = (*it).second.argType;
							}

							if(SymbolTable[argParamVectorHelper[i]].token == NUM)
							{
								int numVar = insertTempSymbol(argumentType);
								myGenCode(ASSIGN,numVar,true, -1, true, argParamVectorHelper[i], true);
								id = numVar;
							}

							int passedType = SymbolTable[id].type;
							if(argumentType != passedType){
								int tempVar = insertTempSymbol(argumentType);
								myGenCode(ASSIGN, tempVar, true, -1, true, id, true);
								id = tempVar;
							}
							myGenCode(PUSH,id,false,-1, true, -1, true);
							incspCount += 4;
							it++;
						}

						int size = argParamVectorHelper.size();
						for(int i = startPoint;i < size; i++)
						{
							argParamVectorHelper.pop_back();
						}
						if(SymbolTable[$1].token == FUN)
						{
							int id = insertTempSymbol(SymbolTable[$1].type);
							myGenCode(PUSH,id,false,-1, true, -1, true);
							incspCount += 4;
							$$ = id;
						}
						myGenCode(CALL, $1,true,-1,true,-1,true);
						stringstream helper;
						helper << incspCount;
						int incspNum = insertNum(helper.str(),INTEGER);
						myGenCode(INCSP,incspNum,true,-1,true,-1,true);
					}
					else
					{
						yyerror("Brak takiej funkcji/procedury.");
						YYERROR;
					}
				}
				argParamVectorHelper.clear();
			}
	;

expression_list:
		expression
			{
				argParamVectorHelper.push_back($1);
			}
	| expression_list ',' expression
			{
				argParamVectorHelper.push_back($3);
			}
	;

expression:
		simple_expression
			{
				$$ = $1;
			}
	| simple_expression RELOP simple_expression
			{
			int labelCorrect = insertLabel();
			myGenCode($2, labelCorrect, true, $1, true, $3, true);
			int result = insertTempSymbol(INTEGER);
			int incorrect = insertNum("0",INTEGER);
			myGenCode(ASSIGN, result, true, -1, true, incorrect, true);
			int labelDone = insertLabel();
			myGenCode(JUMP, labelDone, true, -1, true, -1, true);
			myGenCode(LABEL, labelCorrect, true, -1, true, -1, true);
			int correct = insertNum("1",INTEGER);
			myGenCode(ASSIGN, result, true, -1, true, correct, true);
			myGenCode(LABEL, labelDone, true, -1, true, -1, true);
			$$ = result;
		}
	;

simple_expression:
		term
	| SIGN term
			{
				if($1 == PLUS)
				{
					 $$ = $2;
				}
				else if($1 == MINUS)
				{
					$$ = insertTempSymbol(SymbolTable[$2].type);
					int t0 = insertNum("0",SymbolTable[$2].type);
					myGenCode($1, $$, true, t0, true, $2, true);
				}
			}
	| simple_expression SIGN term
			{
				$$ = insertTempSymbol(getResultType($1, $3));
				myGenCode($2, $$, true, $1, true, $3, true);
			}
	| simple_expression OR term
			{
				$$ = insertTempSymbol(INTEGER);
				myGenCode(OR, $$, true, $1, true, $3, true);
			}
	;

term:
		factor
	| term MULOP factor
			{
				$$ = insertTempSymbol(getResultType($1, $3));
				myGenCode($2, $$, true, $1, true, $3, true);
			}
	;

factor:
		variable
			{	//fun bez parametru lub var
				int var = $1;
				if(SymbolTable[var].token == FUN)
				{
					if(SymbolTable[var].parameters.size() > 0)
					{
						yyerror("Wywołanie funkcji przyjmującej parametry bez parametrów");
						YYERROR;
					}
					var = insertTempSymbol(SymbolTable[var].type);
					writeToOutput(string("\tpush.i #" + SymbolTable[var].address));
					writeToOutput(string("\tcall.i #" + SymbolTable[$1].name));
					writeToOutput(string("\tincsp.i #4"));
				}
				else if(SymbolTable[var].token == PROC)
				{
					yyerror("Nie można pobrać wyniku bo procedura go nie zwraca");
					YYERROR;
				}
				$$ = var;
			}
	| ID '(' expression_list ')' // wywolanie funkcji
			{
				string name = SymbolTable[$1].name;
				int index = lookupForFunction(name); // wyszukuje przez nazwe w tablicy symboli zwraca index lub -1
				if(index == -1)
				{
					yyerror("Niezadeklarowana nazwa.");
					YYERROR;
				}
				if(SymbolTable[index].token == FUN) // sprawdzam czy znaleziony symbol jest tokenem typu FUN
				{
					if(argParamVectorHelper.size() < SymbolTable[index].parameters.size()) //sprawdzam czy ilość argumentów przy wywołaniu funkcji jest mniejszy niż dla deklaracji
					{
						yyerror("Nieprawidłowa liczba parametrów.");
						YYERROR;
					}

					int incspCount = 0;
					
					list<pair<int,ArrayInfo> >::iterator it=SymbolTable[index].parameters.begin();
					int startPoint = argParamVectorHelper.size() - SymbolTable[index].parameters.size();
					
					for(int i=startPoint;i<argParamVectorHelper.size();i++)
					{
						int id = argParamVectorHelper[i];
					
						int argumentType = (*it).first;
						if(argumentType==ARRAY) argumentType = (*it).second.argType;
						
						
							if(SymbolTable[argParamVectorHelper[i]].token==NUM)
							{
								int numVar = insertTempSymbol(argumentType);
								myGenCode(ASSIGN,numVar,true, -1, true, argParamVectorHelper[i], true);
								id = numVar;
							}

							int passedType = SymbolTable[id].type;
							
							if(argumentType!=passedType)
							{
								int tempVar = insertTempSymbol(argumentType);
								myGenCode(ASSIGN, tempVar, true, -1, true, id, true);
								id = tempVar;
							}
							myGenCode(PUSH,id,false,-1, true, -1, true);
							incspCount += 4;
							it++;
						}

						int size = argParamVectorHelper.size();
						for(int i = startPoint;i<size;i++)
						{
							argParamVectorHelper.pop_back();
						}
						
						int id = insertTempSymbol(SymbolTable[index].type);
						myGenCode(PUSH,id,false,-1, true, -1, true);
						incspCount += 4;
						$$ = id;

						myGenCode(CALL, index,true,-1,true,-1,true);
						stringstream helper;
						helper << incspCount;
						
						int incspNum = insertNum(helper.str(),INTEGER);
						myGenCode(INCSP,incspNum,true,-1,true,-1,true);
					}
					else if(SymbolTable[index].token==PROC)
					{
						yyerror("Procedury nie zwracają wartości, nie można wykonać operacji!");
						YYERROR;
					}
					else
					{
						yyerror("Nie znaleziono takiej funkcji/procedury.");
						YYERROR;
					}
				}
	| NUM
	| '(' expression ')'
			{
				$$ = $2;
			}
	| NOT factor
			{	
				int labelFactorEqualZero = insertLabel();
				int zeroId = insertNum("0",INTEGER);
				myGenCode(EQ,labelFactorEqualZero, true, $2, true,  zeroId, true);

				int varWithNotResult = insertTempSymbol(INTEGER);
				myGenCode(ASSIGN,varWithNotResult, true, -1, true, zeroId, true);
				
				int labelFinishNOT = insertLabel();
				myGenCode(JUMP, labelFinishNOT, true, -1, true, -1, true);
				myGenCode(LABEL, labelFactorEqualZero, true, -1, true, -1, true);

				int num1 = insertNum("1",INTEGER);
				myGenCode(ASSIGN,varWithNotResult, true, -1, true, num1, true);
				myGenCode(LABEL, labelFinishNOT, true, -1, true, -1, true);
				$$ = varWithNotResult;
			}
	;

eof:
		DONE
			{
				return 0;
			}
  ;

%%

void yyerror(char const *s)
{
	printf("Blad w linii %d: %s \n",lineno, s);
}
