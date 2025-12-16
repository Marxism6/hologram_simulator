%% 三维物体数字全息模拟程序
% 严格遵循光的衍射、干涉物理规律的数字全息模拟系统
% 支持物体建模、全息生成、多视角再现和三维重建
% 兼容MATLAB R2020b及以上版本

clear; close all; clc;

%% 【第1部分】全局参数设置
% 光学参数
lambda = 632.8e-9;              % 波长 (m) - 氦氖激光
k = 2 * pi / lambda;            % 波数

% 物体参数
object_center = [0, 0, 100e-3]; % 物体中心坐标 (m)
cube_size = 5e-3;               % 立方体边长 (m)
sphere_radius = 2e-3;           % 球体半径 (m)
object_amplitude = 0.8;         % 振幅透射率
object_phase = pi/4;            % 相位延迟 (rad)

% 全息记录面参数
holo_z = 150e-3;                % 全息面到物体的距离 (m)
holo_size = 50e-3;              % 全息面大小 (m × m)
pixel_num = 512;                % 采样像素数 (建议512)
pixel_size = holo_size / pixel_num;  % 像素大小 (m)

% 参考光参数
theta_ref = 15 * pi/180;        % 参考光方位角 (rad)
phi_ref = 0;                    % 参考光仰角 (rad)

% 再现参数
theta_range = -45:15:45;        % 方位角范围 (deg)
phi_range = 0:10:30;            % 仰角范围 (deg)

% 噪声参数
add_noise = true;               % 是否添加噪声
SNR_dB = 30;                    % 信噪比 (dB)

% 输出参数
output_dir = 'hologram_output';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

fprintf('\n========== 三维物体数字全息模拟程序 ==========\n');
fprintf('光学参数：\n');
fprintf('  波长: %.1f nm\n', lambda*1e9);
fprintf('  参考光入射角: θ=%.1f°, φ=%.1f°\n', theta_ref*180/pi, phi_ref*180/pi);
fprintf('\n物体参数：\n');
fprintf('  物体中心: [%.1f, %.1f, %.1f] mm\n', object_center(1)*1e3, object_center(2)*1e3, object_center(3)*1e3);
fprintf('  立方体边长: %.1f mm\n', cube_size*1e3);
fprintf('  球体半径: %.1f mm\n', sphere_radius*1e3);
fprintf('  振幅透射率: %.2f, 相位延迟: %.4f rad\n', object_amplitude, object_phase);
fprintf('\n全息面参数：\n');
fprintf('  全息面距离: %.1f mm\n', holo_z*1e3);
fprintf('  全息面大小: %.1f × %.1f mm\n', holo_size*1e3, holo_size*1e3);
fprintf('  采样像素: %d × %d (像素大小: %.2f μm)\n', pixel_num, pixel_num, pixel_size*1e6);

% ===== 可选：加载用户自定义配置（如果存在 get_custom_config.m） =====
user_config_overridden = {};
if exist('get_custom_config', 'file') == 2
    try
        cfg = get_custom_config();
        fn = fieldnames(cfg);

        % 白名单：允许用户覆盖的字段（安全）
        allowed = {'lambda','object_center','cube_size','sphere_radius', ...
                   'object_amplitude','object_phase','holo_z','holo_size', ...
                   'pixel_num','theta_ref','phi_ref','theta_range','phi_range', ...
                   'add_noise','SNR_dB','output_dir'};

        for ii = 1:length(fn)
            name = fn{ii};
            if ismember(name, allowed)
                try
                    % 将允许的配置值写入当前脚本作用域（覆盖默认）
                    eval([name ' = cfg.' name ';']);
                    user_config_overridden{end+1} = name; %#ok<SAGROW>
                catch
                    fprintf('Warning: 无法将配置字段 %s 应用到主脚本。\n', name);
                end
            else
                fprintf('Info: 忽略未授权配置字段: %s\n', name);
            end
        end

        if ~isempty(user_config_overridden)
            fprintf('Loaded user config: overridden fields: %s\n', strjoin(user_config_overridden, ', '));
        else
            fprintf('get_custom_config() found but no allowed fields applied.\n');
        end
    catch ME
        fprintf('Warning: 调用 get_custom_config() 时出错: %s\n', ME.message);
    end
end

%% 【第2部分】物体建模
fprintf('\n【处理中】物体建模...\n');
[object_field, object_coords] = create_object(...
    object_center, cube_size, sphere_radius, ...
    object_amplitude, object_phase, ...
    lambda, pixel_num, holo_size);
fprintf('  ✓ 物体建模完成，点数: %d\n', length(object_coords.x));

%% 【第3部分】全息生成
fprintf('\n【处理中】全息图生成...\n');

% 计算物光场在全息面上的复振幅
if exist('diffraction_method', 'var')
    [object_field_at_holo, x_holo, y_holo] = angular_spectrum_diffraction(...
        object_field, object_coords, ...
        holo_z, lambda, pixel_num, holo_size, diffraction_method);
else
    [object_field_at_holo, x_holo, y_holo] = angular_spectrum_diffraction(...
        object_field, object_coords, ...
        holo_z, lambda, pixel_num, holo_size);
end

% 计算参考光场
ref_field = compute_reference_field(...
    theta_ref, phi_ref, lambda, x_holo, y_holo);

% 计算干涉图
[hologram_intensity, hologram_phase] = generate_hologram(...
    object_field_at_holo, ref_field, add_noise, SNR_dB);

fprintf('  ✓ 全息图生成完成\n');
fprintf('  物光场范围: [%.4f, %.4f]\n', min(abs(object_field_at_holo(:))), max(abs(object_field_at_holo(:))));
fprintf('  干涉图对比度: %.4f\n', (max(hologram_intensity(:)) - min(hologram_intensity(:))) / mean(hologram_intensity(:)));

