// SPDX-License-Identifier: BSD-2-Clause-Views
/*
 * Copyright (c) 2021-2023 The Regents of the University of California
 */

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

`ifndef APP_CUSTOM_PARAMS_ENABLE
  `define APP_CUSTOM_PARAMS_ENABLE
`endif

`ifndef APP_CUSTOM_PORTS_ENABLE
  `define APP_CUSTOM_PORTS_ENABLE
`endif

`ifdef APP_CUSTOM_PARAMS_ENABLE
  `include "mqnic_app_custom_params.vh"
`endif

`ifdef APP_CUSTOM_PORTS_ENABLE
  `include "mqnic_app_custom_ports.vh"
`endif

/*
 * Application block
 */
module mqnic_app_block #(
  // Structural configuration
  parameter IF_COUNT = 1,
  parameter PORTS_PER_IF = 1,
  parameter SCHED_PER_IF = PORTS_PER_IF,

  parameter PORT_COUNT = IF_COUNT*PORTS_PER_IF,

  // Clock configuration
  parameter CLK_PERIOD_NS_NUM = 4,
  parameter CLK_PERIOD_NS_DENOM = 1,

  // PTP configuration
  parameter PTP_CLK_PERIOD_NS_NUM = 4,
  parameter PTP_CLK_PERIOD_NS_DENOM = 1,
  parameter PTP_PORT_CDC_PIPELINE = 0,
  parameter PTP_PEROUT_ENABLE = 0,
  parameter PTP_PEROUT_COUNT = 1,

  // Interface configuration
  parameter PTP_TS_ENABLE = 1,
  parameter PTP_TS_FMT_TOD = 1,
  parameter PTP_TS_WIDTH = PTP_TS_FMT_TOD ? 96 : 64,
  parameter TX_TAG_WIDTH = 16,
  parameter MAX_TX_SIZE = 9214,
  parameter MAX_RX_SIZE = 9214,

  // RAM configuration
  parameter DDR_CH = 1,
  parameter DDR_ENABLE = 0,
  parameter DDR_GROUP_SIZE = 1,
  parameter AXI_DDR_DATA_WIDTH = 256,
  parameter AXI_DDR_ADDR_WIDTH = 32,
  parameter AXI_DDR_STRB_WIDTH = (AXI_DDR_DATA_WIDTH/8),
  parameter AXI_DDR_ID_WIDTH = 8,
  parameter AXI_DDR_AWUSER_ENABLE = 0,
  parameter AXI_DDR_AWUSER_WIDTH = 1,
  parameter AXI_DDR_WUSER_ENABLE = 0,
  parameter AXI_DDR_WUSER_WIDTH = 1,
  parameter AXI_DDR_BUSER_ENABLE = 0,
  parameter AXI_DDR_BUSER_WIDTH = 1,
  parameter AXI_DDR_ARUSER_ENABLE = 0,
  parameter AXI_DDR_ARUSER_WIDTH = 1,
  parameter AXI_DDR_RUSER_ENABLE = 0,
  parameter AXI_DDR_RUSER_WIDTH = 1,
  parameter AXI_DDR_MAX_BURST_LEN = 256,
  parameter AXI_DDR_NARROW_BURST = 0,
  parameter AXI_DDR_FIXED_BURST = 0,
  parameter AXI_DDR_WRAP_BURST = 0,
  parameter HBM_CH = 1,
  parameter HBM_ENABLE = 0,
  parameter HBM_GROUP_SIZE = 1,
  parameter AXI_HBM_DATA_WIDTH = 256,
  parameter AXI_HBM_ADDR_WIDTH = 32,
  parameter AXI_HBM_STRB_WIDTH = (AXI_HBM_DATA_WIDTH/8),
  parameter AXI_HBM_ID_WIDTH = 8,
  parameter AXI_HBM_AWUSER_ENABLE = 0,
  parameter AXI_HBM_AWUSER_WIDTH = 1,
  parameter AXI_HBM_WUSER_ENABLE = 0,
  parameter AXI_HBM_WUSER_WIDTH = 1,
  parameter AXI_HBM_BUSER_ENABLE = 0,
  parameter AXI_HBM_BUSER_WIDTH = 1,
  parameter AXI_HBM_ARUSER_ENABLE = 0,
  parameter AXI_HBM_ARUSER_WIDTH = 1,
  parameter AXI_HBM_RUSER_ENABLE = 0,
  parameter AXI_HBM_RUSER_WIDTH = 1,
  parameter AXI_HBM_MAX_BURST_LEN = 256,
  parameter AXI_HBM_NARROW_BURST = 0,
  parameter AXI_HBM_FIXED_BURST = 0,
  parameter AXI_HBM_WRAP_BURST = 0,

  // Application configuration
  parameter APP_ID = 32'h12340001,
  parameter APP_CTRL_ENABLE = 1,
  parameter APP_DMA_ENABLE = 1,
  parameter APP_AXIS_DIRECT_ENABLE = 1,
  parameter APP_AXIS_SYNC_ENABLE = 1,
  parameter APP_AXIS_IF_ENABLE = 1,
  parameter APP_STAT_ENABLE = 1,
  parameter APP_GPIO_IN_WIDTH = 32,
  parameter APP_GPIO_OUT_WIDTH = 32,

  // Custom application block parameters
  `ifdef APP_CUSTOM_PARAMS_ENABLE
    `APP_CUSTOM_PARAMS_DECL
  `endif

  // DMA interface configuration
  parameter DMA_ADDR_WIDTH = 64,
  parameter DMA_IMM_ENABLE = 0,
  parameter DMA_IMM_WIDTH = 32,
  parameter DMA_LEN_WIDTH = 16,
  parameter DMA_TAG_WIDTH = 16,
  parameter RAM_SEL_WIDTH = 4,
  parameter RAM_ADDR_WIDTH = 16,
  parameter RAM_SEG_COUNT = 2,
  parameter RAM_SEG_DATA_WIDTH = 256*2/RAM_SEG_COUNT,
  parameter RAM_SEG_BE_WIDTH = RAM_SEG_DATA_WIDTH/8,
  parameter RAM_SEG_ADDR_WIDTH = RAM_ADDR_WIDTH-$clog2(RAM_SEG_COUNT*RAM_SEG_BE_WIDTH),
  parameter RAM_PIPELINE = 2,

  // AXI lite interface (application control from host)
  parameter AXIL_APP_CTRL_DATA_WIDTH = 32,
  parameter AXIL_APP_CTRL_ADDR_WIDTH = 16,
  parameter AXIL_APP_CTRL_STRB_WIDTH = (AXIL_APP_CTRL_DATA_WIDTH/8),

  // AXI lite interface (control to NIC)
  parameter AXIL_CTRL_DATA_WIDTH = 32,
  parameter AXIL_CTRL_ADDR_WIDTH = 16,
  parameter AXIL_CTRL_STRB_WIDTH = (AXIL_CTRL_DATA_WIDTH/8),

  // Ethernet interface configuration (direct, async)
  parameter AXIS_DATA_WIDTH = 512,
  parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
  parameter AXIS_TX_USER_WIDTH = TX_TAG_WIDTH + 1,
  parameter AXIS_RX_USER_WIDTH = (PTP_TS_ENABLE ? PTP_TS_WIDTH : 0) + 1,
  parameter AXIS_RX_USE_READY = 0,

  // Ethernet interface configuration (direct, sync)
  parameter AXIS_SYNC_DATA_WIDTH = AXIS_DATA_WIDTH,
  parameter AXIS_SYNC_KEEP_WIDTH = AXIS_SYNC_DATA_WIDTH/8,
  parameter AXIS_SYNC_TX_USER_WIDTH = AXIS_TX_USER_WIDTH,
  parameter AXIS_SYNC_RX_USER_WIDTH = AXIS_RX_USER_WIDTH,

  // Ethernet interface configuration (interface)
  parameter AXIS_IF_DATA_WIDTH = AXIS_SYNC_DATA_WIDTH*2**$clog2(PORTS_PER_IF),
  parameter AXIS_IF_KEEP_WIDTH = AXIS_IF_DATA_WIDTH/8,
  parameter AXIS_IF_TX_ID_WIDTH = 12,
  parameter AXIS_IF_RX_ID_WIDTH = PORTS_PER_IF > 1 ? $clog2(PORTS_PER_IF) : 1,
  parameter AXIS_IF_TX_DEST_WIDTH = $clog2(PORTS_PER_IF)+4,
  parameter AXIS_IF_RX_DEST_WIDTH = 8,
  parameter AXIS_IF_TX_USER_WIDTH = AXIS_SYNC_TX_USER_WIDTH,
  parameter AXIS_IF_RX_USER_WIDTH = AXIS_SYNC_RX_USER_WIDTH,

  // Statistics counter subsystem
  parameter STAT_ENABLE = 1,
  parameter STAT_INC_WIDTH = 24,
  parameter STAT_ID_WIDTH = 12
) (
  input  wire                                           clk,
  input  wire                                           rst,

  /*
    * AXI-Lite slave interface (control from host)
    */
  input  wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]            s_axil_app_ctrl_awaddr,
  input  wire [2:0]                                     s_axil_app_ctrl_awprot,
  input  wire                                           s_axil_app_ctrl_awvalid,
  output wire                                           s_axil_app_ctrl_awready,
  input  wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]            s_axil_app_ctrl_wdata,
  input  wire [AXIL_APP_CTRL_STRB_WIDTH-1:0]            s_axil_app_ctrl_wstrb,
  input  wire                                           s_axil_app_ctrl_wvalid,
  output wire                                           s_axil_app_ctrl_wready,
  output wire [1:0]                                     s_axil_app_ctrl_bresp,
  output wire                                           s_axil_app_ctrl_bvalid,
  input  wire                                           s_axil_app_ctrl_bready,
  input  wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]            s_axil_app_ctrl_araddr,
  input  wire [2:0]                                     s_axil_app_ctrl_arprot,
  input  wire                                           s_axil_app_ctrl_arvalid,
  output wire                                           s_axil_app_ctrl_arready,
  output wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]            s_axil_app_ctrl_rdata,
  output wire [1:0]                                     s_axil_app_ctrl_rresp,
  output wire                                           s_axil_app_ctrl_rvalid,
  input  wire                                           s_axil_app_ctrl_rready,

  /*
    * AXI-Lite master interface (control to NIC)
    */
  output wire [AXIL_CTRL_ADDR_WIDTH-1:0]                m_axil_ctrl_awaddr,
  output wire [2:0]                                     m_axil_ctrl_awprot,
  output wire                                           m_axil_ctrl_awvalid,
  input  wire                                           m_axil_ctrl_awready,
  output wire [AXIL_CTRL_DATA_WIDTH-1:0]                m_axil_ctrl_wdata,
  output wire [AXIL_CTRL_STRB_WIDTH-1:0]                m_axil_ctrl_wstrb,
  output wire                                           m_axil_ctrl_wvalid,
  input  wire                                           m_axil_ctrl_wready,
  input  wire [1:0]                                     m_axil_ctrl_bresp,
  input  wire                                           m_axil_ctrl_bvalid,
  output wire                                           m_axil_ctrl_bready,
  output wire [AXIL_CTRL_ADDR_WIDTH-1:0]                m_axil_ctrl_araddr,
  output wire [2:0]                                     m_axil_ctrl_arprot,
  output wire                                           m_axil_ctrl_arvalid,
  input  wire                                           m_axil_ctrl_arready,
  input  wire [AXIL_CTRL_DATA_WIDTH-1:0]                m_axil_ctrl_rdata,
  input  wire [1:0]                                     m_axil_ctrl_rresp,
  input  wire                                           m_axil_ctrl_rvalid,
  output wire                                           m_axil_ctrl_rready,

  /*
    * DMA read descriptor output (control)
    */
  output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_read_desc_dma_addr,
  output wire [RAM_SEL_WIDTH-1:0]                       m_axis_ctrl_dma_read_desc_ram_sel,
  output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_read_desc_ram_addr,
  output wire [DMA_LEN_WIDTH-1:0]                       m_axis_ctrl_dma_read_desc_len,
  output wire [DMA_TAG_WIDTH-1:0]                       m_axis_ctrl_dma_read_desc_tag,
  output wire                                           m_axis_ctrl_dma_read_desc_valid,
  input  wire                                           m_axis_ctrl_dma_read_desc_ready,

  /*
    * DMA read descriptor status input (control)
    */
  input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_ctrl_dma_read_desc_status_tag,
  input  wire [3:0]                                     s_axis_ctrl_dma_read_desc_status_error,
  input  wire                                           s_axis_ctrl_dma_read_desc_status_valid,

  /*
    * DMA write descriptor output (control)
    */
  output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_write_desc_dma_addr,
  output wire [RAM_SEL_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_ram_sel,
  output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_write_desc_ram_addr,
  output wire [DMA_IMM_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_imm,
  output wire                                           m_axis_ctrl_dma_write_desc_imm_en,
  output wire [DMA_LEN_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_len,
  output wire [DMA_TAG_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_tag,
  output wire                                           m_axis_ctrl_dma_write_desc_valid,
  input  wire                                           m_axis_ctrl_dma_write_desc_ready,

  /*
    * DMA write descriptor status input (control)
    */
  input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_ctrl_dma_write_desc_status_tag,
  input  wire [3:0]                                     s_axis_ctrl_dma_write_desc_status_error,
  input  wire                                           s_axis_ctrl_dma_write_desc_status_valid,

  /*
    * DMA read descriptor output (data)
    */
  output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_data_dma_read_desc_dma_addr,
  output wire [RAM_SEL_WIDTH-1:0]                       m_axis_data_dma_read_desc_ram_sel,
  output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_data_dma_read_desc_ram_addr,
  output wire [DMA_LEN_WIDTH-1:0]                       m_axis_data_dma_read_desc_len,
  output wire [DMA_TAG_WIDTH-1:0]                       m_axis_data_dma_read_desc_tag,
  output wire                                           m_axis_data_dma_read_desc_valid,
  input  wire                                           m_axis_data_dma_read_desc_ready,

  /*
    * DMA read descriptor status input (data)
    */
  input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_data_dma_read_desc_status_tag,
  input  wire [3:0]                                     s_axis_data_dma_read_desc_status_error,
  input  wire                                           s_axis_data_dma_read_desc_status_valid,

  /*
    * DMA write descriptor output (data)
    */
  output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_data_dma_write_desc_dma_addr,
  output wire [RAM_SEL_WIDTH-1:0]                       m_axis_data_dma_write_desc_ram_sel,
  output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_data_dma_write_desc_ram_addr,
  output wire [DMA_IMM_WIDTH-1:0]                       m_axis_data_dma_write_desc_imm,
  output wire                                           m_axis_data_dma_write_desc_imm_en,
  output wire [DMA_LEN_WIDTH-1:0]                       m_axis_data_dma_write_desc_len,
  output wire [DMA_TAG_WIDTH-1:0]                       m_axis_data_dma_write_desc_tag,
  output wire                                           m_axis_data_dma_write_desc_valid,
  input  wire                                           m_axis_data_dma_write_desc_ready,

  /*
    * DMA write descriptor status input (data)
    */
  input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_data_dma_write_desc_status_tag,
  input  wire [3:0]                                     s_axis_data_dma_write_desc_status_error,
  input  wire                                           s_axis_data_dma_write_desc_status_valid,

  /*
    * DMA RAM interface (control)
    */
  input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         ctrl_dma_ram_wr_cmd_sel,
  input  wire [RAM_SEG_COUNT*RAM_SEG_BE_WIDTH-1:0]      ctrl_dma_ram_wr_cmd_be,
  input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    ctrl_dma_ram_wr_cmd_addr,
  input  wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    ctrl_dma_ram_wr_cmd_data,
  input  wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_wr_cmd_valid,
  output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_wr_cmd_ready,
  output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_wr_done,
  input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         ctrl_dma_ram_rd_cmd_sel,
  input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    ctrl_dma_ram_rd_cmd_addr,
  input  wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_cmd_valid,
  output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_cmd_ready,
  output wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    ctrl_dma_ram_rd_resp_data,
  output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_resp_valid,
  input  wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_resp_ready,

  /*
    * DMA RAM interface (data)
    */
  input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         data_dma_ram_wr_cmd_sel,
  input  wire [RAM_SEG_COUNT*RAM_SEG_BE_WIDTH-1:0]      data_dma_ram_wr_cmd_be,
  input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    data_dma_ram_wr_cmd_addr,
  input  wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    data_dma_ram_wr_cmd_data,
  input  wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_wr_cmd_valid,
  output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_wr_cmd_ready,
  output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_wr_done,
  input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         data_dma_ram_rd_cmd_sel,
  input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    data_dma_ram_rd_cmd_addr,
  input  wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_cmd_valid,
  output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_cmd_ready,
  output wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    data_dma_ram_rd_resp_data,
  output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_resp_valid,
  input  wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_resp_ready,

  /*
    * PTP clock
    */
  input  wire                                           ptp_clk,
  input  wire                                           ptp_rst,
  input  wire                                           ptp_sample_clk,
  input  wire                                           ptp_td_sd,
  input  wire                                           ptp_pps,
  input  wire                                           ptp_pps_str,
  input  wire                                           ptp_sync_locked,
  input  wire [PTP_TS_WIDTH-1:0]                        ptp_sync_ts_rel,
  input  wire                                           ptp_sync_ts_rel_step,
  input  wire [PTP_TS_WIDTH-1:0]                        ptp_sync_ts_tod,
  input  wire                                           ptp_sync_ts_tod_step,
  input  wire                                           ptp_sync_pps,
  input  wire                                           ptp_sync_pps_str,
  input  wire [PTP_PEROUT_COUNT-1:0]                    ptp_perout_locked,
  input  wire [PTP_PEROUT_COUNT-1:0]                    ptp_perout_error,
  input  wire [PTP_PEROUT_COUNT-1:0]                    ptp_perout_pulse,

  /*
    * Ethernet (direct MAC interface - lowest latency raw traffic)
    */
  input  wire [PORT_COUNT-1:0]                          direct_tx_clk,
  input  wire [PORT_COUNT-1:0]                          direct_tx_rst,

  input  wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          s_axis_direct_tx_tdata,
  input  wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          s_axis_direct_tx_tkeep,
  input  wire [PORT_COUNT-1:0]                          s_axis_direct_tx_tvalid,
  output wire [PORT_COUNT-1:0]                          s_axis_direct_tx_tready,
  input  wire [PORT_COUNT-1:0]                          s_axis_direct_tx_tlast,
  input  wire [PORT_COUNT*AXIS_TX_USER_WIDTH-1:0]       s_axis_direct_tx_tuser,

  output wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          m_axis_direct_tx_tdata,
  output wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          m_axis_direct_tx_tkeep,
  output wire [PORT_COUNT-1:0]                          m_axis_direct_tx_tvalid,
  input  wire [PORT_COUNT-1:0]                          m_axis_direct_tx_tready,
  output wire [PORT_COUNT-1:0]                          m_axis_direct_tx_tlast,
  output wire [PORT_COUNT*AXIS_TX_USER_WIDTH-1:0]       m_axis_direct_tx_tuser,

  input  wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             s_axis_direct_tx_cpl_ts,
  input  wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             s_axis_direct_tx_cpl_tag,
  input  wire [PORT_COUNT-1:0]                          s_axis_direct_tx_cpl_valid,
  output wire [PORT_COUNT-1:0]                          s_axis_direct_tx_cpl_ready,

  output wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             m_axis_direct_tx_cpl_ts,
  output wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             m_axis_direct_tx_cpl_tag,
  output wire [PORT_COUNT-1:0]                          m_axis_direct_tx_cpl_valid,
  input  wire [PORT_COUNT-1:0]                          m_axis_direct_tx_cpl_ready,

  input  wire [PORT_COUNT-1:0]                          direct_rx_clk,
  input  wire [PORT_COUNT-1:0]                          direct_rx_rst,

  input  wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          s_axis_direct_rx_tdata,
  input  wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          s_axis_direct_rx_tkeep,
  input  wire [PORT_COUNT-1:0]                          s_axis_direct_rx_tvalid,
  output wire [PORT_COUNT-1:0]                          s_axis_direct_rx_tready,
  input  wire [PORT_COUNT-1:0]                          s_axis_direct_rx_tlast,
  input  wire [PORT_COUNT*AXIS_RX_USER_WIDTH-1:0]       s_axis_direct_rx_tuser,

  output wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          m_axis_direct_rx_tdata,
  output wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          m_axis_direct_rx_tkeep,
  output wire [PORT_COUNT-1:0]                          m_axis_direct_rx_tvalid,
  input  wire [PORT_COUNT-1:0]                          m_axis_direct_rx_tready,
  output wire [PORT_COUNT-1:0]                          m_axis_direct_rx_tlast,
  output wire [PORT_COUNT*AXIS_RX_USER_WIDTH-1:0]       m_axis_direct_rx_tuser,

  /*
    * Ethernet (synchronous MAC interface - low latency raw traffic)
    */
  input  wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_sync_tx_tdata,
  input  wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_sync_tx_tkeep,
  input  wire [PORT_COUNT-1:0]                          s_axis_sync_tx_tvalid,
  output wire [PORT_COUNT-1:0]                          s_axis_sync_tx_tready,
  input  wire [PORT_COUNT-1:0]                          s_axis_sync_tx_tlast,
  input  wire [PORT_COUNT*AXIS_SYNC_TX_USER_WIDTH-1:0]  s_axis_sync_tx_tuser,

  output wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_sync_tx_tdata,
  output wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_sync_tx_tkeep,
  output wire [PORT_COUNT-1:0]                          m_axis_sync_tx_tvalid,
  input  wire [PORT_COUNT-1:0]                          m_axis_sync_tx_tready,
  output wire [PORT_COUNT-1:0]                          m_axis_sync_tx_tlast,
  output wire [PORT_COUNT*AXIS_SYNC_TX_USER_WIDTH-1:0]  m_axis_sync_tx_tuser,

  input  wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             s_axis_sync_tx_cpl_ts,
  input  wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             s_axis_sync_tx_cpl_tag,
  input  wire [PORT_COUNT-1:0]                          s_axis_sync_tx_cpl_valid,
  output wire [PORT_COUNT-1:0]                          s_axis_sync_tx_cpl_ready,

  output wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             m_axis_sync_tx_cpl_ts,
  output wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             m_axis_sync_tx_cpl_tag,
  output wire [PORT_COUNT-1:0]                          m_axis_sync_tx_cpl_valid,
  input  wire [PORT_COUNT-1:0]                          m_axis_sync_tx_cpl_ready,

  input  wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_sync_rx_tdata,
  input  wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_sync_rx_tkeep,
  input  wire [PORT_COUNT-1:0]                          s_axis_sync_rx_tvalid,
  output wire [PORT_COUNT-1:0]                          s_axis_sync_rx_tready,
  input  wire [PORT_COUNT-1:0]                          s_axis_sync_rx_tlast,
  input  wire [PORT_COUNT*AXIS_SYNC_RX_USER_WIDTH-1:0]  s_axis_sync_rx_tuser,

  output wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_sync_rx_tdata,
  output wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_sync_rx_tkeep,
  output wire [PORT_COUNT-1:0]                          m_axis_sync_rx_tvalid,
  input  wire [PORT_COUNT-1:0]                          m_axis_sync_rx_tready,
  output wire [PORT_COUNT-1:0]                          m_axis_sync_rx_tlast,
  output wire [PORT_COUNT*AXIS_SYNC_RX_USER_WIDTH-1:0]  m_axis_sync_rx_tuser,

  /*
    * Ethernet (internal at interface module)
    */
  input  wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         s_axis_if_tx_tdata,
  input  wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         s_axis_if_tx_tkeep,
  input  wire [IF_COUNT-1:0]                            s_axis_if_tx_tvalid,
  output wire [IF_COUNT-1:0]                            s_axis_if_tx_tready,
  input  wire [IF_COUNT-1:0]                            s_axis_if_tx_tlast,
  input  wire [IF_COUNT*AXIS_IF_TX_ID_WIDTH-1:0]        s_axis_if_tx_tid,
  input  wire [IF_COUNT*AXIS_IF_TX_DEST_WIDTH-1:0]      s_axis_if_tx_tdest,
  input  wire [IF_COUNT*AXIS_IF_TX_USER_WIDTH-1:0]      s_axis_if_tx_tuser,

  output wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         m_axis_if_tx_tdata,
  output wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         m_axis_if_tx_tkeep,
  output wire [IF_COUNT-1:0]                            m_axis_if_tx_tvalid,
  input  wire [IF_COUNT-1:0]                            m_axis_if_tx_tready,
  output wire [IF_COUNT-1:0]                            m_axis_if_tx_tlast,
  output wire [IF_COUNT*AXIS_IF_TX_ID_WIDTH-1:0]        m_axis_if_tx_tid,
  output wire [IF_COUNT*AXIS_IF_TX_DEST_WIDTH-1:0]      m_axis_if_tx_tdest,
  output wire [IF_COUNT*AXIS_IF_TX_USER_WIDTH-1:0]      m_axis_if_tx_tuser,

  input  wire [IF_COUNT*PTP_TS_WIDTH-1:0]               s_axis_if_tx_cpl_ts,
  input  wire [IF_COUNT*TX_TAG_WIDTH-1:0]               s_axis_if_tx_cpl_tag,
  input  wire [IF_COUNT-1:0]                            s_axis_if_tx_cpl_valid,
  output wire [IF_COUNT-1:0]                            s_axis_if_tx_cpl_ready,

  output wire [IF_COUNT*PTP_TS_WIDTH-1:0]               m_axis_if_tx_cpl_ts,
  output wire [IF_COUNT*TX_TAG_WIDTH-1:0]               m_axis_if_tx_cpl_tag,
  output wire [IF_COUNT-1:0]                            m_axis_if_tx_cpl_valid,
  input  wire [IF_COUNT-1:0]                            m_axis_if_tx_cpl_ready,

  input  wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         s_axis_if_rx_tdata,
  input  wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         s_axis_if_rx_tkeep,
  input  wire [IF_COUNT-1:0]                            s_axis_if_rx_tvalid,
  output wire [IF_COUNT-1:0]                            s_axis_if_rx_tready,
  input  wire [IF_COUNT-1:0]                            s_axis_if_rx_tlast,
  input  wire [IF_COUNT*AXIS_IF_RX_ID_WIDTH-1:0]        s_axis_if_rx_tid,
  input  wire [IF_COUNT*AXIS_IF_RX_DEST_WIDTH-1:0]      s_axis_if_rx_tdest,
  input  wire [IF_COUNT*AXIS_IF_RX_USER_WIDTH-1:0]      s_axis_if_rx_tuser,

  output wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         m_axis_if_rx_tdata,
  output wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         m_axis_if_rx_tkeep,
  output wire [IF_COUNT-1:0]                            m_axis_if_rx_tvalid,
  input  wire [IF_COUNT-1:0]                            m_axis_if_rx_tready,
  output wire [IF_COUNT-1:0]                            m_axis_if_rx_tlast,
  output wire [IF_COUNT*AXIS_IF_RX_ID_WIDTH-1:0]        m_axis_if_rx_tid,
  output wire [IF_COUNT*AXIS_IF_RX_DEST_WIDTH-1:0]      m_axis_if_rx_tdest,
  output wire [IF_COUNT*AXIS_IF_RX_USER_WIDTH-1:0]      m_axis_if_rx_tuser,

  /*
    * DDR
    */
  input  wire [DDR_CH-1:0]                              ddr_clk,
  input  wire [DDR_CH-1:0]                              ddr_rst,

  output wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_awid,
  output wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0]           m_axi_ddr_awaddr,
  output wire [DDR_CH*8-1:0]                            m_axi_ddr_awlen,
  output wire [DDR_CH*3-1:0]                            m_axi_ddr_awsize,
  output wire [DDR_CH*2-1:0]                            m_axi_ddr_awburst,
  output wire [DDR_CH-1:0]                              m_axi_ddr_awlock,
  output wire [DDR_CH*4-1:0]                            m_axi_ddr_awcache,
  output wire [DDR_CH*3-1:0]                            m_axi_ddr_awprot,
  output wire [DDR_CH*4-1:0]                            m_axi_ddr_awqos,
  output wire [DDR_CH*AXI_DDR_AWUSER_WIDTH-1:0]         m_axi_ddr_awuser,
  output wire [DDR_CH-1:0]                              m_axi_ddr_awvalid,
  input  wire [DDR_CH-1:0]                              m_axi_ddr_awready,
  output wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0]           m_axi_ddr_wdata,
  output wire [DDR_CH*AXI_DDR_STRB_WIDTH-1:0]           m_axi_ddr_wstrb,
  output wire [DDR_CH-1:0]                              m_axi_ddr_wlast,
  output wire [DDR_CH*AXI_DDR_WUSER_WIDTH-1:0]          m_axi_ddr_wuser,
  output wire [DDR_CH-1:0]                              m_axi_ddr_wvalid,
  input  wire [DDR_CH-1:0]                              m_axi_ddr_wready,
  input  wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_bid,
  input  wire [DDR_CH*2-1:0]                            m_axi_ddr_bresp,
  input  wire [DDR_CH*AXI_DDR_BUSER_WIDTH-1:0]          m_axi_ddr_buser,
  input  wire [DDR_CH-1:0]                              m_axi_ddr_bvalid,
  output wire [DDR_CH-1:0]                              m_axi_ddr_bready,
  output wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_arid,
  output wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0]           m_axi_ddr_araddr,
  output wire [DDR_CH*8-1:0]                            m_axi_ddr_arlen,
  output wire [DDR_CH*3-1:0]                            m_axi_ddr_arsize,
  output wire [DDR_CH*2-1:0]                            m_axi_ddr_arburst,
  output wire [DDR_CH-1:0]                              m_axi_ddr_arlock,
  output wire [DDR_CH*4-1:0]                            m_axi_ddr_arcache,
  output wire [DDR_CH*3-1:0]                            m_axi_ddr_arprot,
  output wire [DDR_CH*4-1:0]                            m_axi_ddr_arqos,
  output wire [DDR_CH*AXI_DDR_ARUSER_WIDTH-1:0]         m_axi_ddr_aruser,
  output wire [DDR_CH-1:0]                              m_axi_ddr_arvalid,
  input  wire [DDR_CH-1:0]                              m_axi_ddr_arready,
  input  wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_rid,
  input  wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0]           m_axi_ddr_rdata,
  input  wire [DDR_CH*2-1:0]                            m_axi_ddr_rresp,
  input  wire [DDR_CH-1:0]                              m_axi_ddr_rlast,
  input  wire [DDR_CH*AXI_DDR_RUSER_WIDTH-1:0]          m_axi_ddr_ruser,
  input  wire [DDR_CH-1:0]                              m_axi_ddr_rvalid,
  output wire [DDR_CH-1:0]                              m_axi_ddr_rready,

  input  wire [DDR_CH-1:0]                              ddr_status,

  /*
    * HBM
    */
  input  wire [HBM_CH-1:0]                              hbm_clk,
  input  wire [HBM_CH-1:0]                              hbm_rst,

  output wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_awid,
  output wire [HBM_CH*AXI_HBM_ADDR_WIDTH-1:0]           m_axi_hbm_awaddr,
  output wire [HBM_CH*8-1:0]                            m_axi_hbm_awlen,
  output wire [HBM_CH*3-1:0]                            m_axi_hbm_awsize,
  output wire [HBM_CH*2-1:0]                            m_axi_hbm_awburst,
  output wire [HBM_CH-1:0]                              m_axi_hbm_awlock,
  output wire [HBM_CH*4-1:0]                            m_axi_hbm_awcache,
  output wire [HBM_CH*3-1:0]                            m_axi_hbm_awprot,
  output wire [HBM_CH*4-1:0]                            m_axi_hbm_awqos,
  output wire [HBM_CH*AXI_HBM_AWUSER_WIDTH-1:0]         m_axi_hbm_awuser,
  output wire [HBM_CH-1:0]                              m_axi_hbm_awvalid,
  input  wire [HBM_CH-1:0]                              m_axi_hbm_awready,
  output wire [HBM_CH*AXI_HBM_DATA_WIDTH-1:0]           m_axi_hbm_wdata,
  output wire [HBM_CH*AXI_HBM_STRB_WIDTH-1:0]           m_axi_hbm_wstrb,
  output wire [HBM_CH-1:0]                              m_axi_hbm_wlast,
  output wire [HBM_CH*AXI_HBM_WUSER_WIDTH-1:0]          m_axi_hbm_wuser,
  output wire [HBM_CH-1:0]                              m_axi_hbm_wvalid,
  input  wire [HBM_CH-1:0]                              m_axi_hbm_wready,
  input  wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_bid,
  input  wire [HBM_CH*2-1:0]                            m_axi_hbm_bresp,
  input  wire [HBM_CH*AXI_HBM_BUSER_WIDTH-1:0]          m_axi_hbm_buser,
  input  wire [HBM_CH-1:0]                              m_axi_hbm_bvalid,
  output wire [HBM_CH-1:0]                              m_axi_hbm_bready,
  output wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_arid,
  output wire [HBM_CH*AXI_HBM_ADDR_WIDTH-1:0]           m_axi_hbm_araddr,
  output wire [HBM_CH*8-1:0]                            m_axi_hbm_arlen,
  output wire [HBM_CH*3-1:0]                            m_axi_hbm_arsize,
  output wire [HBM_CH*2-1:0]                            m_axi_hbm_arburst,
  output wire [HBM_CH-1:0]                              m_axi_hbm_arlock,
  output wire [HBM_CH*4-1:0]                            m_axi_hbm_arcache,
  output wire [HBM_CH*3-1:0]                            m_axi_hbm_arprot,
  output wire [HBM_CH*4-1:0]                            m_axi_hbm_arqos,
  output wire [HBM_CH*AXI_HBM_ARUSER_WIDTH-1:0]         m_axi_hbm_aruser,
  output wire [HBM_CH-1:0]                              m_axi_hbm_arvalid,
  input  wire [HBM_CH-1:0]                              m_axi_hbm_arready,
  input  wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_rid,
  input  wire [HBM_CH*AXI_HBM_DATA_WIDTH-1:0]           m_axi_hbm_rdata,
  input  wire [HBM_CH*2-1:0]                            m_axi_hbm_rresp,
  input  wire [HBM_CH-1:0]                              m_axi_hbm_rlast,
  input  wire [HBM_CH*AXI_HBM_RUSER_WIDTH-1:0]          m_axi_hbm_ruser,
  input  wire [HBM_CH-1:0]                              m_axi_hbm_rvalid,
  output wire [HBM_CH-1:0]                              m_axi_hbm_rready,

  input  wire [HBM_CH-1:0]                              hbm_status,

  /*
    * Statistics increment output
    */
  output wire [STAT_INC_WIDTH-1:0]                      m_axis_stat_tdata,
  output wire [STAT_ID_WIDTH-1:0]                       m_axis_stat_tid,
  output wire                                           m_axis_stat_tvalid,
  input  wire                                           m_axis_stat_tready,

  /*
    * GPIO
    */
  input  wire [APP_GPIO_IN_WIDTH-1:0]                   gpio_in,
  output wire [APP_GPIO_OUT_WIDTH-1:0]                  gpio_out,

  /*
    * Custom application block ports
    */
  `ifdef APP_CUSTOM_PORTS_ENABLE
    `APP_CUSTOM_PORTS_DECL
  `endif

  /*
    * JTAG
    */
  input  wire                                           jtag_tdi,
  output wire                                           jtag_tdo,
  input  wire                                           jtag_tms,
  input  wire                                           jtag_tck
);

  generate
    /*
    * AXI-Lite master interface (control to NIC)
    */
    if (APP_CTRL_ENABLE) begin : app_NIC_control
      `ifdef APP_CUSTOM_PORTS_ENABLE
        assign m_axil_ctrl_awaddr = m_axil_ctrl_awaddr_app;
        assign m_axil_ctrl_awprot = m_axil_ctrl_awprot_app;
        assign m_axil_ctrl_awvalid = m_axil_ctrl_awvalid_app;
        assign m_axil_ctrl_awready_app = m_axil_ctrl_awready;
        assign m_axil_ctrl_wdata = m_axil_ctrl_wdata_app;
        assign m_axil_ctrl_wstrb = m_axil_ctrl_wstrb_app;
        assign m_axil_ctrl_wvalid = m_axil_ctrl_wvalid_app;
        assign m_axil_ctrl_wready_app = m_axil_ctrl_wready;
        assign m_axil_ctrl_bresp_app = m_axil_ctrl_bresp;
        assign m_axil_ctrl_bvalid_app = m_axil_ctrl_bvalid;
        assign m_axil_ctrl_bready = m_axil_ctrl_bready_app;
        assign m_axil_ctrl_araddr = m_axil_ctrl_araddr_app;
        assign m_axil_ctrl_arprot = m_axil_ctrl_arprot_app;
        assign m_axil_ctrl_arvalid = m_axil_ctrl_arvalid_app;
        assign m_axil_ctrl_arready_app = m_axil_ctrl_arready;
        assign m_axil_ctrl_rdata_app = m_axil_ctrl_rdata;
        assign m_axil_ctrl_rresp_app = m_axil_ctrl_rresp;
        assign m_axil_ctrl_rvalid_app = m_axil_ctrl_rvalid;
        assign m_axil_ctrl_rready = m_axil_ctrl_rready_app;
      `endif
    end else begin
      assign m_axil_ctrl_awaddr = 0;
      assign m_axil_ctrl_awprot = 0;
      assign m_axil_ctrl_awvalid = 1'b0;
      assign m_axil_ctrl_wdata = 0;
      assign m_axil_ctrl_wstrb = 0;
      assign m_axil_ctrl_wvalid = 1'b0;
      assign m_axil_ctrl_bready = 1'b1;
      assign m_axil_ctrl_araddr = 0;
      assign m_axil_ctrl_arprot = 0;
      assign m_axil_ctrl_arvalid = 1'b0;
      assign m_axil_ctrl_rready = 1'b1;
    end

    if (APP_CTRL_ENABLE) begin : app_dma_control
      `ifdef APP_CUSTOM_PORTS_ENABLE
        /*
        * DMA interface (control)
        */
        assign m_axis_ctrl_dma_read_desc_dma_addr = m_axis_ctrl_dma_read_desc_dma_addr_app;
        assign m_axis_ctrl_dma_read_desc_ram_sel = m_axis_ctrl_dma_read_desc_ram_sel_app;
        assign m_axis_ctrl_dma_read_desc_ram_addr = m_axis_ctrl_dma_read_desc_ram_addr_app;
        assign m_axis_ctrl_dma_read_desc_len = m_axis_ctrl_dma_read_desc_len_app;
        assign m_axis_ctrl_dma_read_desc_tag = m_axis_ctrl_dma_read_desc_tag_app;
        assign m_axis_ctrl_dma_read_desc_valid = m_axis_ctrl_dma_read_desc_valid_app;
        assign m_axis_ctrl_dma_read_desc_ready_app = m_axis_ctrl_dma_read_desc_ready;

        assign s_axis_ctrl_dma_read_desc_status_tag_app = s_axis_ctrl_dma_read_desc_status_tag;
        assign s_axis_ctrl_dma_read_desc_status_error_app = s_axis_ctrl_dma_read_desc_status_error;
        assign s_axis_ctrl_dma_read_desc_status_valid_app = s_axis_ctrl_dma_read_desc_status_valid;

        assign m_axis_ctrl_dma_write_desc_dma_addr = m_axis_ctrl_dma_write_desc_dma_addr_app;
        assign m_axis_ctrl_dma_write_desc_ram_sel = m_axis_ctrl_dma_write_desc_ram_sel_app;
        assign m_axis_ctrl_dma_write_desc_ram_addr = m_axis_ctrl_dma_write_desc_ram_addr_app;
        assign m_axis_ctrl_dma_write_desc_imm = m_axis_ctrl_dma_write_desc_imm_app;
        assign m_axis_ctrl_dma_write_desc_imm_en = m_axis_ctrl_dma_write_desc_imm_en_app;
        assign m_axis_ctrl_dma_write_desc_len = m_axis_ctrl_dma_write_desc_len_app;
        assign m_axis_ctrl_dma_write_desc_tag = m_axis_ctrl_dma_write_desc_tag_app;
        assign m_axis_ctrl_dma_write_desc_valid = m_axis_ctrl_dma_write_desc_valid_app;
        assign m_axis_ctrl_dma_write_desc_ready_app = m_axis_ctrl_dma_write_desc_ready;

        assign s_axis_ctrl_dma_write_desc_status_tag_app = s_axis_ctrl_dma_write_desc_status_tag;
        assign s_axis_ctrl_dma_write_desc_status_error_app = s_axis_ctrl_dma_write_desc_status_error;
        assign s_axis_ctrl_dma_write_desc_status_valid_app = s_axis_ctrl_dma_write_desc_status_valid;

        assign ctrl_dma_ram_wr_cmd_sel_app = ctrl_dma_ram_wr_cmd_sel;
        assign ctrl_dma_ram_wr_cmd_be_app = ctrl_dma_ram_wr_cmd_be;
        assign ctrl_dma_ram_wr_cmd_addr_app = ctrl_dma_ram_wr_cmd_addr;
        assign ctrl_dma_ram_wr_cmd_data_app = ctrl_dma_ram_wr_cmd_data;
        assign ctrl_dma_ram_wr_cmd_valid_app = ctrl_dma_ram_wr_cmd_valid;
        assign ctrl_dma_ram_wr_cmd_ready = ctrl_dma_ram_wr_cmd_ready_app;
        assign ctrl_dma_ram_wr_done = ctrl_dma_ram_wr_done_app;
        assign ctrl_dma_ram_rd_cmd_sel_app = ctrl_dma_ram_rd_cmd_sel;
        assign ctrl_dma_ram_rd_cmd_addr_app = ctrl_dma_ram_rd_cmd_addr;
        assign ctrl_dma_ram_rd_cmd_valid_app = ctrl_dma_ram_rd_cmd_valid;
        assign ctrl_dma_ram_rd_cmd_ready = ctrl_dma_ram_rd_cmd_ready_app;
        assign ctrl_dma_ram_rd_resp_data = ctrl_dma_ram_rd_resp_data_app;
        assign ctrl_dma_ram_rd_resp_valid = ctrl_dma_ram_rd_resp_valid_app;
        assign ctrl_dma_ram_rd_resp_ready_app = ctrl_dma_ram_rd_resp_ready;

        /*
        * DMA interface (data)
        */
        assign m_axis_data_dma_read_desc_dma_addr = m_axis_data_dma_read_desc_dma_addr_app;
        assign m_axis_data_dma_read_desc_ram_sel = m_axis_data_dma_read_desc_ram_sel_app;
        assign m_axis_data_dma_read_desc_ram_addr = m_axis_data_dma_read_desc_ram_addr_app;
        assign m_axis_data_dma_read_desc_len = m_axis_data_dma_read_desc_len_app;
        assign m_axis_data_dma_read_desc_tag = m_axis_data_dma_read_desc_tag_app;
        assign m_axis_data_dma_read_desc_valid = m_axis_data_dma_read_desc_valid_app;
        assign m_axis_data_dma_read_desc_ready_app = m_axis_data_dma_read_desc_ready;

        assign s_axis_data_dma_read_desc_status_tag_app = s_axis_data_dma_read_desc_status_tag;
        assign s_axis_data_dma_read_desc_status_error_app = s_axis_data_dma_read_desc_status_error;
        assign s_axis_data_dma_read_desc_status_valid_app = s_axis_data_dma_read_desc_status_valid;

        assign m_axis_data_dma_write_desc_dma_addr = m_axis_data_dma_write_desc_dma_addr_app;
        assign m_axis_data_dma_write_desc_ram_sel = m_axis_data_dma_write_desc_ram_sel_app;
        assign m_axis_data_dma_write_desc_ram_addr = m_axis_data_dma_write_desc_ram_addr_app;
        assign m_axis_data_dma_write_desc_imm = m_axis_data_dma_write_desc_imm_app;
        assign m_axis_data_dma_write_desc_imm_en = m_axis_data_dma_write_desc_imm_en_app;
        assign m_axis_data_dma_write_desc_len = m_axis_data_dma_write_desc_len_app;
        assign m_axis_data_dma_write_desc_tag = m_axis_data_dma_write_desc_tag_app;
        assign m_axis_data_dma_write_desc_valid = m_axis_data_dma_write_desc_valid_app;
        assign m_axis_data_dma_write_desc_ready_app = m_axis_data_dma_write_desc_ready;

        assign s_axis_data_dma_write_desc_status_tag_app = s_axis_data_dma_write_desc_status_tag;
        assign s_axis_data_dma_write_desc_status_error_app = s_axis_data_dma_write_desc_status_error;
        assign s_axis_data_dma_write_desc_status_valid_app = s_axis_data_dma_write_desc_status_valid;

        assign data_dma_ram_wr_cmd_sel_app = data_dma_ram_wr_cmd_sel;
        assign data_dma_ram_wr_cmd_be_app = data_dma_ram_wr_cmd_be;
        assign data_dma_ram_wr_cmd_addr_app = data_dma_ram_wr_cmd_addr;
        assign data_dma_ram_wr_cmd_data_app = data_dma_ram_wr_cmd_data;
        assign data_dma_ram_wr_cmd_valid_app = data_dma_ram_wr_cmd_valid;
        assign data_dma_ram_wr_cmd_ready = data_dma_ram_wr_cmd_ready_app;
        assign data_dma_ram_wr_done = data_dma_ram_wr_done_app;
        assign data_dma_ram_rd_cmd_sel_app = data_dma_ram_rd_cmd_sel;
        assign data_dma_ram_rd_cmd_addr_app = data_dma_ram_rd_cmd_addr;
        assign data_dma_ram_rd_cmd_valid_app = data_dma_ram_rd_cmd_valid;
        assign data_dma_ram_rd_cmd_ready = data_dma_ram_rd_cmd_ready_app;
        assign data_dma_ram_rd_resp_data = data_dma_ram_rd_resp_data_app;
        assign data_dma_ram_rd_resp_valid = data_dma_ram_rd_resp_valid_app;
        assign data_dma_ram_rd_resp_ready_app = data_dma_ram_rd_resp_ready;
      `endif
    end else begin
      /*
      * DMA interface (control)
      */
      assign m_axis_ctrl_dma_read_desc_dma_addr = 0;
      assign m_axis_ctrl_dma_read_desc_ram_sel = 0;
      assign m_axis_ctrl_dma_read_desc_ram_addr = 0;
      assign m_axis_ctrl_dma_read_desc_len = 0;
      assign m_axis_ctrl_dma_read_desc_tag = 0;
      assign m_axis_ctrl_dma_read_desc_valid = 1'b0;
      assign m_axis_ctrl_dma_write_desc_dma_addr = 0;
      assign m_axis_ctrl_dma_write_desc_ram_sel = 0;
      assign m_axis_ctrl_dma_write_desc_ram_addr = 0;
      assign m_axis_ctrl_dma_write_desc_imm = 0;
      assign m_axis_ctrl_dma_write_desc_imm_en = 0;
      assign m_axis_ctrl_dma_write_desc_len = 0;
      assign m_axis_ctrl_dma_write_desc_tag = 0;
      assign m_axis_ctrl_dma_write_desc_valid = 1'b0;

      assign ctrl_dma_ram_wr_cmd_ready = 1'b1;
      assign ctrl_dma_ram_wr_done = ctrl_dma_ram_wr_cmd_valid;
      assign ctrl_dma_ram_rd_cmd_ready = ctrl_dma_ram_rd_resp_ready;
      assign ctrl_dma_ram_rd_resp_data = 0;
      assign ctrl_dma_ram_rd_resp_valid = ctrl_dma_ram_rd_cmd_valid;

      /*
      * DMA interface (data)
      */
      assign m_axis_data_dma_read_desc_dma_addr = 0;
      assign m_axis_data_dma_read_desc_ram_sel = 0;
      assign m_axis_data_dma_read_desc_ram_addr = 0;
      assign m_axis_data_dma_read_desc_len = 0;
      assign m_axis_data_dma_read_desc_tag = 0;
      assign m_axis_data_dma_read_desc_valid = 1'b0;
      assign m_axis_data_dma_write_desc_dma_addr = 0;
      assign m_axis_data_dma_write_desc_ram_sel = 0;
      assign m_axis_data_dma_write_desc_ram_addr = 0;
      assign m_axis_data_dma_write_desc_imm = 0;
      assign m_axis_data_dma_write_desc_imm_en = 0;
      assign m_axis_data_dma_write_desc_len = 0;
      assign m_axis_data_dma_write_desc_tag = 0;
      assign m_axis_data_dma_write_desc_valid = 1'b0;

      assign data_dma_ram_wr_cmd_ready = 1'b1;
      assign data_dma_ram_wr_done = data_dma_ram_wr_cmd_valid;
      assign data_dma_ram_rd_cmd_ready = data_dma_ram_rd_resp_ready;
      assign data_dma_ram_rd_resp_data = 0;
      assign data_dma_ram_rd_resp_valid = data_dma_ram_rd_cmd_valid;
    end

    /*
    * Ethernet (direct MAC interface - lowest latency raw traffic)
    */
    if (APP_AXIS_DIRECT_ENABLE) begin : app_direct_data
      `ifdef APP_CUSTOM_PORTS_ENABLE
        assign m_axis_direct_tx_tdata = m_axis_direct_tx_tdata_app;
        assign m_axis_direct_tx_tkeep = m_axis_direct_tx_tkeep_app;
        assign m_axis_direct_tx_tvalid = m_axis_direct_tx_tvalid_app;
        assign m_axis_direct_tx_tready_app = m_axis_direct_tx_tready;
        assign m_axis_direct_tx_tlast = m_axis_direct_tx_tlast_app;
        assign m_axis_direct_tx_tuser = m_axis_direct_tx_tuser_app;

        assign m_axis_direct_tx_cpl_ts = m_axis_direct_tx_cpl_ts_app;
        assign m_axis_direct_tx_cpl_tag = m_axis_direct_tx_cpl_tag_app;
        assign m_axis_direct_tx_cpl_valid = m_axis_direct_tx_cpl_valid_app;
        assign m_axis_direct_tx_cpl_ready_app = m_axis_direct_tx_cpl_ready;

        assign m_axis_direct_rx_tdata = m_axis_direct_rx_tdata_app;
        assign m_axis_direct_rx_tkeep = m_axis_direct_rx_tkeep_app;
        assign m_axis_direct_rx_tvalid = m_axis_direct_rx_tvalid_app;
        assign m_axis_direct_rx_tready_app = m_axis_direct_rx_tready;
        assign m_axis_direct_rx_tlast = m_axis_direct_rx_tlast_app;
        assign m_axis_direct_rx_tuser = m_axis_direct_rx_tuser_app;

        assign s_axis_direct_tx_tdata_app = s_axis_direct_tx_tdata;
        assign s_axis_direct_tx_tkeep_app = s_axis_direct_tx_tkeep;
        assign s_axis_direct_tx_tvalid_app = s_axis_direct_tx_tvalid;
        assign s_axis_direct_tx_tready = s_axis_direct_tx_tready_app;
        assign s_axis_direct_tx_tlast_app = s_axis_direct_tx_tlast;
        assign s_axis_direct_tx_tuser_app = s_axis_direct_tx_tuser;

        assign s_axis_direct_tx_cpl_ts_app = s_axis_direct_tx_cpl_ts;
        assign s_axis_direct_tx_cpl_tag_app = s_axis_direct_tx_cpl_tag;
        assign s_axis_direct_tx_cpl_valid_app = s_axis_direct_tx_cpl_valid;
        assign s_axis_direct_tx_cpl_ready = s_axis_direct_tx_cpl_ready_app;

        assign s_axis_direct_rx_tdata_app = s_axis_direct_rx_tdata;
        assign s_axis_direct_rx_tkeep_app = s_axis_direct_rx_tkeep;
        assign s_axis_direct_rx_tvalid_app = s_axis_direct_rx_tvalid;
        assign s_axis_direct_rx_tready = s_axis_direct_rx_tready_app;
        assign s_axis_direct_rx_tlast_app = s_axis_direct_rx_tlast;
        assign s_axis_direct_rx_tuser_app = s_axis_direct_rx_tuser;
      `endif
    end else begin
      assign m_axis_direct_tx_tdata = s_axis_direct_tx_tdata;
      assign m_axis_direct_tx_tkeep = s_axis_direct_tx_tkeep;
      assign m_axis_direct_tx_tvalid = s_axis_direct_tx_tvalid;
      assign s_axis_direct_tx_tready = m_axis_direct_tx_tready;
      assign m_axis_direct_tx_tlast = s_axis_direct_tx_tlast;
      assign m_axis_direct_tx_tuser = s_axis_direct_tx_tuser;

      assign m_axis_direct_tx_cpl_ts = s_axis_direct_tx_cpl_ts;
      assign m_axis_direct_tx_cpl_tag = s_axis_direct_tx_cpl_tag;
      assign m_axis_direct_tx_cpl_valid = s_axis_direct_tx_cpl_valid;
      assign s_axis_direct_tx_cpl_ready = m_axis_direct_tx_cpl_ready;

      assign m_axis_direct_rx_tdata = s_axis_direct_rx_tdata;
      assign m_axis_direct_rx_tkeep = s_axis_direct_rx_tkeep;
      assign m_axis_direct_rx_tvalid = s_axis_direct_rx_tvalid;
      assign s_axis_direct_rx_tready = m_axis_direct_rx_tready;
      assign m_axis_direct_rx_tlast = s_axis_direct_rx_tlast;
      assign m_axis_direct_rx_tuser = s_axis_direct_rx_tuser;
    end

    /*
    * Ethernet (synchronous MAC interface - low latency raw traffic)
    */
    if (APP_AXIS_SYNC_ENABLE) begin : app_snyc_data
      `ifdef APP_CUSTOM_PORTS_ENABLE
        assign m_axis_sync_tx_tdata = m_axis_sync_tx_tdata_app;
        assign m_axis_sync_tx_tkeep = m_axis_sync_tx_tkeep_app;
        assign m_axis_sync_tx_tvalid = m_axis_sync_tx_tvalid_app;
        assign m_axis_sync_tx_tready_app = m_axis_sync_tx_tready;
        assign m_axis_sync_tx_tlast = m_axis_sync_tx_tlast_app;
        assign m_axis_sync_tx_tuser = m_axis_sync_tx_tuser_app;

        assign m_axis_sync_tx_cpl_ts = m_axis_sync_tx_cpl_ts_app;
        assign m_axis_sync_tx_cpl_tag = m_axis_sync_tx_cpl_tag_app;
        assign m_axis_sync_tx_cpl_valid = m_axis_sync_tx_cpl_valid_app;
        assign m_axis_sync_tx_cpl_ready_app = m_axis_sync_tx_cpl_ready;

        assign m_axis_sync_rx_tdata = m_axis_sync_rx_tdata_app;
        assign m_axis_sync_rx_tkeep = m_axis_sync_rx_tkeep_app;
        assign m_axis_sync_rx_tvalid = m_axis_sync_rx_tvalid_app;
        assign m_axis_sync_rx_tready_app = m_axis_sync_rx_tready;
        assign m_axis_sync_rx_tlast = m_axis_sync_rx_tlast_app;
        assign m_axis_sync_rx_tuser = m_axis_sync_rx_tuser_app;

        assign s_axis_sync_tx_tdata_app = s_axis_sync_tx_tdata;
        assign s_axis_sync_tx_tkeep_app = s_axis_sync_tx_tkeep;
        assign s_axis_sync_tx_tvalid_app = s_axis_sync_tx_tvalid;
        assign s_axis_sync_tx_tready = s_axis_sync_tx_tready_app;
        assign s_axis_sync_tx_tlast_app = s_axis_sync_tx_tlast;
        assign s_axis_sync_tx_tuser_app = s_axis_sync_tx_tuser;

        assign s_axis_sync_tx_cpl_ts_app = s_axis_sync_tx_cpl_ts;
        assign s_axis_sync_tx_cpl_tag_app = s_axis_sync_tx_cpl_tag;
        assign s_axis_sync_tx_cpl_valid_app = s_axis_sync_tx_cpl_valid;
        assign s_axis_sync_tx_cpl_ready = s_axis_sync_tx_cpl_ready_app;

        assign s_axis_sync_rx_tdata_app = s_axis_sync_rx_tdata;
        assign s_axis_sync_rx_tkeep_app = s_axis_sync_rx_tkeep;
        assign s_axis_sync_rx_tvalid_app = s_axis_sync_rx_tvalid;
        assign s_axis_sync_rx_tready = s_axis_sync_rx_tready_app;
        assign s_axis_sync_rx_tlast_app = s_axis_sync_rx_tlast;
        assign s_axis_sync_rx_tuser_app = s_axis_sync_rx_tuser;
      `endif
    end else begin
      assign m_axis_sync_tx_tdata = s_axis_sync_tx_tdata;
      assign m_axis_sync_tx_tkeep = s_axis_sync_tx_tkeep;
      assign m_axis_sync_tx_tvalid = s_axis_sync_tx_tvalid;
      assign s_axis_sync_tx_tready = m_axis_sync_tx_tready;
      assign m_axis_sync_tx_tlast = s_axis_sync_tx_tlast;
      assign m_axis_sync_tx_tuser = s_axis_sync_tx_tuser;

      assign m_axis_sync_tx_cpl_ts = s_axis_sync_tx_cpl_ts;
      assign m_axis_sync_tx_cpl_tag = s_axis_sync_tx_cpl_tag;
      assign m_axis_sync_tx_cpl_valid = s_axis_sync_tx_cpl_valid;
      assign s_axis_sync_tx_cpl_ready = m_axis_sync_tx_cpl_ready;

      assign m_axis_sync_rx_tdata = s_axis_sync_rx_tdata;
      assign m_axis_sync_rx_tkeep = s_axis_sync_rx_tkeep;
      assign m_axis_sync_rx_tvalid = s_axis_sync_rx_tvalid;
      assign s_axis_sync_rx_tready = m_axis_sync_rx_tready;
      assign m_axis_sync_rx_tlast = s_axis_sync_rx_tlast;
      assign m_axis_sync_rx_tuser = s_axis_sync_rx_tuser;
    end

    /*
    * Ethernet (internal at interface module)
    */
    if (APP_AXIS_IF_ENABLE) begin : app_if_data
      `ifdef APP_CUSTOM_PORTS_ENABLE
        assign m_axis_if_tx_tdata = m_axis_if_tx_tdata_app;
        assign m_axis_if_tx_tkeep = m_axis_if_tx_tkeep_app;
        assign m_axis_if_tx_tvalid = m_axis_if_tx_tvalid_app;
        assign m_axis_if_tx_tready_app = m_axis_if_tx_tready;
        assign m_axis_if_tx_tlast = m_axis_if_tx_tlast_app;
        assign m_axis_if_tx_tid = m_axis_if_tx_tid_app;
        assign m_axis_if_tx_tdest = m_axis_if_tx_tdest_app;
        assign m_axis_if_tx_tuser = m_axis_if_tx_tuser_app;

        assign m_axis_if_tx_cpl_ts = m_axis_if_tx_cpl_ts_app;
        assign m_axis_if_tx_cpl_tag = m_axis_if_tx_cpl_tag_app;
        assign m_axis_if_tx_cpl_valid = m_axis_if_tx_cpl_valid_app;
        assign m_axis_if_tx_cpl_ready_app = m_axis_if_tx_cpl_ready;

        assign m_axis_if_rx_tdata = m_axis_if_rx_tdata_app;
        assign m_axis_if_rx_tkeep = m_axis_if_rx_tkeep_app;
        assign m_axis_if_rx_tvalid = m_axis_if_rx_tvalid_app;
        assign m_axis_if_rx_tready_app = m_axis_if_rx_tready;
        assign m_axis_if_rx_tlast = m_axis_if_rx_tlast_app;
        assign m_axis_if_rx_tid = m_axis_if_rx_tid_app;
        assign m_axis_if_rx_tdest = m_axis_if_rx_tdest_app;
        assign m_axis_if_rx_tuser = m_axis_if_rx_tuser_app;

        assign s_axis_if_tx_tdata_app = s_axis_if_tx_tdata;
        assign s_axis_if_tx_tkeep_app = s_axis_if_tx_tkeep;
        assign s_axis_if_tx_tvalid_app = s_axis_if_tx_tvalid;
        assign s_axis_if_tx_tready = s_axis_if_tx_tready_app;
        assign s_axis_if_tx_tlast_app = s_axis_if_tx_tlast;
        assign s_axis_if_tx_tid_app = s_axis_if_tx_tid;
        assign s_axis_if_tx_tdest_app = s_axis_if_tx_tdest;
        assign s_axis_if_tx_tuser_app = s_axis_if_tx_tuser;

        assign s_axis_if_tx_cpl_ts_app = s_axis_if_tx_cpl_ts;
        assign s_axis_if_tx_cpl_tag_app = s_axis_if_tx_cpl_tag;
        assign s_axis_if_tx_cpl_valid_app = s_axis_if_tx_cpl_valid;
        assign s_axis_if_tx_cpl_ready = s_axis_if_tx_cpl_ready_app;

        assign s_axis_if_rx_tdata_app = s_axis_if_rx_tdata;
        assign s_axis_if_rx_tkeep_app = s_axis_if_rx_tkeep;
        assign s_axis_if_rx_tvalid_app = s_axis_if_rx_tvalid;
        assign s_axis_if_rx_tready = s_axis_if_rx_tready_app;
        assign s_axis_if_rx_tlast_app = s_axis_if_rx_tlast;
        assign s_axis_if_rx_tid_app = s_axis_if_rx_tid;
        assign s_axis_if_rx_tdest_app = s_axis_if_rx_tdest;
        assign s_axis_if_rx_tuser_app = s_axis_if_rx_tuser;
      `endif
    end else begin
      assign m_axis_if_tx_tdata = s_axis_if_tx_tdata;
      assign m_axis_if_tx_tkeep = s_axis_if_tx_tkeep;
      assign m_axis_if_tx_tvalid = s_axis_if_tx_tvalid;
      assign s_axis_if_tx_tready = m_axis_if_tx_tready;
      assign m_axis_if_tx_tlast = s_axis_if_tx_tlast;
      assign m_axis_if_tx_tid = s_axis_if_tx_tid;
      assign m_axis_if_tx_tdest = s_axis_if_tx_tdest;
      assign m_axis_if_tx_tuser = s_axis_if_tx_tuser;

      assign m_axis_if_tx_cpl_ts = s_axis_if_tx_cpl_ts;
      assign m_axis_if_tx_cpl_tag = s_axis_if_tx_cpl_tag;
      assign m_axis_if_tx_cpl_valid = s_axis_if_tx_cpl_valid;
      assign s_axis_if_tx_cpl_ready = m_axis_if_tx_cpl_ready;

      assign m_axis_if_rx_tdata = s_axis_if_rx_tdata;
      assign m_axis_if_rx_tkeep = s_axis_if_rx_tkeep;
      assign m_axis_if_rx_tvalid = s_axis_if_rx_tvalid;
      assign s_axis_if_rx_tready = m_axis_if_rx_tready;
      assign m_axis_if_rx_tlast = s_axis_if_rx_tlast;
      assign m_axis_if_rx_tid = s_axis_if_rx_tid;
      assign m_axis_if_rx_tdest = s_axis_if_rx_tdest;
      assign m_axis_if_rx_tuser = s_axis_if_rx_tuser;
    end

    /*
    * DDR
    */
    if (DDR_ENABLE) begin : app_ddr
      `ifdef APP_CUSTOM_PORTS_ENABLE
        assign m_axi_ddr_awid = m_axi_ddr_awid_app;
        assign m_axi_ddr_awaddr = m_axi_ddr_awaddr_app;
        assign m_axi_ddr_awlen = m_axi_ddr_awlen_app;
        assign m_axi_ddr_awsize = m_axi_ddr_awsize_app;
        assign m_axi_ddr_awburst = m_axi_ddr_awburst_app;
        assign m_axi_ddr_awlock = m_axi_ddr_awlock_app;
        assign m_axi_ddr_awcache = m_axi_ddr_awcache_app;
        assign m_axi_ddr_awprot = m_axi_ddr_awprot_app;
        assign m_axi_ddr_awqos = m_axi_ddr_awqos_app;
        assign m_axi_ddr_awuser = m_axi_ddr_awuser_app;
        assign m_axi_ddr_awvalid = m_axi_ddr_awvalid_app;
        assign m_axi_ddr_awready_app = m_axi_ddr_awready;
        assign m_axi_ddr_wdata = m_axi_ddr_wdata_app;
        assign m_axi_ddr_wstrb = m_axi_ddr_wstrb_app;
        assign m_axi_ddr_wlast = m_axi_ddr_wlast_app;
        assign m_axi_ddr_wuser = m_axi_ddr_wuser_app;
        assign m_axi_ddr_wvalid = m_axi_ddr_wvalid_app;
        assign m_axi_ddr_wready_app = m_axi_ddr_wready;
        assign m_axi_ddr_bid_app = m_axi_ddr_bid;
        assign m_axi_ddr_bresp_app = m_axi_ddr_bresp;
        assign m_axi_ddr_buser_app = m_axi_ddr_buser;
        assign m_axi_ddr_bvalid_app = m_axi_ddr_bvalid;
        assign m_axi_ddr_bready = m_axi_ddr_bready_app;
        assign m_axi_ddr_arid = m_axi_ddr_arid_app;
        assign m_axi_ddr_araddr = m_axi_ddr_araddr_app;
        assign m_axi_ddr_arlen = m_axi_ddr_arlen_app;
        assign m_axi_ddr_arsize = m_axi_ddr_arsize_app;
        assign m_axi_ddr_arburst = m_axi_ddr_arburst_app;
        assign m_axi_ddr_arlock = m_axi_ddr_arlock_app;
        assign m_axi_ddr_arcache = m_axi_ddr_arcache_app;
        assign m_axi_ddr_arprot = m_axi_ddr_arprot_app;
        assign m_axi_ddr_arqos = m_axi_ddr_arqos_app;
        assign m_axi_ddr_aruser = m_axi_ddr_aruser_app;
        assign m_axi_ddr_arvalid = m_axi_ddr_arvalid_app;
        assign m_axi_ddr_arready_app = m_axi_ddr_arready;
        assign m_axi_ddr_rid_app = m_axi_ddr_rid;
        assign m_axi_ddr_rdata_app = m_axi_ddr_rdata;
        assign m_axi_ddr_rresp_app = m_axi_ddr_rresp;
        assign m_axi_ddr_rlast_app = m_axi_ddr_rlast;
        assign m_axi_ddr_ruser_app = m_axi_ddr_ruser;
        assign m_axi_ddr_rvalid_app = m_axi_ddr_rvalid;
        assign m_axi_ddr_rready = m_axi_ddr_rready_app;
      `endif
    end else begin
      assign m_axi_ddr_awid = 0;
      assign m_axi_ddr_awaddr = 0;
      assign m_axi_ddr_awlen = 0;
      assign m_axi_ddr_awsize = 0;
      assign m_axi_ddr_awburst = 0;
      assign m_axi_ddr_awlock = 0;
      assign m_axi_ddr_awcache = 0;
      assign m_axi_ddr_awprot = 0;
      assign m_axi_ddr_awqos = 0;
      assign m_axi_ddr_awuser = 0;
      assign m_axi_ddr_awvalid = 0;
      assign m_axi_ddr_wdata = 0;
      assign m_axi_ddr_wstrb = 0;
      assign m_axi_ddr_wlast = 0;
      assign m_axi_ddr_wuser = 0;
      assign m_axi_ddr_wvalid = 0;
      assign m_axi_ddr_bready = 0;
      assign m_axi_ddr_arid = 0;
      assign m_axi_ddr_araddr = 0;
      assign m_axi_ddr_arlen = 0;
      assign m_axi_ddr_arsize = 0;
      assign m_axi_ddr_arburst = 0;
      assign m_axi_ddr_arlock = 0;
      assign m_axi_ddr_arcache = 0;
      assign m_axi_ddr_arprot = 0;
      assign m_axi_ddr_arqos = 0;
      assign m_axi_ddr_aruser = 0;
      assign m_axi_ddr_arvalid = 0;
      assign m_axi_ddr_rready = 0;
    end

    /*
    * HBM
    */
    if (HBM_ENABLE) begin : app_hbm
      `ifdef APP_CUSTOM_PORTS_ENABLE
        assign m_axi_hbm_awid = m_axi_hbm_awid_app;
        assign m_axi_hbm_awaddr = m_axi_hbm_awaddr_app;
        assign m_axi_hbm_awlen = m_axi_hbm_awlen_app;
        assign m_axi_hbm_awsize = m_axi_hbm_awsize_app;
        assign m_axi_hbm_awburst = m_axi_hbm_awburst_app;
        assign m_axi_hbm_awlock = m_axi_hbm_awlock_app;
        assign m_axi_hbm_awcache = m_axi_hbm_awcache_app;
        assign m_axi_hbm_awprot = m_axi_hbm_awprot_app;
        assign m_axi_hbm_awqos = m_axi_hbm_awqos_app;
        assign m_axi_hbm_awuser = m_axi_hbm_awuser_app;
        assign m_axi_hbm_awvalid = m_axi_hbm_awvalid_app;
        assign m_axi_hbm_awready_app = m_axi_hbm_awready;
        assign m_axi_hbm_wdata = m_axi_hbm_wdata_app;
        assign m_axi_hbm_wstrb = m_axi_hbm_wstrb_app;
        assign m_axi_hbm_wlast = m_axi_hbm_wlast_app;
        assign m_axi_hbm_wuser = m_axi_hbm_wuser_app;
        assign m_axi_hbm_wvalid = m_axi_hbm_wvalid_app;
        assign m_axi_hbm_wready_app = m_axi_hbm_wready;
        assign m_axi_hbm_bid_app = m_axi_hbm_bid;
        assign m_axi_hbm_bresp_app = m_axi_hbm_bresp;
        assign m_axi_hbm_buser_app = m_axi_hbm_buser;
        assign m_axi_hbm_bvalid_app = m_axi_hbm_bvalid;
        assign m_axi_hbm_bready = m_axi_hbm_bready_app;
        assign m_axi_hbm_arid = m_axi_hbm_arid_app;
        assign m_axi_hbm_araddr = m_axi_hbm_araddr_app;
        assign m_axi_hbm_arlen = m_axi_hbm_arlen_app;
        assign m_axi_hbm_arsize = m_axi_hbm_arsize_app;
        assign m_axi_hbm_arburst = m_axi_hbm_arburst_app;
        assign m_axi_hbm_arlock = m_axi_hbm_arlock_app;
        assign m_axi_hbm_arcache = m_axi_hbm_arcache_app;
        assign m_axi_hbm_arprot = m_axi_hbm_arprot_app;
        assign m_axi_hbm_arqos = m_axi_hbm_arqos_app;
        assign m_axi_hbm_aruser = m_axi_hbm_aruser_app;
        assign m_axi_hbm_arvalid = m_axi_hbm_arvalid_app;
        assign m_axi_hbm_arready_app = m_axi_hbm_arready;
        assign m_axi_hbm_rid_app = m_axi_hbm_rid;
        assign m_axi_hbm_rdata_app = m_axi_hbm_rdata;
        assign m_axi_hbm_rresp_app = m_axi_hbm_rresp;
        assign m_axi_hbm_rlast_app = m_axi_hbm_rlast;
        assign m_axi_hbm_ruser_app = m_axi_hbm_ruser;
        assign m_axi_hbm_rvalid_app = m_axi_hbm_rvalid;
        assign m_axi_hbm_rready = m_axi_hbm_rready_app;
      `endif
    end else begin
      assign m_axi_hbm_awid = 0;
      assign m_axi_hbm_awaddr = 0;
      assign m_axi_hbm_awlen = 0;
      assign m_axi_hbm_awsize = 0;
      assign m_axi_hbm_awburst = 0;
      assign m_axi_hbm_awlock = 0;
      assign m_axi_hbm_awcache = 0;
      assign m_axi_hbm_awprot = 0;
      assign m_axi_hbm_awqos = 0;
      assign m_axi_hbm_awuser = 0;
      assign m_axi_hbm_awvalid = 0;
      assign m_axi_hbm_wdata = 0;
      assign m_axi_hbm_wstrb = 0;
      assign m_axi_hbm_wlast = 0;
      assign m_axi_hbm_wuser = 0;
      assign m_axi_hbm_wvalid = 0;
      assign m_axi_hbm_bready = 0;
      assign m_axi_hbm_arid = 0;
      assign m_axi_hbm_araddr = 0;
      assign m_axi_hbm_arlen = 0;
      assign m_axi_hbm_arsize = 0;
      assign m_axi_hbm_arburst = 0;
      assign m_axi_hbm_arlock = 0;
      assign m_axi_hbm_arcache = 0;
      assign m_axi_hbm_arprot = 0;
      assign m_axi_hbm_arqos = 0;
      assign m_axi_hbm_aruser = 0;
      assign m_axi_hbm_arvalid = 0;
      assign m_axi_hbm_rready = 0;
    end

    /*
    * Statistics increment output
    */
    if (APP_STAT_ENABLE) begin: app_stat
      `ifdef APP_CUSTOM_PORTS_ENABLE
        assign m_axis_stat_tdata = m_axis_stat_tdata_app;
        assign m_axis_stat_tid = m_axis_stat_tid_app;
        assign m_axis_stat_tvalid = m_axis_stat_tvalid_app;
        assign m_axis_stat_tready_app = m_axis_stat_tready;
      `endif
    end else begin
      assign m_axis_stat_tdata = 0;
      assign m_axis_stat_tid = 0;
      assign m_axis_stat_tvalid = 1'b0;
    end

  endgenerate

  /*
  * GPIO
  */
  assign gpio_out = 0;

  /*
  * JTAG
  */
  assign jtag_tdo = jtag_tdi;

endmodule

`resetall
