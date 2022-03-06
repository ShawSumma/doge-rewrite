module doge.walk;
import std.stdio;
import std.algorithm;
import std.array;
import doge.ast;

// TODO: generate dag

/// function that takes a stirng and returns nothing
alias Thunk = void delegate(Match val);

/// hashmap with no values
alias StringSet = typeof(null)[string];

/// a replacment
struct Match
{
    bool isStart;
    bool isFirst;
    string inputString;
    string outputString;
    string ruleName;
    string ruleInput;
    string ruleOutput;
}

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
        size_t head = 0;
        // cache the thens, this may not matter
        Thunk[] thens = then[rs.name];
        StringSet* set = rs.name in done; 
        foreach (src; todo)
        {
            if (src in *set)
            {
                continue;
            }
            (*set)[src] = null;
            Match match = Match(true, true, null, src, rs.name, null, null);
            foreach (func; thens)
            {
                func(match);
            }
        }
        while (todo.length > head)
        {
            // TODO: optimize this, it is memory intensive
            string src = todo[head++];
            // we found a new string, call our callbacks
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
                    scope(exit) index += 1;
                    size_t next = index;
                    foreach (chr; rule.input)
                    {
                        if (chr != src[next++])
                        {
                            continue small;
                        }
                    }
                    // our new string
                    string nextStr = src[0..index] ~ rule.output ~ src[index+rule.input.length..$];
                    if (nextStr in *set)
                    {
                        Match match = Match(false, false, src, nextStr, rs.name, rule.input, rule.output); 
                        foreach (func; thens)
                        {
                            func(match);
                        }
                    }
                    else
                    {
                        (*set)[nextStr] = null;
                        Match match = Match(false, true, src, nextStr, rs.name, rule.input, rule.output); 
                        foreach (func; thens)
                        {
                            func(match);
                        }
                        todo ~= nextStr;
                    }
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
