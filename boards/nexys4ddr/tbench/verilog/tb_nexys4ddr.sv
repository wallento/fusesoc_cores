`timescale 1ps / 1ps

module tb_nexys4ddr
  (
   output reg   clk,

   // push button "CPU RESET" (C12)
   output reg   cpu_resetn,

   // UART (signals names from a DTE/PC point of view)
   output       uart_txd_in,
   input        uart_rxd_out,

   input        ck,
   input        ck_n,
   input        cke,
   input        cs_n,
   input        ras_n,
   input        cas_n,
   input        we_n,
   inout [1:0]  dm_rdqs,
   input [2:0]  ba,
   input [12:0] addr,
   inout [15:0] dq,
   inout [1:0]  dqs,
   inout [1:0]  dqs_n,
   output [1:0] rdqs_n,
   input        odt
   );

   always
     #5000 clk = ~clk;

   initial begin
      u_ddr2.reset_task;
      clk = 0;

      // XXX: is this how it works on the board? Isn't cpu_resetn just a button?
      cpu_resetn = 0;
      @(negedge glbl.GSR);
      #100000
      cpu_resetn = 1;
   end

   ddr2
     u_ddr2
       (.*);

   uartdpi
     #(.BAUD(115200),.FREQ(100000000))
   u_uartdpi(.*,
             .tx  (uart_txd_in),
             .rx  (uart_rxd_out),
             .rst (glbl.GSR));



endmodule // tb_nexys4
