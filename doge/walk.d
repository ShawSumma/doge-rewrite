module doge.walk;
import std.stdio;
import std.algorithm;
import std.array;
import doge.ast;

alias Thunk = void delegate(string val);

class Executor
{
    Thunk[][string] then;
    Program prog;
    typeof(null)[string][string] done;

    this(Program prog, Thunk[string] funcs)
    {
        this.prog = prog;
        foreach (rules; prog.ruleSets)
        {
            done[rules.name] = null;
            then[rules.name] = null;
            foreach (prag; rules.pragmas)
            {
                if (prag.args.length >= 2 && prag.args[0] == "run")
                {
                    foreach (arg; prag.args[1 .. $])
                    {
                        then[rules.name] ~= funcs[arg];
                    }
                }
            }
        }
    }

    void walk(RuleSet rs, string arg)
    {
        string[] todo = [arg];
        typeof(null)[string] done;
        Thunk[] thens = then[rs.name];
        while (todo.length != 0)
        {
            string src = todo[0];
            todo = todo[1..$];
            if (src in done)
            {
                continue;
            }
            done[src] = null;
            foreach (func; thens)
            {
                func(src);
            }
            big: foreach (rule; rs.rules)
            {
                size_t index = 0;
                if (rule.input.length > src.length)
                {
                    continue;
                }
                size_t max = src.length + 1 - rule.input.length;
                small: while (index < max)
                {
                    size_t next = index;
                    foreach (chr; rule.input)
                    {
                        if (chr != src[next++])
                        {
                            index += 1;
                            continue small;
                        }
                    }
                    todo ~= src[0..index] ~ rule.output ~ src[index+rule.input.length..$];
                    continue big;
                }
            }
            foreach (rule; rs.nextRules)
            {
                walk(prog.get(rule), src);
            }
        }
    }

    void walk(string src)
    {
        RuleSet rs = prog.get("start");
        walk(rs, src);
    }
}
