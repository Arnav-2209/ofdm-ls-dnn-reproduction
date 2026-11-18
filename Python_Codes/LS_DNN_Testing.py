from argparse import ArgumentParser
from pathlib import Path

from keras.models import load_model
from scipy.io import loadmat, savemat
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler


parser = ArgumentParser()
parser.add_argument('--snr-index', type=int, choices=range(1, 9), default=7)
parser.add_argument('--data-dir', type=Path, default=Path('.'))
args = parser.parse_args()
model = load_model(f'LS_DNN_{args.snr_index}.keras', compile=False)

# Evaluate on the same seven SNRs and splits as the authors' code.
for j in range(1, 8):
    mat = loadmat(args.data_dir / f'DNN_Dataset_{j}.mat')
    dataset = mat['Preamble_Error_Correction_Dataset'][0, 0]
    X = dataset['X']
    Y = dataset['Y']

    scalerx = StandardScaler().fit(X)
    scalery = StandardScaler().fit(Y)
    XS = scalerx.transform(X)
    YS = scalery.transform(Y)
    _, test_X, _, test_Y = train_test_split(XS, YS, test_size=0.2, random_state=7)
    print(f'Dataset index {j}: {test_X.shape[0]} test rows')

    Y_pred = model.predict(test_X, verbose=0)
    savemat(f'DNN_Results_{j}.mat', {
        f'test_x_{j}': scalerx.inverse_transform(test_X),
        f'test_y_{j}': scalery.inverse_transform(test_Y),
        f'corrected_y_{j}': scalery.inverse_transform(Y_pred),
    })
