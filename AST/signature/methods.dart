import 'package:analyzer/dart/element/element.dart';
import '../implementation/implementation.dart';
import '../comments.dart';
import '../naming.dart';

class Methods {
  static bool isSameSignature(MethodElement m1, MethodElement m2) {
    return methodSignature(m1) == methodSignature(m2);
  }

  static bool overridesBaseMethod(MethodElement method, ClassElement element) {
    if (element.methods.any((m) => isSameSignature(m, method)) ||
        overridesParentBaseMethod(method, element)) return true;

    return false;
  }

  static MethodElement getBaseMethodInClass(MethodElement element) {
    if (element.enclosingElement == null ||
        element.enclosingElement.allSupertypes.length == 0) return element;

    MethodElement methodInSupertype;
    for (var supertype in element.enclosingElement.allSupertypes
        .where((st) => st.methods.length > 0)) {
      methodInSupertype = supertype.methods.firstWhere(
          (method) => method.displayName == element.displayName,
          orElse: () => null);
      if (methodInSupertype != null) {
        // Found method this method extends from
        break;
      }
    }

    if (methodInSupertype != null) {
      return getBaseMethodInClass(methodInSupertype);
    } else
      return element;
  }

  static bool overridesParentBaseMethod(
      MethodElement method, ClassElement element) {
    for (var superType
        in element.allSupertypes.where((st) => !element.mixins.contains(st))) {
      if (overridesBaseMethod(method, superType.element)) return true;
    }
    return false;
  }

  static String printMethod(
      MethodElement element, bool insideMixin, bool isOverride) {
    var baseMethod = getBaseMethodInClass(element);

    var code = new StringBuffer();
    code.writeln("");
    Comments.appendComment(code, element);

    if (element.hasProtected == true) code.write("protected ");
    if (element.isPublic == true) code.write("public ");
    if (element.isPrivate == true) code.write("private ");
    if (element.hasOverride == true && baseMethod != element)
      code.write("override ");
    if (element.hasSealed == true)
      code.write("sealed ");
    // Add virtual as default key if method is not already abstract since all methods are virtual in dart
    else if (element.hasOverride == false && element.isPrivate == false)
      code.write("virtual ");

    code.write(methodSignature(baseMethod));

    code.writeln(Implementation.MethodBody(element));
    
    return code.toString();
  }

  static String printImplementedMethod(
      MethodElement element,
      String implementedInstanceName,
      MethodElement overrideMethod,
      ClassElement classElement) {
    var baseMethod = getBaseMethodInClass(element);

    var name = Naming.nameWithTypeParameters(element, false);
    var code = new StringBuffer();
    code.writeln("");
    Comments.appendComment(code, element);

    if (element.isPublic == true) code.write("public ");
    if (element.hasProtected == true) code.write("protected ");
    if (element.hasSealed == true) code.write("sealed ");
    code.write("virtual ");

    code.write(methodSignature(baseMethod));

    if (overrideMethod == null) {
      if (element.returnType.displayName != "void") code.write("return ");
      code.writeln(
          "{${implementedInstanceName}.${name}(${element.parameters.map((p) => Naming.getFormattedName(p.name, NameStyle.LowerCamelCase)).join(",")});}");
    } else {
      code.writeln(Implementation.MethodBody(overrideMethod));
    }

    return code.toString();
  }

  static String methodSignature(MethodElement element) {
    var methodName = Naming.nameWithTypeParameters(element, false);
    if (methodName ==
        Naming.nameWithTypeParameters(element.enclosingElement, false))
      methodName = "Self" + methodName;

    methodName = Naming.getFormattedName(
        methodName,
        element.isPrivate
            ? NameStyle.LeadingUnderscoreLowerCamelCase
            : NameStyle.UpperCamelCase);

    var parameter = printParameter(element);
    var returnType = Naming.getReturnType(element);
    if (methodName.toLowerCase() == "decodemessage") {
      print("Larp");
    }
    var typeParameter = "";
    if (returnType == "T") {
      var classHasTypeParameter =
          element.enclosingElement.typeParameters.any((x) => x == returnType);
      if (!classHasTypeParameter && element.typeParameters.length == 0) {
        typeParameter = "<" + "T" + ">";
      }
    }

    return "${returnType} ${methodName}${typeParameter}(${parameter})";
  }

  static String printParameter(FunctionTypedElement element) {
    // Parameter
    var parameters = element.parameters.map((p) {
      // Name
      var parameterName = p.name;
      parameterName =
          Naming.getFormattedName(parameterName, NameStyle.LowerCamelCase);
      if (parameterName == "")
        parameterName = "p" + (element.parameters.indexOf(p) + 1).toString();

      // Type
      var parameterType =
          Naming.getVariableType(p, VariableType.Parameter).split(" ").last;
      if (parameterType == "@") {
        parameterType = "object";
      }
      var parameterSignature = parameterType + " " + parameterName;

      if (p.hasRequired) {
        parameterSignature = "[NotNull] " + parameterSignature;
      }

      if(p.isOptional){
        parameterSignature += " = default(${parameterType})";
      }
      return parameterSignature;
    });
    return parameters == null ? "" : parameters.join(",");
  }
}