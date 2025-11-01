-- ============================================================================
-- Entity: substraction_custom
-- Architecture: substraction_custom_beh
-- Description:
--   Signed 12-bit sample-by-sample subtraction between two input channels.
--   The operation is synchronous with the rising edge of clk and outputs
--   the lower 12 bits of the signed difference.
--
-- Interface:
--   Inputs:
--     clk             – System clock.
--     data_paral_ch1  – First 12-bit input (minuend).
--     data_paral_ch2  – Second 12-bit input (subtrahend).
--   Outputs:
--     data_paral      – 12-bit result of (ch1 - ch2).
--
-- Operation:
--   - On each rising edge of clk, compute:
--         data := resize(signed(ch1) - signed(ch2), 13)
--     to allow for one extra bit of overflow/underflow margin.
--   - The result is truncated back to 12 bits and assigned to data_paral.
--   - The internal signal is signed(12 downto 0) to avoid loss during subtraction.
--
-- Notes:
--   - Uses ieee.numeric_std for type-safe signed arithmetic.
--   - Overflow is not saturated; the upper bit is simply truncated.
--   - The commented lines show an alternate approach (two’s complement inversion)
--     that was replaced by the direct signed subtraction method.
--   - This block is typically used to compute the differential signal between
--     two ADC channels before FFT processing in the OCTAVie system.
--
-- Revision history:
--   v1.0 – English documentation added for HardwareX.
-- 
-- Author : L. Durieux
-- ============================================================================

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity substraction_custom is
	port(
		clk              : in  std_logic;
		data_paral_ch1   : in  std_logic_vector(11 downto 0);
		data_paral_ch2   : in  std_logic_vector(11 downto 0);
		data_paral       : out std_logic_vector(11 downto 0)
	);
end substraction_custom;

architecture substraction_custom_beh of substraction_custom is
begin

	process (clk)
		variable data : signed(12 downto 0);  -- 13-bit signed intermediate result
	begin
		if rising_edge(clk) then
			-- Perform signed subtraction between the two input channels
			data := resize(signed(data_paral_ch1) - signed(data_paral_ch2), 13);

			-- Assign the lower 12 bits of the result to the output
			data_paral <= std_logic_vector(data(11 downto 0));
		end if;
	end process;

end architecture;
