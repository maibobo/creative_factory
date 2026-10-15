class demo_test extends uvm_test;

    `uvm_component_utils(demo_test)

    demo_cfg cfg;
    demo_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = demo_cfg::type_id::create("cfg");
        if (!uvm_config_db#(demo_driver_vif_t)::get(
                this,
                "",
                "drv_vif",
                cfg.drv_vif
            )) begin
            `uvm_fatal("DEMO/TEST/DRV_VIF", "driver virtual interface was not provided")
        end
        if (!uvm_config_db#(demo_monitor_vif_t)::get(
                this,
                "",
                "mon_vif",
                cfg.mon_vif
            )) begin
            `uvm_fatal("DEMO/TEST/MON_VIF", "monitor virtual interface was not provided")
        end

        cfg.is_active         = UVM_ACTIVE;
        cfg.transaction_count = 32;

        uvm_config_db#(demo_cfg)::set(this, "env", "cfg", cfg);
        env = demo_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        demo_sequence seq;

        phase.raise_objection(this, "starting explicit root sequence");

        seq = demo_sequence::type_id::create("seq");
        seq.item_count = cfg.transaction_count;
        seq.start(env.get_sequencer());
        env.wait_for_completion();

        phase.drop_objection(this, "stimulus complete and scoreboard empty");
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server report_server;
        int error_count;
        int fatal_count;

        super.report_phase(phase);
        report_server = uvm_report_server::get_server();
        error_count = report_server.get_severity_count(UVM_ERROR);
        fatal_count = report_server.get_severity_count(UVM_FATAL);

        if (env.is_complete() && (error_count == 0) && (fatal_count == 0)) begin
            `uvm_info("DEMO/RESULT", "TEST PASS", UVM_NONE)
        end else begin
            `uvm_error(
                "DEMO/RESULT",
                $sformatf(
                    "TEST FAIL: complete=%0b errors=%0d fatals=%0d",
                    env.is_complete(),
                    error_count,
                    fatal_count
                )
            )
        end
    endfunction

endclass
