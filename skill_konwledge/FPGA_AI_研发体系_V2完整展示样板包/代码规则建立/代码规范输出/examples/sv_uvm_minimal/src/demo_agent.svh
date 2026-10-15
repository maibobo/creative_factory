class demo_agent extends uvm_agent;

    `uvm_component_utils(demo_agent)

    demo_cfg       cfg;
    demo_sequencer sequencer;
    demo_driver    driver;
    demo_monitor   monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(demo_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("DEMO/AGENT/CFG", "required demo_cfg was not provided")
        end

        uvm_config_db#(demo_cfg)::set(this, "monitor", "cfg", cfg);
        monitor = demo_monitor::type_id::create("monitor", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            uvm_config_db#(demo_cfg)::set(this, "driver", "cfg", cfg);
            sequencer = demo_sequencer::type_id::create("sequencer", this);
            driver    = demo_driver::type_id::create("driver", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass
