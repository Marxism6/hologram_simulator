% 角谱衍射辅助函数集
% 包含各种衍射和传播的工具函数

%% FFT基础的角谱衍射（可选高级模块）
function field_out = angular_spectrum_fft(...
    field_in, distance, lambda, dx)
    
    % 基于FFT的角谱衍射（更高效）
    % field_in: 输入光场 (2D)
    % distance: 传播距离
    % lambda: 波长
    % dx: 采样间隔
    
    k = 2*pi/lambda;
    [Ny, Nx] = size(field_in);
    
    % 频率域坐标
    fx = ifftshift((-Nx/2:Nx/2-1)/(Nx*dx));
    fy = ifftshift((-Ny/2:Ny/2-1)/(Ny*dx));
    [FX, FY] = meshgrid(fx, fy);
    
    % 垂直分量
    kz = sqrt(k^2 - (2*pi*FX).^2 - (2*pi*FY).^2);
    kz(k^2 < (2*pi*FX).^2 + (2*pi*FY).^2) = 0;  % 抑制衰减波
    
    % 传播项
    H = exp(1i * kz * distance);
    
    % 角谱衍射
    F_in = fftshift(fft2(ifftshift(field_in)));
    F_out = F_in .* H;
    field_out = fftshift(ifft2(ifftshift(F_out)));
    
end

%% FFT 频率向量辅助函数
function f = fftfreq(N, d)
    % 返回长度为N、采样间隔为d的频率坐标 (cycles per unit)
    % 与 numpy.fft.fftfreq 行为类似，但方便与 ifftshift/fftshift 配合使用
    if mod(N,2) == 0
        f = (-N/2:N/2-1) / (N * d);
    else
        f = (-(N-1)/2:(N-1)/2) / (N * d);
    end
end

%% Fresnel衍射核函数
function h = fresnel_kernel(x, y, z, lambda)
    % 计算Fresnel衍射核（impulse response）
    % h(x,y) = exp(i*pi*(x^2+y^2)/(lambda*z)) / (i*lambda*z)
    
    k = 2*pi/lambda;
    r_sq = x.^2 + y.^2;
    
    h = exp(1i * k * r_sq / (2*z)) / (1i * lambda * z);
    
end

%% 参考光生成（多种类型）
function [ref_field, ref_type] = generate_reference_wave(...
    ref_type, theta, phi, lambda, x_holo, y_holo)
    
    % ref_type: 'plane' (平面波), 'spherical' (球面波), 'gaussian' (高斯光束)
    
    k = 2*pi/lambda;
    [X, Y] = ndgrid(x_holo, y_holo);
    
    switch ref_type
        case 'plane'
            % 平面波
            kx = k * sin(phi) * cos(theta);
            ky = k * sin(phi) * sin(theta);
            ref_field = exp(1i * (kx * X + ky * Y));
            
        case 'spherical'
            % 球面波（来自点源）
            source_z = 200e-3;  % 点源距离
            r = sqrt(X.^2 + Y.^2 + source_z^2);
            ref_field = exp(1i * k * r) ./ r;
            
        case 'gaussian'
            % 高斯光束
            w0 = 5e-3;  % 光束腰径
            r = sqrt(X.^2 + Y.^2);
            ref_field = exp(-r.^2 / w0^2) .* exp(1i * k * r.^2 / (2 * 200e-3));
            
        otherwise
            error('Unknown reference type: %s', ref_type);
    end
    
    % 规范化
    ref_field = ref_field / max(abs(ref_field(:)));
    
end

%% 零级衍射和共轭像滤波
function filtered_field = remove_DC_and_conjugate(...
    field, lambda, x_holo, y_holo, theta_ref, phi_ref)
    
    % 使用频域滤波去除零级衍射和共轭像
    
    k = 2*pi/lambda;
    [X, Y] = ndgrid(x_holo, y_holo);
    
    % 零级衍射位置（在频域原点）
    % 共轭像位置（相对于参考光）
    
    % 高斯带通滤波器
    dx = x_holo(2) - x_holo(1);
    dy = y_holo(2) - y_holo(1);

    fx = fftfreq(length(x_holo), dx);
    fy = fftfreq(length(y_holo), dy);
    [FX_tmp, FY_tmp] = meshgrid(fx, fy);
    % 将频率网格对齐到 FFT 输出（fftshift 对应 fftshift 的频率布局）
    FX = fftshift(FX_tmp);
    FY = fftshift(FY_tmp);

    % 自适应截止频率（cycles per unit），基于采样率，避免硬编码
    nyquist = 1 / (2 * min(dx, dy));
    cutoff_freq = 0.1 * nyquist;  % 默认取 Nyquist 的10%
    H = 1 - exp(-(FX.^2 + FY.^2) / (2 * cutoff_freq^2));  % 高通
    
    % 应用滤波
    F = fftshift(fft2(ifftshift(field)));
    F_filtered = F .* H;
    filtered_field = fftshift(ifft2(ifftshift(F_filtered)));
    
end

%% 相位恢复（从强度到复振幅）
function complex_field = phase_recovery_gerchberg_saxton(...
    intensity, num_iterations, distance, lambda, dx)
    
    % Gerchberg-Saxton算法迭代相位恢复
    % 输入：强度分布
    % 输出：恢复的复振幅
    
    % 初始化：使用随机相位
    phase = 2*pi*rand(size(intensity));
    complex_field = sqrt(intensity) .* exp(1i * phase);
    
    k = 2*pi/lambda;
    
    % 允许可选的采样间隔参数（向后兼容）
    if nargin < 5 || isempty(dx)
        dx = 1; % 默认单位采样间隔
    end

    for iter = 1:num_iterations
        % 前向传播
        field_prop = propagate_field(complex_field, distance, lambda, dx);
        
        % 应用强度约束
        amp_prop = abs(field_prop);
        amp_prop = max(amp_prop, 1e-10);  % 避免0
        intensity_measured = sqrt(intensity);  % 从原始强度回到物面
        
        % 修正幅度，保留相位
        phase_prop = angle(field_prop);
        field_modified = intensity_measured .* exp(1i * phase_prop);
        
        % 逆向传播
        complex_field = propagate_field(field_modified, -distance, lambda, dx);
        
        % 应用物面强度约束
        complex_field = sqrt(intensity) .* exp(1i * angle(complex_field));
        
    end
    
end

%% 光场传播核心函数
function field_prop = propagate_field(field_in, distance, lambda, dx)
    
    if distance == 0
        field_prop = field_in;
        return;
    end
    
    % 简化的Fresnel传播
    [ny, nx] = size(field_in);
    % 允许可选的采样间隔参数（向后兼容）
    if nargin < 4 || isempty(dx)
        dx = 1; % 默认单位采样间隔
    end

    k = 2*pi/lambda;

    % 频率域（使用物理频率，单位 cycles per unit）
    fx = fftfreq(nx, dx);
    fy = fftfreq(ny, dx);
    [FX, FY] = meshgrid(fx, fy);

    % Fresnel传播函数（频域表示）
    % H = exp(1i * pi * lambda * distance * (FX.^2 + FY.^2));
    H = exp(1i * pi * lambda * distance .* (FX.^2 + FY.^2));

    % FFT，乘以传播函数，IFFT（使用一致的 shift 顺序）
    F_in = fftshift(fft2(ifftshift(field_in)));
    F_out = F_in .* H;
    field_prop = fftshift(ifft2(ifftshift(F_out)));
    
end
