module check;

import defs;
import std.stdio;

final class TypeChecker : Visitor {
	Type[string] id_set;
	bool is_error = false;
	
	void error(string[] strs...) {
		foreach (str; strs)
			write(str);
		writeln();
		is_error = true;
	}
	
	override void visit(AST) { assert(0); }
	
	override void visit(Expression) { assert(0); }
	
	override void visit(LambdaExpression exp) {
		if (is_error) return;
		if (!exp) { error("Ill typed expression."); return; }
		// argument already used
		if (exp.arg in id_set) { error("argument ", exp.arg, " already appeared."); return; }
		// set argument type
		id_set[exp.arg] = exp.arg_type;
		
		// return expression
		if (!exp.ret_expr) { error("Ill typed expression."); }
		exp.ret_expr.accept(this);
		exp.type = new FunctionType(exp.arg_type, exp.ret_expr.type);
	}
	
	override void visit(ApplyExpression exp) {
		if (is_error) return;
		if (!exp) { error("Ill typed expression."); return; }
		if (!exp.left) { error("Ill typed expression."); return; }
		exp.left.accept(this);
		if (!exp.right) { error("Ill typed expression."); return; }
		exp.right.accept(this);
		
		if (is_error) return;
		
		// exp = f x
		// f: T -> S, x: T
		if (typeid(exp.left.type) != typeid(FunctionType)) {
			error("Ill typed expression. (application of no function type ", exp.left.type.type_to_string(), ")");
			return;
		}
		if (exp.left.type is null) { error("Ill typed expression."); return; }
		auto f_type = cast(FunctionType) exp.left.type;
		if (f_type.ran is null) { error("Ill typed expression."); return; }
		if (!check_type_equality(f_type.ran, exp.right.type)) { error("Ill typed expression. (ill function application)"); return; }
		exp.type = f_type.dom;
	}
	
	override void visit(IfElseExpression exp) {
		if (is_error) return;
		if (!exp)           { error("Ill typed expression."); return; }
		if (!exp.condition) { error("Ill typed expression."); return; }
		exp.condition.accept(this);
		if (!exp.if_expr)   { error("Ill typed expression."); return; }
		exp.if_expr.accept(this);
		if (!exp.else_expr) { error("Ill typed expression."); return; }
		exp.else_expr.accept(this);
		
		if (is_error) return;
		
		if (!check_type_equality(exp.condition.type, new PrimitiveType(TokenType.bool_))) { error("Ill typed expression. (if condition does not have type bool)"); return; }
		if (!check_type_equality(exp.if_expr.type, exp.else_expr.type)) { error("Ill typed expression. (if body and else body does not have the same type)"); return; }
		exp.type = exp.if_expr.type;
	}
	
	override void visit(IdentifierExpression exp) {
		if (is_error) return;
		if (!exp) { error("Ill typed expression."); return; }
		auto ptr = exp.name in id_set;
		if (ptr is null) { error("Identifier ", exp.name, " has not appeared as an argument of a lambda abstraction."); return; }
		if (*ptr is null) { error("Ill typed expression. (failed to resolve the type of an identifier)"); return; }
		exp.type = *ptr;
	}
	
	override void visit(TrueExpression exp) {
		if (is_error) return;
		if (!exp) { error("Ill typed expression."); return; }
		exp.type = new PrimitiveType(TokenType.bool_);
	}
	override void visit(FalseExpression exp) {
		if (is_error) return;
		if (!exp) { error("Ill typed expression."); return; }
		exp.type = new PrimitiveType(TokenType.bool_);
	}
	override void visit(IntegerExpression exp) {
		if (is_error) return;
		if (!exp) { error("Ill typed expression."); return; }
		exp.type = new PrimitiveType(TokenType.int_);
	}
	
	override void visit(Type) 			{ assert(0); }
	override void visit(FunctionType) 	{ assert(0); }
	override void visit(PrimitiveType) 	{ assert(0); }
}

bool check_type_equality(Type t1, Type t2) {
	if (t1 is null || t2 is null) return false;
	auto v = new TypeEqualityChecker(t2);
	t1.accept(v);
	return v.equal;
}
final class TypeEqualityChecker : Visitor {
	private Type equal_to;
	bool equal = true;
	this (Type e_t) { equal_to = e_t; }
	
	override void visit(AST) 					{ assert(0); }
	override void visit(Expression) 			{ assert(0); }
	override void visit(LambdaExpression) 		{ assert(0); }
	override void visit(ApplyExpression)	 	{ assert(0); }
	override void visit(IfElseExpression) 		{ assert(0); }
	override void visit(IdentifierExpression) 	{ assert(0); }
	override void visit(TrueExpression) 		{ assert(0); }
	override void visit(FalseExpression) 		{ assert(0); }
	override void visit(IntegerExpression) 		{ assert(0); }
	override void visit(Type) 					{ assert(0); }
	
	override void visit(FunctionType type) {
		if (!equal) { return; }
		if (typeid(equal_to) != typeid(FunctionType)) { equal = false; return; }
		
		auto tmp = equal_to;
		
		// check if ranges are equal
		equal_to = (cast(FunctionType) equal_to).ran;
		if (type) { equal = false; return; }
		type.ran.accept(this);
		if (!equal) { return; }
		equal_to = tmp;
		
		// check if domains are equal
		equal_to = (cast(FunctionType) equal_to).dom;
		if (type) { equal = false; return; }
		type.dom.accept(this);
		if (!equal) { return; }
		equal_to = tmp;
	}
	override void visit(PrimitiveType type) {
		if (!equal) { return; }
		if (typeid(equal_to) != typeid(PrimitiveType)) { equal = false; return; }
		
		equal = (cast(PrimitiveType) equal_to).kind == type.kind;
	}
}

string type_to_string(Type t) {
	if (!t) return "error";
	auto v = new TypeToString;
	t.accept(v);
	return v.result;
}
final class TypeToString : Visitor {
	string result;
	this () {}
	
	override void visit(AST) 					{ assert(0); }
	override void visit(Expression) 			{ assert(0); }
	override void visit(LambdaExpression exp) 	{ assert(0); }
	override void visit(ApplyExpression exp) 	{ assert(0); }
	override void visit(IfElseExpression) 		{ assert(0); }
	override void visit(IdentifierExpression) 	{ assert(0); }
	override void visit(TrueExpression) 		{ assert(0); }
	override void visit(FalseExpression) 		{ assert(0); }
	override void visit(IntegerExpression) 		{ assert(0); }
	
	override void visit(Type) 					{ assert(0); }
	override void visit(FunctionType type) {
		if (!type) { result ~= "error"; return; }
		result ~= "(";
		if (type.ran) type.ran.accept(this);
		result ~= " -> ";
		if (type.dom) type.dom.accept(this);
		result ~= ")";
	}
	override void visit(PrimitiveType type) {
		if (!type) { result ~= "error"; return; }
		if (type.kind == TokenType.bool_) {
			result ~= "bool";
		}
		else if (type.kind == TokenType.int_) {
			result ~= "int";
		}
		else {
			result ~= "error";
		}
	}
}
