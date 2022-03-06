module doge.ast;
import std.algorithm;
import std.array;
import std.conv;
import std.traits;

/// takes some arguments and turns them recursivly into strings
string[] strs(Args...)(Args args)
{
    string[] ret;
    // loop over all arguments at compile time
    // they may be differnt types so static is needed
    static foreach (arg; args)
    {
        // if its already a string then just add it
        static if (is(typeof(arg) == string))
        {
            ret ~= arg;
        }
        // if it is an array of something
        // the only array this wont work for is const(char)[]
        // because that is a string
        else static if (isArray!(typeof(arg)))
        {
            // push all arguments strs, this works recursivly
            foreach (subarg; arg)
            {
                ret ~= strs(subarg);
            }
        }
        // if its not a string or other type of array
        else
        {
            // just add its to!string representation
            ret ~= arg.to!string;
        }
    }
    return ret;
}

// (Args...) means that this is a template
// (string sep, Args args) means that this takes a string
// followed by any number of anything
/// uses sep to join args
string joins(Args...)(string sep, Args args)
{
    string ret;
    // loop over all arguments in the string[]
    // returned by strs(args) aka args.strs
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

// indent a string by count spaces
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

// a location in source
// used in the parser to debug messages
struct Location
{
    /// y position
    size_t line;
    /// x position
    size_t column;
}

/// an array of strings
/// started with % and runs until a newline
struct Pragma
{
    // perhaps this should be split
    /// everything after the percent sign
    string[] args;

    // should probably convert this to check types of args
    /// construct a pragma from any number of arguments
    this(Args...)(Args params)
    {
        // this will loop over params
        // static foreach injects each line like the following
        // consider a case where params has 3 entries
        // this will give us:
        // args ~= params[0];
        // args ~= params[1];
        // args ~= params[2];
        static foreach (arg; params)
        {
            args ~= arg;
        }
    }

    /// convert a back to source, no newline included
    string toString()
    {
        return "%" ~ " ".joins(args);
    }
}

/// a rule is a definition of input and output
struct Rule
{
    /// can be changed to support variables
    alias Input = string;
    Input input;
    /// can be changed to support variables
    alias Output = string;
    Output output;

    /// construct a rule from an input and an output string
    this(Input i, Output o)
    {
        input = i;
        output = o;
    }

    /// join the rule by arrow
    /// Rule("hello", "world") will result in: "hello -> world"
    string toString()
    {
        return " -> ".joins(input, output);
    }
}

/// the body of the rule, between curly braces
struct RuleSet
{
    /// the name of the ruleset, follows rule immediatly
    string name;
    Pragma[] pragmas;
    Rule[] rules;
    /// what rules to run on each unique string
    string[] nextRules;

    /// construct a ruleset by name
    this(string n)
    {
        name = n;
    }

    /// pretty print the rulset
    string toString()
    {
        return " ".joins("rule", name, ":", nextRules, "\n".joins("{", pragmas, rules).indent, "\n}");
    }
}

/// whole program
struct Program 
{
    Pragma[] pragmas;
    /// rulesets are given by name here
    RuleSet[string] ruleSets;

    // TODO: add support for construction with no args
    /// construct a ruleset by pragmas
    this(Pragma[] p)
    {
        pragmas = p;
    }

    /// set a rule by name
    void set(string name, RuleSet value)
    {
        // TODO: check if ruleSets has name already
        ruleSets[name] = value;
    }

    /// get a rule by name
    /// throws if not found
    RuleSet get(string name)
    {
        /// make sure we dont bounds error
        if (name !in ruleSets)
        {
            throw new Exception("no such rule set: " ~ name);
        }
        return ruleSets[name];
    }

    /// pretty print the whole program
    string toString()
    {
        return "\n".joins(pragmas, ruleSets.values.map!(x => "\n" ~ x.to!string).array);
    }
}
