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
-- File:			prescaler.vhd
-- Author:		Aster Simon
-- Created:		2016
-- Modified:	2016-06-12
-- Version:		4.2
----------------------------------------------
-- Description:
-- This unit divides the clk signal by 'divisor'
-- and generates an enable signal with that frequency.
-- Additionally 'phase' is the phase shift of the
-- 'clk_en' signal.
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;



entity prescaler is
generic(
	divisor		: natural;		-- f(clk_en) = f(clk) / divisor
	phase			: natural := 0	-- (optional) phase of clk_en [1/100]
);
port(
	rst				: in  std_ulogic;
	clk				: in  std_ulogic;
	i_clk_en	: in  std_ulogic := '1';
	o_clk_en	: out std_ulogic
);
end prescaler;



architecture prescaler_a of prescaler is
	constant phase_val	: natural := divisor * phase / 100;
	signal count : natural range 0 to divisor-1;

begin
	
	with count select
		o_clk_en	<= 	'1' when divisor-1,
						'0' when others;

	counter : process(rst, clk)
	begin
		if rst = '0' then
			count <= phase_val;

		elsif clk'event and clk = '1' and i_clk_en = '1' then

			case count is
				when divisor-1	=>	count  <= 0;
				when others		=>	count  <= count + 1;
			end case;	

		end if;
	end process;

end prescaler_a;
