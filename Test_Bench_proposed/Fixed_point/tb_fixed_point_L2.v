`timescale 1ns / 1ps

module tb;

    reg signed [15:0] r;           // 
    reg signed [7:0]  A;           // 
    reg signed [7:0]  B;           // 
    real i;                  // 
    real j;                  // 
    reg  [15:0] ErrorCounter = 0;
    real ErrorDistance = 0.0; // 
    reg  [31:0] MaxError = 0;
    real RED = 0.0;          // 
    reg  [7:0] r_A = 0;
    reg  [7:0] r_B = 0;
    reg  [8:0] k = 0;
    reg  [7:0] V = 0;
    reg  [7:0] min_V = 0;
    real min_RED = 1.0e38;   // 

    integer rand_seed;       // 
    integer test_count;
    real relative_error;
    real acc_result;
    real appr_result;
    
    integer file_ptr;

    initial 
    begin
    	
    	file_ptr = $fopen("Simulation_Results/Fixed_point_proposed/Fixed_point_L2.csv", "w");
    	
    	
    	if (file_ptr == 0) begin
        	$display("Error: Could not open file.");
    	end
    	
    
    	// Initializing test count.
    	test_count = 1;
    	$display("Test_count = %d", test_count);
    	
        // Print header
        $display("------------------------------------------------------------------------------------------------------------------------");
        $display("| Test |       A        |        B        |     Acc_Result     |   Approx_Result  |   Error Bias   |   Relative Error  |");
        $display("------------------------------------------------------------------------------------------------------------------------");
        
        // To write the headers in the csv file
        $fdisplay(file_ptr, "Test,A,B,Acc_Result,Approx_Result,Error_Bias,Relative_Error");
    
        // 
        for (i = -128; i < 127; ++i)
        begin
            //
            A = i;
             
            for (j = -128; j < 127; ++j) 
            begin 
            	//i = {$random} % 256;
            	//j = {$random} % 256;
            	B = j;
            #0.001;
            
            acc_result = ($itor(i) / 16.0) * ($itor(j) / 16.0);
            appr_result = $itor(r) / 16.0;
            
            
            if ((appr_result < acc_result) || (appr_result == acc_result))
            begin 
            	relative_error = (acc_result) ? (((acc_result) - (appr_result)) / (acc_result)) : 0;
            	ErrorCounter = (appr_result == (i * j)) ? (ErrorCounter + 0) : (ErrorCounter + 1);
                // Display test results
            	$display("| %d |  %f  |   %f  |    %f    |   %f   |  %f  |   %f   |",
                     	test_count, $itor(i)/16.0, $itor(j)/16.0, acc_result, appr_result, (appr_result) - (acc_result), relative_error);
                //$display("Exact multiplication result: %d, Approx-T result: %d, Absolute Error Distance is %d, Relative Error is %f.", i * j, r, i*j-r, ((i * j - r)) / (i * j));
                $fdisplay(file_ptr, "%d,%f,%f,%f,%f,%f,%f", test_count, $itor(i)/16.0, $itor(j)/16.0, acc_result, appr_result, (appr_result) - (acc_result), relative_error);
                test_count = test_count + 1;
            end
            else if (r > i * j)
            begin
            	relative_error = ((appr_result) - (acc_result));
            	ErrorCounter = ErrorCounter + 1;
                $display("| %d |  %f  |   %f  |    %f    |   %f   |  %f  |   %f   |",
                     	test_count, $itor(i)/16.0, $itor(j)/16.0, acc_result, appr_result, (appr_result) - (acc_result), relative_error);
                //$display("Exact multiplication result: %d, Approx-T result: %d, Absolute Error Distance is %d, Relative Error is %f.", i * j, r, r-i*j, ((r - i * j)) / (i * j));
                $fdisplay(file_ptr, "%d,%f,%f,%f,%f,%f,%f", test_count, $itor(i)/16.0, $itor(j)/16.0, acc_result, appr_result, (appr_result) - (acc_result), relative_error);
                test_count = test_count + 1;
            end
            
            

            // 
            /*if (r < i * j)
            begin
                ErrorCounter = ErrorCounter + 1'b1; 
                ErrorDistance = ErrorDistance + (i * j - r); // 
                if ((i * j - r) > MaxError) // 
                begin
                    MaxError = (i * j - r);
                    r_A = i;
                    r_B = j;
                end
                RED = RED + ((i * j - r)) / (i * j); // 
                // Display test results
            	$display("| %d |  %d  |   %d  |    %d    |   %d   |  %d  |   %f   |",
                     	test_count, i, j, i * j, r, i*j-r, ((i * j - r)) / (i * j));
                //$display("Exact multiplication result: %d, Approx-T result: %d, Absolute Error Distance is %d, Relative Error is %f.", i * j, r, i*j-r, ((i * j - r)) / (i * j));
                test_count = test_count + 1;
            end
            else if (r > i * j)
            begin
                ErrorCounter = ErrorCounter + 1'b1; 
                ErrorDistance = ErrorDistance + (r - i * j); // 
                if ((r - i * j) > MaxError)
                begin
                    MaxError = (r - i * j);
                    r_A = i;
                    r_B = j;
                end
                RED = RED + ((r - i * j)) / (i * j); // 
                $display("| %d |  %d  |   %d  |    %d    |   %d   |  %d  |   %f   |",
                     	test_count, i, j, i * j, r, r-i*j, ((i * j - r)) / (i * j));
                //$display("Exact multiplication result: %d, Approx-T result: %d, Absolute Error Distance is %d, Relative Error is %f.", i * j, r, r-i*j, ((r - i * j)) / (i * j));
                test_count = test_count + 1;
            end*/
            
          end

       end
       
       $display("The total number of errors = %d", ErrorCounter);
       $fclose(file_ptr);
       $finish;

    end

    // 
    fixed_point_mul M1(.A(A), .B(B), .R(r), .Conf_Bit_Mask(6'b111));  //6'b1 ~ 6'b111111
endmodule
