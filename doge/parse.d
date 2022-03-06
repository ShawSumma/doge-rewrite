module doge.parse;
import std.stdio;
import doge.ast;

// TODO: line numbers in error messages in parser
/// single string parser, constructed once per program
class Parser
{
    /// the source from the current position onwards
    string src;
    /// the location of src[0]
    Location loc;

    // TODO: support filenames in errors
    /// construct a parser from a string
    this(string txt)
    {
        src = txt;
        loc = Location(1, 1);
    }

    /// have we run out of input
    bool done()
    {
        return src.length == 0;
    }

    /// the first character not used
    /// does not return '\0' on end of input
    char peek()
    {
        assert(!done);
        return src[0];
    }

    /// skip the first character
    /// shifts source location to reflect this change
    void skip()
    {
        // TODO: think about '\r' and '\t'
        if (peek == '\n')
        {
            loc.line += 1;
            loc.column = 1;
        }
        else
        {
            loc.column += 1;
        }
        // when in an index $ means the length
        // so thing[1 .. $] means thing[1 .. thing.length]
        // this just pops a char from the front
        // basically a ptr++, length--; 
        src = src[1 .. $];
    }

    /// read a char, skip it
    char read()
    {
        char ret = peek;
        skip;
        return ret;
    }

    /// if the next char matches ch then read it
    /// returns weather it matched
    bool match(char ch)
    {
        if (peek == ch)
        {
            skip;
            return true;
        }
        else
        {
            return false;
        }
    }

    /// skip whitespace until the end of file or a non space char
    /// consumes newlines as well as spaces and tabs
    void skipLine()
    {
        // TODO: use a better check for spaces, this wont work for '\r'
        while (!done && (match(' ') || match('\n') || match('\t')))
        {
        }
    }

    /// skip spaces and tabs until the next char is not one
    void skipSpace()
    {
        while (!done && (match(' ') || match('\t')))
        {

        }
    }
    
    /// reads the next word 
    /// words are defined as anything that is not a space tab or newline
    string readWord()
    {
        skipSpace;
        string ret;
        while (!done && peek != ' ' && peek != '\n' && peek != '\t')
        {
            ret ~= read;
        }
        return ret;
    }

    /// reads a pragma until newline
    /// skip the percent BEFORE calling this
    Pragma readPragma()
    {
        string[] words;
        skipLine;
        while (!done && peek != '\n')
        {
            words ~= readWord;
            skipSpace;
        }
        skipLine;
        return Pragma(words);
    }

    // TODO: support pragmas after rulesets or rules 
    /// read pragmas all in a row
    /// this only reads at the top of a file or block
    Pragma[] readPragmas()
    {
        Pragma[] ret;
        skipLine;
        while (!done && match('%'))
        {
            ret ~= readPragma;
        }
        skipLine;
        return ret;
    }

    /// read a single rule from 
    /// the array is for if <-> or <=> is used as they are actually two rules
    Rule[] readRule()
    {
        Rule[] ret;
        string s1 = readWord;
        string op = readWord;
        string s2 = readWord;
        // you need to put spaces arround the rule input and output
        // TODO: support "x"->"y" style escaping
        switch (op)
        {
        default:
            throw new Exception("invalid op: " ~ op);
        case "=>":
        case "->":
            ret ~= Rule(s1, s2);
            break;
        case "<=>":
        case "<->":
            ret ~= Rule(s1, s2);
            ret ~= Rule(s2, s1);
            break;
        }
        return ret;
    }

    // TODO: make this not take a name, will require work in ast
    /// reads a ruleset
    /// the word rule and its name should have been already skiped here
    /// needs a name for the RuleSet constructor
    RuleSet readRuleBody(string name)
    {
        RuleSet ret = RuleSet(name);
        skipSpace;
        // if we have colon we read the next rules
        if (match(':'))
        {
            while (peek != '{')
            {
                skipSpace;
                ret.nextRules ~= readWord;
                skipSpace;
                if (done)
                {
                    throw new Exception("expected `{` before end of file");
                }
            }
        }
        // no need to skipSpace here
        // colon or not there should be a curly brace here
        if (!match('{'))
        {
            throw new Exception("expected `{` not `" ~ peek ~ "`");
        }
        // pragmas first
        ret.pragmas = readPragmas();
        skipLine;
        // rules next
        while (peek != '}')
        {
            if (done)
            {
                throw new Exception("unexpected end of file");
            }
            skipLine;
            ret.rules ~= readRule;
            skipLine;
        }
        skip;
        return ret;
    }

    /// read a whole progrea
    Program readProgram()
    {
        // pragmas first
        Pragma[] pragmas = readPragmas();
        Program ret = Program(pragmas);
        // read until we have no more to read
        while (!done)
        {
            skipLine;
            string word = readWord();
            // TODO: add different things to rules
            // this allows for more types of statments than just rule
            switch (word)
            {
            case "rule":
                string ident = readWord;
                ret.ruleSets[ident] = readRuleBody(ident);
                break;
            default:
                throw new Exception("unependent word `" ~ word ~ "` at toplevel");
            }
            skipLine;
        }
        return ret;
    }
}
