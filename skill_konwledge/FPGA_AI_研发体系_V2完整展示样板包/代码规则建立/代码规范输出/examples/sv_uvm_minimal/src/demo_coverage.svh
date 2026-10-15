class demo_coverage extends uvm_subscriber #(demo_item);

    `uvm_component_utils(demo_coverage)

    bit [7:0] sampled_req;
    bit       sampled_match;

    covergroup demo_cg;
        option.per_instance = 1;

        cp_req: coverpoint sampled_req {
            bins zero = {8'h00};
            bins low  = {[8'h01:8'h3f]};
            bins mid  = {[8'h40:8'hbf]};
            bins high = {[8'hc0:8'hfe]};
            bins max  = {8'hff};
        }

        cp_match: coverpoint sampled_match {
            bins match    = {1'b1};
            bins mismatch = {1'b0};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        demo_cg = new();
    endfunction

    virtual function void write(demo_item item);
        sampled_req   = item.req_data;
        sampled_match = (item.rsp_data == (item.req_data + 8'd1));
        demo_cg.sample();
    endfunction

endclass
