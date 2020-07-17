import std.stdio;
import check, defs, parse;

void main()
{
	while (true) {
		auto str = readln;
		if (str.length < 2) break;
		
		// parse
		auto parser = new Parser(str);
		auto ast = parser.parse();
		if (parser.is_error || !ast) { writeln("parse failed"); continue; }
		
		// type check
		auto type_checker = new TypeChecker;
		ast.accept(type_checker);
		
		if (ast.type && !type_checker.is_error) { writeln("Well typed: ", type_to_string(ast.type)); }
	}
}
