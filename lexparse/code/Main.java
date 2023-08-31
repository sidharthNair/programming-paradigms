import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTree;
import java.nio.file.Path;
import java.nio.file.FileSystems;

public class Main {

    public static void main(String[] args) throws Exception {
        Path path = FileSystems.getDefault().getPath(args[0]);
        SimpleLangLexer lexer = new SimpleLangLexer(CharStreams.fromPath(path));
        SimpleLangParser parser = new SimpleLangParser(new CommonTokenStream(lexer));
        ParseTree tree = parser.project();

        EntryVisitor visitor = new EntryVisitor();
        boolean foundEntry = visitor.visit(tree);
        if (!foundEntry) {
            System.out.println("ENTRY ERROR");
        }
    }
}
