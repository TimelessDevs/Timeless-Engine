package tscript.lexer;

class Token {
    public final kind:TokenKind;
    public final lexeme:String;
    public final line:Int;
    public final column:Int;
    public final offset:Int;
    public final literal:Dynamic;

    public function new(kind:TokenKind, lexeme:String, line:Int, column:Int, offset:Int, ?literal:Dynamic) {
        this.kind = kind;
        this.lexeme = lexeme;
        this.line = line;
        this.column = column;
        this.offset = offset;
        this.literal = literal;
    }

    public function toString():String
        return '${kind} "$lexeme" ($line:$column)';
}
