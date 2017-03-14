-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.


{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}

module Duckling.Rules.ES
  ( rules
  ) where

import Duckling.Dimensions.Types
import qualified Duckling.Distance.ES.Rules as Distance
import qualified Duckling.Finance.ES.Rules as Finance
import qualified Duckling.Number.ES.Rules as Number
import qualified Duckling.Ordinal.ES.Rules as Ordinal
import qualified Duckling.Temperature.ES.Rules as Temperature
import qualified Duckling.Time.ES.Rules as Time
import qualified Duckling.TimeGrain.ES.Rules as TimeGrain
import qualified Duckling.Volume.ES.Rules as Volume
import Duckling.Types

rules :: Some Dimension -> [Rule]
rules (Some Distance) = Distance.rules
rules (Some Duration) = []
rules (Some Numeral) = Number.rules
rules (Some Email) = []
rules (Some Finance) = Finance.rules
rules (Some Ordinal) = Ordinal.rules
rules (Some PhoneNumber) = []
rules (Some Quantity) = []
rules (Some RegexMatch) = []
rules (Some Temperature) = Temperature.rules
rules (Some Time) = Time.rules
rules (Some TimeGrain) = TimeGrain.rules
rules (Some Url) = []
rules (Some Volume) = Volume.rules
