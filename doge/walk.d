module doge.walk;
import std.stdio;
import std.algorithm;
import std.array;
import doge.ast;

// TODO: generate dag

/// function that takes a stirng and returns nothing
alias Thunk = void delegate(string val);

/// hashmap with no values
alias StringSet = typeof(null)[string];

/// this is oop sadness
class Executor
{
    /// the functions to run upon a new string, per rule
    Thunk[][string] then;
    /// the program itself, in whole
    Program prog;
    /// things we have already done
    StringSet[string] done;

    /// construct an executor from a program and a hashmap of funcs
    this(Program prog, Thunk[string] funcs)
    {
        this.prog = prog;
        // build done and then tables
        foreach (rules; prog.ruleSets)
        {
            // start by clearing the done
            // nothing is done by default
            done[rules.name] = null;
            // clear then
            then[rules.name] = null;
            // build then
            foreach (prag; rules.pragmas)
            {
                // is it a %run word+
                if (prag.args.length >= 2 && prag.args[0] == "run")
                {
                    foreach (arg; prag.args[1 .. $])
                    {
                        // lookup what func to use
                        then[rules.name] ~= funcs[arg];
                    }
                }
            }
        }
    }

    /// walk a ruleset for any given string
    void walk(RuleSet rs, string[] todo)
    {
        // cache the thens, this may not matter
        Thunk[] thens = then[rs.name];
        StringSet* set = rs.name in done; 
        while (todo.length != 0)
        {
            // TODO: optimize this, it is memory intensive
            string src = todo[0];
            // pop the front of todo
            // the $ is the length of todo here
            todo = todo[1..$];
            // if we already are processing this string, dont redo
            if (src in *set)
            {
                continue;
            }
            // add it to the processing strings for this rule
            (*set)[src] = null;
            // we found a new string, call our callbacks
            foreach (func; thens)
            {
                func(src);
            }
            bool first = true;
            // for all rules, run them on the string
            foreach (rule; rs.rules)
            {
                size_t index = 0;
                // it is too long for our input
                if (rule.input.length > src.length)
                {
                    continue;
                }
                // stop before we bounds error
                size_t max = src.length + 1 - rule.input.length;
                small: while (index < max)
                {
                    size_t next = index;
                    foreach (chr; rule.input)
                    {
                        if (chr != src[next++])
                        {
                            // we did not find it, carry on
                            index += 1;
                            continue small;
                        }
                    }
                    // our new string
                    todo ~= src[0..index] ~ rule.output ~ src[index+rule.input.length..$];
                    index += 1;
                }
            }
            // run all the next rules
            foreach (rule; rs.nextRules)
            {
                walk(prog.get(rule), [src]);
            }
        }
    }

    /// walk the rule "start"
    void walk(string src)
    {
        RuleSet rs = prog.get("start");
        walk(rs, [src]);
    }
}
