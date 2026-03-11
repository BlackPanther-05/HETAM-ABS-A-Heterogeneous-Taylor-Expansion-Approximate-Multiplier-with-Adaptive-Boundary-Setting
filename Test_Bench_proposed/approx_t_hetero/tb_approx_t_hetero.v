//==============================================================
// File    : Test_Bench/approx_t/tb_approx_t.v
// Description:
//   Purely combinational testbench for approx_t (no clock).
//   Supports WIDTH=8 (full sweep) and WIDTH=24 (random sampling).
//
//   Compile-time parameter  : WIDTH  (set via -Ptb_approx_t.WIDTH=N)
//   Runtime plusargs        : +level=<0-5>   +width=<8|24>
//
//   WIDTH=8  : full sweep of all 128x128 = 16,384 combinations
//   WIDTH=24 : 100,000 random input vectors (full sweep not feasible)
//
//   All CSV values are in BINARY string format.
//
//   Output paths (relative to Test_Bench_proposed/approx_t_hetero/ — the vvp cwd):
//     CSV -> ../../Simulation_Results/approx_t_hetero/results_wW_levelL.csv
//     VCD -> ../../vcd/approx_t_hetero/approx_t_hetero_wW_levelL.vcd
//
//   Bit widths per parameter:
//     WIDTH=8  : x,y=7b  f=16b  exact=14b  err=16b  mask=6b
//     WIDTH=24 : x,y=23b f=48b  exact=46b  err=48b  mask=22b
//
//   Level -> Conf_Bit_Mask (lower 6 bits; upper bits 0):
//     Level 0: ...00_00_01  (f0 only)
//     Level 1: ...00_00_11  (f0+f1)
//     Level 2: ...00_01_11  (f0+f1+f2)
//     Level 3: ...00_11_11  (f0+f1+f2+f3)
//     Level 4: ...01_11_11  (f0+f1+f2+f3+f4)
//     Level 5: ...11_11_11  (all terms, most accurate)
//
//   Between every test vector inputs are forced to 0 so all
//   internal nodes return to 0 -> worst-case switching for power.
//
//   VCD is explicitly flushed with $dumpflush before $finish to
//   guarantee a complete, valid VCD file for power analysis.
//==============================================================

