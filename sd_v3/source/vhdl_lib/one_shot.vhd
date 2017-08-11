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
-- File:			one_shot.vhd
-- Author:		Simon Aster
-- Created:		2016
-- Modified:	2017-06-03
-- Version:		4.3
----------------------------------------------
-- Description:
-- After a rising edge of input, tick will be set high
-- for one clk cycle.
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;



entity one_shot is
port(
	rst		: in  std_ulogic;
	clk		: in  std_ulogic;
	input	: in  std_ulogic;
	tick	: out std_ulogic
);
end one_shot;

architecture one_shot_a of one_shot is
	signal input_dly	: std_ulogic;

begin

	tick <= input and not input_dly;

	next_state_logic : process(rst, clk)
	begin
	if rst = '0' then
		input_dly <= '0';
	
	elsif clk'event and clk = '1' then
		input_dly <= input;

	end if;	
	end process;
end one_shot_a;
