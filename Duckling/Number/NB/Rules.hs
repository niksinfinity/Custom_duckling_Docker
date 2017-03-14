-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.


{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}

module Duckling.Number.NB.Rules
  ( rules ) where

import Data.HashMap.Strict (HashMap)
import qualified Data.HashMap.Strict as HashMap
import Data.Maybe
import Data.Text (Text)
import qualified Data.Text as Text
import Prelude
import Data.String

import Duckling.Dimensions.Types
import Duckling.Number.Helpers
import Duckling.Number.Types (NumberData (..))
import qualified Duckling.Number.Types as TNumber
import Duckling.Regex.Types
import Duckling.Types

ruleIntersectWithAnd :: Rule
ruleIntersectWithAnd = Rule
  { name = "intersect (with and)"
  , pattern =
    [ numberWith (fromMaybe 0 . TNumber.grain) (>1)
    , regex "og"
    , numberWith TNumber.multipliable not
    ]
  , prod = \tokens -> case tokens of
      (Token Numeral (NumberData {TNumber.value = val1, TNumber.grain = Just g}):
       _:
       Token Numeral (NumberData {TNumber.value = val2}):
       _) | (10 ** fromIntegral g) > val2 -> double $ val1 + val2
      _ -> Nothing
  }

ruleNumbersPrefixWithNegativeOrMinus :: Rule
ruleNumbersPrefixWithNegativeOrMinus = Rule
  { name = "numbers prefix with -, negative or minus"
  , pattern =
    [ regex "-|minus\\s?|negativ\\s?"
    , dimension Numeral
    ]
  , prod = \tokens -> case tokens of
      (_:Token Numeral nd:_) -> double (TNumber.value nd * (-1))
      _ -> Nothing
  }

ruleIntegerNumeric :: Rule
ruleIntegerNumeric = Rule
  { name = "integer (numeric)"
  , pattern =
    [ regex "(\\d{1,18})"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) -> do
        v <- toInteger <$> parseInt match
        integer v
      _ -> Nothing
  }

ruleFew :: Rule
ruleFew = Rule
  { name = "few"
  , pattern =
    [ regex "(noen )?f\x00e5"
    ]
  , prod = \_ -> integer 3
  }

ruleDecimalWithThousandsSeparator :: Rule
ruleDecimalWithThousandsSeparator = Rule
  { name = "decimal with thousands separator"
  , pattern =
    [ regex "(\\d+(\\.\\d\\d\\d)+\\,\\d+)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):
       _) -> let dot = Text.singleton '.'
                 comma = Text.singleton ','
                 fmt = Text.replace comma dot $ Text.replace dot Text.empty match
        in parseDouble fmt >>= double
      _ -> Nothing
  }

ruleMultiply :: Rule
ruleMultiply = Rule
  { name = "compose by multiplication"
  , pattern =
    [ dimension Numeral
    , numberWith TNumber.multipliable id
    ]
  , prod = \tokens -> case tokens of
      (token1:token2:_) -> multiply token1 token2
      _ -> Nothing
  }

ruleDecimalNumber :: Rule
ruleDecimalNumber = Rule
  { name = "decimal number"
  , pattern =
    [ regex "(\\d*,\\d+)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):
       _) -> parseDecimal False match
      _ -> Nothing
  }

ruleInteger3 :: Rule
ruleInteger3 = Rule
  { name = "integer 21..99"
  , pattern =
    [ oneOf [70, 20, 60, 50, 40, 90, 30, 80]
    , numberBetween 1 10
    ]
  , prod = \tokens -> case tokens of
      (Token Numeral (NumberData {TNumber.value = v1}):
       Token Numeral (NumberData {TNumber.value = v2}):
       _) -> double $ v1 + v2
      _ -> Nothing
  }

ruleSingle :: Rule
ruleSingle = Rule
  { name = "single"
  , pattern =
    [ regex "enkelt"
    ]
  , prod = \_ -> integer 1 >>= withGrain 1
  }

ruleIntersect :: Rule
ruleIntersect = Rule
  { name = "intersect"
  , pattern =
    [ numberWith (fromMaybe 0 . TNumber.grain) (>1)
    , numberWith TNumber.multipliable not
    ]
  , prod = \tokens -> case tokens of
      (Token Numeral (NumberData {TNumber.value = val1, TNumber.grain = Just g}):
       Token Numeral (NumberData {TNumber.value = val2}):
       _) | (10 ** fromIntegral g) > val2 -> double $ val1 + val2
      _ -> Nothing
  }

ruleNumbersSuffixesKMG :: Rule
ruleNumbersSuffixesKMG = Rule
  { name = "numbers suffixes (K, M, G)"
  , pattern =
    [ dimension Numeral
    , regex "([kmg])(?=[\\W\\$\x20ac]|$)"
    ]
  , prod = \tokens -> case tokens of
      (Token Numeral (NumberData {TNumber.value = v}):
       Token RegexMatch (GroupMatch (match:_)):
       _) -> case Text.toLower match of
         "k" -> double $ v * 1e3
         "m" -> double $ v * 1e6
         "g" -> double $ v * 1e9
         _   -> Nothing
      _ -> Nothing
  }

