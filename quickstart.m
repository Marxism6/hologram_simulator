% 快速开始脚本 - 初学者指南
% 这个脚本展示如何一步步运行全息模拟

clear; close all; clc;

fprintf('\n');
fprintf('╔═══════════════════════════════════════════════════════════════╗\n');
fprintf('║      三维物体数字全息模拟 - 快速开始                           ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════╝\n\n');

%% 第一步：验证环境
fprintf('【第一步】验证MATLAB环境...\n');
fprintf('  MATLAB版本: %s\n', version('-release'));
fprintf('  ✓ 环境检查完成\n\n');

%% 第二步：选择运行模式
fprintf('【第二步】选择运行模式\n');
fprintf('  1. 快速模式 (256×256像素，~30秒)\n');
fprintf('  2. 标准模式 (512×512像素，~60秒) [推荐]\n');
fprintf('  3. 高质量模式 (1024×1024像素，~3分钟)\n');
fprintf('  4. 自定义参数\n\n');

mode = 2;  % 默认标准模式

%% 第三步：设置参数
fprintf('【第三步】设置模拟参数...\n');

% 根据模式选择像素数
switch mode
    case 1
        pixel_num = 256;
        fprintf('  模式: 快速 (256×256)\n');
    case 2
        pixel_num = 512;
        fprintf('  模式: 标准 (512×512) [推荐]\n');
    case 3
        pixel_num = 1024;
        fprintf('  模式: 高质量 (1024×1024)\n');
    otherwise
        pixel_num = 512;
end

% 基本参数
lambda = 632.8e-9;              % 氦氖激光
object_center = [0, 0, 100e-3]; % 物体中心: 100mm
cube_size = 5e-3;               % 5mm立方体
sphere_radius = 2e-3;           % 2mm球体
object_amplitude = 0.8;         % 振幅: 80%
object_phase = pi/4;            % 相位延迟

holo_z = 150e-3;                % 全息面: 150mm
holo_size = 50e-3;              % 全息面: 50×50mm
theta_ref = 15 * pi/180;        % 参考光: 15°
phi_ref = 0;

% 再现视角
theta_range = -45:15:45;        % 方位角
phi_range = 0:10:30;            % 仰角

% 噪声设置
add_noise = true;               % 添加现实噪声
SNR_dB = 30;                    % 信噪比30dB

fprintf('  ✓ 光源: λ = %.1f nm (氦氖激光)\n', lambda*1e9);
fprintf('  ✓ 物体: 5mm立方体 + 2mm球体\n');
fprintf('  ✓ 全息面: 50×50mm, %d×%d像素\n', pixel_num, pixel_num);
fprintf('  ✓ 再现视角: %d个\n\n', length(theta_range)*length(phi_range));

%% 第四步：创建输出目录
output_dir = 'hologram_output_quickstart';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
fprintf('【第四步】创建输出目录\n');
fprintf('  路径: %s\n\n', fullfile(pwd, output_dir));

%% 第五步：物体建模
fprintf('【第五步】物体建模...\n');
tic;
[object_field, object_coords] = create_object(...
    object_center, cube_size, sphere_radius, ...
    object_amplitude, object_phase, ...
    lambda, pixel_num, holo_size);
elapsed_time = toc;
fprintf('  ✓ 完成！用时: %.2f 秒\n', elapsed_time);
fprintf('  物体点数: %d\n\n', length(object_coords.x));

%% 第六步：衍射计算
fprintf('【第六步】计算物光场衍射...\n');
tic;
[object_field_at_holo, x_holo, y_holo] = angular_spectrum_diffraction(...
    object_field, object_coords, holo_z, lambda, pixel_num, holo_size);
elapsed_time = toc;
fprintf('  ✓ 完成！用时: %.2f 秒\n', elapsed_time);
fprintf('  物光强度范围: [%.4f, %.4f]\n\n', ...
    min(abs(object_field_at_holo(:))), max(abs(object_field_at_holo(:))));

