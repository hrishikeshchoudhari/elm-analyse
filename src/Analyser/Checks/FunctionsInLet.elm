module Analyser.Checks.FunctionsInLet exposing (checker)

import Analyser.Checks.Base exposing (Checker, keyBasedChecker)
import Analyser.Configuration exposing (Configuration)
import Analyser.FileContext exposing (FileContext)
import Analyser.Messages.Types exposing (Message, MessageData(FunctionInLet), newMessage)
import Inspector exposing (Order(Post, Inner), defaultConfig)
import AST.Types exposing (..)
import ASTUtil.Functions


type alias Context =
    { inLetBlock : Bool
    , functions : List Function
    }


startingContext : Context
startingContext =
    { inLetBlock = False, functions = [] }


checker : Checker
checker =
    { check = scan
    , shouldCheck = keyBasedChecker [ "FunctionsInLet" ]
    }


scan : FileContext -> Configuration -> List Message
scan fileContext _ =
    Inspector.inspect
        { defaultConfig
            | onLetBlock = Inner onLetBlock
            , onFunction = Post onFunction
        }
        fileContext.ast
        startingContext
        |> .functions
        |> List.map (asMessage fileContext)


asMessage : FileContext -> Function -> Message
asMessage fileContext f =
    newMessage [ ( fileContext.sha1, fileContext.path ) ]
        (FunctionInLet fileContext.path f.declaration.name.range)


onFunction : Function -> Context -> Context
onFunction function context =
    let
        isStatic =
            ASTUtil.Functions.isStatic function
    in
        if not isStatic && context.inLetBlock then
            { context | functions = function :: context.functions }
        else
            context


onLetBlock : (Context -> Context) -> LetBlock -> Context -> Context
onLetBlock continue _ context =
    { context | inLetBlock = True }
        |> continue
        |> \after -> { after | inLetBlock = context.inLetBlock }
