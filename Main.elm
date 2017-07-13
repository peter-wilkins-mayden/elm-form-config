module Main exposing (..)

import Json.Decode
import Json.Decode.Pipeline
import Json.Encode


type Elements
    = NoteText String
    | SectionHeading
    | Select
    | Text
    | DatePicker
    | Radio
    | PostcodeUK
    | MultiCheckbox
    | PhoneNumber
    | Email
    | Textarea


type Validator
    = CharacterHyphenAndQuote
    | SafeCharacters
    | Date
    | IsPastDateValidator
    | StringLength
    | Digit
    | ConditionalRequirementSpecifiedValuesValidaton
    | ConditionalRequirementValidator
    | PhoneNumberOrEmpty
    | UnitedKingdomMobile


type alias Element =
    { spec : ElementSpec
    , flags : ElementFlags
    }


type alias ElementSpecOptions =
    { label : String
    }


type alias ElementSpecAttributes =
    { required : Bool
    }


type alias ElementSpec =
    { type_ : String
    , name : String
    , options : ElementSpecOptions
    , attributes : ElementSpecAttributes
    , priority : String
    }


type alias ElementFlags =
    { priority : String
    }


decodeElement : Json.Decode.Decoder Element
decodeElement =
    Json.Decode.Pipeline.decode Element
        |> Json.Decode.Pipeline.required "spec" decodeElementSpec
        |> Json.Decode.Pipeline.required "flags" decodeElementFlags


decodeElementSpecOptions : Json.Decode.Decoder ElementSpecOptions
decodeElementSpecOptions =
    Json.Decode.Pipeline.decode ElementSpecOptions
        |> Json.Decode.Pipeline.required "label" Json.Decode.string


decodeElementSpecAttributes : Json.Decode.Decoder ElementSpecAttributes
decodeElementSpecAttributes =
    Json.Decode.Pipeline.decode ElementSpecAttributes
        |> Json.Decode.Pipeline.required "required" Json.Decode.bool


decodeElementSpecType : Json.Decode.Decoder Elements
decodeElementSpecType =
    Json.Decode.Pipeline.decode Element
        |> Json.Decode.Pipeline.required "type" Json.Decode.string


decodeElementSpec : Json.Decode.Decoder ElementSpec
decodeElementSpec =
    Json.Decode.Pipeline.decode ElementSpec
        |> Json.Decode.Pipeline.required "type" decodeElementSpecType
        |> Json.Decode.Pipeline.required "name" Json.Decode.string
        |> Json.Decode.Pipeline.required "options" decodeElementSpecOptions
        |> Json.Decode.Pipeline.required "attributes" decodeElementSpecAttributes
        |> Json.Decode.Pipeline.required "priority" Json.Decode.string


decodeElementFlags : Json.Decode.Decoder ElementFlags
decodeElementFlags =
    Json.Decode.Pipeline.decode ElementFlags
        |> Json.Decode.Pipeline.required "priority" Json.Decode.string


encodeElement : Element -> Json.Encode.Value
encodeElement record =
    Json.Encode.object
        [ ( "spec", encodeElementSpec <| record.spec )
        , ( "flags", encodeElementFlags <| record.flags )
        ]


encodeElementSpecOptions : ElementSpecOptions -> Json.Encode.Value
encodeElementSpecOptions record =
    Json.Encode.object
        [ ( "label", Json.Encode.string <| record.label )
        ]


encodeElementSpecAttributes : ElementSpecAttributes -> Json.Encode.Value
encodeElementSpecAttributes record =
    Json.Encode.object
        [ ( "required", Json.Encode.bool <| record.required )
        ]


encodeElementSpec : ElementSpec -> Json.Encode.Value
encodeElementSpec record =
    Json.Encode.object
        [ ( "type", Json.Encode.string <| record.type_ )
        , ( "name", Json.Encode.string <| record.name )
        , ( "options", encodeElementSpecOptions <| record.options )
        , ( "attributes", encodeElementSpecAttributes <| record.attributes )
        , ( "priority", Json.Encode.string <| record.priority )
        ]


encodeElementFlags : ElementFlags -> Json.Encode.Value
encodeElementFlags record =
    Json.Encode.object
        [ ( "priority", Json.Encode.string <| record.priority )
        ]
