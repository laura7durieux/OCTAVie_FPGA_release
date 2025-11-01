-- ============================================================================
-- Entity: control_adc_2ch
-- Architecture: control_adc_2ch_beh
-- Description:
--   Dual-channel ADC controller using a bit-banged SPI-like interface.
--   A 40 MHz system clock drives a fixed 200-cycle frame:
--     • Channel 1 phase:   cycles 0–99   (CONV pulse at 0; data read 75–99)
--     • Channel 2 phase:   cycles 100–199 (CONV pulse at 100; data read 175–199)
--   For each channel:
--     1) Assert a 1-clock CONV pulse and wait for conversion to complete.
--     2) Toggle SCK for 12 reads on data_SDO (MSB to LSB) while updating SDI bits
--        that pre-configure the next conversion (channel selection, mode, etc.).
--
-- Interface:
--   Inputs:
--     CLK  – System clock at 40 MHz
--     RST  – Active-low reset, synchronous to CLK
--     data_SDO – Serial data line from ADC (sample bits read on SCK rising edge)
--   Outputs:
--     conv, sck, sdi – SPI-like interface control signals for the ADC
--     data_paral_ch1, data_paral_ch2 – 12-bit parallel outputs for each channel
--
-- Timing and operation:
--   - Each frame lasts 200 clock cycles (5 µs at 40 MHz).
--   - Conversion waiting time: 75 cycles after CONV pulse.
--   - 25 clock cycles are used for serial readout and next-configuration setup.
--   - SCK toggles once per bit; data_SDO is sampled when SCK = '1'.
--   - The SDI line carries configuration bits for the upcoming channel.
--
-- Notes:
--   - The design is fully deterministic and free-running (no external handshake).
--   - Ensure ADC setup/hold timings and conversion delay meet 40 MHz constraints.
--   - Reset clears outputs and restarts the 200-cycle sequence.
--
-- Revision history:
--   v1.0 – Full English documentation for HardwareX article.
-- 
-- Author : L. Durieux
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity control_adc_2ch is
	port(
		CLK, RST : in std_logic;                       -- 40 MHz system clock and active-low reset
		data_SDO : in std_logic;                       -- Serial data input from ADC
		conv, sck, sdi : out std_logic;                -- SPI interface signals
		data_paral_ch1, data_paral_ch2 : out std_logic_vector(11 downto 0) -- 12-bit parallel outputs
	);
end control_adc_2ch;

architecture control_adc_2ch_beh of control_adc_2ch is
begin

PROCESS (CLK)
	variable counter : integer := 0; -- Counts from 0 to 199 (200 cycles per frame)

