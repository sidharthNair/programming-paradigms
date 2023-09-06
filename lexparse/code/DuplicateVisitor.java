import org.antlr.v4.runtime.*;
import java.util.Stack;

public class DuplicateVisitor extends SimpleLangBaseVisitor<Object> {

    private ScopeNode root;
    private Stack<ScopeNode> stack;
    boolean foundDuplicate = false;

    public Object visitProject(SimpleLangParser.ProjectContext ctx) {
        root = new ScopeNode(ctx.PROJECT().getText());
        stack = new Stack<ScopeNode>();
        stack.push(root);
        Object result = visitChildren(ctx);
        stack.pop();
        return result;
    }

    public Object visitConstSet(SimpleLangParser.ConstSetContext ctx) {
        ScopeNode curr = stack.peek();
        String type = ((SimpleLangParser.ConstDeclContext) ctx.getParent()).type().getText();
        curr.addSymbol(ctx.IDENT().getText(), type);
        return visitChildren(ctx);
    }

    public Object visitEnumDecl(SimpleLangParser.EnumDeclContext ctx) {
        ScopeNode curr = stack.peek();
        curr.addSymbol(ctx.IDENT().getText(), "_enum");
        return visitChildren(ctx);
    }

    public Object visitEnumSet(SimpleLangParser.EnumSetContext ctx) {
        ScopeNode curr = stack.peek();
        curr.addSymbol(ctx.IDENT().getText(), "_enum_val");
        return visitChildren(ctx);
    }

    public Object visitVarSet(SimpleLangParser.VarSetContext ctx) {
        ScopeNode curr = stack.peek();
        String name = ctx.IDENT().getText();
        if (curr.checkDeclared(name, IdentifierType.VAR_NAME) != null) {
            error(name, curr.scopeName);
        }
        String type = ((SimpleLangParser.VarDeclContext) ctx.getParent()).type().getText();
        curr.addSymbol(ctx.IDENT().getText(), type + (isArray(ctx) ? "[]" : ""));
        return visitChildren(ctx);
    }

    public Object visitClassDecl(SimpleLangParser.ClassDeclContext ctx) {
        ScopeNode curr = stack.peek();
        int typeIndex = 0;
        String parent = null;
        if (ctx.EXTENDS() != null) {
            parent = ctx.type(typeIndex++).IDENT().getText();
        }
        String className = ctx.IDENT().getText();
        curr.addSymbol(className, "_class");
        ScopeNode classScope = curr.newChildScope(className, parent);
        stack.push(classScope);
        Object result = visitChildren(ctx);
        stack.pop();
        return result;
    }

    public Object visitInterfaceDecl(SimpleLangParser.InterfaceDeclContext ctx) {
        ScopeNode curr = stack.peek();
        String ifaceName = ctx.IDENT().getText();
        curr.addSymbol(ifaceName, "_interface");
        stack.push(curr.newChildScope(ifaceName));
        Object result = visitChildren(ctx);
        stack.pop();
        return result;
    }

    public Object visitInterfaceMethodDecl(SimpleLangParser.InterfaceMethodDeclContext ctx) {
        ScopeNode curr = stack.peek();
        String returnType = (ctx.type() == null ? "void" : ctx.type().IDENT().getText());
        String ifaceMethodName = ctx.IDENT().getText();
        curr.addSymbol(ifaceMethodName, "_interface_method");
        stack.push(curr.newChildScope(ifaceMethodName));
        Object result = visitChildren(ctx);
        stack.pop();
        return result;
    }

    public Object visitMethodDecl(SimpleLangParser.MethodDeclContext ctx) {
        ScopeNode curr = stack.peek();
        String returnType = (ctx.type() == null ? "void" : ctx.type().IDENT().getText());
        String methodName = ctx.IDENT().getText();
        curr.addSymbol(methodName, "_method");
        stack.push(curr.newChildScope(methodName));
        Object result = visitChildren(ctx);
        stack.pop();
        return result;
    }

    public Object visitParameter(SimpleLangParser.ParameterContext ctx) {
        ScopeNode curr = stack.peek();
        String name = ctx.IDENT().getText();
        if (curr.checkDeclared(name, IdentifierType.VAR_NAME) != null) {
            error(name, curr.scopeName);
        }
        String type = ctx.type().getText();
        curr.addSymbol(ctx.IDENT().getText(), type + (isArray((ParserRuleContext) ctx) ? "[]" : ""));
        return visitChildren(ctx);
    }

    public void error(String var, String scope) {
        System.out.println("Found duplicate variable name '" + var + "' in scope '" + scope + "'");
        root.printScopeTree("  ");
        foundDuplicate = true;
    }

    public boolean isArray(ParserRuleContext ctx) {
        return ctx.getStop().getText().equals("]");
    }
}