`timescale 1ns/1ps

module tb_approx_t;

    //------------------------------------------------------------------
    // Compile-time parameter — override with -Ptb_approx_t.WIDTH=24
    //------------------------------------------------------------------
    parameter WIDTH    = 8;
    parameter PROP_DLY = 10;       // ns: combinational settle budget
    parameter NUM_RAND = 100000;   // random vectors used for WIDTH=24

    //------------------------------------------------------------------
    // Derived widths
    //   WIDTH=8  : XY=7,  F=16, MASK=6,  EXACT=14
    //   WIDTH=24 : XY=23, F=48, MASK=22, EXACT=46
    //------------------------------------------------------------------
    localparam XY_BITS    = WIDTH - 1;
    localparam F_BITS     = 2 * WIDTH;
    localparam MASK_BITS  = WIDTH - 2;
    localparam EXACT_BITS = 2 * (WIDTH - 1);

    //------------------------------------------------------------------
    // DUT signals
    //------------------------------------------------------------------
    reg  [WIDTH-2:0]   x;
    reg  [WIDTH-2:0]   y;
    reg  [WIDTH-3:0]   Conf_Bit_Mask;
    wire [2*WIDTH-1:0] f;

    //------------------------------------------------------------------
    // DUT instantiation
    //------------------------------------------------------------------
    approx_t_hetero #(.WIDTH(WIDTH)) dut (
        .x             (x),
        .y             (y),
        .Conf_Bit_Mask  (Conf_Bit_Mask),
        .f             (f)
    );

    //------------------------------------------------------------------
    // Internal variables
    //------------------------------------------------------------------
    integer         level;
    integer         width_arg;    // from +width= plusarg (for filenames)
    integer         i, j, k;
    integer         fd;
    reg [WIDTH-3:0] mask;

    // 64-bit arithmetic holders — wide enough for both WIDTH=8 and WIDTH=24
    // WIDTH=24 max product: (2^23-1)^2 < 2^46 — fits in 64 bits easily
    reg [63:0]  xi;
    reg [63:0]  yi;
    reg [63:0]  exact_int;
    reg [63:0]  f_int;
    reg [63:0]  abs_err;

    //------------------------------------------------------------------
    // Binary string output buffers
    // Sized for the widest case (WIDTH=24):
    //   x,y   : 23 bits -> 23 chars
    //   f,err : 48 bits -> 48 chars
    //   exact : 46 bits -> 46 chars
    // WIDTH=8 tasks write into the same buffers (use lower slice).
    //------------------------------------------------------------------
    reg [23*8-1:0]  x_bin;
    reg [23*8-1:0]  y_bin;
    reg [48*8-1:0]  f_bin;
    reg [46*8-1:0]  exact_bin;
    reg [48*8-1:0]  err_bin;

    //------------------------------------------------------------------
    // Binary string conversion tasks
    //------------------------------------------------------------------

    // 7-bit -> string (x, y for WIDTH=8)
    task to_bin7;
        input  [6:0]      val;
        output [23*8-1:0] str;
        integer b;
        begin
            str = {23*8{1'b0}};
            for (b = 0; b < 7; b = b + 1)
                str[(6-b)*8 +: 8] = val[6-b] ? "1" : "0";
        end
    endtask

    // 23-bit -> string (x, y for WIDTH=24)
    task to_bin23;
        input  [22:0]     val;
        output [23*8-1:0] str;
        integer b;
        begin
            for (b = 0; b < 23; b = b + 1)
                str[(22-b)*8 +: 8] = val[22-b] ? "1" : "0";
        end
    endtask

    // 16-bit -> string (f, err for WIDTH=8)
    task to_bin16;
        input  [15:0]     val;
        output [48*8-1:0] str;
        integer b;
        begin
            str = {48*8{1'b0}};
            for (b = 0; b < 16; b = b + 1)
                str[(15-b)*8 +: 8] = val[15-b] ? "1" : "0";
        end
    endtask

    // 48-bit -> string (f, err for WIDTH=24)
    task to_bin48;
        input  [47:0]     val;
        output [48*8-1:0] str;
        integer b;
        begin
            for (b = 0; b < 48; b = b + 1)
                str[(47-b)*8 +: 8] = val[47-b] ? "1" : "0";
        end
    endtask

    // 14-bit -> string (exact product for WIDTH=8)
    task to_bin14;
        input  [13:0]     val;
        output [46*8-1:0] str;
        integer b;
        begin
            str = {46*8{1'b0}};
            for (b = 0; b < 14; b = b + 1)
                str[(13-b)*8 +: 8] = val[13-b] ? "1" : "0";
        end
    endtask

    // 46-bit -> string (exact product for WIDTH=24)
    task to_bin46;
        input  [45:0]     val;
        output [46*8-1:0] str;
        integer b;
        begin
            for (b = 0; b < 46; b = b + 1)
                str[(45-b)*8 +: 8] = val[45-b] ? "1" : "0";
        end
    endtask

    //==================================================================
    // Main simulation body — purely event-driven, NO clock
    //==================================================================
    initial begin : sim_main

        //--------------------------------------------------------------
        // STEP 1: Read plusargs
        //--------------------------------------------------------------
        if (!$value$plusargs("level=%d", level)) begin
            $display("ERROR: Missing +level=<0-5>"); $finish;
        end
        if (!$value$plusargs("width=%d", width_arg)) begin
            $display("ERROR: Missing +width=<8|24>"); $finish;
        end
        if (level < 0 || level > 5) begin
            $display("ERROR: level must be 0-5, got %0d", level); $finish;
        end
        if (width_arg != 8 && width_arg != 24) begin
            $display("ERROR: width must be 8 or 24, got %0d", width_arg); $finish;
        end

        //--------------------------------------------------------------
        // STEP 2: Set Conf_Bit_Mask
        //   Lower 6 bits encode the level; upper bits are 0.
        //--------------------------------------------------------------
        case (level)
            0: mask = {{(MASK_BITS-6){1'b0}}, 6'b00_00_01};
            1: mask = {{(MASK_BITS-6){1'b0}}, 6'b00_00_11};
            2: mask = {{(MASK_BITS-6){1'b0}}, 6'b00_01_11};
            3: mask = {{(MASK_BITS-6){1'b0}}, 6'b00_11_11};
            4: mask = {{(MASK_BITS-6){1'b0}}, 6'b01_11_11};
            5: mask = {{(MASK_BITS-6){1'b0}}, 6'b11_11_11};
            default: mask = {MASK_BITS{1'b0}};
        endcase
        Conf_Bit_Mask = mask;

        //--------------------------------------------------------------
        // STEP 3: Open CSV file
        //   12 combinations: {w8, w24} x {level 0-5}
        //--------------------------------------------------------------
        if (width_arg == 8) begin
            case (level)
                0: fd=$fopen("../../Simulation_Results/approx_t/results_w8_level0.csv","w");
                1: fd=$fopen("../../Simulation_Results/approx_t/results_w8_level1.csv","w");
                2: fd=$fopen("../../Simulation_Results/approx_t/results_w8_level2.csv","w");
                3: fd=$fopen("../../Simulation_Results/approx_t/results_w8_level3.csv","w");
                4: fd=$fopen("../../Simulation_Results/approx_t/results_w8_level4.csv","w");
                5: fd=$fopen("../../Simulation_Results/approx_t/results_w8_level5.csv","w");
            endcase
        end else begin
            case (level)
                0: fd=$fopen("../../Simulation_Results/approx_t/results_w24_level0.csv","w");
                1: fd=$fopen("../../Simulation_Results/approx_t/results_w24_level1.csv","w");
                2: fd=$fopen("../../Simulation_Results/approx_t/results_w24_level2.csv","w");
                3: fd=$fopen("../../Simulation_Results/approx_t/results_w24_level3.csv","w");
                4: fd=$fopen("../../Simulation_Results/approx_t/results_w24_level4.csv","w");
                5: fd=$fopen("../../Simulation_Results/approx_t/results_w24_level5.csv","w");
            endcase
        end

        if (fd == 0) begin
            $display("ERROR: Cannot open CSV for level %0d.", level);
            $display("       Ensure Simulation_Results/approx_t/ directory exists.");
            $finish;
        end

        // CSV header — all data fields are binary strings
        $fdisplay(fd, "level,x_bin,y_bin,f_approx_bin,f_exact_bin,abs_error_bin");

        //--------------------------------------------------------------
        // STEP 4: Open VCD dump
        //   $dumpfile requires a string literal so all 12 cases are
        //   enumerated explicitly.
        //   $dumpvars(0,...) captures the full design hierarchy.
        //--------------------------------------------------------------
        if (width_arg == 8) begin
            case (level)
                0: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w8_level0.vcd");
                1: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w8_level1.vcd");
                2: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w8_level2.vcd");
                3: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w8_level3.vcd");
                4: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w8_level4.vcd");
                5: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w8_level5.vcd");
            endcase
        end else begin
            case (level)
                0: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w24_level0.vcd");
                1: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w24_level1.vcd");
                2: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w24_level2.vcd");
                3: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w24_level3.vcd");
                4: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w24_level4.vcd");
                5: $dumpfile("../../vcd/approx_t_hetero/approx_t_hetero_w24_level5.vcd");
            endcase
        end

        // Capture ALL signals in the full hierarchy (tb + dut internals)
        $dumpvars(0, tb_approx_t);

        $display("============================================================");
        $display(" approx_t TB | WIDTH=%0d | Level=%0d | Mask=%b",
                  WIDTH, level, mask);
        if (WIDTH == 8)
            $display(" Mode: FULL SWEEP  (128 x 128 = 16384 combinations)");
        else
            $display(" Mode: RANDOM SAMPLE (%0d vectors)", NUM_RAND);
        $display("============================================================");

        //--------------------------------------------------------------
        // STEP 5: Initial reset — ensure outputs start from 0
        //--------------------------------------------------------------
        x = {(WIDTH-1){1'b0}};
        y = {(WIDTH-1){1'b0}};
        #(PROP_DLY);

        //--------------------------------------------------------------
        // STEP 6A: WIDTH=8 — full sweep 128 x 128
        //--------------------------------------------------------------
        if (WIDTH == 8) begin
            for (i = 0; i < 128; i = i + 1) begin
                for (j = 0; j < 128; j = j + 1) begin

                    // Apply inputs
                    x = i[6:0];
                    y = j[6:0];
                    #(PROP_DLY);

                    // Exact reference
                    exact_int = i * j;      // max 127*127=16129 < 2^14
                    f_int     = 64'b0;
                    f_int[2*WIDTH-1:0] = f;

                    if (f_int >= exact_int) abs_err = f_int - exact_int;
                    else                    abs_err = exact_int - f_int;

                    // Build binary strings
                    to_bin7 (x[6:0],          x_bin);
                    to_bin7 (y[6:0],          y_bin);
                    to_bin16(f[15:0],         f_bin);
                    to_bin14(exact_int[13:0], exact_bin);
                    to_bin16(abs_err[15:0],   err_bin);

                    // Write CSV row
                    $fdisplay(fd, "%0d,%0s,%0s,%0s,%0s,%0s",
                        level,
                        x_bin[7*8-1:0],
                        y_bin[7*8-1:0],
                        f_bin[16*8-1:0],
                        exact_bin[14*8-1:0],
                        err_bin[16*8-1:0]
                    );

                    // Reset to 0 — forces all internal nodes low,
                    // giving worst-case 0->value->0 toggling for power
                    x = {(WIDTH-1){1'b0}};
                    y = {(WIDTH-1){1'b0}};
                    #(PROP_DLY);

                end // j
            end // i
        end // WIDTH==8

        //--------------------------------------------------------------
        // STEP 6B: WIDTH=24 — 100,000 random vectors
        //   x,y are 23-bit unsigned. Max product = (2^23-1)^2 < 2^46.
        //   $random returns 32-bit signed; AND-mask to 23 bits.
        //--------------------------------------------------------------
        else begin
            for (k = 0; k < NUM_RAND; k = k + 1) begin

                // 23-bit random values
                xi = {$random} & 64'h00000000007FFFFF;
                yi = {$random} & 64'h00000000007FFFFF;

                x = xi[22:0];
                y = yi[22:0];
                #(PROP_DLY);

                // Exact 46-bit product
                exact_int = xi * yi;

                // f is [2*WIDTH-1:0] = [47:0] for WIDTH=24
                f_int = 64'b0;
                f_int[2*WIDTH-1:0] = f;

                if (f_int >= exact_int) abs_err = f_int - exact_int;
                else                    abs_err = exact_int - f_int;

                // Build binary strings
                to_bin23(x[22:0],         x_bin);
                to_bin23(y[22:0],         y_bin);
                to_bin48(f_int[47:0],     f_bin);
                to_bin46(exact_int[45:0], exact_bin);
                to_bin48(abs_err[47:0],   err_bin);

                // Write CSV row
                $fdisplay(fd, "%0d,%0s,%0s,%0s,%0s,%0s",
                    level,
                    x_bin[23*8-1:0],
                    y_bin[23*8-1:0],
                    f_bin[48*8-1:0],
                    exact_bin[46*8-1:0],
                    err_bin[48*8-1:0]
                );

                // Reset to 0 — worst-case switching activity
                x = {(WIDTH-1){1'b0}};
                y = {(WIDTH-1){1'b0}};
                #(PROP_DLY);

            end // k
        end // WIDTH==24

        //--------------------------------------------------------------
        // STEP 7: Close CSV and flush VCD completely before finishing.
        //
        // CRITICAL: $dumpflush forces iverilog to write all pending VCD
        // data to disk. Without this, the VCD may be truncated/incomplete
        // When signals are not flushed and $finish is called,
        // the VCD file may be incomplete or truncated.
        // The #1 delay gives the simulator time to process
        // the flush before $finish terminates the simulation.
        //--------------------------------------------------------------
        $fclose(fd);
        $dumpflush;           // flush all VCD buffers to disk
        #1;                   // allow flush to complete before $finish
        $dumpoff;             // cleanly stop VCD recording

        $display("============================================================");
        $display(" WIDTH=%0d Level=%0d DONE.", WIDTH, level);
        $display(" CSV  -> Simulation_Results/approx_t_hetero/results_w%0d_level%0d.csv",
                  width_arg, level);
        $display(" VCD  -> vcd/approx_t_hetero/approx_t_hetero_w%0d_level%0d.vcd (flushed)",
                  width_arg, level);
        $display("============================================================");
        $finish;

    end // sim_main

endmodule
