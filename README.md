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
[to be inserted]

### License
- Hardware → CERN OHL-S v2.0
- Software → GPL-3.0
- Documentation → CC BY-SA 4.0
(see LICENSES/)

---

## Repository Structure
octavie/
├─ README.md
├─ LICENSES/
├─ CITATION.cff
├─ CODE_OF_CONDUCT.md
├─ CONTRIBUTING.md
├─ CODEOWNERS
├─ docs/
├─ hardware/
├─ firmware_fpga/
├─ software_pc/
├─ data/
├─ tests/
└─ .zenodo.json


### docs/
├─ overview/
│  ├─ project_summary.md
│  └─ system_architecture.md   (high-level block diagrams)
├─ build_guide/
│  ├─ pcb_assembly.md 
│  ├─ mechanical_assembly.md
│  ├─ fpga_programming.md
│  └─ pc_software_installation.md
├─ user_guide/
│  └─ user manual.md
├─ publication_assets/
│  ├─ bom_master_v1.0.csv/ 
│  ├─ ...
│  └─ list_files.md
└─ divers/
   ├─ ...
   └─ version_guide.md


### hardware/
├─ microphone/
│  ├─ v1.0/
│  │  ├─ electronics/
│  │  │  ├─ pcb_design/              (ECAD sources + libraries)
│  │  │  └─ fabrication/             (pcb/: Gerbers, drill, stackup.pdf ; assembly/: BOM, PnP, panel notes)
│  │  ├─ enclosure/
│  │  │  ├─ cad/                     (FreeCAD sources + STEP/STL)
│  │  │  └─ drawings/                (PDF drawings, tolerances)
│  │  ├─ assembly/
│  │  │  ├─ work_instructions.md     (steps, tools, ESD)
│  │  │  └─ wiring.md                (pinouts, harness if needed)
│  │  ├─ bom/
│  │  │  └─ bom_microphone_v1.0.csv
│  │  └─ README.md
│  └─ v1.1/ …
│
├─ acquisition_unit/
│  ├─ v1.0/
│  │  ├─ electronics/
│  │  │  ├─ analog_signal_board/
│  │  │  │  ├─ pcb_design/
│  │  │  │  └─ fabrication/          (pcb/, assembly/)
│  │  │  └─ fpga_devkit/             (notes if off-the-shelf; or pcb_design/ if custom carrier)
│  │  ├─ enclosure/
│  │  │  ├─ cad/
│  │  │  └─ drawings/
│  │  ├─ assembly/
│  │  │  ├─ work_instructions.md
│  │  │  └─ wiring.md
│  │  ├─ bom/
│  │  │  └─ bom_acquisition_unit_v1.0.csv
│  │  └─ README.md
│  └─ v1.1/ …
│
└─ system_integration/
   ├─ v1.0/
   │  ├─ final_assembly.md           (how to connect mic ↔ acquisition unit, 2 cables)
   │  └─ README.md

### firmware_fpga/
├─ vhdl/
│  ├─ src/
│  │  ├─ top_octavie_fft.vhd
│  │  ├─ adc_interface.vhd
│  │  ├─ windowing.vhd
│  │  ├─ fft_core_wrapper.vhd
│  │  └─ uart_streamer.vhd
│  ├─ tb/                     (testbenches)
│  └─ ip/                     (vendor IP metadata; no binaries)
├─ builds/
│  ├─ quartus_project_v1.0/
│  │  ├─ constraints/         (.sdc, pin assignments)
│  │  └─ bitstreams/          
├─ docs/
│  ├─ register_map.md
│  └─ data_interface.md
└─ README.md


### software_pc/
├─ app/
│  ├─ src/                    (C/C++ or Python package)
│  ├─ cli/                    (command-line tools)
│  ├─ gui/                    (if applicable)
│  ├─ requirements.txt or pyproject.toml
│  ├─ setup.cfg / setup.py
│  └─ README.md
├─ drivers/                   (USB/UART instructions, links)
├─ packaging/                 (conda/pip wheels, installers specs)
├─ docs/                      (API docs, usage examples)
└─ tests/                     (unit/integration tests)


### data/
├─ example_outputs/
│  ├─ fft_spectrum_bat_call.csv
│  └─ spectrogram_bat_call.png
└─ results/
   ├─ microphone_sensitivity_v1.0.csv
   └─ adc_noise_floor_v1.0.csv


### tests/
├─ procedures/
│  ├─ acoustic_bandwidth_test.md
│  ├─ noise_floor_test.md
│  └─ emi_precheck.md
├─ fixtures/                  (test jigs drawings)
└─ results/
   ├─ 2025-08-22_bandwidth_v1.0.md
   └─ raw/ (CSV logs; small samples)


