/****************************************************/
/* File: util.c                                     */
/* Utility function implementation                  */
/* for the TINY compiler                            */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/

#include "util.h"

#include "globals.h"

/* Procedure printToken prints a token
 * and its lexeme to the listing file
 */
void printToken(TokenType token, const char *tokenString)
{
	switch (token)
	{
		case IF:
		case ELSE:
		case WHILE:
		case RETURN:
		case INT:
		case VOID: fprintf(listing, "reserved word: %s\n", tokenString); break;
		case ASSIGN: fprintf(listing, "=\n"); break;
		case EQ: fprintf(listing, "==\n"); break;
		case NE: fprintf(listing, "!=\n"); break;
		case LT: fprintf(listing, "<\n"); break;
		case LE: fprintf(listing, "<=\n"); break;
		case GT: fprintf(listing, ">\n"); break;
		case GE: fprintf(listing, ">=\n"); break;
		case PLUS: fprintf(listing, "+\n"); break;
		case MINUS: fprintf(listing, "-\n"); break;
		case TIMES: fprintf(listing, "*\n"); break;
		case OVER: fprintf(listing, "/\n"); break;
		case LPAREN: fprintf(listing, "(\n"); break;
		case RPAREN: fprintf(listing, ")\n"); break;
		case LBRACE: fprintf(listing, "[\n"); break;
		case RBRACE: fprintf(listing, "]\n"); break;
		case LCURLY: fprintf(listing, "{\n"); break;
		case RCURLY: fprintf(listing, "}\n"); break;
		case SEMI: fprintf(listing, ";\n"); break;
		case COMMA: fprintf(listing, ",\n"); break;
		case ENDFILE: fprintf(listing, "EOF\n"); break;

		case NUM: fprintf(listing, "NUM, val= %s\n", tokenString); break;
		case ID: fprintf(listing, "ID, name= %s\n", tokenString); break;
		case ERROR: fprintf(listing, "ERROR: %s\n", tokenString); break;
		default: /* should never happen */ fprintf(listing, "Unknown token: %d\n", token);
	}
}

/* Function newStmtNode creates a new statement
 * node for syntax tree construction
 */

/*
TreeNode *newTreeNode(NodeKind kind)
{
	TreeNode *t = (TreeNode *)malloc(sizeof(TreeNode));
	if (t == NULL)
	{
		fprintf(listing, "Out of memory error at line %d\n", lineno);
		return t;
	}

	int i;
	for (i = 0; i < MAXCHILDREN; ++i) t->child[i] = NULL;
	t->sibling = NULL;
	t->lineno = lineno;
	t->nodekind = kind;
	return t;
}
*/
TreeNode *newStmtNode(StmtKind kind)
{
	TreeNode *t = (TreeNode *)malloc(sizeof(TreeNode));
	if (t == NULL)
	{
		fprintf(listing, "Out of memory error at line %d\n", lineno);
		return t;
	}
	int i;
	for (i = 0; i < MAXCHILDREN; ++i) t->child[i] = NULL;
	t->sibling = NULL;
	t->lineno = lineno;
	t->nodekind = StmtK;
	t->kind.stmt = kind;
	return t;
}

TreeNode *newExpNode(ExpKind kind)
{
	TreeNode *t = (TreeNode *)malloc(sizeof(TreeNode));
	if (t == NULL)
	{
		fprintf(listing, "Out of memory error at line %d\n", lineno);
		return t;
	}
	int i;
	for (i = 0; i < MAXCHILDREN; ++i) t->child[i] = NULL;
	t->sibling = NULL;
	t->lineno = lineno;
	t->nodekind = ExpK;
	t->type = Void;
	t->kind.exp = kind;
	return t;
}

/* Function copyString allocates and makes a new
 * copy of an existing string
 */
char *copyString(char *s)
{
	int n;
	char *t;
	if (s == NULL) return NULL;
	n = strlen(s) + 1;
	t = malloc(n);
	if (t == NULL) fprintf(listing, "Out of memory error at line %d\n", lineno);
	else
		strcpy(t, s);
	return t;
}

