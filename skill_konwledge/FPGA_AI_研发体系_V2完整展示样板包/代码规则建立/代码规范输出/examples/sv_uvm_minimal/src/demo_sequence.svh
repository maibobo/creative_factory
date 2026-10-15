class demo_sequence extends uvm_sequence #(demo_item);

    `uvm_object_utils(demo_sequence)

    int unsigned item_count = 32;

    function new(string name = "demo_sequence");
        super.new(name);
    endfunction

    virtual task body();
        demo_item req;

        for (int unsigned index = 0; index < item_count; index++) begin
            req = demo_item::type_id::create($sformatf("req_%0d", index));
            start_item(req);
            if (!req.randomize()) begin
                `uvm_fatal(
                    "DEMO/SEQUENCE/RANDOMIZE",
                    $sformatf("randomization failed for item %0d", index)
                )
            end
            finish_item(req);
        end
    endtask

endclass
