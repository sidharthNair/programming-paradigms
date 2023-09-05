import org.antlr.v4.runtime.*;
import java.util.Stack;

public class UndeclaredVisitor extends SimpleLangBaseVisitor<Object> {

    private ScopeNode root;
    private Stack<ScopeNode> stack;
    boolean foundUndeclared = false;

    public Object visitProject(SimpleLangParser.ProjectContext ctx) {
        root = new ScopeNode(ctx.PROJECT().getText());
        stack = new Stack<ScopeNode>();
        stack.push(root);
        Object result = visitChildren(ctx);
        stack.pop();
        // if (!foundUndeclared) {
        //     root.printScopeTree("");
        // }
        return result;
    }

    public Object visitConstSet(SimpleLangParser.ConstSetContext ctx) {
        ScopeNode curr = stack.peek();
        String type = ((SimpleLangParser.ConstDeclContext) ctx.getParent()).type().getText();
        if (curr.checkDeclared(type, IdentifierType.DECL_TYPE) == null) {
            error(type);
        }
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
        String type = ((SimpleLangParser.VarDeclContext) ctx.getParent()).type().getText();
        if (curr.checkDeclared(type, IdentifierType.DECL_TYPE) == null) {
            error(type);
        }
        curr.addSymbol(ctx.IDENT().getText(), type + (isArray(ctx) ? "[]" : ""));
        return visitChildren(ctx);
    }

    public Object visitClassDecl(SimpleLangParser.ClassDeclContext ctx) {
        ScopeNode curr = stack.peek();
        int typeIndex = 0;
        String parent = null;
        if (ctx.EXTENDS() != null) {
            parent = ctx.type(typeIndex++).IDENT().getText();
            if (curr.checkDeclared(parent, IdentifierType.EXTENDS) == null) {
                error(parent);
            }
        }
        for (int i = typeIndex; i < ctx.type().size(); i++) {
            String iface = ctx.type(i).IDENT().getText();
            if (curr.checkDeclared(iface, IdentifierType.IMPLEMENTS) == null) {
                error(iface);
            }
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
        if (curr.checkDeclared(returnType, IdentifierType.RETURN_TYPE) == null) {
            error(returnType);
        }
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
        if (curr.checkDeclared(returnType, IdentifierType.RETURN_TYPE) == null) {
            error(returnType);
        }
        String methodName = ctx.IDENT().getText();
        curr.addSymbol(methodName, "_method");
        stack.push(curr.newChildScope(methodName));
        Object result = visitChildren(ctx);
        stack.pop();
        return result;
    }

    public Object visitParameter(SimpleLangParser.ParameterContext ctx) {
        ScopeNode curr = stack.peek();
        String type = ctx.type().getText();
        if (curr.checkDeclared(type, IdentifierType.DECL_TYPE) == null) {
            error(type);
        }
        curr.addSymbol(ctx.IDENT().getText(), type + (isArray((ParserRuleContext) ctx) ? "[]" : ""));
        return visitChildren(ctx);
    }

    public Object visitDesignator(SimpleLangParser.DesignatorContext ctx) {
        ScopeNode curr = stack.peek();
        String token = ctx.IDENT(0).getText();
        String next;
        if (ctx.getChildCount() == 1) {
            ScopeNode found = curr.checkDeclared(token, IdentifierType.SINGLE);
            if (found == null) {
                error(token);
            }
        } else {
            for (int i = 1; i < ctx.getChildCount(); i++) {
                next = ctx.getChild(i).getText();
                if (next.equals(".")) {
                    next = ctx.getChild(++i).getText();
                    curr = curr.checkDeclared(token + "." + next, IdentifierType.DOT);
                    if (curr == null) {
                        error(token + "." + next);
                    }
                    token = next;
                } else {
                    curr = curr.checkDeclared(token, IdentifierType.ARRAY_INDEX);
                    if (curr == null) {
                        error(token + "[EXPR]");
                    }
                    i += 3;
                }

            }
        }
        return visitChildren(ctx);
    }

    public void error(String var) {
        System.out.println("Found undeclared reference: " + var);
        root.printScopeTree("\t");
        foundUndeclared = true;
    }

    public boolean isArray(ParserRuleContext ctx) {
        return ctx.getStop().getText().equals("]");
    }
}
