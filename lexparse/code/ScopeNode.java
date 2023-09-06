import java.util.Arrays;
import java.util.HashSet;
import java.util.HashMap;

enum IdentifierType {
    SINGLE,
    DOT,
    ARRAY_INDEX,
    EXTENDS,
    IMPLEMENTS,
    RETURN_TYPE,
    DECL_TYPE,
    VAR_NAME
}

public class ScopeNode extends Node {
    static HashSet<String> booleans = new HashSet<String>(Arrays.asList("true", "false"));
    static HashSet<String> primitives = new HashSet<String>(Arrays.asList("int", "boolean", "char"));
    static HashSet<String> predefinedMethods = new HashSet<String>(Arrays.asList("ord", "chr", "length"));
    static HashMap<String, ScopeNode> classMap = new HashMap<String, ScopeNode>();

    String scopeName;
    String classParent;
    HashMap<String, String> symbolTable;

    public ScopeNode(String n) {
        super();
        symbolTable = new HashMap<String, String>();
        scopeName = n;
    }

    // Non-class scope
    public ScopeNode newChildScope(String name) {
        ScopeNode child = new ScopeNode(name);
        child.parent = this;
        this.children.add(child);
        return child;
    }

    // If a classParent object is passed then we know this scope defines a class
    public ScopeNode newChildScope(String name, String classParent) {
        ScopeNode child = new ScopeNode(name);
        child.classParent = classParent;
        child.addSymbol("this", child.scopeName);
        classMap.put(child.scopeName, child);
        child.parent = this;
        this.children.add(child);
        return child;
    }

    public void addSymbol(String name, String declaredType) {
        this.symbolTable.put(name, declaredType);
    }

    // Returns the scope where the variable / method is found
    public ScopeNode checkDeclared(String identifier, IdentifierType dt) {
        ScopeNode classSearch = null;
        switch (dt) {
            case SINGLE:
                if (booleans.contains(identifier)) {
                    // true or false
                    return this;
                }
                if (predefinedMethods.contains(identifier)) {
                    // ord, chr, or length
                    return this;
                }
                if (symbolTable.containsKey(identifier) &&
                        (primitives.contains(symbolTable.get(identifier))
                                || classMap.containsKey(symbolTable.get(identifier))
                                || symbolTable.get(identifier).equals("_method"))) {
                    // in symbol table; primitive, class instance, or method
                    return this;
                }
                if (classMap.containsKey(this.scopeName)) {
                    classSearch = searchClassHierarchy(this.scopeName, identifier);
                    if (classSearch != null) {
                        return classSearch;
                    }
                }
                break;
            case DOT:
                String[] words = identifier.split("[.]");
                String first = words[0];
                String second = words[1];
                if (symbolTable.containsKey(first) &&
                        symbolTable.containsKey(second) &&
                        symbolTable.get(first).equals("_enum") &&
                        symbolTable.get(second).equals("_enum_val")) {
                    // ENUM.ENUM_VAL
                    return this;
                }
                if (first.equals("this") && classMap.containsKey(this.scopeName)) {
                    classSearch = searchClassHierarchy(this.scopeName, second);
                    if (classSearch != null) {
                        return classSearch;
                    }
                }
                if (symbolTable.containsKey(first)) {
                    String firstType = symbolTable.get(first);
                    if (firstType.contains("[]")) {
                        firstType = firstType.substring(0, firstType.indexOf("[]"));
                    }
                    if (classMap.containsKey(firstType)) {
                        // class_VAR.{METHOD | VAR}
                        return searchClassHierarchy(firstType, second);
                    }
                }
                break;
            case ARRAY_INDEX:
                if (symbolTable.containsKey(identifier)
                        && symbolTable.get(identifier).contains("[]")) {
                    return this;
                }
                break;
            case EXTENDS:
                if (symbolTable.containsKey(identifier)
                        && symbolTable.get(identifier).equals("_class")) {
                    return this;
                }
                break;
            case IMPLEMENTS:
                if (symbolTable.containsKey(identifier)
                        && symbolTable.get(identifier).equals("_interface")) {
                    return this;
                }
                break;
            case RETURN_TYPE:
                if (identifier.equals("void")) {
                    return this;
                }
                // fall through
            case DECL_TYPE:
                if (primitives.contains(identifier)) {
                    return this;
                }
                if (symbolTable.containsKey(identifier)
                        && (symbolTable.get(identifier).equals("_class")
                                || symbolTable.get(identifier).equals("_enum"))) {
                    return this;
                }
                break;
            case VAR_NAME:
                if (symbolTable.containsKey(identifier)
                        && (!this.scopeName.equals("project"))) {
                    return this;
                }
                break;
            default:
                break;
        }
        if (this.parent == null) {
            // Reached top of tree and haven't found variable declared
            return null;
        } else {
            return ((ScopeNode) this.parent).checkDeclared(identifier, dt);
        }
    }

    // Searches class hierarchy for word starting at class className
    public static ScopeNode searchClassHierarchy(String className, String word) {
        ScopeNode classScope = classMap.get(className);
        do {
            if (classScope.symbolTable.containsKey(word)) {
                return classScope;
            }
            classScope = classMap.get(classScope.classParent);
        } while (classScope != null);
        return null;
    }

    // Prints scope tree rooted at this node
    public void printScopeTree(String prefix) {
        System.out.print(prefix + scopeName + ": { ");
        Object[] keys = symbolTable.keySet().toArray();
        Arrays.sort(keys);
        for (Object k : keys) {
            System.out.print(symbolTable.get(k) + ":" + k + " ");
        }
        System.out.println("}");
        for (Node n : this.children) {
            ((ScopeNode) n).printScopeTree(prefix + "  ");
        }
    }
}
