package demo_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef virtual demo_if.driver_mp  demo_driver_vif_t;
    typedef virtual demo_if.monitor_mp demo_monitor_vif_t;

    `include "demo_cfg.svh"
    `include "demo_item.svh"
    `include "demo_sequencer.svh"
    `include "demo_driver.svh"
    `include "demo_monitor.svh"
    `include "demo_coverage.svh"
    `include "demo_scoreboard.svh"
    `include "demo_agent.svh"
    `include "demo_env.svh"
    `include "demo_sequence.svh"
    `include "demo_test.svh"

endpackage
