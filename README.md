# OCTAVie – Ultrasonic Acquisition Platform

**OCTAVie** is an open-source hardware and software platform designed to capture and analyze ultrasonic vocalizations of animals (up to ≥80 kHz).  
It combines a sensitive microphone module, an analog front-end, an FPGA-based acquisition unit, and a PC application for real-time spectral analysis.

This repository hosts the **complete open-source design files**: electronics, enclosures, FPGA firmware, PC software, documentation, and example datasets.  
The project is developed at **ICube, LNCA, and the Faculty of Physics and Engineering – Strasbourg, France**, within the framework of the **OCTAVie project**.

---

## Quickstart

### 1. Build Hardware
- Go to [hardware/](hardware/)  
- Assemble the **microphone** and the **acquisition unit** following the build guide:  
  - [docs/build_guide/pcb_assembly.md](docs/build_guide/pcb_assembly.md)  
  - [docs/build_guide/mechanical_assembly.md](docs/build_guide/mechanical_assembly.md)  
- Complete system integration: [hardware/system_integration/final_assembly.md](hardware/system_integration/final_assembly.md)

### 2. Program FPGA
- Go to [firmware_fpga/](firmware_fpga/)  
- Compile the project in Quartus (or use provided bitstreams in [releases/](releases/))  
- Load bitstream on Cyclone V GX using Quartus Programmer

### 3. Run PC Application
- Go to [software_pc/](software_pc/)  
- Install dependencies
- Run the software


### Documentation
- Build guide → docs/build_guide/
- User guide → docs/user_guide/user_manual.md
- Validation & tests → docs/validation/
- BOM → docs/publication_assets/tables/bom_master_v1.0.csv


### Citation
If you use this project, please cite the associated HardwareX article and Zenodo DOI:
10.5281/zenodo.17356089

### License
- Hardware → CERN OHL-S v2.0
- Software → GPL-3.0
- Documentation → CC BY-SA 4.0
(see LICENSES/)

---

## Repository Structure
Please see the document : File_list_V1.xlsx 
This document regroups all the documents available in this project as well as their localisation and their status.

