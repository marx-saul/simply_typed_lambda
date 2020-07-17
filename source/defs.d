module defs;

enum TokenType {
	error,
	identifier, lambda, colon, dot,
	if_, then, else_,
	lparen, rparen,
	integer, true_, false_,
	int_, bool_, rightarrow,
	end_of_file,
}

struct Token {
	TokenType kind;
	string str;
}

abstract class AST {
	void accept(Visitor v) { v.visit(this); }
}

abstract class Expression : AST {
	Type type;
}

final class LambdaExpression : Expression {
	string arg;
	Type arg_type;
	Expression ret_expr;
	this (string a, Type a_t, Expression r_e) {
		arg = a;
		arg_type = a_t;
		ret_expr = r_e;
	}
	override void accept(Visitor v) { v.visit(this); }
}

final class ApplyExpression : Expression {
	Expression left;
	Expression right;
	this (Expression l, Expression r) {
		left = l;
		right = r;
	}
	override void accept(Visitor v) { v.visit(this); }
}

final class IfElseExpression : Expression {
	Expression condition;
	Expression if_expr;
	Expression else_expr;
	this (Expression c, Expression i_e, Expression e_e) {
		condition = c;
		if_expr = i_e;
		else_expr = e_e;
	}
	override void accept(Visitor v) { v.visit(this); }
}

final class IdentifierExpression : Expression {
	string name;
	this (string n) {
		name = n;
	}
	override void accept(Visitor v) { v.visit(this); }
}

final class TrueExpression : Expression {
	this () {}
	override void accept(Visitor v) { v.visit(this); }
}

final class FalseExpression : Expression {
	this () {}
	override void accept(Visitor v) { v.visit(this); }
}

final class IntegerExpression : Expression {
	string str;
	this (string s) { str = s; }
	override void accept(Visitor v) { v.visit(this); }
}

abstract class Type : AST {
	bool error;
	override void accept(Visitor v) { v.visit(this); }
}

final class FunctionType : Type {
	Type ran;	// range
	Type dom;	// domain
	this (Type r, Type d) {
		ran = r;
		dom = d;
	}
	override void accept(Visitor v) { v.visit(this); }
}

// int or bool
final class PrimitiveType : Type {
	TokenType kind;
	this (TokenType k) {
		kind = k;
	}
	override void accept(Visitor v) { v.visit(this); }
}

abstract class Visitor {
	void visit(AST);
	
	void visit(Expression);
	void visit(LambdaExpression);
	void visit(ApplyExpression);
	void visit(IfElseExpression);
	void visit(IdentifierExpression);
	void visit(TrueExpression);
	void visit(FalseExpression);
	void visit(IntegerExpression);
	
	void visit(Type);
	void visit(FunctionType);
	void visit(PrimitiveType);
}