%% 第七步：参考光和全息图生成
fprintf('【第七步】生成全息干涉图...\n');
tic;
% 计算参考光
ref_field = exp(1i * (2*pi/lambda * sin(phi_ref)*cos(theta_ref) * ...
    repmat(x_holo', 1, length(y_holo)) + ...
    2*pi/lambda * sin(phi_ref)*sin(theta_ref) * ...
    repmat(y_holo, length(x_holo), 1)));

% 生成干涉图
[hologram_intensity, hologram_phase] = generate_hologram(...
    object_field_at_holo, ref_field, add_noise, SNR_dB);
elapsed_time = toc;
fprintf('  ✓ 完成！用时: %.2f 秒\n', elapsed_time);
fprintf('  干涉强度范围: [%.4f, %.4f]\n', ...
    min(hologram_intensity(:)), max(hologram_intensity(:)));
fprintf('  对比度: %.4f\n\n', ...
    (max(hologram_intensity(:)) - min(hologram_intensity(:))) / mean(hologram_intensity(:)));

%% 第八步：再现
fprintf('【第八步】多视角全息再现...\n');
tic;

reconstructed_images = cell(length(theta_range), length(phi_range));

for i = 1:length(theta_range)
    for j = 1:length(phi_range)
        theta_view = theta_range(i) * pi/180;
        phi_view = phi_range(j) * pi/180;
        
        % 计算再现光
        recon_field = exp(1i * (2*pi/lambda * sin(phi_view)*cos(theta_view) * ...
            repmat(x_holo', 1, length(y_holo)) + ...
            2*pi/lambda * sin(phi_view)*sin(theta_view) * ...
            repmat(y_holo, length(x_holo), 1)));
        
        % 再现
        [recon_intensity, ~] = reconstruct_hologram(...
            hologram_intensity, recon_field, lambda, holo_z, pixel_num, holo_size);
        
        reconstructed_images{i, j} = recon_intensity;
    end
end

elapsed_time = toc;
fprintf('  ✓ 完成！用时: %.2f 秒\n\n', elapsed_time);

%% 第九步：快速可视化
fprintf('【第九步】生成可视化...\n');
tic;

% 干涉图
fig1 = figure('Position', [100, 100, 1200, 400], 'Visible', 'off');
subplot(1, 3, 1);
imagesc(x_holo*1e3, y_holo*1e3, hologram_intensity);
colormap(gca, 'gray');
title('全息干涉图');
xlabel('x (mm)'); ylabel('y (mm)');
axis equal; set(gca, 'YDir', 'normal');

subplot(1, 3, 2);
imagesc(x_holo*1e3, y_holo*1e3, hologram_phase);
colormap(gca, 'hsv');
title('相位分布');
xlabel('x (mm)'); ylabel('y (mm)');
axis equal; set(gca, 'YDir', 'normal');

subplot(1, 3, 3);
imagesc(x_holo*1e3, y_holo*1e3, abs(object_field_at_holo));
colormap(gca, 'hot');
title('物光强度');
xlabel('x (mm)'); ylabel('y (mm)');
axis equal; set(gca, 'YDir', 'normal');

sgtitle('全息图对比');
saveas(fig1, fullfile(output_dir, 'hologram_overview.png'));
close(fig1);

% 再现图对比
fig2 = figure('Position', [100, 100, 800, 800], 'Visible', 'off');
for i = 1:min(4, length(theta_range)*length(phi_range))
    [ii, jj] = ind2sub([length(theta_range), length(phi_range)], i);
    subplot(2, 2, i);
    imagesc(x_holo*1e3, y_holo*1e3, reconstructed_images{ii, jj});
    colormap(gca, 'gray');
    title(sprintf('θ=%.0f°, φ=%.0f°', theta_range(ii), phi_range(jj)));
    axis equal; set(gca, 'YDir', 'normal');
end
sgtitle('多视角再现像');
saveas(fig2, fullfile(output_dir, 'reconstructions.png'));
close(fig2);

elapsed_time = toc;
fprintf('  ✓ 完成！用时: %.2f 秒\n\n', elapsed_time);

%% 第十步：总结
fprintf('【第十步】总结和输出\n');
fprintf('╔════════════════════════════════════════════════╗\n');
fprintf('║            模拟执行成功！                      ║\n');
fprintf('╚════════════════════════════════════════════════╝\n\n');

fprintf('输出文件位置: %s\n\n', fullfile(pwd, output_dir));
fprintf('生成的文件:\n');
fprintf('  √ hologram_overview.png      - 干涉图对比\n');
fprintf('  √ reconstructions.png        - 再现像对比\n\n');

fprintf('后续步骤:\n');
fprintf('  1. 查看输出文件夹中的图像\n');
fprintf('  2. 修改参数重新运行 (编辑本文件)\n');
fprintf('  3. 运行 main.m 获得完整功能\n');
fprintf('  4. 查看 README.md 了解更多功能\n\n');

fprintf('【提示】\n');
fprintf('  • 要改变波长: 修改 lambda 变量\n');
fprintf('  • 要改变物体: 编辑 cube_size 和 sphere_radius\n');
fprintf('  • 要改变分辨率: 修改 pixel_num (256/512/1024)\n');
fprintf('  • 要关闭噪声: 设置 add_noise = false\n\n');
