`timescale 1ns / 1ps

module tb;

    wire [15:0] r;           // 
    reg  [7:0]  A;           // 
    reg  [7:0]  B;           // 
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
    
    integer file_ptr;

    initial 
    begin
    	
    	file_ptr = $fopen("Simulation_Results/proposed/Unsigned_int/Unsigned_int_L0.csv", "w");
    	
    	
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
        for (i = 0; i < 256; ++i)
        begin
            //
            A = i;
             
            for (j=0; j < 256; ++j) 
            begin 
            	//i = {$random} % 256;
            	//j = {$random} % 256;
            	B = j;
            #0.001;
            
            
            if ((r < i * j) || (r == i * j))
            begin 
            	relative_error = (i*j) ? ((i * j - r) / (i * j)) : 0;
            	ErrorCounter = (r == (i * j)) ? (ErrorCounter + 0) : (ErrorCounter + 1);
                // Display test results
            	$display("| %d |  %d  |   %d  |    %d    |   %d   |  %d  |   %f   |",
                     	test_count, i, j, i * j, r, (r-(i*j)), relative_error);
                //$display("Exact multiplication result: %d, Approx-T result: %d, Absolute Error Distance is %d, Relative Error is %f.", i * j, r, i*j-r, ((i * j - r)) / (i * j));
                $fdisplay(file_ptr, "%d,%d,%d,%d,%d,%d,%f", test_count, i, j, i * j, r, (r-(i*j)), relative_error);
                test_count = test_count + 1;
            end
            else if (r > i * j)
            begin
            	relative_error = ((r - i * j) / (i * j)) ;
            	ErrorCounter = ErrorCounter + 1;
                $display("| %d |  %d  |   %d  |    %d    |   %d   |  %d  |   %f   |",
                     	test_count, i, j, i * j, r, (r-(i*j)), relative_error);
                //$display("Exact multiplication result: %d, Approx-T result: %d, Absolute Error Distance is %d, Relative Error is %f.", i * j, r, r-i*j, ((r - i * j)) / (i * j));
                $fdisplay(file_ptr, "%d,%d,%d,%d,%d,%d,%f", test_count, i, j, i * j, r, (r-(i*j)), relative_error);
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
    unsigned_int_mul M1(.A(A), .B(B), .R(r), .Conf_Bit_Mask(6'b1));  //6'b1 ~ 6'b111111
endmodule
