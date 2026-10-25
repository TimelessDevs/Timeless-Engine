package tscript.lexer;

import tscript.lexer.TokenKind.*;

/** Tokenizes TScript source. It has no dependency on the game engine. */
class TScriptLexer {
    final source:String;
    final tokens:Array<Token> = [];
    var start:Int = 0;
    var current:Int = 0;
    var line:Int = 1;
    var column:Int = 1;
    var startLine:Int = 1;
    var startColumn:Int = 1;

    static final keywords:Map<String, TokenKind> = [
        "let" => Let, "var" => Var, "const" => Const, "function" => Function,
        "return" => Return, "if" => If, "else" => Else,
        "while" => While, "for" => For, "break" => Break,
        "continue" => Continue, "true" => True, "false" => False,
        "null" => Null, "import" => Import, "export" => Export,
        "from" => From, "as" => As, "class" => Class,
        "extends" => Extends, "new" => New, "this" => This,
        "try" => Try, "catch" => Catch, "throw" => Throw,
        "async" => Async, "await" => Await
    ];

    public function new(source:String) {
        this.source = source == null ? "" : source;
    }

    public function scanTokens():Array<Token> {
        while (!isAtEnd()) {
            start = current;
            startLine = line;
            startColumn = column;
            scanToken();
        }
        tokens.push(new Token(EOF, "", line, column, current));
        return tokens;
    }

    function scanToken():Void {
        var c = advance();
        switch (c) {
            case " ", "\r", "\t":
            case "\n":
            case "(": add(LeftParen);
            case ")": add(RightParen);
            case "{": add(LeftBrace);
            case "}": add(RightBrace);
            case "[": add(LeftBracket);
            case "]": add(RightBracket);
            case ",": add(Comma);
            case ".": add(Dot);
            case ":": add(Colon);
            case ";": add(Semicolon);
            case "?": add(match("?") ? NullCoalesce : Question);
            case "+": add(match("+") ? PlusPlus : match("=") ? PlusEqual : Plus);
            case "-": add(match("-") ? MinusMinus : match("=") ? MinusEqual : match(">") ? Arrow : Minus);
            case "*": add(match("=") ? StarEqual : Star);
            case "%": add(Percent);
            case "!":
                if (match("=")) add(match("=") ? StrictNotEqual : BangEqual); else add(Bang);
            case "=":
                if (match("=")) add(match("=") ? StrictEqual : EqualEqual); else add(Equal);
            case "<": add(match("=") ? LessEqual : Less);
            case ">": add(match("=") ? GreaterEqual : Greater);
            case "&": if (match("&")) add(AndAnd); else fail("Expected '&' after '&'.");
            case "|": if (match("|")) add(OrOr); else fail("Expected '|' after '|'.");
            case "/":
                if (match("/")) {
                    while (peek() != "\n" && !isAtEnd()) advance();
                } else if (match("*")) {
                    blockComment();
                } else if (match("=")) add(SlashEqual); else add(Slash);
            case '"', "'": string(c);
            default:
                if (isDigit(c)) number();
                else if (isAlpha(c)) identifier();
                else fail('Unexpected character "$c".');
        }
    }

    function blockComment():Void {
        while (!isAtEnd()) {
            if (peek() == "*" && peekNext() == "/") {
                advance(); advance();
                return;
            }
            advance();
        }
        fail("Unterminated block comment.");
    }

    function string(quote:String):Void {
        var out = new StringBuf();
        while (!isAtEnd() && peek() != quote) {
            var c = advance();
            if (c == "\\") {
                if (isAtEnd()) fail("Unterminated escape sequence.");
                switch (advance()) {
                    case "n": out.add("\n");
                    case "r": out.add("\r");
                    case "t": out.add("\t");
                    case "\\": out.add("\\");
                    case "\"": out.add('"');
                    case "'": out.add("'");
                    default: fail("Unsupported escape sequence.");
                }
            } else out.add(c);
        }
        if (isAtEnd()) fail("Unterminated string literal.");
        advance(); // closing quote
        add(StringLiteral, out.toString());
    }

    function number():Void {
        while (isDigit(peek())) advance();
        var isFloat = false;
        if (peek() == "." && isDigit(peekNext())) {
            isFloat = true;
            advance();
            while (isDigit(peek())) advance();
        }
        var text = source.substring(start, current);
        add(isFloat ? FloatLiteral : IntLiteral, isFloat ? Std.parseFloat(text) : Std.parseInt(text));
    }

    function identifier():Void {
        while (isAlphaNumeric(peek())) advance();
        var text = source.substring(start, current);
        var kind = keywords.get(text);
        add(kind == null ? Identifier : kind);
    }

    inline function add(kind:TokenKind, ?literal:Dynamic):Void
        tokens.push(new Token(kind, source.substring(start, current), startLine, startColumn, start, literal));

    function advance():String {
        var c = source.charAt(current++);
        if (c == "\n") { line++; column = 1; } else column++;
        return c;
    }

    inline function match(expected:String):Bool {
        if (isAtEnd() || source.charAt(current) != expected) return false;
        advance();
        return true;
    }
    inline function peek():String return isAtEnd() ? "\u0000" : source.charAt(current);
    inline function peekNext():String return current + 1 >= source.length ? "\u0000" : source.charAt(current + 1);
    inline function isAtEnd():Bool return current >= source.length;
    inline function isDigit(c:String):Bool return c >= "0" && c <= "9";
    inline function isAlpha(c:String):Bool return (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c == "_" || c == "$";
    inline function isAlphaNumeric(c:String):Bool return isAlpha(c) || isDigit(c);

    function fail(message:String):Void
        throw new LexerError(message, startLine, startColumn);
}
