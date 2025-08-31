# CNN Accelerator 

##  Project Overview
This repository contains an **FPGA-based CNN accelerator design (under development)**.  
Currently, the design has been tested in **simulation (testbench)** with **dummy weights** and pixel data generation.  

The next steps include:  
- Loading **trained weights** exported from Python models  
- Implementing on an **FPGA board** (e.g., Xilinx Zynq-7000)  
- Running end-to-end image classification in hardware  

--------------

## Architecture 
- Input   : 32 × 32 grayscale images  
- Conv1   : 5×5 kernel, stride 1 → ReLU → MaxPooling(2×2)  
- Conv2   : 5×5 kernel, stride 1 → ReLU → MaxPooling(2×2)  
- Flatten : 5 × 5 × 16 = 400 features  
- FC1     : 400 → 120 neurons  
- FC2     : 120 → 80 neurons  
- FC3     : 80 → 10 neurons  
- Argmax  : Final classification output (digits 0–9)  

--------------

## Current Status
- Implemented Verilog/SystemVerilog modules for CNN layers  
- Verified functionality in **testbench** with **dummy weights & pixel streams**  
- Confirmed pipeline dataflow (pixel-by-pixel processing)  

--------------

## Work in Progress / Future Plans
- Export real weights from a trained Python model and integrate into FPGA memory  
- Synthesize the design for **Xilinx Zynq-7000 FPGA**  
- Verify classification on real datasets (MNIST / CIFAR-10)  
- Add support for RGB images and deeper CNNs  

--------------

## Technologies
- **HDL**: Verilog / SystemVerilog  
- **Simulator**: ModelSim / Vivado Simulator  
- **FPGA (Planned)**: Xilinx Zynq-7000 (400 DSPs)  
- **Training (Planned)**: Python (for CNN training & weight export)  

--------------

## Repository Structure
CNN
│── src/ # Verilog/SystemVerilog source files
│── README.md # Project documentation


