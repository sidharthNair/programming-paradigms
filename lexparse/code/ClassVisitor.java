import org.antlr.v4.runtime.*;
import java.util.Stack;
import java.util.HashMap;
import java.util.HashSet;

public class ClassVisitor extends SimpleLangBaseVisitor<Object> {

    private Stack<String> stack = new Stack<String>();

    HashMap<String, HashSet<String>> classInterfaces = new HashMap<String, HashSet<String>>();
    HashMap<String, HashSet<String>> classMethods = new HashMap<String, HashSet<String>>();
    HashMap<String, HashSet<String>> interfaceMethods = new HashMap<String, HashSet<String>>();
    boolean error = false;

    public Object visitProject(SimpleLangParser.ProjectContext ctx) {
        Object result = visitChildren(ctx);
        for (String c : classInterfaces.keySet()) {
            for (String i : classInterfaces.get(c)) {
                if (!classMethods.get(c).containsAll(interfaceMethods.get(i))) {
                    error = true;
                    System.out.println("Class " + c + " does not implement all methods of interface " + i);
                    HashSet<String> tmp = new HashSet<String>(interfaceMethods.get(i));
                    tmp.removeAll(classMethods.get(c));
                    System.out.println("\tMissing methods: " + tmp);
                }
            }
        }
        return result;
    }

    public Object visitClassDecl(SimpleLangParser.ClassDeclContext ctx) {
        String className = ctx.IDENT().getText();
        classInterfaces.put(className, new HashSet<String>());
        classMethods.put(className, new HashSet<String>());
        for (int i = (ctx.EXTENDS() == null ? 0 : 1); i < ctx.type().size(); i++) {
            classInterfaces.get(className).add(ctx.type(i).IDENT().getText());
        }
        stack.push(className);
        Object result = visitChildren(ctx);
        stack.pop();
        return result;
    }

    public Object visitMethodDecl(SimpleLangParser.MethodDeclContext ctx) {
        String className = stack.empty() ? null : stack.peek();
        if (className != null) {
            String returnType = (ctx.type() == null ? "void" : ctx.type().IDENT().getText());
            String methodName = ctx.IDENT().getText();
            String parameters = "(";
            if (ctx.formPars() != null) {
                for (SimpleLangParser.ParameterContext pctx : ctx.formPars().parameter()) {
                    parameters += pctx.type().getText() + (isArray((ParserRuleContext) pctx) ? "[]" : "") + ", ";
                }
                parameters = parameters.substring(0, parameters.length() - 2) + ")";
            } else {
                parameters += ")";
            }
            classMethods.get(className).add(returnType + " " + methodName + parameters);
        }
        return visitChildren(ctx);
    }

    public Object visitInterfaceDecl(SimpleLangParser.InterfaceDeclContext ctx) {
        interfaceMethods.put(ctx.IDENT().getText(), new HashSet<String>());
        return visitChildren(ctx);
    }

    public Object visitInterfaceMethodDecl(SimpleLangParser.InterfaceMethodDeclContext ctx) {
        String interfaceName = ((SimpleLangParser.InterfaceDeclContext) ctx.getParent()).IDENT().getText();
        String returnType = (ctx.type() == null ? "void" : ctx.type().IDENT().getText());
        String methodName = ctx.IDENT().getText();
        String parameters = "(";
        if (ctx.formPars() != null) {
            for (SimpleLangParser.ParameterContext pctx : ctx.formPars().parameter()) {
                parameters += pctx.type().getText() + (isArray((ParserRuleContext) pctx) ? "[]" : "") + ", ";
            }
            parameters = parameters.substring(0, parameters.length() - 2) + ")";
        } else {
            parameters += ")";
        }
        interfaceMethods.get(interfaceName).add(returnType + " " + methodName + parameters);
        return visitChildren(ctx);
    }

    public boolean isArray(ParserRuleContext ctx) {
        return ctx.getStop().getText().equals("]");
    }
}