%% 【第4部分】全息再现 - 多视角
fprintf('\n【处理中】多视角全息再现...\n');

% 存储再现图像
reconstructed_images = cell(length(theta_range), length(phi_range));
reconstructed_coords = cell(length(theta_range), length(phi_range));

for i = 1:length(theta_range)
    for j = 1:length(phi_range)
        theta_view = theta_range(i) * pi/180;
        phi_view = phi_range(j) * pi/180;
        
        % 计算再现光场
        recon_field = compute_reconstruction_field(...
            theta_view, phi_view, lambda, x_holo, y_holo);
        
        % 逆向传播重构物体空间
        [recon_intensity, recon_coords] = reconstruct_hologram(...
            hologram_intensity, recon_field, lambda, ...
            holo_z, pixel_num, holo_size);
        
        reconstructed_images{i,j} = recon_intensity;
        reconstructed_coords{i,j} = recon_coords;
        
        fprintf('  ✓ 视角 (θ=%.0f°, φ=%.0f°) 再现完成\n', theta_range(i), phi_range(j));
    end
end

%% 【第5部分】可视化和输出
fprintf('\n【处理中】生成可视化结果...\n');

% 调用可视化模块
visualize_results(...
    hologram_intensity, hologram_phase, object_field_at_holo, ref_field, ...
    reconstructed_images, theta_range, phi_range, ...
    object_coords, x_holo, y_holo, ...
    output_dir, lambda, pixel_num, SNR_dB, add_noise);

%% 【第6部分】参数日志输出
log_file = fullfile(output_dir, 'hologram_parameters.log');
fid = fopen(log_file, 'w');
fprintf(fid, '=== 三维物体数字全息模拟 - 参数日志 ===\n');
fprintf(fid, '生成时间: %s\n\n', datetime('now'));
fprintf(fid, '【光学参数】\n');
fprintf(fid, '波长 (nm): %.1f\n', lambda*1e9);
fprintf(fid, '参考光方位角 (deg): %.1f\n', theta_ref*180/pi);
fprintf(fid, '参考光仰角 (deg): %.1f\n', phi_ref*180/pi);
fprintf(fid, '\n【物体参数】\n');
fprintf(fid, '物体中心 (mm): [%.3f, %.3f, %.3f]\n', object_center(1)*1e3, object_center(2)*1e3, object_center(3)*1e3);
fprintf(fid, '立方体边长 (mm): %.3f\n', cube_size*1e3);
fprintf(fid, '球体半径 (mm): %.3f\n', sphere_radius*1e3);
fprintf(fid, '振幅透射率: %.3f\n', object_amplitude);
fprintf(fid, '相位延迟 (rad): %.4f\n', object_phase);
fprintf(fid, '\n【全息面参数】\n');
fprintf(fid, '全息面距离 (mm): %.3f\n', holo_z*1e3);
fprintf(fid, '全息面尺寸 (mm): %.3f × %.3f\n', holo_size*1e3, holo_size*1e3);
fprintf(fid, '采样像素数: %d × %d\n', pixel_num, pixel_num);
fprintf(fid, '像素大小 (um): %.3f\n', pixel_size*1e6);
fprintf(fid, '\n【再现参数】\n');
fprintf(fid, '方位角范围 (deg): ');
fprintf(fid, '%d ', theta_range); fprintf(fid, '\n');
fprintf(fid, '仰角范围 (deg): ');
fprintf(fid, '%d ', phi_range); fprintf(fid, '\n');
fprintf(fid, '\n【噪声参数】\n');
fprintf(fid, '添加噪声: %s\n', string(add_noise));
fprintf(fid, '信噪比 (dB): %.1f\n', SNR_dB);

% 记录是否有用户自定义配置覆盖
if exist('user_config_overridden', 'var') && ~isempty(user_config_overridden)
    fprintf(fid, '\n【用户配置覆盖】\n');
    fprintf(fid, '覆盖的字段: %s\n', strjoin(user_config_overridden, ', '));
else
    fprintf(fid, '\n【用户配置覆盖】\n');
    fprintf(fid, '无\n');
end
fclose(fid);

fprintf('\n  ✓ 参数日志已保存: %s\n', log_file);
fprintf('\n========== 程序执行完成 ==========\n');
fprintf('输出目录: %s\n\n', output_dir);

%% ==================== 嵌入式辅助函数 ====================

%% 计算参考光场
function ref_field = compute_reference_field(theta_ref, phi_ref, lambda, x_holo, y_holo)
    % 参考光为离轴平面波
    % theta_ref: 方位角 (rad)
    % phi_ref: 仰角 (rad)
    
    k = 2*pi/lambda;
    
    % 参考光传播方向的波矢
    kx_ref = k * sin(phi_ref) * cos(theta_ref);
    ky_ref = k * sin(phi_ref) * sin(theta_ref);
    
    % 二维矩阵化
    [X, Y] = ndgrid(x_holo, y_holo);
    
    % 参考光复振幅（单位振幅）
    ref_field = exp(1i * (kx_ref * X + ky_ref * Y));
end

%% 计算再现光场
function recon_field = compute_reconstruction_field(theta_view, phi_view, lambda, x_holo, y_holo)
    % 再现光为平面波，与参考光波长相同
    
    k = 2*pi/lambda;
    
    % 再现光传播方向的波矢
    kx_view = k * sin(phi_view) * cos(theta_view);
    ky_view = k * sin(phi_view) * sin(theta_view);
    
    % 二维矩阵化
    [X, Y] = ndgrid(x_holo, y_holo);
    
    % 再现光复振幅
    recon_field = exp(1i * (kx_view * X + ky_view * Y));
end

end
