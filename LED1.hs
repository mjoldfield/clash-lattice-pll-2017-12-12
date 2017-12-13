module LED1
  ( 
    topEntity 
  ) where

import Clash.Prelude
import Lattice


-- F_PLLIN:   100.000 MHz (given)
-- F_PLLOUT:   50.000 MHz (requested)
-- F_PLLOUT:   50.000 MHz (achieved)
-- 
-- FEEDBACK: SIMPLE
-- F_PFD:  100.000 MHz
-- F_VCO:  800.000 MHz
-- 
-- DIVR:  0 (4'b0000)
-- DIVF:  7 (7'b0000111)
-- DIVQ:  4 (3'b100)
-- 
-- FILTER_RANGE: 5 (3'b101)

myPLL :: ("REFERENCECLK" ::: Clock inp 'Source)
      -> ("REFERENCERST" ::: Signal inp Bool)
      -> ("CLK" ::: Clock outdom 'Source
         ,"RST" ::: Reset outdom 'Asynchronous)
myPLL = ice40Top d0 d7 d4 d5

-- System clock fed into FPGA
-- 100MHz => 10,000ps
type ClkSys = 'Dom "system" 10000

-- PLL generated 50MHz clock
--  50MHz => 20,000ps
type Clk50  = 'Dom "main" 20000


flipper :: (Num a, Eq a) => a -> Signal Clk50 Bit
flipper n =  mealy go (0,0) $ osc
   where go (i,x) _ | i == n    = ((0,   complement x), complement x)
                    | otherwise = ((i+1,     x),     x)

--osc :: Signal Clk50 Bit
osc = register 0 (pure 0)


blinky :: Signal Clk50 Bit
blinky = flipper 29999999

{-# ANN topEntity
  (defTop
    { t_name   = "LED1"
    , t_inputs = [ PortName "CLK" ]
    , t_output = PortName "LED0"
    }) #-}
topEntity :: Clock ClkSys 'Source
          -> Signal Clk50 Bit
topEntity clk = let (clk', rst) = myPLL clk (pure True)
          in withClockReset clk' rst blinky


