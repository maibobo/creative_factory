class demo_cfg extends uvm_object;

    `uvm_object_utils(demo_cfg)

    demo_driver_vif_t       drv_vif;
    demo_monitor_vif_t      mon_vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    int unsigned            transaction_count = 32;

    function new(string name = "demo_cfg");
        super.new(name);
    endfunction

endclass
