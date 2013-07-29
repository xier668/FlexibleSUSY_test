
BeginPackage["Parameters`", {"SARAH`", "CConversion`"}];

CreateSetAssignment::usage="";
CreateDisplayAssignment::usage="";
CreateParameterNames::usage="";

SetParameter::usage="set model parameter";

ApplyGUTNormalization::usage="Returns a list of repacement rules for
gauge couplings, which replace non-normalized gauge couplings
(e.g. gY) by normalized ones (e.g. g1).";

GetGUTNormalization::usage="Returns GUT normalization of the given
coupling";

CreateIndexReplacementRules::usage="";

AddRealParameter::usage="";

SaveParameterLocally::usage="Save parameters in local variables";
RestoreParameter::usage="Restore parameters from local variables";

GetType::usage="";

IsRealParameter::usage="";
IsComplexParameter::usage="";
IsRealExpression::usage="";

SetInputParameters::usage="";
SetModelParameters::usage="";
SetOutputParameters::usage="";

GetModelParameters::usage="";

CreateLocalConstRefs::usage="creates local const references to model
parameters / input parameters.";

CreateLocalConstRefsForBetas::usage="";

CreateLocalConstRefsForInputParameters::usage="creates local const
references for all input parameters in the given expression.";

Begin["Private`"];

allInputParameters = {};
allModelParameters = {};
allOutputParameters = {};

SetInputParameters[pars_List] := allInputParameters = pars;
SetModelParameters[pars_List] := allModelParameters = pars;
SetOutputParameters[pars_List] := allOutputParameters = pars;

GetModelParameters[] := allModelParameters;

additionalRealParameters = {};

AddRealParameter[parameter_List] :=
    additionalRealParameters = DeleteDuplicates[Join[additionalRealParameters, parameter]];

AddRealParameter[parameter_] :=
    additionalRealParameters = DeleteDuplicates[Join[additionalRealParameters, {parameter}]];

