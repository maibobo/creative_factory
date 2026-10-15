class demo_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(demo_scoreboard)

    uvm_analysis_imp #(demo_item, demo_scoreboard) analysis_export;
    demo_cfg                                      cfg;
    int unsigned                                  checked_count;
    int unsigned                                  mismatch_count;
    event                                         completion_e;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(demo_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("DEMO/SCOREBOARD/CFG", "required demo_cfg was not provided")
        end
        checked_count  = 0;
        mismatch_count = 0;
    endfunction

    virtual function void write(demo_item observed);
        bit [7:0] expected_data;

        expected_data = observed.req_data + 8'd1;
        checked_count++;

        if (!observed.response_seen || (observed.rsp_data != expected_data)) begin
            mismatch_count++;
            `uvm_error(
                "DEMO/SCOREBOARD/MISMATCH",
                $sformatf(
                    "request=0x%02h expected=0x%02h actual=0x%02h",
                    observed.req_data,
                    expected_data,
                    observed.rsp_data
                )
            )
        end

        if (checked_count >= cfg.transaction_count) begin
            ->completion_e;
        end
    endfunction

    task wait_for_completion();
        while (checked_count < cfg.transaction_count) begin
            @completion_e;
        end
    endtask

    function bit is_complete();
        return (checked_count == cfg.transaction_count) &&
               (mismatch_count == 0);
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (checked_count != cfg.transaction_count) begin
            `uvm_error(
                "DEMO/SCOREBOARD/COUNT",
                $sformatf(
                    "expected %0d completed transactions, observed %0d",
                    cfg.transaction_count,
                    checked_count
                )
            )
        end
    endfunction

endclass
