import std.stdio;
import std.file;
import doge.ast;
import doge.parse;
import doge.walk;

void main(string[] args)
{
    if (args.length <= 2)
    {
        throw new Exception("not enough arguments");
    }
    string src = args[1].readText;
    Program prog = new Parser(src).readProgram;
    // writeln(prog);
    size_t n = 0;
    Executor executor = new Executor(prog, [
        "exec": (string src) {
            n += 1;
            // writeln("exec: ", src);
        },
    ]);
    executor.walk(args[2]);
    writeln(n);
}
