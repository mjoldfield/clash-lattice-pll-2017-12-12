module LED1
  ( 
    topEntity 
  ) where


import Clash.Explicit.Prelude
import Lattice

-- System clock fed into FPGA
-- 12MHz => 83,333ps
type ClkSys = 'Dom "system" 83333

-- PLL generated 60MHz clock
--  60MHz => 16,667pm
type ClkPLL  = 'Dom "main" 16667

--
-- F_PLLIN:    12.000 MHz (given)
-- F_PLLOUT:   60.000 MHz (requested)
-- F_PLLOUT:   60.000 MHz (achieved)
-- 
-- FEEDBACK: SIMPLE
-- F_PFD:   12.000 MHz
-- F_VCO:  960.000 MHz
-- 
-- DIVR:  0 (4'b0000)
-- DIVF: 79 (7'b1001111)
-- DIVQ:  4 (3'b100)
-- 
-- FILTER_RANGE: 1 (3'b001)
-- 
myPLL :: ("REFERENCECLK" ::: Clock inp 'Source)
      -> ("REFERENCERST" ::: Signal inp Bool)
      -> ("PLLCLK" ::: Clock outdom 'Source
         ,"RST" ::: Reset outdom 'Asynchronous)
--myPLL = ice40Top d0 d7 d4 d5
myPLL = ice40Top d0 d79 d4 d1

--  do (n-1) cycles of 0, then (n-1) cycles of 1, and repeat..
flipper :: (Num a, Eq a) => Clock dom gated -> Reset dom sync -> a -> Signal dom Bit
flipper clk rst n =  mealy clk rst go (0,0) $ zeros clk rst
   where go (i,x) _ | i == n    = ((0,   complement x), complement x)
                    | otherwise = ((i+1,     x),     x)

-- a signal of 0 just to feed into the mealy machine
zeros :: Clock dom gated -> Reset dom sync -> Signal dom Bit
zeros clk rst = register clk rst (0 :: Bit) (pure 0)

blinky :: Clock dom gated -> Reset dom sync -> Signal dom Bit
blinky clk rst = flipper clk rst (24999999 :: Unsigned 32)

{-# ANN topEntity
  (defTop
    { t_name   = "LED1"
    , t_inputs = [ PortName "CLK" ]
    , t_output = PortName "LED0"
    }) #-}
topEntity :: Clock ClkSys 'Source
          -> Signal ClkPLL Bit
topEntity clk = let (clk', rst) = myPLL clk (pure True)
          in blinky clk' rst


