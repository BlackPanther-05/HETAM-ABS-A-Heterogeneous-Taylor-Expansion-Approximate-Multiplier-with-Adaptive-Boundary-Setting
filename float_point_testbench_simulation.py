import subprocess
import concurrent.futures
import os
from tqdm import tqdm

# Define the simulations you want to run
# Format: (Testbench_File, Output_Executable_Name)
simulations = [
    ("Test_Bench/Floating_point/tb4float_L0.v", "test_float_point_L0"),
    ("Test_Bench/Floating_point/tb4float_L1.v", "test_float_point_L1"),
    ("Test_Bench/Floating_point/tb4float_L2.v", "test_float_point_L2"),
]

def run_iverilog_sim(testbench, output_name):
    """Function to compile and execute a single simulation."""
    try:
        print(f"--- Starting: {testbench} ---")

        # 1. Compile Command
        compile_cmd = [
            "iverilog", "-g2012", 
            "-o", output_name, 
            "RTL/floating_point_mul.v", # Add your specific RTL files or use "RTL/*.v"
            "RTL/approx_t.v",
            "RTL/bit_mask_sel.v",
            testbench
        ]
        
        # Run Compilation
        subprocess.run(compile_cmd, check=True)
        print(f"Successfully compiled {testbench}")

        # Ensure CSV directory exists before running vvp
        csv_dir = "Simulation_Results/Floating_point"
        if not os.path.exists(csv_dir):
            os.makedirs(csv_dir)

        # 2. VVP Execution Command
        # We use capture_output=True to keep the terminal clean
        vvp_cmd = ["vvp", output_name]
        result = subprocess.run(vvp_cmd, capture_output=True, text=True, check=True)
        
        # Define the directory and ensure it exists
        log_dir = "Simulation_log"
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
        
    	# 2. Create the full file path string
        log_file = f"{output_name}_sim.log"
        log_file_path = os.path.join(log_dir, log_file)
        
        # Save output to a log file instead of flooding the terminal
        with open(log_file_path, "w") as f:
            f.write(result.stdout)

        return f"Finished {testbench}. Results in {log_file}"

    except subprocess.CalledProcessError as e:
        return f"Error occurred while running {testbench}: {e}"

# Use ThreadPoolExecutor to run simulations in parallel
def main():
    # Ensure result folder exists for Verilog CSV output
    if not os.path.exists("Simulation_Results/Floating_point"):
        os.makedirs("Simulation_Results/Floating_point")

    print(f"Starting {len(simulations)} simulations parallelly...\n")
    
    with concurrent.futures.ThreadPoolExecutor() as executor:
        # Map the function to the list of simulations
        futures = [executor.submit(run_iverilog_sim, sim[0], sim[1]) for sim in simulations]
        
        # tqdm wraps the as_completed iterator to show progress
        # total=len(simulations) tells tqdm how many items to expect
        for future in tqdm(concurrent.futures.as_completed(futures), total=len(simulations), desc="Simulating", unit="test"):
            result = future.result()
            # If you want to see the result of each test as it finishes without breaking the bar:
            # tqdm.write(result)
        
        for future in concurrent.futures.as_completed(futures):
            print(future.result())
        
         

    print("\nAll simulations completed.")

if __name__ == "__main__":
    main()
