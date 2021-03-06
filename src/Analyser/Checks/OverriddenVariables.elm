module Analyser.Checks.OverriddenVariables exposing (checker)

import AST.Types exposing (File, Case, LetBlock, VariablePointer, Destructuring, Pattern, Function, Lambda, Exposure, ModuleName)
import AST.Ranges exposing (Range)
import ASTUtil.Variables exposing (getImportsVars, patternToVars)
import Analyser.FileContext exposing (FileContext)
import Analyser.Messages.Types exposing (Message, MessageData(RedefineVariable), newMessage)
import Dict exposing (Dict)
import Inspector exposing (Order(Inner), defaultConfig)
import Analyser.Configuration exposing (Configuration)
import Analyser.Checks.Base exposing (Checker, keyBasedChecker)


checker : Checker
checker =
    { check = scan
    , shouldCheck = keyBasedChecker [ "RedefineVariable" ]
    }


type alias Context =
    ( List Redefine, Dict String Range )


type alias Redefine =
    ( String, Range, Range )


scan : FileContext -> Configuration -> List Message
scan fileContext _ =
    let
        topLevels : Dict String Range
        topLevels =
            getImportsVars fileContext.ast.imports
                |> List.map (\( x, _ ) -> ( x.value, x.range ))
                |> Dict.fromList
    in
        Inspector.inspect
            { defaultConfig
                | onFunction = Inner onFunction
                , onLambda = Inner onLambda
                , onCase = Inner onCase
                , onDestructuring = Inner onDestructuring
            }
            fileContext.ast
            ( [], topLevels )
            |> Tuple.first
            |> List.map (\( n, r1, r2 ) -> RedefineVariable fileContext.path n r1 r2)
            |> List.map (newMessage [ ( fileContext.sha1, fileContext.path ) ])


visitWithVariablePointers : List VariablePointer -> (Context -> Context) -> Context -> Context
visitWithVariablePointers variablePointers f ( redefines, known ) =
    let
        redefinedPattern : List VariablePointer
        redefinedPattern =
            variablePointers
                |> List.filter (.value >> flip Dict.member known)

        newKnown : Dict String Range
        newKnown =
            List.foldl (\a b -> Dict.insert a.value a.range b) known variablePointers

        ( newRedefines, _ ) =
            f ( redefines, newKnown )
    in
        ( newRedefines
            ++ (redefinedPattern
                    |> List.filterMap (\x -> Dict.get x.value known |> Maybe.map (\r -> ( x.value, r, x.range )))
               )
        , known
        )


visitWithPatterns : List Pattern -> (Context -> Context) -> Context -> Context
visitWithPatterns patterns f context =
    visitWithVariablePointers (patterns |> List.concatMap patternToVars |> List.map Tuple.first) f context


onDestructuring : (Context -> Context) -> Destructuring -> Context -> Context
onDestructuring f destructuring context =
    visitWithVariablePointers
        (destructuring.pattern |> patternToVars |> List.map Tuple.first)
        f
        context


onFunction : (Context -> Context) -> Function -> Context -> Context
onFunction f function context =
    visitWithVariablePointers
        (function.declaration.arguments |> List.concatMap patternToVars |> List.map Tuple.first |> (::) function.declaration.name)
        f
        context


onLambda : (Context -> Context) -> Lambda -> Context -> Context
onLambda f lambda context =
    visitWithPatterns lambda.args f context


onCase : (Context -> Context) -> Case -> Context -> Context
onCase f caze context =
    visitWithVariablePointers (Tuple.first caze |> patternToVars |> List.map Tuple.first) f context
