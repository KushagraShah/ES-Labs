
module system (
	clk_clk,
	dispaly_6mod7seg_1_conduit_end_reset_led,
	dispaly_6mod7seg_1_conduit_end_nseldig,
	dispaly_6mod7seg_1_conduit_end_selseg,
	reset_reset_n);	

	input		clk_clk;
	output		dispaly_6mod7seg_1_conduit_end_reset_led;
	output	[5:0]	dispaly_6mod7seg_1_conduit_end_nseldig;
	output	[7:0]	dispaly_6mod7seg_1_conduit_end_selseg;
	input		reset_reset_n;
endmodule
