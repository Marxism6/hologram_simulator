%% 全息图生成函数
% 计算干涉图和相位型全息图
% 干涉图：I = |物光 + 参考光|^2
% 相位型全息图：arg(物光 + 参考光)
%
% 输入：
%   object_field_at_holo: 物光场复振幅 (2D矩阵)
%   ref_field: 参考光场复振幅 (2D矩阵)
%   add_noise: 是否添加噪声 (布尔值)
%   SNR_dB: 信噪比 (dB)
%
% 输出：
%   hologram_intensity: 干涉图强度 (2D矩阵，0-1或0-255)
%   hologram_phase: 相位型全息图 (2D矩阵)

function [hologram_intensity, hologram_phase] = generate_hologram(...
    object_field_at_holo, ref_field, add_noise, SNR_dB)

    % 合成干涉场
    combined_field = object_field_at_holo + ref_field;
    
    % 干涉强度 I = |U_object + U_ref|^2
    hologram_intensity = abs(combined_field).^2;
    
    % 相位信息 arg(U_object + U_ref)
    hologram_phase = angle(combined_field);
    
    % 【噪声处理】
    if add_noise
        % 计算信号功率
        signal_power = mean(hologram_intensity(:));
        
        % 根据信噪比计算噪声功率
        SNR_linear = 10^(SNR_dB/10);
        noise_power = signal_power / SNR_linear;
        
        % 生成零均值高斯白噪声（方差 = noise_power）并加入
        noise = sqrt(noise_power) * randn(size(hologram_intensity));
        hologram_intensity = hologram_intensity + noise;
        % 数值安全：裁剪负值
        hologram_intensity = max(0, hologram_intensity);
    end
    
    % 【强度规范化】到 [0, 1]
    I_max = max(hologram_intensity(:));
    I_min = min(hologram_intensity(:));
    
    if I_max > I_min
        hologram_intensity = (hologram_intensity - I_min) / (I_max - I_min);
    else
        hologram_intensity = zeros(size(hologram_intensity));
    end
    
    % 确保相位在 [-π, π]
    hologram_phase = mod(hologram_phase + pi, 2*pi) - pi;

end
