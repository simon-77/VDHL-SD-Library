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
-- Library:		sd
-- File:			crc.vhd
-- Author:		Simon Aster
-- Created:		2017-03-09
-- Modified:	2017-06-02
-- Version:		2.3
----------------------------------------------
-- Description:
-- This unit calculates the CRC (Cyclic Redundancy Check).
------------------------------
-- 'length' is the number of bits of the calculated crc.
-- If 'dat_in' is '1', the internal crc-register will be 
-- xored with 'polynomial', which has to have 'length' number of bits.
------------------------------
-- 'rst' and 'clk' must be provided by the system. Additionally this unit can be
-- slowed down with an 'clk_en' signal.
-- The signals 'rst_crc', 'en_crc' and 'shift_out' control the behaviour of this unit.
-- Those actions are taken with the next rising edge of the clock.
--
-- * 'rst_crc' = 1
-- The internal crc-register will be set to 0
--
-- * 'en_crc' = 1
-- The next bit 'dat_in' is shifted in for calculating the crc
--
-- * 'shift_out' = 1
-- The internal crc-register will be shifted out. 'dat_in' will be ignored
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.de0_nano_const_pkg.all;

entity crc is
generic(
	length			: natural;
	polynomial	: std_ulogic_vector
);
port(
	rst				: in  std_ulogic;
	clk				: in  std_ulogic;
	clk_en		: in  std_ulogic := '1';
	------------------
	rst_crc			: in  std_ulogic := '0';
	en_crc			: in  std_ulogic := '1';
	shift_out		: in  std_ulogic := '0';
	dat_in			: in  std_ulogic;
	dat_out			: out std_ulogic
);
end crc;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture crc_a of crc is
	signal reg	: std_ulogic_vector(length-1 downto 0);
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
begin

	dat_out <= reg(length-1);


	p_crc: process(rst, clk)
	begin
	if rst = '0' then
		reg <= (others=>'0');

	elsif clk'event and clk = '1' then
		if clk_en = '1' then
	
			if rst_crc = '1' then
				reg <= (others=>'0');
	
			elsif en_crc = '1' then
				if (reg(length-1) xor dat_in) = '1' then
					reg <= (reg(length-2 downto 0) & '0') xor polynomial;
				else
					reg <= (reg(length-2 downto 0) & '0');
				end if;

			elsif shift_out = '1' then
				reg <= reg(length-2 downto 0) & '0';
			end if;
	
		end if;
	end if;
	end process;

end crc_a;
