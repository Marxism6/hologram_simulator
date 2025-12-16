%% 全息再现函数
% 逆角谱衍射，重构物体空间的光场分布
%
% 输入：
%   hologram_intensity: 干涉图强度 (2D矩阵)
%   recon_field: 再现光场复振幅 (2D矩阵)
%   lambda: 波长 (m)
%   distance: 再现距离 (m)
%   pixel_num: 采样像素数
%   holo_size: 全息面大小 (m)
%
% 输出：
%   recon_intensity: 再现像强度分布 (2D矩阵)
%   recon_coords: 三维重建坐标 (结构体)

function [recon_intensity, recon_coords] = reconstruct_hologram(...
    hologram_intensity, recon_field, lambda, ...
    distance, pixel_num, holo_size)

    k = 2*pi/lambda;
    pixel_size = holo_size / pixel_num;
    
    % 全息面坐标
    x_holo = linspace(-holo_size/2, holo_size/2, pixel_num);
    y_holo = linspace(-holo_size/2, holo_size/2, pixel_num);
    [X_holo, Y_holo] = ndgrid(x_holo, y_holo);
    
    % ===== 将全息图强度转换为复振幅 =====
    % 实际上，我们需要全息图的相位信息来恢复完整的复振幅
    % 这里使用一个简化方法：假设全息图的强度信息足以重建
    % 更精确的方法需要存储或恢复相位信息
    
    % 初始化再现复振幅
    hologram_complex = sqrt(hologram_intensity) .* recon_field;
    
    % ===== 逆向传播 (Fresnel衍射逆向) =====
    % 通过Fresnel衍射公式反向传播
    
    % 再现物体平面坐标
    x_obj = x_holo;
    y_obj = y_holo;
    [X_obj, Y_obj] = ndgrid(x_obj, y_obj);
    
    % 初始化再现场（兼容所有 MATLAB 版本）
    recon_field_obj = complex(zeros(pixel_num, pixel_num));
    
    % 对全息面上的每个点，计算其到物体平面各点的衍射贡献
    for i = 1:pixel_num
        for j = 1:pixel_num
            % 全息面上的点
            xh = X_holo(i, j);
            yh = Y_holo(i, j);
            
            % 到物体平面各点的距离
            dx = X_obj - xh;
            dy = Y_obj - yh;
            rho_sq = dx.^2 + dy.^2;
            
            % Fresnel相位
            fresnel_phase = exp(1i * k * rho_sq / (2 * distance));
            
            % 传播系数
            propagation_coeff = exp(1i * k * distance) / (1i * lambda * distance);
            
            % 该全息面点对物体平面的贡献
            contribution = hologram_complex(i, j) * propagation_coeff * fresnel_phase;
            
            recon_field_obj = recon_field_obj + contribution;
        end
    end
    
    % 再现强度
    recon_intensity = abs(recon_field_obj).^2;
    
    % 规范化（安全检查避免除以零）
    mx = max(recon_intensity(:));
    if mx > 0
        recon_intensity = recon_intensity / mx;
    end
    
    % ===== 三维坐标提取 =====
    % 找到高强度点作为三维点云
    threshold = 0.1 * max(recon_intensity(:));
    [i_idx, j_idx] = find(recon_intensity > threshold);
    
    % 转换为物理坐标
    recon_coords.x = X_obj(sub2ind(size(X_obj), i_idx, j_idx));
    recon_coords.y = Y_obj(sub2ind(size(Y_obj), i_idx, j_idx));
    recon_coords.intensity = recon_intensity(sub2ind(size(recon_intensity), i_idx, j_idx));
    
    % z坐标（物体平面）
    recon_coords.z = distance * ones(size(recon_coords.x));

end
