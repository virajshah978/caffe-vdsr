close all;
clear all;

run matconvnet/matlab/vl_setupnn;

addpath('utils')

% the performance of 'VDSR_Official' model is better than 'VDSR_170000'
% and it fit different scales, 'VDSR_170000' need cascade to generate 
% good results when factor is 3 and 4
load('VDSR_Official.mat');
use_cascade = 0;

% load('VDSR_170000.mat');
% use_cascade = 1;

use_gpu = 0;
up_scale = 3;
shave = 1;

im_gt = imread('./Data/Set5/butterfly_GT.bmp');

if use_gpu
    for i = 1:20
        model.weight{i} = gpuArray(model.weight{i});
        model.bias{i} = gpuArray(model.bias{i});
    end
end

im_gt = modcrop(im_gt,up_scale);
im_l = imresize(im_gt,1/up_scale,'bicubic');
im_gt = double(im_gt);
im_l  = double(im_l) / 255.0;

[H,W,C] = size(im_l);
if C == 3
    im_l_ycbcr = rgb2ycbcr(im_l);
else
    im_l_ycbcr = zeros(H,W,C);
    im_l_ycbcr(:,:,1) = im_l;
    im_l_ycbcr(:,:,2) = im_l;
    im_l_ycbcr(:,:,3) = im_l;
end
im_l_y = im_l_ycbcr(:,:,1);
if use_gpu
    im_l_y = gpuArray(im_l_y);
end
tic;
im_h_y = VDSR_Matconvnet(im_l_y, model,up_scale,use_cascade);
toc;
if use_gpu
    im_h_y = gather(im_h_y);
end
im_h_y = im_h_y * 255;
im_h_ycbcr = imresize(im_l_ycbcr,up_scale,'bicubic');
im_b = ycbcr2rgb(im_h_ycbcr) * 255.0;
im_h_ycbcr(:,:,1) = im_h_y / 255.0;
im_h  = ycbcr2rgb(im_h_ycbcr) * 255.0;

figure;imshow(uint8(im_b));title('Bicubic Interpolation');
figure;imshow(uint8(im_h));title('SR Reconstruction');
figure;imshow(uint8(im_gt));title('Origin');

if shave == 1;
    shave_border = round(up_scale);
else
    shave_border = 0;
end

sr_psnr = compute_psnr(im_h,im_gt,shave_border);
bi_psnr = compute_psnr(im_b,im_gt,shave_border);
fprintf('sr_psnr: %f dB\n',sr_psnr);
fprintf('bi_psnr: %f dB\n',bi_psnr);
