module Parser.TypeReference exposing (typeReference)

import Combine exposing (choice, lazy, Parser, parens, map, sepBy, (>>=), (<*>), succeed, (*>), string, maybe, (<$>), sepBy, between, many, (<*), or, whitespace)
import Parser.Tokens exposing (functionName, typeName)
import AST.Types exposing (TypeReference(FunctionTypeReference, Unit, Tupled, GenericType, GenericRecord, Record, Typed), RecordField, RecordDefinition)
import AST.Ranges exposing (Range)
import Parser.Util exposing (moreThanIndentWhitespace, trimmed)
import Parser.Whitespace exposing (realNewLine)
import Parser.State exposing (State)
import Parser.Ranges exposing (withRange)


typeReferenceNoFn : Parser State TypeReference
typeReferenceNoFn =
    lazy
        (\() ->
            withRange <|
                choice
                    [ parensTypeReference
                    , typedTypeReference
                    , recordTypeReference
                    , genericRecordTypeReference
                    , genericTypeReference
                    ]
        )


typeReference : Parser State TypeReference
typeReference =
    lazy
        (\() ->
            withRange <|
                typeReferenceNoFn
                    >>= \typeRef ->
                            or (FunctionTypeReference typeRef <$> (trimmed (string "->") *> typeReference))
                                (succeed (always typeRef))
        )


parensTypeReference : Parser State (Range -> TypeReference)
parensTypeReference =
    lazy
        (\() ->
            parens (maybe moreThanIndentWhitespace *> sepBy (string ",") (trimmed typeReference))
                |> map asTypeReference
        )


asTypeReference : List TypeReference -> (Range -> TypeReference)
asTypeReference x =
    case x of
        [] ->
            Unit

        [ item ] ->
            always item

        xs ->
            Tupled xs


genericTypeReference : Parser State (Range -> TypeReference)
genericTypeReference =
    lazy (\() -> GenericType <$> functionName)


recordFieldsTypeReference : Parser State RecordDefinition
recordFieldsTypeReference =
    lazy (\() -> sepBy (string ",") (trimmed recordFieldDefinition))


genericRecordTypeReference : Parser State (Range -> TypeReference)
genericRecordTypeReference =
    lazy
        (\() ->
            between
                (string "{")
                (maybe realNewLine *> string "}")
                (succeed GenericRecord
                    <*> (maybe whitespace *> functionName)
                    <*> (maybe whitespace *> string "|" *> maybe whitespace *> recordFieldsTypeReference)
                )
        )


recordTypeReference : Parser State (Range -> TypeReference)
recordTypeReference =
    lazy
        (\() ->
            between
                (string "{")
                (maybe realNewLine *> string "}")
                (Record <$> recordFieldsTypeReference)
        )


recordFieldDefinition : Parser State RecordField
recordFieldDefinition =
    lazy
        (\() ->
            succeed (,)
                <*> (maybe moreThanIndentWhitespace *> functionName)
                <*> (maybe moreThanIndentWhitespace *> string ":" *> maybe moreThanIndentWhitespace *> typeReference)
        )


typedTypeReference : Parser State (Range -> TypeReference)
typedTypeReference =
    lazy
        (\() ->
            succeed Typed
                <*> many (typeName <* string ".")
                <*> typeName
                <*> (Maybe.withDefault []
                        <$> maybe (moreThanIndentWhitespace *> sepBy moreThanIndentWhitespace typeReferenceNoFn)
                    )
        )
