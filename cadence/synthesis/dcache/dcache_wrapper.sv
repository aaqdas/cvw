import cvw::*;
`include "config.vh"
`include "parameter-defs.vh"

localparam   LLENWORDSPERLINE = P.DCACHE_LINELENINBITS/P.LLEN;             // Number of LLEN words in cacheline
localparam   LLENLOGBWPL = $clog2(LLENWORDSPERLINE);                       // Log2 of ^
localparam   BEATSPERLINE = P.DCACHE_LINELENINBITS/P.AHBW;                 // Number of AHBW words (beats) in cacheline
localparam   AHBWLOGBWPL = $clog2(BEATSPERLINE);                           // Log2 of ^
localparam   LINELEN = P.DCACHE_LINELENINBITS;                             // Number of bits in cacheline
localparam   LLENPOVERAHBW = P.LLEN / P.AHBW;                              // Number of AHB beats in a LLEN word. AHBW cannot be larger than LLEN. (implementation limitation)
localparam   CACHEWORDLEN = P.ZICCLSM_SUPPORTED ? 2*P.LLEN : P.LLEN; 

module dcache_wrapper (
  input  logic                   clk,
  input  logic                   reset,
  input  logic                   Stall,             // Stall the cache, preventing new accesses. In-flight access finished but does not return to READY
  input  logic                   FlushStage,        // Pipeline flush of second stage (prevent writes and bus operations)
  // cpu side
  input  logic [1:0]             CacheRW,           // [1] Read, [0] Write 
  input  logic                   FlushCache,        // Flush all dirty lines back to memory
  input  logic                   InvalidateCache,   // Clear all valid bits
  input  logic [3:0]             CMOpM,              // 1: cbo.inval; 2: cbo.flush; 4: cbo.clean; 8: cbo.zero
  input  logic [11:0]            NextSet,           // Virtual address, but we only use the lower 12 bits.
  input  logic [PA_BITS-1:0]     PAdr,              // Physical address
  input  logic [(CACHEWORDLEN-1)/8:0] ByteMask,          // Which bytes to write (D$ only)
  input  logic [CACHEWORDLEN-1:0]     WriteData,    // Data to write to cache (D$ only)
  output logic                   CacheCommitted,    // Cache has started bus operation that shouldn't be interrupted
  output logic                   CacheStall,        // Cache stalls pipeline during multicycle operation
  output logic [CACHEWORDLEN-1:0]     ReadDataWord,      // Word read from cache (goes to CPU and bus)
  // to performance counters to cpu
  output logic                   CacheMiss,         // Cache miss
  output logic                   CacheAccess,       // Cache access
  // lsu control
  input  logic                   SelHPTW,           // Use PAdr from Hardware Page Table Walker rather than NextSet
  // Bus fsm interface
  input  logic                   CacheBusAck,       // Bus operation completed
  input  logic                   SelBusBeat,        // Word in cache line comes from BeatCount
  input  logic [LLENLOGBWPL-1:0]     BeatCount,         // Beat in burst
  input  logic [LINELEN-1:0]     FetchBuffer,       // Buffer long enough to hold entire cache line arriving from bus
  output logic [1:0]             CacheBusRW,        // [1] Read (cache line fetch) or [0] write bus (cache line writeback)
  output logic [P.PA_BITS-1:0]     CacheBusAdr    
);

 

 cache #(.P(P), .PA_BITS(P.PA_BITS), .LINELEN(P.DCACHE_LINELENINBITS), .NUMSETS(P.DCACHE_WAYSIZEINBYTES*8/LINELEN),
        .NUMWAYS(P.DCACHE_NUMWAYS), .LOGBWPL(LLENLOGBWPL), .WORDLEN(CACHEWORDLEN), .MUXINTERVAL(P.LLEN), .READ_ONLY_CACHE(0)) 
        dcache(
    .clk,
  .reset ,
  .Stall,             // Stall the cache, preventing new accesses. In-flight access finished but does not return to READY
  .FlushStage,        // Pipeline flush of second stage (prevent writes and bus operations)
  // cpu side
  .CacheRW,           // [1] Read, [0] Write 
  .FlushCache,        // Flush all dirty lines back to memory
  .InvalidateCache,   // Clear all valid bits
  .CMOpM,              // 1: cbo.inval; 2: cbo.flush; 4: cbo.clean; 8: cbo.zero
  .NextSet,           // Virtual address, but we only use the lower 12 bits.
  .PAdr,              // Physical address
  .ByteMask,          // Which bytes to write (D$ only)
  .WriteData,    // Data to write to cache (D$ only)
  .CacheCommitted,    // Cache has started bus operation that shouldn't be interrupted
  .CacheStall,        // Cache stalls pipeline during multicycle operation
  .ReadDataWord,      // Word read from cache (goes to CPU and bus)
  // to performance counters to cpu
  .CacheMiss,         // Cache miss
  .CacheAccess,       // Cache access
  // lsu control
  .SelHPTW,           // Use PAdr from Hardware Page Table Walker rather than NextSet
  // Bus fsm interface
  .CacheBusAck,       // Bus operation completed
  .SelBusBeat,        // Word in cache line comes from BeatCount
  .BeatCount,         // Beat in burst
  .FetchBuffer,       // Buffer long enough to hold entire cache line arriving from bus
  .CacheBusRW,        // [1] Read (cache line fetch) or [0] write bus (cache line writeback)
  .CacheBusAdr   
    );

endmodule 