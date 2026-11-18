clc; clearvars; close all;
set(groot, 'DefaultFigureVisible', 'off');
baseline = load('ErrSet.mat');
testRows = find(baseline.SNR_p <= 30);
testSNR = baseline.SNR_p(testRows);

plotComparison(baseline, testRows, testSNR, ...
    ["DNN1_30dB", "DNN2_30dB", "DNN3_30dB", "DNN4_30dB"], ...
    ["DNN1", "DNN2", "DNN3", "DNN4"], ...
    "All DNNs trained at 30 dB", "Fig2_NMSE_Architectures")

plotComparison(baseline, testRows, testSNR, ...
    ["DNN1_0dB", "DNN1_10dB", "DNN1_20dB", "DNN1_30dB", "DNN1_50dB"], ...
    ["DNN1 at 0 dB", "DNN1 at 10 dB", "DNN1 at 20 dB", ...
    "DNN1 at 30 dB", "DNN1 at 50 dB"], ...
    "DNN1 by training SNR", "Fig1_NMSE_Training_SNR")

function plotComparison(baseline, testRows, testSNR, cases, labels, heading, outputName)
    nmse = table(testSNR, baseline.Err_LSth(testRows), ...
        baseline.Err_LSsim(testRows), baseline.Err_MMSEth(testRows), ...
        baseline.Err_MMSEsim(testRows), 'VariableNames', ...
        {'SNR_dB', 'Analytical_LS', 'Simulation_LS', ...
        'Analytical_MMSE', 'Simulation_MMSE'});
    fig = figure('Position', [100 100 850 580], 'Color', 'white');
    theme(fig, "light");
    semilogy(testSNR, nmse.Analytical_LS, 'k--', 'DisplayName', 'Analytical LS');
    hold on
    semilogy(testSNR, nmse.Simulation_LS, 'kx', 'DisplayName', 'Simulated LS');
    semilogy(testSNR, nmse.Analytical_MMSE, 'k:', 'DisplayName', 'Analytical MMSE');
    semilogy(testSNR, nmse.Simulation_MMSE, 'ko', 'DisplayName', 'Simulated MMSE');
    markers = ["-d", "-s", "-^", "-v", "-p"];
    for model = 1:numel(cases)
        [repoError, energyError] = measureCase(cases(model), numel(testSNR));
        semilogy(testSNR, repoError, markers(model), 'LineWidth', 1.5, ...
            'DisplayName', labels(model));
        nmse.(cases(model) + "_repo") = repoError;
        nmse.(cases(model) + "_energy") = energyError;
    end
    grid on
    xlim([testSNR(1), testSNR(end)])
    ylim([1e-6 1.2])
    xticks(testSNR)
    xlabel('Test SNR (dB)')
    ylabel('Normalized mean squared error')
    title(heading)
    legend('Location', 'southwest')
    exportgraphics(fig, outputName + ".png", 'Resolution', 180);
    writetable(nmse, outputName + ".csv");
    close(fig)
end

function [repoError, energyError] = measureCase(caseName, numberOfSNRs)
    repoError = zeros(numberOfSNRs, 1);
    energyError = zeros(numberOfSNRs, 1);
    for i = 1:numberOfSNRs
        predictions = load(fullfile('cases', caseName, "DNN_Results_" + i + ".mat"));
        truth = asComplex(predictions.("test_y_" + i));
        estimate = asComplex(predictions.("corrected_y_" + i));
        residual = truth - estimate;
        % Preserve the authors' default matrix norm for the plotted curves.
        repoError(i) = norm(residual)^2 / norm(truth)^2;
        % Save the ratio of total squared errors to total channel energy as well.
        energyError(i) = norm(residual, 'fro')^2 / norm(truth, 'fro')^2;
    end
end

function channel = asComplex(rows)
    channel = (double(rows(:, 1:52)) + 1i * double(rows(:, 53:104))).';
end
