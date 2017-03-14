-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.


{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}

module Duckling.Rules.VI
  ( rules
  ) where

import Duckling.Dimensions.Types
import qualified Duckling.Finance.VI.Rules as Finance
import qualified Duckling.Number.VI.Rules as Number
import Duckling.Types

rules :: Some Dimension -> [Rule]
rules (Some Distance) = []
rules (Some Duration) = []
rules (Some Numeral) = Number.rules
rules (Some Email) = []
rules (Some Finance) = Finance.rules
rules (Some Ordinal) = []
rules (Some PhoneNumber) = []
rules (Some Quantity) = []
rules (Some RegexMatch) = []
rules (Some Temperature) = []
rules (Some Time) = []
rules (Some TimeGrain) = []
rules (Some Url) = []
rules (Some Volume) = []
