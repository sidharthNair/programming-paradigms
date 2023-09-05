import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;
import java.nio.file.Path;
import java.nio.file.FileSystems;
import java.io.IOException;

public class Main {

    public static void main(String[] args) throws IOException {
        Path path = FileSystems.getDefault().getPath(args[0]);
        SimpleLangLexer lexer = new SimpleLangLexer(CharStreams.fromPath(path));
        SimpleLangParser parser = new SimpleLangParser(new CommonTokenStream(lexer));
        LexErrorListener lexerErrorListener = new LexErrorListener();
        ParserErrorListener parserErrorListener = new ParserErrorListener();
        lexer.addErrorListener(lexerErrorListener);
        parser.addErrorListener(parserErrorListener);
        ParseTree tree = parser.project();

        UndeclaredVisitor undeclaredVisitor = new UndeclaredVisitor();
        undeclaredVisitor.visit(tree);
        if (undeclaredVisitor.foundUndeclared) {
            System.out.println("NAME USE ERROR");
        }

        EntryVisitor entryVisitor = new EntryVisitor();
        boolean foundEntry = entryVisitor.visit(tree);
        if (!foundEntry) {
            System.out.println("ENTRY ERROR");
        }
    }
}

class LexErrorListener extends BaseErrorListener {
    @Override
    public void syntaxError(Recognizer<?, ?> recognizer, Object offendingSymbol, int line, int charPositionInLine, String msg, RecognitionException e) {
        System.out.println("LEX ERROR");
        System.exit(1);
    }
}

class ParserErrorListener extends BaseErrorListener {
    @Override
    public void syntaxError(Recognizer<?, ?> recognizer, Object offendingSymbol, int line, int charPositionInLine, String msg, RecognitionException e) {
        System.out.println("PARSER ERROR");
        System.exit(2);
    }
}
