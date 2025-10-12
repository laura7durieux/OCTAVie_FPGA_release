library ieee;

use ieee.std_logic_1164.all;


--- déclaration de l'entité
entity control_adc_2ch is
	--generic(Tw : integer := 5);

	port(CLK, RST: in std_logic; -- Clock general - 40MHz
		data_SDO: in std_logic; -- Data
		
		conv, sck, sdi : out std_logic; -- SPI ADC interface
		
		data_paral_ch1, data_paral_ch2 : out std_logic_vector(11 downto 0)		
		);  -- ch2 added
	
end control_adc_2ch;


ARCHITECTURE control_adc_2ch_beh of control_adc_2ch is

BEGIN

PROCESS (CLK)
variable counter : integer := 0;


BEGIN

IF((CLK'event) and (CLK = '1')) THEN
	
	if (RST = '0') then
	conv <= '0';
	sck <= '0';
	sdi <= '0';
	data_paral_ch1 <= (others => '0');
	data_paral_ch2 <= (others => '0');
	counter := 0;
	
	else
	
	-- Script écrit pour une horloge de 40M avec 200 coups d'horloges par cycle
	
	-------------------------------------------------------------------------------------------
	------------------------------ Channel 1 -00-(0 à 99 inclut)-----------------------------------
	-- Démarage de la conversion et attente de la fin de celle ci (75 coup d'horloge)
	if (counter >= 0 and counter < 75) then
		-- Clock de la liaison serie à 0 pendant cette étape
		SCK <= '0';
		-- Demander le demarrage de la conversion - 1 coup d'hloge (25 ns - need to be between 20 et 40 ns)
		if ((counter = 0)) then
			conv <= '1';
		else 
			conv <= '0';
		end if;
		-- add one to the counter
		counter := counter +1;
	
	
	-- deuxième etape : envoi des données et parametrage de la conversion suivante
	elsif (counter >= 75 and counter < 100) then
		-- Pas de demande de conversion
		conv <= '0';
		
		-- lecture et parametrage (25 coups d'horloge) - ecrire avec case statement à l'occase
		if (counter = 75) then
			SCK <= '0';
			SDI <= '0'; -- differnetial bit
			
		elsif (counter = 76) then
			SCK <= '1';
			data_paral_ch1(11) <= data_SDO; -- lire b11
			
		elsif (counter = 77) then
			SCK <= '0';
			SDI <= '0'; -- Change le signe
			
		elsif (counter = 78) then
			SCK <= '1';
			data_paral_ch1(10) <= data_SDO; -- lire b10
			
		elsif (counter = 79) then
			SCK <= '0';
			SDI <= '0'; -- poid fort de la chanel d'entrée (ch2 -01 - config d'avance)
			
		elsif (counter = 80) then
			SCK <= '1';
			data_paral_ch1(9) <= data_SDO; -- lire b9
			
		elsif (counter = 81) then
			SCK <= '0';
			SDI <= '1'; -- poid faible de la chanel d'entrée (ch2 -01- config d'avance)
			
		elsif (counter = 82) then
			SCK <= '1';
			data_paral_ch1(8) <= data_SDO; -- lire b8
			
		elsif (counter = 83) then
			SCK <= '0';
			SDI <= '0'; -- bit UNI - bipolar mode
			
		elsif (counter = 84) then
			SCK <= '1';
			data_paral_ch1(7) <= data_SDO; -- lire b7
			
		elsif (counter = 85) then
			SCK <= '0';
			SDI <= '0'; -- evite la veille
			
		elsif (counter = 86) then
			SCK <= '1';
			data_paral_ch1(6) <= data_SDO; -- lire b6
			
		elsif (counter = 87) then
			SCK <= '0';
			
		elsif (counter = 88) then
			SCK <= '1';
			data_paral_ch1(5) <= data_SDO; -- lire b5
			
		elsif (counter = 89) then
			SCK <= '0';
			
		elsif (counter = 90) then
			SCK <= '1';
			data_paral_ch1(4) <= data_SDO; -- lire b4
			
		elsif (counter = 91) then
			SCK <= '0';
			
		elsif (counter = 92) then
			SCK <= '1';
			data_paral_ch1(3) <= data_SDO; -- lire b3
			
		elsif (counter = 93) then
			SCK <= '0';
			
		elsif (counter = 94) then
			SCK <= '1';
			data_paral_ch1(2) <= data_SDO; -- lire b2
			
		elsif (counter = 95) then
			SCK <= '0';
			
		elsif (counter = 96) then
			SCK <= '1';
			data_paral_ch1(1) <= data_SDO; -- lire b1
			
		elsif (counter = 97) then
			SCK <= '0';
			
		elsif (counter = 98) then
			SCK <= '1';
			data_paral_ch1(0) <= data_SDO; -- lire b0
		
		elsif (counter = 99) then
			SCK <= '0';
		end if;
		
		-- add one to the counter
		counter := counter +1;
		
		---------------------------------------------------------------------------------------
		------------------------ Channel 2 -01- (100 à 199 inclut)----------------------------------
		-- Démarage de la conversion et attente de la fin de celle ci (75 coup d'horloge)
	elsif (counter >= 100 and counter < 175) then
		-- Clock de la liaison serie à 0 pendant cette étape
		SCK <= '0';
		-- Demander le demarrage de la conversion - 1 coup d'hloge (25 ns - need to be between 20 et 40 ns)
		if ((counter = 100)) then
			conv <= '1';
		else 
			conv <= '0';
		end if;
		-- add one to the counter
		counter := counter +1;
	
	
	-- deuxième etape : envoi des données et parametrage de la conversion suivante
	elsif (counter >= 175 and counter < 200) then
		-- Pas de demande de conversion
		conv <= '0';
		
		-- lecture et parametrage (25 coups d'horloge) - ecrire avec case statement à l'occase
		if (counter = 175) then
			SCK <= '0';
			SDI <= '0'; -- differential bit
			
		elsif (counter = 176) then
			SCK <= '1';
			data_paral_ch2(11) <= data_SDO; -- lire b11
			
		elsif (counter = 177) then
			SCK <= '0';
			SDI <= '0'; -- Change le signe
			
		elsif (counter = 178) then
			SCK <= '1';
			data_paral_ch2(10) <= data_SDO; -- lire b10
			
		elsif (counter = 179) then
			SCK <= '0';
			SDI <= '0'; -- poid fort de la chanel d'entrée (ch1 -00- pour le coup suivant)
			
		elsif (counter = 180) then
			SCK <= '1';
			data_paral_ch2(9) <= data_SDO; -- lire b9
			
		elsif (counter = 181) then
			SCK <= '0';
			SDI <= '0'; -- poid faible de la chanel d'entrée (ch1 -00- pour le coup suivant)
			
		elsif (counter = 182) then
			SCK <= '1';
			data_paral_ch2(8) <= data_SDO; -- lire b8
			
		elsif (counter = 183) then
			SCK <= '0';
			SDI <= '0'; -- bit UNI - bipolar mode
			
		elsif (counter = 184) then
			SCK <= '1';
			data_paral_ch2(7) <= data_SDO; -- lire b7
			
		elsif (counter = 185) then
			SCK <= '0';
			SDI <= '0'; -- evite la veille
			
		elsif (counter = 186) then
			SCK <= '1';
			data_paral_ch2(6) <= data_SDO; -- lire b6
			
		elsif (counter = 187) then
			SCK <= '0';
			
		elsif (counter = 188) then
			SCK <= '1';
			data_paral_ch2(5) <= data_SDO; -- lire b5
			
		elsif (counter = 189) then
			SCK <= '0';
			
		elsif (counter = 190) then
			SCK <= '1';
			data_paral_ch2(4) <= data_SDO; -- lire b4
			
		elsif (counter = 191) then
			SCK <= '0';
			
		elsif (counter = 192) then
			SCK <= '1';
			data_paral_ch2(3) <= data_SDO; -- lire b3
			
		elsif (counter = 193) then
			SCK <= '0';
			
		elsif (counter = 194) then
			SCK <= '1';
			data_paral_ch2(2) <= data_SDO; -- lire b2
			
		elsif (counter = 195) then
			SCK <= '0';
			
		elsif (counter = 196) then
			SCK <= '1';
			data_paral_ch2(1) <= data_SDO; -- lire b1
			
		elsif (counter = 197) then
			SCK <= '0';
			
		elsif (counter = 198) then
			SCK <= '1';
			data_paral_ch2(0) <= data_SDO; -- lire b0
		
		elsif (counter = 199) then
			SCK <= '0';
		end if;

		
		-- incrementation du counter
		counter := counter +1;
	end if;
	
	-- Resart the cycle
	if(counter = 200) then
		counter := 0;
	end if;
	
	end if;
	
END IF;

END PROCESS;
END ARCHITECTURE;