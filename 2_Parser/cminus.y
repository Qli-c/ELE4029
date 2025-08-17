/****************************************************/
/* File: cminus.y                                   */
/* The TINY Yacc/Bison specification file           */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/
%{
#define YYPARSER /* distinguishes Yacc output from other code files */

#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *
static TreeNode * savedTree; /* stores syntax tree for later return */
static int yyerror(char * message);
static int yylex(void); // added 11/2/11 to ensure no conflict with lex
%}

%token IF WHILE RETURN INT VOID
%nonassoc RPAREN
%nonassoc ELSE 
%token ID NUM
%token EQ NE LT LE GT GE LPAREN LBRACE RBRACE LCURLY RCURLY COMMA SEMI
%token ERROR 
%left PLUS MINUS 
%left TIMES OVER 
%right ASSIGN

%% /* Grammar for C- */

program             : declaration_list { savedTree = $1; } 
                    ;
declaration_list    : declaration_list declaration
                         { 
							YYSTYPE t = $1; 
							if (t != NULL)
                            {
								while (t->sibling != NULL) t = t->sibling;
								t->sibling = $2; 
								$$ = $1; 
							} 
							else $$ = $2;
                         }
                    | declaration { $$ = $1; }
                    ;
declaration         : var_declaration { $$ = $1; }
                    | fun_declaration { $$ = $1; }
                    ;
var_declaration     : type_specifier identifier SEMI
                         { 
							$$ = newStmtNode(VarDeclationK);
							$$->lineno = $2->lineno;
							$$->type = $1->type;
							$$->attr.name = $2->attr.name;
							free($1); free($2);
                         }
                    | type_specifier identifier LBRACE number RBRACE SEMI
                         { 
							$$ = newStmtNode(VarArrayDeclationK);
							$$->lineno = $2->lineno;
							if ($1->type == Int) $$->type = Int;
							else if ($1->type == Void) $$->type = Void;
							$$->attr.name = $2->attr.name;
							$$->child[0] = $4;
							free($1); free($2);
                         }
                    ;
type_specifier      : INT  { $$ = newExpNode(ConstK); $$->lineno = lineno; $$->type = Int; }
                    | VOID { $$ = newExpNode(ConstK); $$->lineno = lineno; $$->type = Void; }
                    ;
fun_declaration     : type_specifier identifier LPAREN params RPAREN compound_stmt
                         { 
							$$ = newStmtNode(FuncK);
                                   $$->child[0] = $4;
                                   $$->child[1] = $6;
                                   $$->lineno = $2->lineno;
                                   $$->attr.name = $2->attr.name;
                                   $$->type = $1->type;
                         }
                    ;
params              : param_list { $$ = $1; }
                    | VOID
                         {
                              $$ = newStmtNode(VoidK);
                              $$->lineno = lineno;
                         }
                    ;
param_list          : param_list COMMA param
                         {
							YYSTYPE t = $1;
                                   if (t != NULL)
                                   {
                                        while(t->sibling != NULL) t = t->sibling;
                                        t->sibling = $3;
                                        $$ = $1;
                                   }
                                   else
                                   {
                                        $$ = $3;
                                   }
                         }
                    | param { $$ = $1;}
                    ;
param               : type_specifier identifier
                         {
						     $$ = newStmtNode(ParamK);
                                   $$->type = $1->type;
                                   $$->attr.name = $2->attr.name;
                         }
                    | type_specifier identifier LBRACE RBRACE
                         { 
						     $$ = newStmtNode(ParamArrayK);
                                   $$->type = $1->type;
                                   $$->attr.name = $2->attr.name;
                         }
                    ;
compound_stmt       : LCURLY local_declarations statement_list RCURLY
                         { 
							$$ = newStmtNode(CompK);
                                   $$->child[0] = $2;
                                   $$->child[1] = $3;
                         }
                    ;
local_declarations  : local_declarations var_declaration
                         {
							YYSTYPE t = $1;
                                   if (t != NULL)
                                   {
                                        while (t->sibling != NULL) t = t->sibling;
                                        t->sibling = $2;
                                        $$ = $1;
                                   }
                                   else
                                   {
                                        $$ = $2;
                                   }
                         }
                    | empty { $$ = NULL;}
                    ;
statement_list      : statement_list statement
                         { 
							YYSTYPE t = $1;
                                   if (t != NULL)
                                   {
                                        while (t->sibling != NULL) t = t->sibling;
                                        t->sibling = $2;
                                        $$ = $1;
                                   }
                                   else
                                   {
                                        $$ = $2;
                                   }
                         }
                    | empty { $$ = NULL; }
                    ;
statement			: selection_stmt { $$ = $1; }
					| expression_stmt { $$ = $1; }
                    | compound_stmt { $$ = $1; }
                    | iteration_stmt { $$ = $1; }
                    | return_stmt { $$ = $1; }
					;
