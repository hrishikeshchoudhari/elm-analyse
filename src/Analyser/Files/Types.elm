module Analyser.Files.Types
    exposing
        ( Dependency
        , Version
        , LoadedSourceFiles
        , LoadedSourceFile
        , FileLoad(Failed, Loaded)
        , LoadedFile
        , ModuleIndex
        , OperatorTable
        , FileContent
        , LoadedFileData
        , Interface
        , ExposedInterface(Function, Type, Alias, Operator)
        )

import AST.Types as AST
import Dict exposing (Dict)


type alias Version =
    String


type alias Dependency =
    { name : String
    , version : Version
    , interfaces : Dict AST.ModuleName Interface
    }


type alias Interface =
    List ExposedInterface


type ExposedInterface
    = Function String
    | Type ( String, List String )
    | Alias String
    | Operator AST.Infix


type alias LoadedSourceFiles =
    List LoadedSourceFile


type alias LoadedSourceFile =
    ( FileContent, FileLoad )


type alias LoadedFile =
    ( FileContent, FileLoad )


type FileLoad
    = Failed String
    | Loaded LoadedFileData


type alias LoadedFileData =
    { interface : Interface
    , moduleName : Maybe AST.ModuleName
    , ast : AST.File
    }


type alias ModuleIndex =
    Dict AST.ModuleName Interface


type alias OperatorTable =
    Dict String AST.Infix


type alias FileContent =
    { path : String
    , success : Bool
    , sha1 : Maybe String
    , content : Maybe String
    , ast : Maybe String
    , formatted : Bool
    }
