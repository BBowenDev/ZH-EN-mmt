import torch
import torch.nn as nn
from fairseq import utils
from fairseq.modules import (
    AdaptiveSoftmax,
    BaseLayer,
    FairseqDropout,
    LayerNorm,
    PositionalEmbedding
)
from fairseq.modules.quant_noise import quant_noise

class FeatsTransformEmbed(nn.Module):

    @staticmethod
    def add_args(parser):
        """Add model-specific arguments to the parser."""
        # fmt: off
        parser.add_argument(
            "--feats-shape", type=str, default="(2048,)",
            help=("shape of the multimodal features")
            )
        parser.add_argument(
            "--feats-positional-embedding", action='store_true', default=True,
            help=("add sinusoidal positional embedding to feats")
            )
        parser.add_argument(
            "--feats-avgpool", action='store_true', default=False,
            help=("flatten feats to single vector with average pooling")
            )
        parser.add_argument(
            "--feats-transpose", action='store_true', default=True,
            help=("transpose feats if 2-dimensional matrix")
            )
        # fmt: on

    def __init__(self, args):
        super().__init__()
        self.args = args
        self.embed_dim = args.encoder_embed_dim
        self.quant_noise = getattr(args, 'quant_noise_pq', 0)
        self.quant_noise_block_size = getattr(args, 'quant_noise_pq_block_size', 8) or 8
        self.activation_fn = utils.get_activation_fn(
            activation=getattr(args, 'activation_fn', 'relu') or "relu"
        )
        self.dropout_module = FairseqDropout(
            args.dropout, module_name=self.__class__.__name__
        )
        activation_dropout_p = getattr(args, "activation_dropout", 0) or 0
        if activation_dropout_p == 0:
            # for backwards compatibility with models that use args.relu_dropout
            activation_dropout_p = getattr(args, "relu_dropout", 0) or 0
        self.activation_dropout_module = FairseqDropout(
            float(activation_dropout_p), module_name=self.__class__.__name__
        )
        if not args.encoder_normalize_before:
            self.final_layer_norm = LayerNorm(self.embed_dim)
        else:
            self.final_layer_norm = None

        self.do_positional_embedding = args.feats_positional_embedding
        self.do_avgpool = args.feats_avgpool
        self.do_transpose = args.feats_transpose

        if self.do_transpose:
            self.feats_shape = tuple(reversed(eval(args.feats_shape)))
            # e.g. feats_shape is (2048,) or (2048,10) or (1024,14,14)
            # so transpose to (2048,) or (10,2048) or (14,14,1024)
        else:
            self.feats_shape = eval(args.feats_shape)
            # e.g. feats_shape is (2048,) or (10,2048) or (14,14,1024)
        self.feats_dim = len(self.feats_shape)
        self.feats_channels = self.feats_shape[-1]

        if self.feats_dim == 1:
            self.max_regions = 1
        elif self.feats_dim == 2:
            self.max_regions = self.feats_shape[0]
        elif self.feats_dim == 3:
            self.max_regions = self.feats_shape[0] * self.feats_shape[1]
        else:
            raise(Exception("feats-shape must be 3 dimensions or fewer"))
            
        if self.do_positional_embedding:
            self.embed_positions = PositionalEmbedding(
                self.max_regions,
                self.feats_channels,
                padding_idx=0)
        else:
            self.embed_positions = None

        if self.do_avgpool:
            self.avgpool = nn.AdaptiveAvgPool2d((1,1))
        else:
            self.avgpool = None

        self.fc = quant_noise(
            nn.Linear(self.feats_channels, self.embed_dim),
            p=self.quant_noise, block_size=self.quant_noise_block_size
        )

    def forward(self, x):
        if self.feats_dim == 1:
            x = x.reshape((x.shape[0],1,self.feats_channels))
        elif self.feats_dim == 2:
            if self.do_transpose:
                x = x.permute((0,2,1))
            else:
                x = x
        elif self.feats_dim == 3:
            if self.do_transpose:
                x = x.reshape((x.shape[0],self.feats_channels,-1)).permute((0,2,1))
            else:
                x = x.reshape((x.shape[0],-1,self.feats_channels))
        else:
            raise(Exception("feats-shape"))

        if self.embed_positions is not None:
            x += self.embed_positions(torch.ones(x.shape[0], x.shape[1], device=x.device))

        x = self.activation_fn(self.fc(x))
        x = self.activation_dropout_module(x)

        if self.avgpool is not None:
            x = self.avgpool(x)
        else:
            if self.final_layer_norm is not None:
                x = self.final_layer_norm(x)

        return x
