# Step 1 run notes

- Upstream commit `0e6ebb70c02ab72bdc74952aefd918867f425170`. The Desktop project separates the original clone, working code, results and paper.
- MATLAB R2026a Update 5 on Apple silicon. GNU Octave was not found on PATH or in Applications. The system Apple Python reported 3.9.6. The working environment uses bundled arm64 Python 3.12.14 and the versions pinned in `requirements.txt`, including TensorFlow 2.21.0, Keras 3.15.1, SciPy 1.18.1 and scikit-learn 1.9.1.

## Problems and fixes

| Problem | Action |
| --- | --- |
| The sandbox blocked GitHub DNS and MATLAB's per-user directory creation | Retried the clone and MATLAB with execution approval. |
| `Unable to resolve the name 'comm.RayleighChannel'` | Installed the licensed Communications Toolbox using MathWorks Package Manager. It also installed required DSP System Toolbox and Signal Processing Toolbox. See `matlab-original.log` and `matlab-toolbox-install.log`. |
| `Changing the complexity (from real to complex) on input 1 of System object comm.RayleighChannel is not allowed` | In `ApplyChannel`, pass both the impulse and waveform as complex arrays, including the real dummy waveform used for covariance estimation. Their values and the channel reset remain the same. Preallocating a complex impulse still failed when MATLAB extracted a column with zero imaginary part. Casting at the call resolved it. See `matlab-original-retry.log` and `matlab-complex-allocation-attempt.log`. |
| `ModuleNotFoundError: No module named 'keras.initializers.initializers_v1'` | Use Keras's public `TruncatedNormal` API and an explicit input layer. Keep the same mean and standard deviation and create one initializer per tensor so modern Keras does not reuse identical draws for equal-shaped tensors. Save checkpoints in native `.keras` format and load for prediction with `compile=False`. See `python-training-original.log` and `python-install.log`. |
| The released scripts select only DNN4 at 30 dB and write each model's predictions to the same filenames | Parameterize the four Table I architectures and training SNR index. Give each model a results directory with its checkpoint, predictions and logs. Load each checkpoint once and write the same MATLAB arrays directly. |
| The released generator stops at 30 dB and the plotter reads only one DNN | Append 50 dB as the eighth dataset and use it for training only. Keep the seven test SNRs from 0 to 30 dB. Plot the two requested sets of curves and save PNG and CSV files. |

## Experimental protocol

The run preserves the authors' single OFDM preamble, 64 subcarriers with 52 active, 12-path RTV profile from Table II, static fading within a realization, and 1,000 realizations per SNR. The fixed split gives 600 optimization, 200 validation and 200 test rows per SNR. Hidden layers use ReLU and the 104-unit regression output is linear. Training uses MSE, Adam at 0.001, batch size 32 and 500 epochs for every model. The checkpoint criterion remains the authors' highest validation accuracy. With Keras's `acc` alias and 104 outputs, this is an argmax agreement, so it does not measure channel-estimation error directly. The paper mentions both training and validation accuracy. The code monitors validation accuracy alone. Training weight and noise draws were not assigned new fixed seeds.

The script retains one complex noise draw per realization, broadcast across the frequency bins. This gives perfectly correlated frequency-domain noise, unlike the white-noise model in the paper. The MMSE filter still uses the white-noise formula. The script also fits input and target scalers on all rows at each SNR, including held-out rows, and uses the test dataset's target scaler for inverse scaling. At 0 dB the MMSE covariance uses the same channel seeds as the simulation. These are properties of the authors' implementation.

The plots preserve the repository's DNN metric, which compares the largest singular values of the error and channel matrices after squaring. The baselines still use total channel/error energy over all 1,000 realizations. CSV columns ending in `_energy` give the ratio of total squared DNN error to total target energy over the 200 test rows. Columns ending in `_repo` are the values plotted.

Rerun from Terminal with `bash run_step1.sh`. This regenerates the pipeline outputs and trains new models. The eight case-specific training and testing logs are under `results/cases/`.

## Reproduced results

- Fig. 2 shows the four 30 dB models below simulated LS throughout and below simulated MMSE for all four models from 10 through 25 dB. At a 30 dB test SNR, repository NMSE is 3.74e-5 (DNN1), 2.87e-5 (DNN2), 4.13e-5 (DNN3) and 1.32e-4 (DNN4). Simulated MMSE is 1.06e-4. The paper's DNNs are approximately 2e-6 to 6e-6 there and DNN4 is lowest.
- Fig. 1 shows dips when testing at the 0, 10 or 20 dB training SNR. The 30 dB-trained model beats the 50 dB-trained model at every tested point in this run. Their plotted NMSEs at 30 dB are 3.74e-5 and 2.63e-4, respectively. The paper shows these curves much closer together.
- The differences in noise, normalization and checkpoint procedure limit comparison with the paper. The release provides no original checkpoints or exact random states with which to isolate the source of the gap. The run was kept at the specified data size and epoch count.
