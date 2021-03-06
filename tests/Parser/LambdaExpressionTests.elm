module Parser.LambdaExpressionTests exposing (..)

import Parser.CombineTestUtil exposing (..)
import Expect
import Parser.Declarations as Parser exposing (..)
import AST.Types exposing (..)
import AST.Ranges exposing (..)
import Test exposing (..)
import Parser.State exposing (emptyState)


all : Test
all =
    describe "LambdaExpressionTests"
        [ test "unit lambda" <|
            \() ->
                parseFullStringState emptyState "\\() -> foo" Parser.expression
                    |> Maybe.map (Tuple.second >> noRangeInnerExpression)
                    |> Expect.equal
                        (Just
                            (LambdaExpression
                                { args = [ UnitPattern emptyRange ]
                                , expression = emptyRanged <| FunctionOrValue "foo"
                                }
                            )
                        )
        , test "args lambda" <|
            \() ->
                parseFullStringState emptyState "\\a b -> a + b" Parser.expression
                    |> Maybe.map (Tuple.second >> noRangeInnerExpression)
                    |> Expect.equal
                        (Just
                            (LambdaExpression
                                { args =
                                    [ VarPattern "a" emptyRange
                                    , VarPattern "b" emptyRange
                                    ]
                                , expression =
                                    emptyRanged <|
                                        Application
                                            [ emptyRanged <| FunctionOrValue "a"
                                            , emptyRanged <| Operator "+"
                                            , emptyRanged <| FunctionOrValue "b"
                                            ]
                                }
                            )
                        )
        , test "tuple lambda" <|
            \() ->
                parseFullStringState emptyState "\\(a,b) -> a + b" Parser.expression
                    |> Maybe.map (Tuple.second >> noRangeInnerExpression)
                    |> Expect.equal
                        (Just
                            (LambdaExpression
                                { args =
                                    [ TuplePattern
                                        [ VarPattern "a" emptyRange
                                        , VarPattern "b" emptyRange
                                        ]
                                        emptyRange
                                    ]
                                , expression = emptyRanged <| Application [ emptyRanged <| FunctionOrValue "a", emptyRanged <| Operator "+", emptyRanged <| FunctionOrValue "b" ]
                                }
                            )
                        )
        ]
