import std.stdio;
import std.file;
import doge.ast;
import doge.parse;
import doge.walk;

/// the entry point to our application
void main(string[] args)
{
    if (args.length <= 2)
    {
        // TODO: add a nice help message
        throw new Exception("not enough arguments");
    }
    // read the file
    string src = args[1].readText;
    // read parse the program
    Program prog = new Parser(src).readProgram;
    size_t n = 0;
    // oop moment, this is to avoid actual globals
    Executor executor = new Executor(prog, [
        // this is a delegate, it is like a function pointer
        // it that also holds variables inside it
        "count": delegate (string src) {
            n += 1;
        },
        "echo": delegate (string src) {
            writeln(src);
        },
    ]);
    executor.walk(args[2]);
    // TODO: think if we want to print this when zero
    if (n != 0)
    {
        writeln(n);
    }
}
