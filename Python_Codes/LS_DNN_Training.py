from argparse import ArgumentParser
from pathlib import Path

from keras import Input, Sequential
from keras.callbacks import ModelCheckpoint
from keras.initializers import TruncatedNormal
from keras.layers import Dense
from scipy.io import loadmat
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler


HIDDEN_LAYERS = {
    1: (52,),
    2: (104,),
    3: (52, 52),
    4: (104, 104),
}

parser = ArgumentParser()
parser.add_argument('--architecture', type=int, choices=HIDDEN_LAYERS, default=4)
parser.add_argument('--snr-index', type=int, choices=range(1, 9), default=7)
parser.add_argument('--data-dir', type=Path, default=Path('.'))
args = parser.parse_args()
snr = args.snr_index

# Keep the authors' preprocessing, split and checkpoint criterion.
mat = loadmat(args.data_dir / f'DNN_Dataset_{snr}.mat')
dataset = mat['Preamble_Error_Correction_Dataset'][0, 0]
X = dataset['X']
Y = dataset['Y']
print('Loaded dataset inputs and outputs:', X.shape, Y.shape)

XS = StandardScaler().fit_transform(X)
YS = StandardScaler().fit_transform(Y)
train_X, test_X, train_Y, test_Y = train_test_split(
    XS, YS, test_size=0.2, random_state=7
)
print('Rows before validation split:', train_X.shape[0])
print('Test rows:', test_X.shape[0])


def dense(units, activation=None):
    return Dense(
        units,
        activation=activation,
        kernel_initializer=TruncatedNormal(mean=0.0, stddev=0.05),
        bias_initializer=TruncatedNormal(mean=0.0, stddev=0.05),
    )


model = Sequential([
    Input(shape=(104,)),
    *(dense(width, 'relu') for width in HIDDEN_LAYERS[args.architecture]),
    dense(104),
])
model.compile(loss='mean_squared_error', optimizer='adam', metrics=['acc'])
model.summary()
print('Adam learning rate:', float(model.optimizer.learning_rate.numpy()))

checkpoint = ModelCheckpoint(
    f'LS_DNN_{snr}.keras', monitor='val_acc', verbose=1, save_best_only=True,
    mode='max',
)
model.fit(
    train_X, train_Y, epochs=500, batch_size=32, verbose=2,
    validation_split=0.25, callbacks=[checkpoint],
)
