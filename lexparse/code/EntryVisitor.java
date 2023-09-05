public class EntryVisitor extends SimpleLangBaseVisitor<Boolean> {

    Boolean found = false;

    public Boolean visitProject(SimpleLangParser.ProjectContext ctx) {
        visitChildren(ctx);
        if (!found) {
            System.out.println("Valid entry() function not found");
        }
        return found;
    }

    public Boolean visitMethodDecl(SimpleLangParser.MethodDeclContext ctx) {
        found |= ctx.IDENT().getText().equals("entry")
                        && ctx.VOID() != null
                        && ctx.formPars() == null;
        return visitChildren(ctx);
    }

}