/* Variable indentno is used by printTree to
 * store current number of spaces to indent
 */
static int indentno = 0;

/* macros to increase/decrease indentation */
#define INDENT	 indentno += 2
#define UNINDENT indentno -= 2

/* printSpaces indents by printing spaces */
static void printSpaces(void)
{
	int i;
	for (i = 0; i < indentno; i++) fprintf(listing, " ");
}

#define TYPE2STR(type) \
	((type) == Integer ? "int" : (type) == IntegerArray ? "int[]" : (type) == Void ? "void" : (type) == VoidArray ? "void[]" : "unknown")

/* procedure printTree prints a syntax tree to the
 * listing file using indentation to indicate subtrees
 */
void printTree(TreeNode *tree)
{
	int i;
	INDENT;
	while (tree != NULL)
	{
		printSpaces();
		if (tree->nodekind==StmtK)
		{
		switch (tree->kind.stmt)
		{
			case CompK: fprintf(listing, "Compound Statement:\n"); break;
			case WhileK: fprintf(listing, "While Statement:\n"); break;
			case RetK:
				if (tree->child[0] == NULL) fprintf(listing, "Non-value Return Statement\n");
				else fprintf(listing, "Return Statement:\n");
				break;
			case IfK: 
				if (tree->child[2] == NULL) fprintf(listing, "If Statement:\n");
				else fprintf(listing, "If-Else Statement:\n");
				break;
			case ParamK:
				fprintf(listing,"Parameter: name = %s, type = ", tree->attr.name);
				if(tree->type == Void)
				{
					fprintf(listing, "void\n");
				}
				else if (tree->type == Int)
				{
					fprintf(listing, "int\n");
				}
				break;
			case ParamArrayK:
				fprintf(listing,"Parameter: name = %s, type = ", tree->attr.name);
				if(tree->type == Void)
				{
					fprintf(listing, "void[]\n");
				}
				else if (tree->type == Int)
				{
					fprintf(listing, "int[]\n");
				}
				break;
			case VoidK: fprintf(listing,"Void Parameter\n"); break;
			case FuncK:
				fprintf(listing,"Function Declaration: name = %s, return type = ", tree->attr.name);
				if(tree->type == Void)
				{
					fprintf(listing, "void\n");
				}
				else if (tree->type == Int)
				{
					fprintf(listing, "int\n");
				}
				break;
			case VarDeclationK: 
				fprintf(listing,"Variable Declaration: name = %s, type = ", tree->attr.name);
				if(tree->type == Void)
				{
					fprintf(listing, "void\n");
				}
				else if (tree->type == Int)
				{
					fprintf(listing, "int\n");
				}
				break;
			case VarArrayDeclationK:
				fprintf(listing,"Variable Declaration: name = %s, type = ", tree->attr.name);
				if(tree->type == Void)
				{
					fprintf(listing, "void[]\n");
				}
				else if (tree->type == Int)
				{
					fprintf(listing, "int[]\n");
				}
				break;
			default: fprintf(listing, "Unknown Stmt kind\n"); break;
		}
		}
		else if(tree->nodekind==ExpK)
		{
			switch(tree->kind.exp)
			{
				case OpK:
					fprintf(listing, "Op: ");
					printToken(tree->attr.op,"\0");
					break;
				case ConstK:
					fprintf(listing,"Const: %d\n",tree->attr.val);
					break;
				case AssignK:
					fprintf(listing, "Assign:\n");
					break;
				case CallK:
					fprintf(listing, "Call: function name = %s\n", tree->attr.name);
					break;
				case VarK:
					fprintf(listing, "Variable: name = %s\n", tree->attr.name);
					break;
				default:
					fprintf(listing,"Unknown ExpNode kind\n");
					break;
			}
		}
		else
		{
			fprintf(listing,"Unknown node kind\n");
		}
		for (i = 0; i < MAXCHILDREN; i++) printTree(tree->child[i]);
		tree = tree->sibling;
	}
	UNINDENT;
}