selection_stmt		: IF LPAREN expression RPAREN statement ELSE statement
						{
                                   $$ = newStmtNode(IfK);
                                   $$->child[0] = $3;
                                   $$->child[1] = $5;
                                   $$->child[2] = $7;
						}
					| IF LPAREN expression RPAREN statement 
						{
							$$ = newStmtNode(IfK);
                                   $$->child[0] = $3;
                                   $$->child[1] = $5;
                                   $$->child[2] = NULL;
						}
					;
expression_stmt     : expression SEMI { $$ = $1; }
                    | SEMI { $$ = NULL; }
                    ;
iteration_stmt      : WHILE LPAREN expression RPAREN statement
                         { 
							$$ = newStmtNode(WhileK);
                                   $$->child[0] = $3;
                                   $$->child[1] = $5;
                         }
                    ;
return_stmt         : RETURN SEMI 
						{ 
							$$ = newStmtNode(RetK);
                                   $$->lineno = lineno;
						}
                    | RETURN expression SEMI
                         { 
                              $$ = newStmtNode(RetK);
                              $$->child[0] = $2;
                         }
                    ;
expression          : var ASSIGN expression
                         { 
                              $$ = newExpNode(AssignK);
                              $$->child[0] = $1;
                              $$->child[1] = $3;
                         }
                    | simple_expression { $$ = $1; }
                    ;
var                 : identifier
                         { 
						$$ = $1;
                         }
                    | identifier LBRACE expression RBRACE
                         {
						$$ = newExpNode(VarK);
                              $$->lineno = $1->lineno;
                              $$->child[0] = $3;
                              $$->attr.name = $1->attr.name;
                         }
                    ;
simple_expression   : additive_expression relop additive_expression
                         { 
							$$ = $2;
                                   $$->child[0] = $1;
                                   $$->child[1] = $3;
                         }
                    | additive_expression { $$ = $1; }
                    ;
relop               : LE { $$ = newExpNode(OpK); $$->attr.op = LE; }
                    | LT { $$ = newExpNode(OpK); $$->attr.op = LT; }
                    | GT { $$ = newExpNode(OpK); $$->attr.op = GT; }
                    | GE { $$ = newExpNode(OpK); $$->attr.op = GE; }
                    | EQ { $$ = newExpNode(OpK); $$->attr.op = EQ; }
                    | NE { $$ = newExpNode(OpK); $$->attr.op = NE; }
                    ;
additive_expression : additive_expression addop term
                         { 
						$$ = $2;
                              $$->child[0] = $1;
                              $$->child[1] = $3;	
                         }
					| term { $$ = $1; }
addop				: PLUS  { $$ = newExpNode(OpK); $$->attr.op = PLUS;}
					| MINUS { $$ = newExpNode(OpK); $$->attr.op = MINUS; }
					;
term                : term mulop factor
						{
							$$ = $2;
                                   $$->child[0] = $1;
                                   $$->child[1] = $3;
						}
					| factor { $$ = $1; }
					;
mulop               : TIMES { $$ = newExpNode(OpK); $$->attr.op = TIMES; }
					| OVER  { $$ = newExpNode(OpK); $$->attr.op = OVER; }
					;
factor              : LPAREN expression RPAREN { $$ = $2; }
                    | var { $$ = $1; }
                    | call { $$ = $1;  }
                    | number { $$ = $1; }
                    ;
call                : identifier LPAREN args RPAREN
                         {
                              $$ = newExpNode(CallK);
						$$->child[0] = $3;
                              $$->attr.name = $1->attr.name;
                         }
                    ;
args                : arg_list { $$ = $1; }
                    | empty { $$ = NULL; }
                    ;
arg_list            : arg_list COMMA expression
                         {
							YYSTYPE t = $1; 
							if (t != NULL)
							{ 
								while (t->sibling != NULL) t = t->sibling;
								t->sibling = $3; 
								$$ = $1; 
							} 
							else $$ = $3;
                         }
                    | expression { $$ = $1; }
                    ;
identifier			: ID
						{
							$$ = newExpNode(VarK);
							$$->lineno = lineno;
							$$->attr.name = copyString(tokenString);
						}
					;
number				: NUM
						{
							$$ = newExpNode(ConstK);
							$$->lineno = lineno;
							$$->attr.val = atoi(tokenString);
						}
					;
empty               : { $$ = NULL;}
                    ;

%%

int yyerror(char * message)
{
	fprintf(listing,"Syntax error at line %d: %s\n",lineno,message);
	fprintf(listing,"Current token: ");
	printToken(yychar,tokenString);
	Error = TRUE;
	return 0;
}

/* yylex calls getToken to make Yacc/Bison output
 * compatible with ealier versions of the TINY scanner
 */
static int yylex(void)
{ return getToken(); }

TreeNode * parse(void)
{ 
	yyparse();
	return savedTree;
}
