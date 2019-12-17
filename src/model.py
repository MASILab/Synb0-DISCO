import torch
import torch.nn as nn


class UNet3D(nn.Module):
    def __init__(self, n_in, n_out):
        super(UNet3D, self).__init__()
        # Encoder
        self.ec0 = self.encoder_block(      n_in,    32, kernel_size=3, stride=1, padding=1)
        self.ec1 = self.encoder_block(        32,    64, kernel_size=3, stride=1, padding=1)
        self.pool0 = nn.MaxPool3d(2)
        self.ec2 = self.encoder_block(        64,    64, kernel_size=3, stride=1, padding=1)
        self.ec3 = self.encoder_block(        64,   128, kernel_size=3, stride=1, padding=1)
        self.pool1 = nn.MaxPool3d(2)
        self.ec4 = self.encoder_block(       128,   128, kernel_size=3, stride=1, padding=1)
        self.ec5 = self.encoder_block(       128,   256, kernel_size=3, stride=1, padding=1)
        self.pool2 = nn.MaxPool3d(2)
        self.ec6 = self.encoder_block(       256,   256, kernel_size=3, stride=1, padding=1)
        self.ec7 = self.encoder_block(       256,   512, kernel_size=3, stride=1, padding=1)
        self.el  =          nn.Conv3d(       512,   512, kernel_size=1, stride=1, padding=0)

        # Decoder
        self.dc9 = self.decoder_block(       512,   512, kernel_size=2, stride=2, padding=0)
        self.dc8 = self.decoder_block( 512 + 256,   256, kernel_size=3, stride=1, padding=1)
        self.dc7 = self.decoder_block(       256,   256, kernel_size=3, stride=1, padding=1)
        self.dc6 = self.decoder_block(       256,   256, kernel_size=2, stride=2, padding=0)
        self.dc5 = self.decoder_block( 256 + 128,   128, kernel_size=3, stride=1, padding=1)
        self.dc4 = self.decoder_block(       128,   128, kernel_size=3, stride=1, padding=1)
        self.dc3 = self.decoder_block(       128,   128, kernel_size=2, stride=2, padding=0)
        self.dc2 = self.decoder_block(  128 + 64,    64, kernel_size=3, stride=1, padding=1)
        self.dc1 = self.decoder_block(        64,    64, kernel_size=3, stride=1, padding=1)
        self.dc0 = self.decoder_block(        64, n_out, kernel_size=1, stride=1, padding=0)
        self.dl  = nn.ConvTranspose3d(     n_out, n_out, kernel_size=1, stride=1, padding=0)

    def encoder_block(self, in_channels, out_channels, kernel_size, stride, padding):
        layer = nn.Sequential(
            nn.Conv3d(in_channels, out_channels, kernel_size, stride=stride, padding=padding, bias=False),
            nn.InstanceNorm3d(out_channels),
            nn.LeakyReLU())
        return layer

    def decoder_block(self, in_channels, out_channels, kernel_size, stride, padding):
        layer = nn.Sequential(
            nn.ConvTranspose3d(in_channels, out_channels, kernel_size, stride=stride, padding=padding, bias=False),
            nn.InstanceNorm3d(out_channels),
            nn.LeakyReLU())
        return layer

    def forward(self, x):
        # Encode
        e0   = self.ec0(x)
        syn0 = self.ec1(e0)
        del e0

        e1   = self.pool0(syn0)
        e2   = self.ec2(e1)
        syn1 = self.ec3(e2)
        del e1, e2

        e3   = self.pool1(syn1)
        e4   = self.ec4(e3)
        syn2 = self.ec5(e4)
        del e3, e4

        e5   = self.pool2(syn2)
        e6   = self.ec6(e5)
        e7   = self.ec7(e6)

        # Last layer without relu
        el   = self.el(e7)
        del e5, e6, e7

        # Decode
        d9   = torch.cat((self.dc9(el), syn2), 1)
        del el, syn2

        d8   = self.dc8(d9)
        d7   = self.dc7(d8)
        del d9, d8

        d6   = torch.cat((self.dc6(d7), syn1), 1)
        del d7, syn1

        d5   = self.dc5(d6)
        d4   = self.dc4(d5)
        del d6, d5

        d3   = torch.cat((self.dc3(d4), syn0), 1)
        del d4, syn0

        d2   = self.dc2(d3)
        d1   = self.dc1(d2)
        del d3, d2

        d0   = self.dc0(d1)
        del d1

        # Last layer without relu
        out  = self.dl(d0)

        return out