rulePowersOfTen :: Rule
rulePowersOfTen = Rule
  { name = "powers of tens"
  , pattern =
    [ regex "(hundrede?|tusen?|million(er)?)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) -> case Text.toLower match of
        "hundred"   -> double 1e2 >>= withGrain 2 >>= withMultipliable
        "hundrede"  -> double 1e2 >>= withGrain 2 >>= withMultipliable
        "tuse"      -> double 1e3 >>= withGrain 3 >>= withMultipliable
        "tusen"     -> double 1e3 >>= withGrain 3 >>= withMultipliable
        "million"   -> double 1e6 >>= withGrain 6 >>= withMultipliable
        "millioner" -> double 1e6 >>= withGrain 6 >>= withMultipliable
        _           -> Nothing
      _ -> Nothing
  }

ruleAPair :: Rule
ruleAPair = Rule
  { name = "a pair"
  , pattern =
    [ regex "et par"
    ]
  , prod = \_ -> integer 2 >>= withGrain 1
  }

ruleDozen :: Rule
ruleDozen = Rule
  { name = "dozen"
  , pattern =
    [ regex "dusin"
    ]
  , prod = \_ -> integer 12 >>= withGrain 1 >>= withMultipliable
  }

zeroToNineteenMap :: HashMap Text Integer
zeroToNineteenMap = HashMap.fromList
  [ ( "null" , 0 )
  , ( "ingen" , 0 )
  , ( "intet" , 0 )
  , ( "en" , 1 )
  , ( "ett" , 1 )
  , ( "\x00e9n" , 1 )
  , ( "to" , 2 )
  , ( "tre" , 3 )
  , ( "fire" , 4 )
  , ( "fem" , 5 )
  , ( "seks" , 6 )
  , ( "sju" , 7 )
  , ( "syv" , 7 )
  , ( "otte" , 8 )
  , ( "ni" , 9 )
  , ( "ti" , 10 )
  , ( "elleve" , 11 )
  , ( "tolv" , 12 )
  , ( "tretten" , 13 )
  , ( "fjorten" , 14 )
  , ( "femten" , 15 )
  , ( "seksten" , 16 )
  , ( "s\x00f8tten" , 17 )
  , ( "sytten" , 17 )
  , ( "atten" , 18 )
  , ( "nitten" , 19 )
  ]

ruleInteger :: Rule
ruleInteger = Rule
  { name = "integer (0..19)"
  , pattern =
    [ regex "(intet|ingen|null|en|ett|\x00e9n|to|tretten|tre|fire|femten|fem|seksten|seks|syv|sju|\x00e5tte|nitten|ni|ti|elleve|tolv|fjorten|sytten|s\x00f8tten|atten)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) ->
        HashMap.lookup (Text.toLower match) zeroToNineteenMap >>= integer
      _ -> Nothing
  }

dozensMap :: HashMap Text Integer
dozensMap = HashMap.fromList
  [ ( "tyve" , 20 )
  , ( "tjue" , 20 )
  , ( "tredve" , 30 )
  , ( "f\x00f8rti" , 40 )
  , ( "femti" , 50 )
  , ( "seksti" , 60 )
  , ( "sytti" , 70 )
  , ( "\x00e5tti" , 80 )
  , ( "nitti" , 90 )
  ]

ruleInteger2 :: Rule
ruleInteger2 = Rule
  { name = "integer (20..90)"
  , pattern =
    [ regex "(tyve|tjue|tredve|f\x00f8rti|femti|seksti|sytti|\x00e5tti|nitti)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) ->
        HashMap.lookup (Text.toLower match) dozensMap >>= integer
      _ -> Nothing
  }

ruleNumberDotNumber :: Rule
ruleNumberDotNumber = Rule
  { name = "number dot number"
  , pattern =
    [ dimension Numeral
    , regex "komma"
    , numberWith TNumber.grain isNothing
    ]
  , prod = \tokens -> case tokens of
      (Token Numeral nd1:_:Token Numeral nd2:_) ->
        double $ TNumber.value nd1 + decimalsToDouble (TNumber.value nd2)
      _ -> Nothing
  }

ruleIntegerWithThousandsSeparator :: Rule
ruleIntegerWithThousandsSeparator = Rule
  { name = "integer with thousands separator ."
  , pattern =
    [ regex "(\\d{1,3}(\\.\\d\\d\\d){1,5})"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) ->
        parseDouble (Text.replace (Text.singleton '.') Text.empty match) >>= double
      _ -> Nothing
  }

rules :: [Rule]
rules =
  [ ruleAPair
  , ruleDecimalNumber
  , ruleDecimalWithThousandsSeparator
  , ruleDozen
  , ruleFew
  , ruleInteger
  , ruleInteger2
  , ruleInteger3
  , ruleIntegerNumeric
  , ruleIntegerWithThousandsSeparator
  , ruleIntersect
  , ruleIntersectWithAnd
  , ruleMultiply
  , ruleNumberDotNumber
  , ruleNumbersPrefixWithNegativeOrMinus
  , ruleNumbersSuffixesKMG
  , rulePowersOfTen
  , ruleSingle
  ]
