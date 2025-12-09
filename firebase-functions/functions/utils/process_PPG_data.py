# apply the moving average and other filters here

# Preprocessing method based on this paper:
# S. Heo, S. Kwon and J. Lee, "Stress Detection With Single PPG Sensor by Orchestrating Multiple Denoising and Peak-Detecting Methods," 
# in IEEE Access, vol. 9, pp. 47777-47785, 2021, doi: 10.1109/ACCESS.2021.3060441.
# Adapted July 16th 2024 by Justin Laiti and ChatGPT

import numpy as np
import scipy.signal as signal
from scipy.stats import kurtosis, skew

#%% Filters ##

# Define band-pass filter function
def bandpass_filter(data, lowcut, highcut, fs, order=2):
    nyquist = 0.5 * fs
    low = lowcut / nyquist
    high = highcut / nyquist
    b, a = signal.butter(order, [low, high], btype='band')
    y = signal.filtfilt(b, a, data)
    return y

# Define the moving average filter function
def moving_average_filter(data, window_size=3):
    return np.convolve(data, np.ones(window_size)/window_size, mode='same')

# Define the statistical noise elimination function
def eliminate_noise_in_time(data, fs, std_ths, kurt_ths, skew_ths, cycle=1):
    def pair_valley(valley):
        pair_valley = []
        for i in range(len(valley) - 1):
            pair_valley.append([valley[i], valley[i + 1]])
        return pair_valley

    def valley_detection(dataset, fs):
        window = []
        valleylist = []
        listpos = 0
        localaverage = np.average(dataset)
        for datapoint in dataset:
            if (datapoint > localaverage) and (len(window) < 1):
                listpos += 1
            elif (datapoint <= localaverage):
                window.append(datapoint)
                listpos += 1
            else:
                minimum = min(window)
                beatposition = listpos - len(window) + (window.index(min(window)))
                valleylist.append(beatposition)
                window = []
                listpos += 1
        return valleylist

    def statistic_detection(signal, fs):
        valley = pair_valley(valley_detection(signal, fs))
        stds, kurtosiss, skews = [], [], []
        for val in valley:
            stds.append(np.std(signal[val[0]:val[1]]))
            kurtosiss.append(kurtosis(signal[val[0]:val[1]]))
            skews.append(skew(signal[val[0]:val[1]]))
        return stds, kurtosiss, skews, valley

    stds, kurtosiss, skews, valley = statistic_detection(data, fs)
    std_ths_val = np.mean(stds) + std_ths
    kurt_ths_val = np.mean(kurtosiss) + kurt_ths
    skew_ths_val = [np.mean(skews) - skew_ths[0], np.mean(skews) + skew_ths[1]]

    eli_std = [i for i, x in enumerate(stds) if x < std_ths_val]
    eli_kurt = [i for i, x in enumerate(kurtosiss) if x < kurt_ths_val]
    eli_skew = [i for i, x in enumerate(skews) if skew_ths_val[0] < x < skew_ths_val[1]]

    total_list = eli_std + eli_kurt + eli_skew
    dic = {i: total_list.count(i) for i in set(total_list)}

    clean_segments = [i for i, x in dic.items() if x >= 3]
    clean_data = [data[valley[i * cycle][0]:valley[i * cycle + cycle - 1][1]] for i in clean_segments]

    return np.concatenate(clean_data)