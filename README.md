# OFDM LS-DNN Reproduction

Step 1 of a Wireless Communications course project reproducing the simulations in *Enhancing Least Square Channel Estimation Using Deep Learning* by Abdul Karim Gizzini, Marwa Chafii, Ahmad Nimr, and Gerhard Fettweis (IEEE VTC2020-Spring). The fork is based on the [authors’ code](https://github.com/abdulkarimgizzini/Enhancing_Least_Square_Channel_Estimation_Using_Deep_Learning) at commit `0e6ebb7`. [Paper on HAL](https://hal.science/hal-02504757v1)

## Results

| Experiment | Files |
| --- | --- |
| Fig. 2. DNN1–DNN4 trained at 30 dB | [PNG](results/Fig2_NMSE_Architectures.png) · [CSV](results/Fig2_NMSE_Architectures.csv) |
| Fig. 1. DNN1 trained at 0, 10, 20, 30 and 50 dB | [PNG](results/Fig1_NMSE_Training_SNR.png) · [CSV](results/Fig1_NMSE_Training_SNR.csv) |

The run used 1,000 channel realizations per SNR and 500 training epochs per model. The reproduced Fig. 2 DNN curves have a higher error floor than the paper’s curves. At 30 dB, DNN2 has the lowest plotted error in this run and DNN4 has the lowest in the paper. The CSVs include the repository’s published-code calculation and DNN error normalized by total channel energy. [Run notes and fixes](results/step1-run-notes.md) · [Verification log](results/verification.log)

## Running the pipeline

The run was verified on Apple silicon with MATLAB R2026a Update 5, Communications Toolbox, and Python 3.12.14. MATLAB Package Manager installed DSP System Toolbox and Signal Processing Toolbox as required dependencies. The Python packages, including TensorFlow and Keras, are pinned in [requirements.txt](requirements.txt).

From the repository root:

```bash
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
bash run_step1.sh
```

Set `WCOM_MATLAB` to the MATLAB executable if it differs from the default macOS path. The script sets `KERAS_BACKEND=tensorflow` and uses `WCOM_MATLAB_CODE` to locate the MATLAB scripts. It regenerates the datasets, checkpoints, predictions, logs, and plots under `results/`, overwriting the saved run outputs. Random training and noise draws can change the numerical results on a rerun.

The execution order is `Main_Simulation` → `Process_Training_Data` → `LS_DNN_Training` → `LS_DNN_Testing` → `DNN_Results_Processing`.
