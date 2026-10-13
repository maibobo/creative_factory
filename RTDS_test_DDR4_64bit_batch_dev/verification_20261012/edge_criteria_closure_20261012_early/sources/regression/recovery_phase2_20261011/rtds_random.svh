// 修改记录 2026-10-11：独立xorshift32随机流，SEED显式输入并记录抽样值和末状态。
integer phase2_seed;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
integer unsigned phase2_rng=0;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
integer phase2_draws=0;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
bit phase2_rng_ready=0;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
function automatic integer phase2_pick(input integer lo,input integer hi);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    integer unsigned v;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    if(!phase2_rng_ready) begin   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        if(!$value$plusargs("SEED=%d",phase2_seed)) phase2_seed=20261011;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        phase2_rng=32'(phase2_seed)^32'h6d2b79f5;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        if(phase2_rng==0) phase2_rng=1;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        phase2_rng_ready=1;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        $display("RNG_INIT scope=%m seed=%0d algorithm=xorshift32",phase2_seed);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    end   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    phase2_rng=phase2_rng^(phase2_rng<<13);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    phase2_rng=phase2_rng^(phase2_rng>>17);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    phase2_rng=phase2_rng^(phase2_rng<<5);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    v=phase2_rng;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    phase2_pick=lo+integer'(v%unsigned'(hi-lo+1));   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    phase2_draws++;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    if(phase2_draws<=8) $display("RNG_DRAW scope=%m n=%0d value=%0d lo=%0d hi=%0d",phase2_draws,phase2_pick,lo,hi);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
endfunction   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
final $display("RNG_SUMMARY scope=%m seed=%0d draws=%0d state=%h",phase2_seed,phase2_draws,phase2_rng);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
