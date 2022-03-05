module doge.ast;
import std.algorithm;
import std.array;
import std.conv;
import std.traits;

string[] strs(Args...)(Args args)
{
    string[] ret;
    static foreach (arg; args)
    {
        static if (is(typeof(arg) == string))
        {
            ret ~= arg;
        }
        else static if (isArray!(typeof(arg)))
        {
  foreach (subarg; arg)
            {
                ret ~= strs(subarg);
            }
        }
        else
        {
            ret ~= arg.to!string;
        }
    }
    return ret;
}

string joins(Args...)(string sep, Args args)
{
    string ret;
    foreach (index, arg; args.strs)
    {
        if (index != 0)
        {
            ret ~= sep;
        }
        ret ~= arg;
    }
    return ret;
}

string indent(size_t count = 4)(string src)
{
    string ret;
    foreach (chr; src)
    {
        ret ~= chr;
        if (chr == '\n')
        {
            foreach (i; 0 .. count)
            {
                ret ~= ' ';
            }
        }
    }
    return ret;
}

struct Location
{
    size_t line;
    size_t column;
}


struct Pragma
{
    string[] args;

    this(Args...)(Args params)
    {
        static foreach (arg; params)
        {
            args ~= arg;
        }
    }

    string toString()
    {
        return "%" ~ " ".joins(args);
    }
}
struct Rule
{
    alias Input = string;
    alias Output = string;
    Input input;
    Output output;

    this(Input i, Output o)
    {
        input = i;
        output = o;
    }

    string toString()
    {
        return " ".joins(input, output);
    }
}

struct RuleSet
{
    string name;
    Pragma[] pragmas;
    Rule[] rules;
    string[] nextRules;

    this(string n)
    {
        name = n;
    }

    string toString()
    {
        return " ".joins("rule", name, ":", nextRules, "\n".joins("{", pragmas, rules).indent, "\n}");
    }
}


struct Program 
{
    Pragma[] pragmas;
    RuleSet[string] ruleSets;

    this(Pragma[] p)
    {
        pragmas = p;
    }

    void set(string name, RuleSet value)
    {
        ruleSets[name] = value;
    }

    RuleSet get(string name)
    {
        if (name !in ruleSets)
        {
            throw new Exception("no such rule set: " ~ name);
        }
        return ruleSets[name];
    }

    string toString()
    {
        return "\n".joins(pragmas, ruleSets.values.map!(x => "\n" ~ x.to!string).array);
    }
}
