package tscript.lexer;

enum TokenKind {
    EOF;
    Identifier;
    IntLiteral;
    FloatLiteral;
    StringLiteral;

    // Keywords
    Let;
    Var;
    Const;
    Function;
    Return;
    If;
    Else;
    While;
    For;
    Break;
    Continue;
    True;
    False;
    Null;
    Import;
    Export;
    From;
    As;
    Class;
    Extends;
    New;
    This;
    Try;
    Catch;
    Throw;
    Async;
    Await;

    // Delimiters
    LeftParen;
    RightParen;
    LeftBrace;
    RightBrace;
    LeftBracket;
    RightBracket;
    Comma;
    Dot;
    Colon;
    Semicolon;
    Question;

    // Operators
    Plus;
    Minus;
    Star;
    Slash;
    Percent;
    Bang;
    Equal;
    Less;
    Greater;
    PlusPlus;
    MinusMinus;
    PlusEqual;
    MinusEqual;
    StarEqual;
    SlashEqual;
    EqualEqual;
    BangEqual;
    StrictEqual;
    StrictNotEqual;
    LessEqual;
    GreaterEqual;
    AndAnd;
    OrOr;
    NullCoalesce;
    Arrow;
}
