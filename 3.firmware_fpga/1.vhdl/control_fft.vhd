library ieee;

use ieee.std_logic_1164.all;


--- déclaration de l'entité
entity control_fft is
	--generic(Tw : integer := 5);

	port(CLK: in std_logic; -- Clock
		in_signal: in std_logic_vector(11 downto 0); -- Data
		
		sink_valid, sink_sop, sink_eop, inverse, source_ready : out std_logic; -- signal need to control FFT
		sink_error : out std_logic_vector (1 downto 0); -- signal to generate an error - not used here
		
		fft_pts : out std_logic_vector (9 downto 0); -- chose the number of point of the FFT
		
		outreal, outimag : out std_logic_vector(11 downto 0);
		
		reset : out std_logic -- Since the fft function want a front to start with the reset 
		
		); 
	
end control_fft;


-- architecture
ARCHITECTURE control_fft_bh of control_fft is
BEGIN

-- Declaration of the static signals
inverse <= '0'; -- Not doing the reverse FFT
sink_error <= "00"; -- generate some kind of error on the ligne - not used

-- chosing the nomber of point of the FFT - will be used to test the results of the different possibilities
fft_pts <="1000000000"; -- 512

-- Declaration of the data signals
outreal <= in_signal; 
outimag <= (others => '0'); -- will not use the phase of the data

-- Definition of control signals

PROCESS(CLK)

variable count : integer := 512; -- will count the number of data points
variable count_rst : integer := 10;-- will count the number of clock trigger to launch the reset at the start

BEGIN

-- To generate the eop and sop signal, indicating the start and the end of the fft data points
IF((CLK'event) and (CLK = '1')) THEN
	count := count - 1;
		
	
	IF(count = 1) THEN
		sink_eop <= '1'; -- eop : end of paquet
	ELSE
		sink_eop <= '0';
	END IF;
	
	
	IF(count = 0) THEN
		count := 512;
		sink_sop <= '1'; -- start of paquet
	ELSE
		sink_sop <= '0';
	END IF;
	
	-- taking care of signals needing one rising clock
	IF(count_rst>0) THEN
		count_rst := count_rst - 1;
	END IF;
	
	IF(count_rst < 4) THEN
		reset <= '1'; -- Je crois qu'il doit etre en négatif
	ELSE
		reset <= '0';
	END IF;
	
	IF(count_rst < 2)THEN
		sink_valid <= '1'; -- 
		source_ready <= '1';
	ELSE
		sink_valid <= '0'; -- 
		source_ready <= '0';
	END IF;
	
	
END IF;

END PROCESS;

END ARCHITECTURE;