IsRealParameter[sym_] :=
    MemberQ[Join[SARAH`realVar, additionalRealParameters], sym];

IsComplexParameter[sym_] :=
    !IsRealParameter[sym];

IsRealExpression[expr_?NumericQ] :=
    Element[expr, Reals];

IsRealExpression[_Complex] := False;

IsRealExpression[_Real] := True;

IsRealExpression[expr_[i1,i2]] := IsRealExpression[expr];

IsRealExpression[HoldPattern[SARAH`Delta[_,_]]] := True;
IsRealExpression[HoldPattern[SARAH`ThetaStep[_,_]]] := True;
IsRealExpression[Cos[_]] := True;
IsRealExpression[Sin[_]] := True;
IsRealExpression[ArcCos[_]] := True;
IsRealExpression[ArcSin[_]] := True;
IsRealExpression[ArcTan[_]] := True;
IsRealExpression[Power[a_,b_]] := IsRealExpression[a] && IsRealExpression[b];
IsRealExpression[Susyno`LieGroups`conj[expr_]] :=
    IsRealExpression[expr];
IsRealExpression[SARAH`Conj[expr_]] := IsRealExpression[expr];
IsRealExpression[Conjugate[expr_]]  := IsRealExpression[expr];
IsRealExpression[Transpose[expr_]]  := IsRealExpression[expr];
IsRealExpression[SARAH`Tp[expr_]]   := IsRealExpression[expr];
IsRealExpression[SARAH`Adj[expr_]]  := IsRealExpression[expr];
IsRealExpression[bar[expr_]]        := IsRealExpression[expr];

IsRealExpression[expr_Symbol] := IsRealParameter[expr];

IsRealExpression[Times[Susyno`LieGroups`conj[a_],a_]] := True;
IsRealExpression[Times[a_,Susyno`LieGroups`conj[a_]]] := True;
IsRealExpression[Times[SARAH`Conj[a_],a_]]            := True;
IsRealExpression[Times[a_,SARAH`Conj[a_]]]            := True;

IsRealExpression[factors_Times] :=
    And @@ (IsRealExpression[#]& /@ (List @@ factors));

IsRealExpression[terms_Plus] :=
    And @@ (IsRealExpression[#]& /@ (List @@ terms));

IsRealExpression[terms_SARAH`trace] :=
    And @@ (IsRealExpression[#]& /@ (List @@ terms));

IsRealExpression[terms_SARAH`MatMul] :=
    And @@ (IsRealExpression[#]& /@ (List @@ terms));

IsRealExpression[sum[index_, start_, stop_, expr_]] :=
    IsRealExpression[expr];

IsRealExpression[otherwise_] := False;

GetTypeFromDimension[sym_, {}] :=
    If[True || IsRealParameter[sym],
       CConversion`ScalarType["double"],
       CConversion`ScalarType["Complex"]
      ];

GetTypeFromDimension[sym_, {1}] :=
    GetTypeFromDimension[sym, {}];

GetTypeFromDimension[sym_, {num_?NumberQ}] :=
    If[True || IsRealParameter[sym],
       CConversion`VectorType["Eigen::Matrix<double," <> ToString[num] <> ",1>", num],
       CConversion`VectorType["Eigen::Matrix<Complex," <> ToString[num] <> ",1>", num]
      ];

GetTypeFromDimension[sym_, {num1_?NumberQ, num2_?NumberQ}] :=
    If[True || IsRealParameter[sym],
       CConversion`MatrixType["Eigen::Matrix<double," <> ToString[num1] <> "," <> ToString[num2] <> ">", num1, num2],
       CConversion`MatrixType["Eigen::Matrix<Complex," <> ToString[num1] <> "," <> ToString[num2] <> ">", num1, num2]
      ];

GetType[sym_] :=
    GetTypeFromDimension[sym, SARAH`getDimParameters[sym]];

CreateIndexReplacementRules[pars_List] :=
    Module[{indexReplacementRules, p, i,j,k,l, dim, rule, parameter},
           indexReplacementRules = {};
           For[p = 1, p <= Length[pars], p++,
               parameter = pars[[p]];
               dim = SARAH`getDimParameters[parameter];
               rule = {};
               Switch[Length[dim],
                      1, rule = RuleDelayed @@ Rule[parameter[i_], parameter[i-1]];,
                      2, rule = RuleDelayed @@ Rule[parameter[i_,j_], parameter[i-1,j-1]];,
                      3, rule = RuleDelayed @@ Rule[parameter[i_,j_,k_], parameter[i-1,j-1,k-1]];,
                      4, rule = RuleDelayed @@ Rule[parameter[i_,j_,k_,l_], parameter[i-1,j-1,k-1,l-1]];
                     ];
               AppendTo[indexReplacementRules, rule];
              ];
           Return[Flatten[indexReplacementRules]]
          ];

GetGUTNormalization[coupling_Symbol] :=
    Module[{pos, norm},
           pos = Position[SARAH`Gauge, coupling];
           If[pos =!= {},
              norm = SARAH`GUTren[pos[[1,1]]];
              If[NumericQ[norm],
                 Return[norm];
                ];
             ];
           Return[1];
          ];

ApplyGUTNormalization[] :=
    Module[{i, rules = {}, coupling},
           For[i = 1, i <= Length[SARAH`Gauge], i++,
               If[NumericQ[SARAH`GUTren[i]],
                  coupling = SARAH`Gauge[[i,4]];
                  AppendTo[rules, Rule[coupling, coupling SARAH`GUTren[i]]];
                 ];
              ];
           Return[rules];
          ];

CreateSetAssignment[name_, startIndex_, parameterType_] :=
    Block[{},
          Print["Error: CreateSetAssignment: unknown parameter type: ", ToString[parameterType]];
          Quit[];
          ];

CreateSetAssignment[name_, startIndex_, CConversion`ScalarType["double"]] :=
    Module[{ass = ""},
           ass = name <> " = v(" <> ToString[startIndex] <> ");\n";
           Return[{ass, 1}];
          ];

CreateSetAssignment[name_, startIndex_, CConversion`ScalarType["Complex"]] :=
    Module[{ass = ""},
           ass = name <> " = Complex(v(" <> ToString[startIndex] <>
                 ", v(" <> ToString[startIndex + 1] <> "));\n";
           Return[{ass, 2}];
          ];

CreateSetAssignment[name_, startIndex_, CConversion`MatrixType[type_, rows_, cols_]] :=
    Module[{ass = "", i, j, count = 0},
           For[i = 0, i < rows, i++,
               For[j = 0, j < cols, j++; count++,
                   ass = ass <> name <> "(" <> ToString[i] <> "," <> ToString[j]
                         <> ") = v(" <> ToString[startIndex + count] <> ");\n";
                  ];
              ];
           If[rows * cols != count,
              Print["Error: CreateSetAssignment: something is wrong with the indices: "
                    <> ToString[rows * cols] <> " != " <> ToString[count]];];
           Return[{ass, rows * cols}];
          ];

CreateDisplayAssignment[name_, startIndex_, parameterType_] :=
    Block[{},
          Print["Error: CreateDisplayAssignment: unknown parameter type: ",
                ToString[parameterType]];
          Quit[];
          ];

CreateDisplayAssignment[name_, startIndex_, CConversion`ScalarType["double"]] :=
    Module[{ass = ""},
           ass = "pars(" <> ToString[startIndex] <> ") = "
                 <> name <> ";\n";
           Return[{ass, 1}];
          ];

CreateDisplayAssignment[name_, startIndex_, CConversion`ScalarType["Complex"]] :=
    Module[{ass = ""},
           ass = "pars(" <> ToString[startIndex] <> ") = Re(" <> name <> ");\n" <>
                 "pars(" <> ToString[startIndex + 1] <> ") = Im(" <> name <> ");\n";
           Return[{ass, 2}];
          ];

CreateDisplayAssignment[name_, startIndex_, CConversion`MatrixType[type_, rows_, cols_]] :=
    Module[{ass = "", i, j, count = 0},
           For[i = 0, i < rows, i++,
               For[j = 0, j < cols, j++; count++,
                   ass = ass <> "pars(" <> ToString[startIndex + count] <> ") = "
                          <> name <> "(" <> ToString[i] <> "," <> ToString[j]
                          <> ");\n";
                  ];
              ];
           If[rows * cols != count,
              Print["Error: CreateDisplayAssignment: something is wrong with the indices: "
                    <> ToString[rows * cols] <> " != " <> ToString[count]];];
           Return[{ass, rows * cols}];
          ];

CreateParameterNames[name_, startIndex_, parameterType_] :=
    Block[{},
          Print["Error: CreateParameterNames: unknown parameter type: ",
                ToString[parameterType]];
          Quit[];
          ];

CreateParameterNames[name_String, startIndex_, CConversion`ScalarType["double"]] :=
    Module[{ass},
           ass = "names[" <> ToString[startIndex] <> "] = \""
                 <> name <> "\";\n";
           Return[{ass, 1}];
          ];

CreateParameterNames[name_String, startIndex_, CConversion`ScalarType["Complex"]] :=
    Module[{ass = ""},
           ass = "names[" <> ToString[startIndex] <> "] = \"Re(" <> name <> ")\";\n" <>
                 "names[" <> ToString[startIndex + 1] <> "] = \"Im(" <> name <> ")\";\n";
           Return[{ass, 2}];
          ];

CreateParameterNames[name_String, startIndex_, CConversion`MatrixType[type_, rows_, cols_]] :=
    Module[{ass = "", i, j, count = 0},
           For[i = 0, i < rows, i++,
               For[j = 0, j < cols, j++; count++,
                   ass = ass <> "names[" <> ToString[startIndex + count] <> "] = \""
                          <> name <> "(" <> ToString[i] <> "," <> ToString[j]
                          <> ")\";\n";
                  ];
              ];
           If[rows * cols != count,
              Print["Error: CreateParameterNames: something is wrong with the indices: "
                    <> ToString[rows * cols] <> " != " <> ToString[count]];];
           Return[{ass, rows * cols}];
          ];

SetParameter[parameter_, value_String, class_String] :=
    Module[{parameterStr},
           parameterStr = CConversion`ToValidCSymbolString[parameter];
           class <> "->set_" <> parameterStr <> "(" <> value <> ");\n"
          ];

SetParameter[parameter_, value_, class_String] :=
    SetParameter[parameter, CConversion`RValueToCFormString[value], class];

SaveParameterLocally[parameters_List, prefix_String, caller_String] :=
    Module[{i, result = ""},
           For[i = 1, i <= Length[parameters], i++,
               result = result <> SaveParameterLocally[parameters[[i]], prefix, caller];
              ];
           Return[result];
          ];

SaveParameterLocally[parameter_, prefix_String, caller_String] :=
    Module[{ parStr },
           parStr = CConversion`ToValidCSymbolString[parameter];
           "const auto " <> prefix <> parStr <> " = " <>
           If[caller != "", caller <> "(" <> parStr <> ")", parStr] <> ";\n"
          ];

RestoreParameter[parameters_List, prefix_String, modelPtr_String] :=
    Module[{i, result = ""},
           For[i = 1, i <= Length[parameters], i++,
               result = result <> RestoreParameter[parameters[[i]], prefix, modelPtr];
              ];
           Return[result];
          ];

RestoreParameter[parameter_, prefix_String, modelPtr_String] :=
    Module[{ parStr },
           parStr = CConversion`ToValidCSymbolString[parameter];
           If[modelPtr != "",
              SetParameter[parameter, prefix <> parStr, modelPtr],
              CConversion`ToValidCSymbolString[parameter] <> " = " <> prefix <> parStr <> ";\n"]
          ];

RemoveProtectedHeads[expr_] :=
    expr /. SARAH`SM[__] -> SARAH`SM[];

DefineLocalConstCopy[parameter_, macro_String, prefix_String:""] :=
    "const auto " <> prefix <> ToValidCSymbolString[parameter] <> " = " <>
    macro <> "(" <> ToValidCSymbolString[parameter] <> ");\n";

CreateLocalConstRefs[expr_] :=
    Module[{result = "", symbols, inputSymbols, modelPars, outputPars,
            compactExpr},
           compactExpr = RemoveProtectedHeads[expr];
           symbols = { Cases[compactExpr, _Symbol, Infinity],
                       Cases[compactExpr, a_[__] /; MemberQ[allModelParameters,a] :> a, Infinity],
                       Cases[compactExpr, a_[__] /; MemberQ[allOutputParameters,a] :> a, Infinity],
                       Cases[compactExpr, FlexibleSUSY`M[a_]     /; MemberQ[allOutputParameters,FlexibleSUSY`M[a]], Infinity],
                       Cases[compactExpr, FlexibleSUSY`M[a_[__]] /; MemberQ[allOutputParameters,FlexibleSUSY`M[a]] :> FlexibleSUSY`M[a], Infinity]
                     };
           symbols = DeleteDuplicates[Flatten[symbols]];
           inputSymbols = DeleteDuplicates[Select[symbols, (MemberQ[allInputParameters,#])&]];
           modelPars    = DeleteDuplicates[Select[symbols, (MemberQ[allModelParameters,#])&]];
           outputPars   = DeleteDuplicates[Select[symbols, (MemberQ[allOutputParameters,#])&]];
           (result = result <> DefineLocalConstCopy[#,"INPUTPARAMETER"])& /@ inputSymbols;
           (result = result <> DefineLocalConstCopy[#,"MODELPARAMETER"])& /@ modelPars;
           (result = result <> DefineLocalConstCopy[#,"MODELPARAMETER"])& /@ outputPars;
           Return[result];
          ];

CreateLocalConstRefsForBetas[expr_] :=
    Module[{result = "", symbols, modelPars, compactExpr},
           compactExpr = RemoveProtectedHeads[expr];
           symbols = { Cases[compactExpr, _Symbol, Infinity],
                       Cases[compactExpr, a_[__] /; MemberQ[allModelParameters,a] :> a, Infinity] };
           symbols = DeleteDuplicates[Flatten[symbols]];
           modelPars = DeleteDuplicates[Select[symbols, (MemberQ[allModelParameters,#])&]];
           (result = result <> DefineLocalConstCopy[#, "BETAPARAMETER", "beta_"])& /@ modelPars;
           Return[result];
          ];

CreateLocalConstRefsForInputParameters[expr_] :=
    Module[{result = "", symbols, inputPars, compactExpr},
           compactExpr = RemoveProtectedHeads[expr];
           symbols = Cases[compactExpr, _Symbol, Infinity];
           symbols = DeleteDuplicates[Flatten[symbols]];
           Print["symbols: ", symbols];
           inputPars = DeleteDuplicates[Select[symbols, (MemberQ[allInputParameters,#])&]];
           Print["input parameters: ", inputPars];
           (result = result <> DefineLocalConstCopy[#, "INPUT"])& /@ inputPars;
           Print["decl of input parameters: ", result];
           Return[result];
          ];

End[];

EndPackage[];
