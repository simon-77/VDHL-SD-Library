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
-- File:			ff_rs.vhd
-- Author:		Simon Aster
-- Created:		2016
-- Modifed:		2017-04-04
-- Version:		1.2
----------------------------------------------
-- Description:
-- RS-FlipFlop.
-- q is changed when a rising clk-edge occures and clk_en = '1'.
-- s: set q to '1'
-- r: set q to '0'
-- nothing: q does not change
-- s & r: set q to '1'
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;


entity ff_rs is
port(
	rst			: in  std_ulogic;
	clk			: in  std_ulogic;
	clk_en	: in  std_ulogic := '1';
	s				: in  std_ulogic;
	r				: in  std_ulogic;
	q				: out std_ulogic
);
end ff_rs;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture ff_rs_a of ff_rs is
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
begin

	p_ff_rs: process(rst, clk)
	begin
		if rst = '0' then
			q <= '0';

		elsif clk'event and clk = '1' then
			if s = '1' then
				q <= '1';
			elsif r = '1' then
				q <= '0';
			end if;
		end if;
	end process;

end ff_rs_a;
