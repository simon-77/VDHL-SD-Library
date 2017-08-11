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
-- File:			reset_unit.vhd
-- Author:		Aster Simon
-- Created:		2016
-- Modified:	2016-06-12
-- Version: 	5.2
----------------------------------------------
-- Description:
-- This unit generates a low-active reset signal
-- for the first n positive clk edges 
-- after this device is powered on. 
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.de0_nano_const_pkg.all;


entity reset_unit is
generic(n : natural := CLK_FREQ/10);	-- default rst-time: 1/10s = 100ms
port(
	i_rst		: in  std_ulogic := '1';
	o_rst		: out std_ulogic;
	clk			: in  std_ulogic
);
end reset_unit;

architecture reset_unit_a of reset_unit is
	signal count : natural range 0 to n := 0;
begin
	
	with count select
		o_rst <=	'1' when n,
					'0' when others;
	
	pwr_on_reset : process(i_rst, clk)
	begin
		if i_rst = '0' then
			count <= 0;

		elsif clk'event and clk = '1' then
			
			case count is
				when n =>		count <= count;
				when others =>	count <= count + 1;
			end case;
			
		end if;
	end process;
	
end reset_unit_a;
