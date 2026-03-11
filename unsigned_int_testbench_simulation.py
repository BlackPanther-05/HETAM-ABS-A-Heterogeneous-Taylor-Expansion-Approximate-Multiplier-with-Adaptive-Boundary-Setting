import subprocess
import concurrent.futures
import os
from tqdm import tqdm

# Define the simulations you want to run
simulations = [
    ("Test_Bench/Unsigned_int/tb_unsigned_int_L0.v", "test_Unsigned_int_L0"),
    ("Test_Bench/Unsigned_int/tb_unsigned_int_L1.v", "test_Unsigned_int_L1"),
    ("Test_Bench/Unsigned_int/tb_unsigned_int_L2.v", "test_Unsigned_int_L2"),
]

def run_iverilog_sim(testbench, output_name):
    """Function to compile and execute a single simulation."""
    try:
        # 1. Compile Command
        compile_cmd = [
            "iverilog", "-g2012", 
            "-o", output_name, 
            "RTL/unsigned_int_mul.v",
            "RTL/approx_t.v",
            "RTL/leading_one_detector.v",
            "RTL/bit_mask_sel.v",
            testbench
        ]
        
        subprocess.run(compile_cmd, check=True, capture_output=True)

        # Ensure CSV directory exists before running vvp
        csv_dir = "Simulation_Results/base/Unsigned_int"
        if not os.path.exists(csv_dir):
            os.makedirs(csv_dir)

        # 2. VVP Execution Command - Pass unique CSV path via +OUT
        csv_path = f"{csv_dir}/{output_name}.csv"
        vvp_cmd = ["vvp", output_name, f"+OUT={csv_path}"]
        
        result = subprocess.run(vvp_cmd, capture_output=True, text=True, check=True)
        
        # Log handling
        log_dir = "Simulation_log"
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
        
        log_file_path = os.path.join(log_dir, f"{output_name}_sim.log")
        with open(log_file_path, "w") as f:
            f.write(result.stdout)

        return f"Finished {testbench}. CSV: {csv_path}"

    except subprocess.CalledProcessError as e:
        return f"Error occurred while running {testbench}: {e}"

def main():
    if not os.path.exists("Simulation_Results/base/Unsigned_int"):
        os.makedirs("Simulation_Results/base/Unsigned_int")

    print(f"Starting {len(simulations)} simulations parallelly...\n")
    
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [executor.submit(run_iverilog_sim, sim[0], sim[1]) for sim in simulations]
        
        # Use tqdm to track progress
        for future in tqdm(concurrent.futures.as_completed(futures), total=len(simulations), desc="Simulating", unit="test"):
            result = future.result()
            # Use tqdm.write to print without breaking the progress bar
            tqdm.write(result) 

    print("\nAll simulations completed.")

if __name__ == "__main__":
    main()
