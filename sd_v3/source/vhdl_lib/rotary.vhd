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
-- File:			rotary.vhd
-- Author:		Simon Aster
-- Created:		2016
-- Modified:	2017-02-10
-- Version:		5.2
----------------------------------------------
-- Description:
-- This unit takes the two phases (a and b) of 
-- an gray-code rotary-encoder. Every four steps
-- a tick depending on the rotation direction is
-- generated. The direction can be inverted by
-- by setting 'dir' to '1'.
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.de0_nano_const_pkg.all;
use work.vhdl_lib_pkg.debounce;


entity rotary is
generic(dir		: std_ulogic := '0');
port(
	rst					: in  std_ulogic;
	clk					: in  std_ulogic;
	clk_en			: in  std_ulogic := '1';
	a						: in  std_ulogic;
	b						: in  std_ulogic;
	tick_cw			: out std_ulogic;
	tick_ccw		: out std_ulogic
);
end rotary;


architecture rotary_a of rotary is
	constant deb_n		: natural := CLK_FREQ/10e3;
	constant threshhold : natural := 3;

	signal state : std_ulogic_vector(3 downto 0);
	signal count : integer range -8 to 7;

	signal inc	: integer range -1 to 1;
begin

	with dir select
		inc <=  1 when '0',
			   -1 when others;

	debounce_a: debounce generic map (n=>deb_n) port map (rst=>rst, clk=>clk, key=>a, debounced=>state(0));
	debounce_b: debounce generic map (n=>deb_n) port map (rst=>rst, clk=>clk, key=>b, debounced=>state(1));
	
	rotary_p: process(rst, clk)
	begin
		if rst = '0' then
			state(3 downto 2) <= (others=>'1');
			count <= 0;
			tick_cw <= '0';
			tick_ccw <= '0';

		elsif clk'event and clk = '1' and clk_en = '1' then
			state(3 downto 2) <= state(1 downto 0);

			if state(3 downto 2) /= state(1 downto 0) then
				case state is
					when "1101"	=>	count <= count + inc;
					when "0100"	=>	count <= count + inc;
					when "0010" =>	count <= count + inc;
					when "1011" =>	count <= count + inc;
	
					when "1110"	=>	count <= count - inc;
					when "1000"	=>	count <= count - inc;
					when "0001"	=>	count <= count - inc;
					when "0111"	=>	count <= count - inc;
	
					when others => count <= 0;
				end case;
			end if;

			if state(1 downto 0) = "11" then
				count <= 0;
			end if;


			tick_cw <= '0';
			tick_ccw <= '0';

			if count >= threshhold then
				tick_cw <= '1';
				count <= 0;
			end if;

			if count <= -threshhold then
				tick_ccw <= '1';
				count <= 0;
			end if;

		end if;
	end process;
	
end rotary_a;
