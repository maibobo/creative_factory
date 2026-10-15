class demo_env extends uvm_env;

    `uvm_component_utils(demo_env)

    demo_cfg        cfg;
    demo_agent      agent;
    demo_scoreboard scoreboard;
    demo_coverage   coverage;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(demo_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("DEMO/ENV/CFG", "required demo_cfg was not provided")
        end

        uvm_config_db#(demo_cfg)::set(this, "agent", "cfg", cfg);
        uvm_config_db#(demo_cfg)::set(this, "scoreboard", "cfg", cfg);

        agent      = demo_agent::type_id::create("agent", this);
        scoreboard = demo_scoreboard::type_id::create("scoreboard", this);
        coverage   = demo_coverage::type_id::create("coverage", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.analysis_export);
        agent.monitor.ap.connect(coverage.analysis_export);
    endfunction

    function demo_sequencer get_sequencer();
        if ((cfg.is_active != UVM_ACTIVE) || (agent.sequencer == null)) begin
            `uvm_fatal("DEMO/ENV/SEQUENCER", "active sequencer is not available")
        end
        return agent.sequencer;
    endfunction

    task wait_for_completion();
        scoreboard.wait_for_completion();
    endtask

    function bit is_complete();
        return scoreboard.is_complete();
    endfunction

endclass
