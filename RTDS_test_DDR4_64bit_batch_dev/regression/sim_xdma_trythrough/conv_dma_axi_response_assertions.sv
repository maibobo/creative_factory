`timescale 1ns / 1ps

// Bind or instantiate this monitor on CONV_DMA's M_AXI response channels in
// the vendor Root-Port/BD profile. It intentionally turns any non-OKAY memory
// response into a simulation failure so an out-of-range access cannot hang
// silently inside the legacy CONV_DMA state machine.
module conv_dma_axi_response_assertions (
        input aclk,
        input aresetn,
        input [1:0] m_axi_bresp,
        input m_axi_bvalid,
        input [1:0] m_axi_rresp,
        input m_axi_rvalid
    );
    assert property (@(posedge aclk) disable iff (!aresetn)
        m_axi_bvalid |-> (m_axi_bresp == 2'b00))
        else
            $error("CONV_DMA received non-OKAY BRESP");
    assert property (@(posedge aclk) disable iff (!aresetn)
        m_axi_rvalid |-> (m_axi_rresp == 2'b00))
        else
            $error("CONV_DMA received non-OKAY RRESP");
endmodule
