package tscript.lexer;

class LexerError extends haxe.Exception {
    public final line:Int;
    public final column:Int;

    public function new(message:String, line:Int, column:Int) {
        this.line = line;
        this.column = column;
        super('TScript $line:$column: $message');
    }
}
