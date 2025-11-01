-- ============================================================================
-- Entity: adder_custom
-- Architecture: adder_custom_beh
-- Description:
--   Simple 24-bit combinational adder.
--   This module performs an unsigned addition between two input vectors (A, B)
--   and outputs the 24-bit result (S). 
--
-- Context of use:
--   Used inside the FPGA signal-processing chain of the OCTAVie system
--   to perform arithmetic operations such as amplitude accumulation or scaling.
--
-- Notes:
--   - No clock or reset signal: this is a purely combinational logic block.
--   - Uses the IEEE.std_logic_unsigned library for arithmetic operations.
--   - Overflow beyond 24 bits is ignored (result wraps around).
--
-- Revision history:
--   v1.0 – Initial implementation and documentation for HardwareX article.
-- 
-- Author : L. Durieux
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

-- ============================================================================
-- Entity declaration
-- ============================================================================
entity adder_custom is
	port(
		A : in  std_logic_vector(23 downto 0);  -- First 24-bit input operand
		B : in  std_logic_vector(23 downto 0);  -- Second 24-bit input operand
		S : out std_logic_vector(23 downto 0)   -- 24-bit sum output (A + B)
	);
end adder_custom;

-- ============================================================================
-- Architecture implementation
-- ============================================================================
architecture adder_custom_beh of adder_custom is
begin

	-- Combinational addition: output is the sum of A and B.
	S <= A + B;

end adder_custom_beh;
