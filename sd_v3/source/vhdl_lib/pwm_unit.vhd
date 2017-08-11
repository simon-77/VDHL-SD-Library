--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- A VHDL-Library for reading SD-Cards with a FPGA inside a small test project.
-- Copyright (C) 2017  Simon Aster
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
----------------------------------------------
-- Library:		vhdl_lib
-- File:			pwm_uni.vhd
-- Author:		Aster Simon
-- Created:		2016
-- Modified:	2016-06-12
-- Version:		4.2
----------------------------------------------
-- Description:
-- This unit generates a pwm signal. The duty-cycle of pwm_out
-- is 'pwm_val' / (max-1). The pwm frequency of 'pwm_out' is
-- f(clk_en) / (max-2).
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;



entity pwm_unit is
generic(
	max			: natural;		-- exclusive maximum for 'pwm_val'
	phase		: natural := 0	-- (optional) phase of the pwm-signal [1/100]
);
port(
	rst			: in  std_ulogic;
	clk			: in  std_ulogic;
	clk_en 	: in  std_ulogic;
	pwm_val	: in  natural range 0 to max-1;
	pwm_out	: out std_ulogic
);	-- f(pwm_out) = f(clk_en) / (max-2)
end pwm_unit;

architecture pwm_unit_a of pwm_unit is
	constant phase_val : natural := (max-1) * phase / 100;
	
	-- dut-cyc(0) = off; duty-cycle(max-1) = on; => count 0 to (max-2)
	signal count : natural range 0 to max-2;
begin
	
	pwm : process(count)
	begin
		if pwm_val > count then
			pwm_out <= '1';
		else
			pwm_out <= '0';
		end if;
	end process;
	
	
	counter : process(rst, clk)
	begin
		if rst = '0' then
			count <= phase_val;
			
		elsif clk'event and clk = '1' then
		if clk_en = '1' then
			
			case count is
				when max-2	=>	count <= 0;
				when others => count <= count + 1;
			end case;
			
		end if;
		end if;
	end process;
	
end pwm_unit_a;
