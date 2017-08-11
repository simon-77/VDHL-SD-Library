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
-- Project:		sd_v3
-- File:			tick_extend.vhd
-- Author:		Simon Aster
-- Created:		2017-06-02
-- Modified:	2017-06-02
-- Version:		1.1
----------------------------------------------
-- Description:
-- Extend the tick 'a', which has the length of one clock-periode, to
-- the tick 'y' that is related to the clock-enable signal 'clk_en_y'.
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.de0_nano_const_pkg.all;

entity tick_extend is
port(
	rst				: in  std_ulogic;
	clk				: in  std_ulogic;
	------------------
	clk_en_y	: in  std_ulogic;
	a					: in  std_ulogic;
	y					: out std_ulogic
);
end tick_extend;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture tick_extend_a of tick_extend is
	signal tmp	: std_ulogic;
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
begin

	y <= a or tmp;

	p_tick_extend: process(rst, clk)
	begin
	if rst = '0' then
		tmp <= '0';

	elsif clk'event and clk = '1' then

		if a = '1' then
			tmp <= '1';
		end if;

		if clk_en_y = '1' then
			tmp <= '0';
		end if;

	end if;
	end process;

end tick_extend_a;
