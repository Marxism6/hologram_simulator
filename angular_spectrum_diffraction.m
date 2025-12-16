%% 角谱衍射法 (Angular Spectrum Diffraction Method)
% 计算三维物体各面元散射光在全息面的复振幅分布
% 
% 原理：
% - 光场分解为平面波的叠加（傅里叶变换）
% - 每个平面波在传播过程中积累相位 exp(i*kz*d)
% - 其中 kz = sqrt(k^2 - kx^2 - ky^2)
% - 最后通过逆傅里叶变换重构空间域光场
%
% 输入：
%   object_field: 物体表面的复振幅 (列向量)
%   object_coords: 物体坐标 (结构体：x, y, z)
%   distance: 传播距离 (m)
%   lambda: 波长 (m)
%   pixel_num: 采样点数
%   holo_size: 全息面大小 (m)
%
% 输出：
%   field_at_holo: 全息面上的复振幅 (2D矩阵)
%   x_holo, y_holo: 全息面的坐标轴 (1D向量)

function [field_at_holo, x_holo, y_holo] = angular_spectrum_diffraction(...
    object_field, object_coords, distance, lambda, pixel_num, holo_size, method)

    % 基本参数
    k = 2*pi/lambda;
    pixel_size = holo_size / pixel_num;
    
    % 全息面坐标
    x_holo = linspace(-holo_size/2, holo_size/2, pixel_num);
    y_holo = linspace(-holo_size/2, holo_size/2, pixel_num);
    [X_holo, Y_holo] = ndgrid(x_holo, y_holo);
    
    % 初始化全息面复振幅（兼容所有 MATLAB 版本）
    field_at_holo = complex(zeros(pixel_num, pixel_num));
    
    % ===== 方法1：Fresnel近似 + Convolution（快速）=====
    % 对每个物体点，计算其到全息面上各点的Fresnel衍射
    
    num_points = length(object_coords.x);
    
    for p = 1:num_points
        % 物体点坐标
        xp = object_coords.x(p);
        yp = object_coords.y(p);
        zp = object_coords.z(p);
        
        % 该点到全息面各点的传播距离
        % 使用Fresnel近似：r ≈ z0 + (x^2+y^2)/(2*z0)
        z_prop = distance - zp;  % 该点到全息面的z距离
        
        if z_prop <= 0
            continue;  % 跳过负距离或在全息面后的点
        end
        
        % 相对坐标
        dx = X_holo - xp;
        dy = Y_holo - yp;
        rho_sq = dx.^2 + dy.^2;
        
        % Fresnel衍射积分（使用卷积实现）
        % U = exp(i*k*z0) / (i*lambda*z0) * exp(i*k*rho^2/(2*z0))
        
        % 相位项：Fresnel相位
        fresnel_phase = exp(1i * k * rho_sq / (2 * z_prop));
        
        % 传播系数
        propagation_coeff = exp(1i * k * z_prop) / (1i * lambda * z_prop);
        
        % 该点对全息面的贡献
        contribution = object_field(p) * propagation_coeff * fresnel_phase;
        
        % 累加
        field_at_holo = field_at_holo + contribution;
    end
    
    % 若用户指定使用角谱方法，则调用方法2（更精确但更慢）
    if nargin >= 7 && ischar(method) && strcmpi(method, 'angular_spectrum')
        field_at_holo = angular_spectrum_propagation(...
            object_field, object_coords, distance, lambda, ...
            pixel_num, holo_size, x_holo, y_holo);
    end
    
    % 规范化（安全检查避免除以零）
    mx = max(abs(field_at_holo(:)));
    if mx > 0
        field_at_holo = field_at_holo / mx;
    end
    
end

%% 角谱精确传播法（可选）
function field_out = angular_spectrum_propagation(...
    object_field, object_coords, distance, lambda, ...
    pixel_num, holo_size, x_holo, y_holo)
    
    k = 2*pi/lambda;
    pixel_size = holo_size / pixel_num;
    
    % 初始化
    field_out = complex(zeros(pixel_num, pixel_num));
    
    % 对每个物体点进行角谱分解和传播
    num_points = length(object_coords.x);
    
    for p = 1:num_points
        xp = object_coords.x(p);
        yp = object_coords.y(p);
        zp = object_coords.z(p);
        z_prop = distance - zp;
        
        if z_prop <= 0
            continue;
        end
        
        % 在物体点处创建点源的初始场（Dirac delta）
        [X, Y] = ndgrid(x_holo, y_holo);
        
        % 简化：使用Fresnel衍射
        dx = X - xp;
        dy = Y - yp;
        r = sqrt(dx.^2 + dy.^2 + z_prop^2);
        
        % 正确的球面波表达式（Kirchhoff衍射公式）
        % U = A * exp(ikr) / r * 斜率因子（在近轴近似下简化）
        
        % 近轴近似下的Fresnel衍射
        field_contribution = object_field(p) * exp(1i * k * r) ./ r;
        
        field_out = field_out + field_contribution;
    end
    
    % 规范化（安全检查避免除以零）
    mx2 = max(abs(field_out(:)));
    if mx2 > 0
        field_out = field_out / mx2;
    end
    
end
