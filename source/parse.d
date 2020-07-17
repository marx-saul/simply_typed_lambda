module parse;

import defs;
import std.ascii;
import std.stdio;

enum EOF = cast(char) -1;

class Lexer {
	private string source;
	private size_t index;
	
	this (string s) {
		source = s;
		nextToken();
	}
	
	private char ch() @property {
		if (index >= source.length) return EOF;
		else return source[index];
	}
	protected void nextChar() {
		++index;
	}
	
	private Token _token;
	protected Token token() @property {
		return _token;
	}
	protected void nextToken() @property {
		Token result;
		
		start:
		// get rid of spaces
		while (ch().isWhite && ch() != EOF) { nextChar(); }
		
		with (TokenType)
		// end_of_file
		if (ch() == EOF) {
			result.kind = end_of_file;
			result.str = "EOF";
			
		}
		// identifier
		else if (ch().isAlpha || ch() == '_') {
			result.kind = identifier;
			while (ch().isAlphaNum || ch() == '_') {
				result.str ~= ch();
				nextChar();
			}
			// keywords
			switch (result.str) {
				case "if":		result.kind = if_;		break;
				case "then":	result.kind = then;		break;
				case "else":	result.kind = else_;	break;
				case "true":	result.kind = true_;	break;
				case "false":	result.kind = false_;	break;
				case "int":		result.kind = int_;		break;
				case "bool":	result.kind = bool_;	break;
				default: break;
			}
		}
		// integer
		else if (ch().isDigit) {
			result.kind = integer;
			while (ch().isDigit) {
				result.str ~= ch();
				nextChar();
			}
		}
		// symbols
		else {
			switch (ch()) {
				case '\\':	result.kind = lambda;	result.str = "\\";	break;
				case ':':	result.kind = colon;	result.str = ":";	break;
				case '.':	result.kind = dot;		result.str = ".";	break;
				case '(':	result.kind = lparen;	result.str = "(";	break;
				case ')':	result.kind = rparen;	result.str = ")";	break;
				case '-':
					nextChar();
					if (ch() == '>') {
						result.kind = rightarrow;	result.str = "->";
					} 
					else {
						writeln("-> expected.");
						goto start;
					}
					break;
				default:
					writeln("Invalid character ", ch());
					nextChar();
					goto start;
			}
			nextChar();
			
		}
		
		_token = result;
	}
}

class Parser : Lexer {
	bool is_error = false;
	this (string s) {
		super(s);
	}
	
	void check(TokenType k) {
		if (token.kind != k) {
			writeln(k, " was expected.");
			is_error = true;
			do {
				nextToken();
			} while (token.kind != k && token.kind != TokenType.end_of_file);
		}
		else {
			nextToken();
		}
	}
	
	public Expression parse() {
		return parseExpression();
	}
	
	// parse expression
	private pure bool isFirstOfExpression(TokenType k) {
		import std.algorithm: among;
		with (TokenType)
			return k.among!(lambda, lparen, identifier, integer, true_, false_, if_) != 0;
	}
	private:
	Expression parseExpression() {
		return parseLambdaExpression();
	}
	Expression parseLambdaExpression() {
		if (token.kind == TokenType.lambda) {
			nextToken();	// get rid of \
			// error
			if (token.kind != TokenType.identifier) {
				writeln("identifier expected, not ", token.str);
				is_error = true;
				return null;
			}
			auto id = token.str;
			nextToken();	// get rid of id
			check(TokenType.colon);
			auto type = parseType();
			check(TokenType.dot);
			auto expr = parseExpression();
			return new LambdaExpression(id, type, expr);
		}
		else return parseApplyExpression();
	}
	Expression parseApplyExpression() {
		auto e0 = parseAtomExpression();
		while (isFirstOfExpression(token.kind)) {
			auto e1 = parseAtomExpression();
			e0 = new ApplyExpression(e0, e1);
		}
		return e0;
	}
	Expression parseAtomExpression() {
		with (TokenType)
		switch (token.kind) {
		case identifier:
			auto id = token.str;
			nextToken();
			return new IdentifierExpression(id);
		case integer:
			auto str = token.str;
			nextToken();
			return new IntegerExpression(str);
		case true_:
			nextToken();
			return new TrueExpression;
		case false_:
			nextToken();
			return new FalseExpression;
		case if_:
			nextToken();
			auto e0 = parseExpression();
			check(TokenType.then);
			auto e1 = parseExpression();
			check(TokenType.else_);
			auto e2 = parseExpression();
			return new IfElseExpression(e0, e1, e2);
		case lparen:
			nextToken();
			auto e0 = parseExpression();
			check(TokenType.rparen);
			return e0;
		default:
			writeln("An expression expected, not ", token.str);
			is_error = true;
			nextToken();
			return null;
		}
	}
	
	// parse type
	Type parseType() {
		return parseFunctionType();
	}
	Type parseFunctionType() {
		auto t0 = parsePrimitiveType();
		if (token.kind == TokenType.rightarrow) {
			nextToken();
			auto t1 = parseFunctionType();
			return new FunctionType(t0, t1);
		}
		else return t0;
	}
	Type parsePrimitiveType() {
		with (TokenType)
		switch (token.kind) {
		case int_:
			nextToken();
			return new PrimitiveType(int_);
		case bool_:
			nextToken();
			return new PrimitiveType(bool_);
		case lparen:
			nextToken();
			auto t0 = parseType();
			check(TokenType.rparen);
			return t0;
		default:
			writeln("A type expected, not ", token.str);
			is_error = true;
			nextToken();
			return null;
		}
	}
}
