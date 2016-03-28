// Copyright 2016 by the authors
//
// Copyright and related rights are licensed under the Solderpad
// Hardware License, Version 0.51 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a
// copy of the License at http://solderpad.org/licenses/SHL-0.51.
// Unless required by applicable law or agreed to in writing,
// software, hardware and materials distributed under this License is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the
// License.
//
// Authors:
//    Stefan Wallentowitz <stefan@wallentowitz.de>

module wb2nasti
  #(parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter NASTI_ID_WIDTH = 1,
    parameter NASTI_ID = 0)
   (
    input                       clk,
    input                       rst,

    // Wishbone signals
    input                       wb_cyc_i,
    input                       wb_stb_i,
    input                       wb_we_i,
    input [ADDR_WIDTH-1:0]      wb_adr_i,
    input [DATA_WIDTH-1:0]      wb_dat_i,
    input [DATA_WIDTH/8-1:0]    wb_sel_i,
    input [2:0]                 wb_cti_i,
    input [1:0]                 wb_bte_i,
    output                      wb_ack_o,
    output                      wb_err_o,
    output                      wb_rty_o,
    output [DATA_WIDTH-1:0]     wb_dat_o,

    // NASTI signals
    output [NASTI_ID_WIDTH-1:0] m_nasti_awid,
    output [ADDR_WIDTH-1:0]     m_nasti_awaddr,
    output [7:0]                m_nasti_awlen,
    output [2:0]                m_nasti_awsize,
    output [1:0]                m_nasti_awburst,
    output [3:0]                m_nasti_awcache,
    output [2:0]                m_nasti_awprot,
    output [3:0]                m_nasti_awqos,
    output                      m_nasti_awvalid,
    input                       m_nasti_awready,
    output [DATA_WIDTH-1:0]     m_nasti_wdata,
    output [DATA_WIDTH/8-1:0]   m_nasti_wstrb,
    output                      m_nasti_wlast,
    output                      m_nasti_wvalid,
    input                       m_nasti_wready,
    input [NASTI_ID_WIDTH-1:0]  m_nasti_bid,
    input [1:0]                 m_nasti_bresp,
    input                       m_nasti_bvalid,
    output                      m_nasti_bready,
    output [NASTI_ID_WIDTH-1:0] m_nasti_arid,
    output [ADDR_WIDTH-1:0]     m_nasti_araddr,
    output [7:0]                m_nasti_arlen,
    output [2:0]                m_nasti_arsize,
    output [1:0]                m_nasti_arburst,
    output [3:0]                m_nasti_arcache,
    output [2:0]                m_nasti_arprot,
    output [3:0]                m_nasti_arqos,
    output                      m_nasti_arvalid,
    input                       m_nasti_arready,
    input [NASTI_ID_WIDTH-1:0]  m_nasti_rid,
    input [DATA_WIDTH-1:0]      m_nasti_rdata,
    input [1:0]                 m_nasti_rresp,
    input                       m_nasti_rlast,
    input                       m_nasti_rvalid,
    output                      m_nasti_rready
    );

   assign m_nasti_awid = NASTI_ID;
   assign m_nasti_awaddr = wb_adr_i;
   assign m_nasti_awlen = 0;
   assign m_nasti_awsize = DATA_WIDTH >> 4;
   assign m_nasti_awburst = 2'b01;
   assign m_nasti_awcache = 4'b0000;
   assign m_nasti_awprot = 3'b010;
   assign m_nasti_awqos = 4'b0000;

   assign m_nasti_wdata = wb_dat_i;
   assign m_nasti_wstrb = wb_sel_i;
   assign m_nasti_wlast = 1;

   assign m_nasti_arid = NASTI_ID;
   assign m_nasti_araddr = wb_adr_i;
   assign m_nasti_arlen = 0;
   assign m_nasti_arsize = DATA_WIDTH >> 4;
   assign m_nasti_arburst = 2'b01;
   assign m_nasti_arcache = 4'b0000;
   assign m_nasti_arprot = 3'b010;
   assign m_nasti_arqos = 4'b0000;
   
   logic                             write_transfer;
   logic                             read_transfer;
   
   assign write_transfer = (wb_cyc_i & wb_stb_i) & wb_we_i;
   assign read_transfer = (wb_cyc_i & wb_stb_i) & !wb_we_i;

   reg                               awdone, wdone, ardone;

   always @(posedge clk) begin
      if (rst) begin
         awdone <= 0;
         wdone <= 0;
         ardone <= 0;
      end else begin
         if (awdone & m_nasti_bvalid)
           awdone <= 0;
         else if (write_transfer & m_nasti_awready)
           awdone <= 1;

         if (wdone & m_nasti_bvalid)
           wdone <= 0;
         else if (write_transfer & m_nasti_wready)
           wdone <= 1;

         if (ardone & m_nasti_rvalid)
           ardone <= 0;
         else if (read_transfer & m_nasti_arready)
           ardone <= 1;
      end
   end
   
   assign m_nasti_awvalid = write_transfer & !awdone;
   assign m_nasti_wvalid = write_transfer & !wdone;
   assign m_nasti_arvalid = read_transfer & !ardone;

   assign m_nasti_bready = 1;
   assign m_nasti_rready = 1;
   
   logic transfer_done, transfer_success;
   assign transfer_done = m_nasti_bvalid | m_nasti_rvalid;
   assign transfer_success = (m_nasti_bvalid & !m_nasti_bresp[1]) |
                             (m_nasti_rvalid & !m_nasti_rresp[1]);

   assign wb_ack_o = transfer_done & transfer_success;
   assign wb_err_o = transfer_done & !transfer_success;
   assign wb_rty_o = 0;

   assign wb_dat_o = m_nasti_rdata;

   
endmodule // wb2nasti

    
