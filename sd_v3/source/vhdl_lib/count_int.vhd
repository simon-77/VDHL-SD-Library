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
-- File:			count_int.vhd
-- Author:		Simon Aster
-- Created:		2016
-- Modified:	2017-04-02
-- Version:		2.2
----------------------------------------------
-- Description:
-- This unit will count the integer signal 'cnt' in a range
-- from min to max-1. 'clk_en' slows the whole unit down.
-- 'set_min' and 'set_max' set output value 'cnt' to minimum and maximum.
-- 'up' and 'down' increments and decrements the output value 'cnt'.
-- prioritiy: 'set_min'; 'set_max'; 'up'; 'down'
-- 'cnt' will overflow and underflow at max-1 and min.
-- overflow-flag 'ofl' and underflow-flag 'ufl' will generate a tick.
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.de0_nano_const_pkg.all;

entity count_int is
generic(
	max			: integer;
	min			: integer := 0
);
port(
	rst			: in  std_ulogic;
	clk			: in  std_ulogic;
	clk_en	: in  std_ulogic := '1';
	set_min	: in  std_ulogic := '0';
	set_max	: in  std_ulogic := '0';
	up			: in  std_ulogic := '0';
	down		: in  std_ulogic := '0';
	cnt			: out integer range min to max-1;
	ofl			: out std_ulogic;
	ufl			: out std_ulogic
);
end count_int;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture count_int_a of count_int is
	signal val	: integer range min to max-1;
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
begin

	cnt <= val;

	p_count_int: process(rst, clk)
	begin
	
	if rst = '0' then
		val <= min;
		ofl <= '0';
		ufl <= '0';

	elsif clk'event and clk = '1' then
		if clk_en = '1' then
			ofl <= '0';
			ufl <= '0';

			if set_min = '1' then
				val <= min;

			elsif set_max = '1' then
				val <= max-1;

			elsif up = '1' then
				case val is
					when max-1	=>	val <= min;
									ofl <= '1';
					when others =>	val <= val + 1;
				end case;

			elsif down = '1' then
				case val is
					when min	=>	val <= max-1;
									ufl <= '1';
					when others =>	val <= val - 1;
				end case;
				
			end if;
		end if;
	end if;
	end process;

end count_int_a;
