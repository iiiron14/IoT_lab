# IoT Lab Exercises

This repository contains a collection of MATLAB scripts from a university laboratory course on the Internet of Things (IoT). The exercises cover fundamental concepts in digital signal processing, wireless communications, and real-time data handling using Software-Defined Radio (SDR). The projects progress from basic signal analysis to building a complete real-time receiver and dashboard for wireless environmental sensors.

## Repository Structure

The repository is organized into directories, each corresponding to a specific lab exercise (`Es1` through `Es7`).

-   **/Es1/**: Signal generation and Power Spectral Density (PSD) analysis.
-   **/Es2/**: FIR digital filter design and application.
-   **/es3/**: FM radio demodulation, both offline and in real-time, including a GUI-based audio equalizer.
-   **/Es4/**: Offline demodulation and symbol timing recovery for OOK/ASK digital packets.
-   **/Es5/**: A complete real-time receiver for decoding wireless sensor packets.
-   **/Es6/**: A real-time MATLAB GUI dashboard for visualizing the decoded sensor data.
-   **/Es7/**: A simulation of a multi-tag UWB RFID system.

## Key Concepts & Features

-   **Signal Processing:** Generation of sinusoids, PAM signals, and analysis using FFT and Welch's method (`pwelch`).
-   **Digital Filter Design:** Design and implementation of FIR filters using the Parks-McClellan algorithm (`firpm`) to meet specific frequency-domain requirements.
-   **SDR Integration:** Interfacing with an RTL-SDR dongle to capture and process live radio signals.
-   **FM Demodulation:** Implementation of both offline and real-time FM broadcast receivers.
-   **Digital Communications:**
    -   Non-coherent energy detection for OOK/ASK signals.
    -   Symbol timing recovery using a non-linear method to extract the bit rate clock.
    -   Packet synchronization using Barker code correlation.
    -   Payload extraction and CRC-8 error checking.
-   **Data Visualization:** Creation of dynamic, real-time MATLAB GUIs to plot and display sensor data (Temperature, Humidity, Pressure, and Battery Voltage).
-   **UWB RFID Simulation:** Modeling a multi-tag RFID system using Hadamard codes for orthogonality and Root-Raised Cosine (RRC) pulse shaping.

## Exercise Details

### Es1: Signal Analysis

-   `es1p1_nori_edoardo.m`: Generates a signal composed of two sinusoids plus Additive White Gaussian Noise (AWGN). It then computes and plots the Power Spectral Density (PSD) for different FFT lengths, demonstrating the trade-off between frequency resolution and variance.
-   `es1p2_nori_edoardo.m`: Creates a Pulse Amplitude Modulation (PAM) signal and compares its estimated PSD with the theoretical `sinc^2` shape.

### Es2: FIR Filter Design

-   `es1p2_Nori_Edoardo.m`: Analyzes the frequency response of a simple moving average FIR filter.
-   `es2p2_Nori_Edoardo.m`: Designs a low-pass FIR filter based on a defined mask (pass-band ripple, stop-band attenuation) using `firpmord` and `firpm`. The designed filter is then used to process a provided signal.

### es3: FM Radio Receiver

-   `CaptureSave_IQ_samples.m`: Uses an RTL-SDR to capture a segment of the FM radio band and saves the raw IQ samples to `samplesIQcatturati.mat`.
-   `DemodFMoffline_nori_edoardo.m`: An offline script that loads the captured IQ samples, applies a channel selection filter, performs FM demodulation, isolates the mono (L+R) audio signal, and saves it as a `.wav` file.
-   `FM_RealTime.m`: A real-time FM radio receiver. It continuously captures frames from the RTL-SDR, demodulates them, and plays the audio directly using `soundsc`.
-   `equalizerGUI.m` & `processAudioLab.m`: A functional real-time FM radio receiver with a graphical user interface that acts as a 6-band audio equalizer. Sliders in the GUI control the gain of different frequency bands, which are separated by pre-designed FIR filters loaded from `coeff*.txt` files.

### Es4: Digital Packet Demodulation (Offline)

-   `PacketRX_es4_nori_edoardo.m`: Performs the first stages of receiving a digitally modulated packet from I/Q samples stored in `samplesIQpacket.mat`. The process includes:
    1.  Downsampling the signal.
    2.  Non-coherent demodulation (energy detection) to get the baseband signal envelope `A(nT)`.
    3.  Symbol timing recovery by applying a non-linearity (`A^2`) and band-pass filtering to extract a timing wave at the bit rate.
    4.  Sampling the signal `A` at the correct instants determined by the timing wave.

### Es5: Complete Packet Receiver (Real-time)

-   `Es5PacketRX_RealTime_nori_edoardo.m`: Extends the work from Es4 into a complete, real-time packet decoder running on an RTL-SDR. It adds the remaining crucial steps:
    1.  **Packet Synchronization:** Correlates the decoded bitstream with a flipped Barker-13 sequence to find the start of a packet.
    2.  **Payload Extraction:** Once a packet is detected, it extracts the payload containing sensor data.
    3.  **Data Decoding & CRC Check:** Decodes the sensor ID, measurement types, and values (Temperature, Humidity, Pressure, Battery). It performs a CRC-8 check to validate the integrity of the received payload and prints the decoded data to the console.

### Es6: Real-time Sensor Dashboard

-   `GUI_IOT_RTLSDR_nori_edoardo.m`: A script that creates a MATLAB GUI to provide a real-time dashboard for the received sensor data. It calls `process_frame_nori_edoardo.m` to handle the reception and decoding. The GUI features:
    -   Separate plots for Temperature, Humidity, and Pressione that update over time.
    -   A table displaying the latest battery voltage for each detected sensor ID.
-   `GUI_IOT_RTLSDR_facoltativo.m`: An optional, more advanced version of the GUI with enhanced features like sensor filtering, live statistics, and improved layout.
-   `process_frame_nori_edoardo.m`: Encapsulates the entire receiver logic from Es5 into a single function, making it modular for use with the GUI.

### Es7: UWB RFID Simulation

-   `RFID_template.m`: A complete simulation of an Ultra-Wideband (UWB) Radio-Frequency Identification (RFID) system. The simulation demonstrates:
    -   Assigning orthogonal Hadamard codes to different tags to enable multi-tag identification.
    -   Spreading the tag's data bits with its unique code.
    -   Generating a Root-Raised Cosine (RRC) transmit pulse.
    -   Modeling the backscattered signal from multiple tags, including channel attenuation.
    -   Simulating a receiver that uses a matched filter (matched to the RRC pulse) and a correlator (to despread the signal) to recover the data from each tag.

## Getting Started

### Prerequisites

-   MATLAB
-   MATLAB Communications Toolbox
-   MATLAB Signal Processing Toolbox
-   RTL-SDR Support Package for MATLAB (for exercises involving the RTL-SDR dongle)

### Hardware

-   An RTL-SDR dongle is required for the real-time exercises in `es3`, `Es5`.
-   `Es6` is based on a proprietary sensor developed in our university, therefore it can not be done unless another sensor with the same communication protocol is used. 

### Usage

1.  Clone the repository.
2.  Navigate to the desired exercise directory (e.g., `cd Es5`).
3.  Open the main MATLAB script for that exercise (e.g., `Es5PacketRX_RealTime_nori_edoardo.m`).
4.  Run the script. For real-time exercises, ensure your RTL-SDR is connected and the antenna is suited for the 433 MHz ISM band.
