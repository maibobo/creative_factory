class demo_monitor extends uvm_monitor;

    `uvm_component_utils(demo_monitor)

    uvm_analysis_port #(demo_item) ap;
    demo_cfg                         cfg;
    demo_monitor_vif_t               vif;
    bit [7:0]                        pending_req[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(demo_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("DEMO/MONITOR/CFG", "required demo_cfg was not provided")
        end
        if (cfg.mon_vif == null) begin
            `uvm_fatal("DEMO/MONITOR/VIF", "monitor virtual interface is null")
        end
        vif = cfg.mon_vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        demo_item observed;

        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.rst_n !== 1'b1) begin
                pending_req.delete();
            end else begin
                if ((vif.mon_cb.req_valid === 1'b1) &&
                    (vif.mon_cb.req_ready === 1'b1)) begin
                    pending_req.push_back(vif.mon_cb.req_data);
                end

                if (vif.mon_cb.rsp_valid === 1'b1) begin
                    if (pending_req.size() == 0) begin
                        `uvm_error(
                            "DEMO/MONITOR/ORPHAN_RSP",
                            "response observed with no pending request"
                        )
                    end else begin
                        observed = demo_item::type_id::create("observed");
                        observed.req_data      = pending_req.pop_front();
                        observed.rsp_data      = vif.mon_cb.rsp_data;
                        observed.response_seen = 1'b1;
                        ap.write(observed);
                    end
                end
            end
        end
    endtask

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (pending_req.size() != 0) begin
            `uvm_error(
                "DEMO/MONITOR/PENDING",
                $sformatf("%0d request(s) remained without response", pending_req.size())
            )
        end
    endfunction

endclass