BEGIN
	IF ((CLK'event) and (CLK = '1')) THEN
	
		-- Reset condition: clear outputs and counter
		if (RST = '0') then
			conv <= '0';
			sck <= '0';
			sdi <= '0';
			data_paral_ch1 <= (others => '0');
			data_paral_ch2 <= (others => '0');
			counter := 0;
		
		else
			-- ================================================
			-- Channel 1 operation (cycles 0–99)
			-- ================================================

			-- Phase 1: Start conversion and wait for completion (0–74)
			if (counter >= 0 and counter < 75) then
				sck <= '0'; -- Keep serial clock low during conversion
				if (counter = 0) then
					conv <= '1'; -- Single-cycle CONV pulse
				else 
					conv <= '0';
				end if;
				counter := counter + 1;
			
			-- Phase 2: Read 12 bits and set configuration for next conversion (75–99)
			elsif (counter >= 75 and counter < 100) then
				conv <= '0'; -- Conversion command disabled
				if (counter = 75) then
					sck <= '0'; sdi <= '0'; -- Differential mode
				elsif (counter = 76) then
					sck <= '1'; data_paral_ch1(11) <= data_SDO;
				elsif (counter = 77) then
					sck <= '0'; sdi <= '0'; -- Sign control
				elsif (counter = 78) then
					sck <= '1'; data_paral_ch1(10) <= data_SDO;
				elsif (counter = 79) then
					sck <= '0'; sdi <= '0'; -- Next channel high bit (channel 2)
				elsif (counter = 80) then
					sck <= '1'; data_paral_ch1(9) <= data_SDO;
				elsif (counter = 81) then
					sck <= '0'; sdi <= '1'; -- Next channel low bit (channel 2)
				elsif (counter = 82) then
					sck <= '1'; data_paral_ch1(8) <= data_SDO;
				elsif (counter = 83) then
					sck <= '0'; sdi <= '0'; -- Unipolar mode
				elsif (counter = 84) then
					sck <= '1'; data_paral_ch1(7) <= data_SDO;
				elsif (counter = 85) then
					sck <= '0'; sdi <= '0'; -- Disable sleep
				elsif (counter = 86) then
					sck <= '1'; data_paral_ch1(6) <= data_SDO;
				elsif (counter = 87) then
					sck <= '0';
				elsif (counter = 88) then
					sck <= '1'; data_paral_ch1(5) <= data_SDO;
				elsif (counter = 89) then
					sck <= '0';
				elsif (counter = 90) then
					sck <= '1'; data_paral_ch1(4) <= data_SDO;
				elsif (counter = 91) then
					sck <= '0';
				elsif (counter = 92) then
					sck <= '1'; data_paral_ch1(3) <= data_SDO;
				elsif (counter = 93) then
					sck <= '0';
				elsif (counter = 94) then
					sck <= '1'; data_paral_ch1(2) <= data_SDO;
				elsif (counter = 95) then
					sck <= '0';
				elsif (counter = 96) then
					sck <= '1'; data_paral_ch1(1) <= data_SDO;
				elsif (counter = 97) then
					sck <= '0';
				elsif (counter = 98) then
					sck <= '1'; data_paral_ch1(0) <= data_SDO; -- LSB
				elsif (counter = 99) then
					sck <= '0';
				end if;
				counter := counter + 1;
			
			-- ================================================
			-- Channel 2 operation (cycles 100–199)
			-- ================================================
			
			-- Phase 1: Start conversion and wait for completion (100–174)
			elsif (counter >= 100 and counter < 175) then
				sck <= '0';
				if (counter = 100) then
					conv <= '1'; -- Start second channel conversion
				else 
					conv <= '0';
				end if;
				counter := counter + 1;
			
			-- Phase 2: Read 12 bits for channel 2 (175–199)
			elsif (counter >= 175 and counter < 200) then
				conv <= '0';
				if (counter = 175) then
					sck <= '0'; sdi <= '0'; -- Differential mode
				elsif (counter = 176) then
					sck <= '1'; data_paral_ch2(11) <= data_SDO;
				elsif (counter = 177) then
					sck <= '0'; sdi <= '0'; -- Sign control
				elsif (counter = 178) then
					sck <= '1'; data_paral_ch2(10) <= data_SDO;
				elsif (counter = 179) then
					sck <= '0'; sdi <= '0'; -- Next channel select (channel 1)
				elsif (counter = 180) then
					sck <= '1'; data_paral_ch2(9) <= data_SDO;
				elsif (counter = 181) then
					sck <= '0'; sdi <= '0'; -- Low channel select bit (ch1)
				elsif (counter = 182) then
					sck <= '1'; data_paral_ch2(8) <= data_SDO;
				elsif (counter = 183) then
					sck <= '0'; sdi <= '0'; -- Unipolar mode
				elsif (counter = 184) then
					sck <= '1'; data_paral_ch2(7) <= data_SDO;
				elsif (counter = 185) then
					sck <= '0'; sdi <= '0'; -- Disable sleep
				elsif (counter = 186) then
					sck <= '1'; data_paral_ch2(6) <= data_SDO;
				elsif (counter = 187) then
					sck <= '0';
				elsif (counter = 188) then
					sck <= '1'; data_paral_ch2(5) <= data_SDO;
				elsif (counter = 189) then
					sck <= '0';
				elsif (counter = 190) then
					sck <= '1'; data_paral_ch2(4) <= data_SDO;
				elsif (counter = 191) then
					sck <= '0';
				elsif (counter = 192) then
					sck <= '1'; data_paral_ch2(3) <= data_SDO;
				elsif (counter = 193) then
					sck <= '0';
				elsif (counter = 194) then
					sck <= '1'; data_paral_ch2(2) <= data_SDO;
				elsif (counter = 195) then
					sck <= '0';
				elsif (counter = 196) then
					sck <= '1'; data_paral_ch2(1) <= data_SDO;
				elsif (counter = 197) then
					sck <= '0';
				elsif (counter = 198) then
					sck <= '1'; data_paral_ch2(0) <= data_SDO; -- LSB
				elsif (counter = 199) then
					sck <= '0';
				end if;
				counter := counter + 1;
			end if;
			
			-- Restart frame after both channels complete
			if (counter = 200) then
				counter := 0;
			end if;
		end if;
		
	END IF;
END PROCESS;

end architecture;
