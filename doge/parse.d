module doge.parse;
import std.stdio;
import doge.ast;

class Parser
{
    string src;
    Location loc;

    this(string txt)
    {
        src = txt;
        loc = Location(1, 1);
    }

    bool done()
    {
        return src.length == 0;
    }

    char peek()
    {
        assert(!done);
        return src[0];
    }

    void skip()
    {
        if (peek == '\n')
        {
            loc.line += 1;
            loc.column = 1;
        }
        else
        {
            loc.column += 1;
        }
        src = src[1 .. $];
    }

    char read()
    {
        char ret = peek;
        skip;
        return ret;
    }

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

    void skipLine()
    {
        while (!done && (match(' ') || match('\n') || match('\t')))
        {
        }
    }

    void skipSpace()
    {
        while (!done && (match(' ') || match('\t')))
        {

        }
    }

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

    Rule[] readRule()
    {
        Rule[] ret;
        string s1 = readWord;
        string op = readWord;
        string s2 = readWord;
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

    RuleSet readRuleBody(string name)
    {
        RuleSet ret = RuleSet(name);
        skipSpace;
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
        if (!match('{'))
        {
            throw new Exception("expected `{` not `" ~ peek ~ "`");
        }
        ret.pragmas = readPragmas();
        skipLine;
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

    Program readProgram()
    {
        Pragma[] pragmas = readPragmas();
        Program ret = Program(pragmas);
        while (!done)
        {
            skipLine;
            string word = readWord();
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
