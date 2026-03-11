module approx_t_hetero
#(
    parameter WIDTH = 8   // FP32 mantissa width (including hidden 1)
)
(
    // Mantissas from floating_point_mul (ALREADY 1.x)
    input  [WIDTH-2:0] x,
    input  [WIDTH-2:0] y,

    // Approximation level select
    input  [WIDTH-3:0] Conf_Bit_Mask,   

    

    // Output (signed fixed-point, same as homogeneous)
    output [WIDTH*2-1:0] f
);
     // TL = 1.0
    localparam [5:0] l1 = 3, l2 = 0, l3 = 0;
    localparam       sl1 = 0, sl2 = 0, sl3 = 0;

    // TH ≈ 1 + 2^-4 + 2^-5 + 2^-6 = 1.109375
    localparam [5:0] h1 = 6'd1, h2 = 6'd2, h3 = 6'd3;
    localparam       sh1 = 0, sh2 = 0, sh3 = 0;

     

  
    // =====================================================
    // Promote mantissas to internal signed domain
    // (DO NOT re-add hidden 1)
    // =====================================================
    wire [WIDTH-1:0] xm, ym;
    assign xm = {1'b1, x};
    assign ym = {1'b1, y};

    // Constant "1.0" in same domain
    wire [WIDTH-1:0] ONE;
    // 1.0 aligned to match xm (at bit WIDTH-1)
    assign ONE = { 1'b1, {(WIDTH-1){1'b0}}};

    // =====================================================
    // f0 = 1.5x + 1.5y − 2.25  (IDENTICAL to homogeneous)
    // =====================================================
    wire [WIDTH*2-1:0] f0;
    assign f0 =
          xm + ym
        + ((xm + ym) >>> 1)
        - {2'b10, 2'b01, {(WIDTH-3){1'b0}}};

    // =====================================================
    // x − 1.5  (CORRECT)
    // =====================================================
    wire [WIDTH*2-1:0] xm_m_1p5;
    assign xm_m_1p5 = xm - ONE - (ONE >>> 1);

    // =====================================================
    // Build TL and TH from constants ONLY
    // =====================================================
    wire [WIDTH*2-1:0] TL_val, TH_val;

    assign TL_val = ONE
    + ((l1 != 0) ? (sl1 ? -(ONE >>> l1) : (ONE >>> l1)) : 0)
    + ((l2 != 0) ? (sl2 ? -(ONE >>> l2) : (ONE >>> l2)) : 0)
    + ((l3 != 0) ? (sl3 ? -(ONE >>> l3) : (ONE >>> l3)) : 0);

   assign TH_val = ONE
    + ((h1 != 0) ? (sh1 ? -(ONE >>> h1) : (ONE >>> h1)) : 0)
    + ((h2 != 0) ? (sh2 ? -(ONE >>> h2) : (ONE >>> h2)) : 0)
    + ((h3 != 0) ? (sh3 ? -(ONE >>> h3) : (ONE >>> h3)) : 0);

      
      wire y_lt_tl = (ym < TL_val);
    wire y_gt_th = (ym > TH_val);
    // =====================================================
    // Δf1 = (b1 − b0)(x − 1.5)
    // =====================================================
    wire [WIDTH*2-1:0] delf1_high, delf1_low, delf1_mid;

    // y > TH  →  b1 = (2 + TH)/2
    assign delf1_high =
         ((h1!=0)? (sh1 ? -(xm_m_1p5 >>> (h1+1)) : (xm_m_1p5 >>> (h1+1))):0)
        +((h2!=0)? (sh2 ? -(xm_m_1p5 >>> (h2+1)) : (xm_m_1p5 >>> (h2+1))):0)
        +((h3!=0)? (sh3 ? -(xm_m_1p5 >>> (h3+1)) : (xm_m_1p5 >>> (h3+1))):0);

    // y < TL → b1 = (1 + TL)/2
    assign delf1_low =
         ((l1!=0)? (sl1 ? -(xm_m_1p5 >>> (l1+1)) : (xm_m_1p5 >>> (l1+1))):0)
        +((l2!=0)? (sl2 ? -(xm_m_1p5 >>> (l2+1)) : (xm_m_1p5 >>> (l2+1))):0)
        +((l3!=0)? (sl3 ? -(xm_m_1p5 >>> (l3+1)) : (xm_m_1p5 >>> (l3+1))):0)
        - (xm_m_1p5 >>> 1);

    // TL ≤ y ≤ TH → b1 = (TL + TH)/2
    assign delf1_mid =
          delf1_high
        + ((l1!=0)? (sl1 ? -(xm_m_1p5 >>> (l1+1)) : (xm_m_1p5 >>> (l1+1))):0)
        + ((l2!=0)? (sl2 ? -(xm_m_1p5 >>> (l2+1)) : (xm_m_1p5 >>> (l2+1))):0)
        + ((l3!=0)? (sl3 ? -(xm_m_1p5 >>> (l3+1)) : (xm_m_1p5 >>> (l3+1))):0)
        - (xm_m_1p5 >>> 1);

    wire [WIDTH*2-1:0] delta_f1;
    assign delta_f1 =
          y_gt_th ? delf1_high :
          y_lt_tl ? delf1_low  :
                    delf1_mid;

    // =====================================================
    // Δf2 = (a2 − a1)(y − b)
    // =====================================================
    wire dense_band;
    assign dense_band = ~(y_lt_tl | y_gt_th);

    // b = (TL + TH)/2
    wire [WIDTH*2-1:0] b_val;
    assign b_val = (TL_val + TH_val) >>> 1;

    // y − b
    wire [WIDTH*2-1:0] ym_m_b;
    assign ym_m_b = ym - b_val;

    // a2 − a1 = ±2^-2
    wire x_gt_1p5;
    assign x_gt_1p5 = (xm > (ONE + (ONE >>> 1)));

    wire [WIDTH*2-1:0] delta_f2;
    assign delta_f2 =
        dense_band ?
            (x_gt_1p5 ? (ym_m_b >>> 2) : -(ym_m_b >>> 2))
        : 0;

    // =====================================================
    // Final output (level select)
    // =====================================================
    wire [WIDTH*2-1:0] t_f0_f1,t_f2_f3 ; 
   
           
         bit_mask_sel #(WIDTH*2) bms0(.sel(Conf_Bit_Mask[1:0]),.x(f0),.y(delta_f1),.r(t_f0_f1));
                     bit_mask_sel #(WIDTH*2) bms1(.sel(Conf_Bit_Mask[3:2]),.x(delta_f2),.y({(WIDTH*2){1'b0}}),.r(t_f2_f3));


   assign f = t_f0_f1 + t_f2_f3 ;

endmodule
