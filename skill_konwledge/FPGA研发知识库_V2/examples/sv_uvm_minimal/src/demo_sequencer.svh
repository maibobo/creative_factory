class demo_sequencer extends uvm_sequencer #(demo_item);

    `uvm_component_utils(demo_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
