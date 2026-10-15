class demo_item extends uvm_sequence_item;

    rand bit [7:0] req_data;
         bit [7:0] rsp_data;
         bit       response_seen;

    `uvm_object_utils(demo_item)

    constraint c_default_req_data {
        soft req_data inside {[8'h00:8'hff]};
    }

    function new(string name = "demo_item");
        super.new(name);
    endfunction

    virtual function void do_copy(uvm_object rhs);
        demo_item rhs_item;

        super.do_copy(rhs);
        if (!$cast(rhs_item, rhs)) begin
            `uvm_fatal("DEMO/ITEM/COPY", "do_copy received an incompatible object")
        end
        req_data      = rhs_item.req_data;
        rsp_data      = rhs_item.rsp_data;
        response_seen = rhs_item.response_seen;
    endfunction

    virtual function bit do_compare(
        uvm_object   rhs,
        uvm_comparer comparer
    );
        demo_item rhs_item;

        if (!$cast(rhs_item, rhs)) begin
            return 1'b0;
        end
        return super.do_compare(rhs, comparer) &&
               (req_data      == rhs_item.req_data) &&
               (rsp_data      == rhs_item.rsp_data) &&
               (response_seen == rhs_item.response_seen);
    endfunction

    virtual function string convert2string();
        return $sformatf(
            "req_data=0x%02h rsp_data=0x%02h response_seen=%0b",
            req_data,
            rsp_data,
            response_seen
        );
    endfunction

endclass
