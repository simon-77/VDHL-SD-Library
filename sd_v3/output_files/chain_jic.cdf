/* Quartus Prime Version 16.0.1 Build 218 06/01/2016 SJ Lite Edition */
/*
############################################################
# Project:	sd_v3
# File:			chain_jic.cdf
# Author:		Simon Aster
# Created:	2017-05-19
# Modified:	2017-05-19
# Version:	1
############################################################
# Template:
# ------------------
# File:			chain_jic.cdf
# Created:	December 17, 2016
# Modified:	December 17, 2016
# Version:	1
############################################################
# Quartus Programming chain for programming a *jic file.
*/
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(EP4CE22) Path("/myData/projects/de0_nano/sd_v3/") File("sd_v3.jic") MfrSpec(OpMask(1) SEC_Device(EPCS64) Child_OpMask(1 7));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
