class demo_driver extends uvm_driver #(demo_item);

    `uvm_component_utils(demo_driver)

    demo_cfg          cfg;
    demo_driver_vif_t vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(demo_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("DEMO/DRIVER/CFG", "required demo_cfg was not provided")
        end
        if (cfg.drv_vif == null) begin
            `uvm_fatal("DEMO/DRIVER/VIF", "driver virtual interface is null")
        end
        vif = cfg.drv_vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        demo_item req;

        vif.drv_cb.req_valid <= 1'b0;
        vif.drv_cb.req_data  <= 8'b0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    protected task drive_item(demo_item req);
        do begin
            @(vif.drv_cb);
        end while (vif.drv_cb.rst_n !== 1'b1);

        vif.drv_cb.req_data  <= req.req_data;
        vif.drv_cb.req_valid <= 1'b1;

        do begin
            @(vif.drv_cb);
        end while ((vif.drv_cb.rst_n !== 1'b1) ||
                   (vif.drv_cb.req_ready !== 1'b1));

        vif.drv_cb.req_valid <= 1'b0;
        vif.drv_cb.req_data  <= 8'b0;
    endtask

endclass
