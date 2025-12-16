%% 高级配置和示例脚本
% 展示如何使用自定义参数和高级功能

%% 示例1：基础模式（默认参数）
function example_basic()
    fprintf('示例1：基础模式运行\n');
    fprintf('========================================\n');
    main;
end

%% 示例2：高分辨率模式
function example_high_resolution()
    fprintf('\n示例2：高分辨率全息模拟\n');
    fprintf('========================================\n');
    
    % 参数设置
    lambda = 632.8e-9;
    object_center = [0, 0, 100e-3];
    cube_size = 5e-3;
    sphere_radius = 2e-3;
    object_amplitude = 0.8;
    object_phase = pi/4;
    
    holo_z = 150e-3;
    holo_size = 50e-3;
    pixel_num = 1024;  % 高分辨率
    pixel_size = holo_size / pixel_num;
    
    theta_ref = 15 * pi/180;
    phi_ref = 0;
    theta_range = -45:15:45;
    phi_range = 0:10:30;
    
    add_noise = false;  % 无噪声
    SNR_dB = 50;
    
    output_dir = 'hologram_output_hires';
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    fprintf('  分辨率: %d × %d像素\n', pixel_num, pixel_num);
    fprintf('  像素大小: %.2f μm\n', pixel_size*1e6);
    fprintf('  计算时间: 预计2-3分钟\n');
    
    % 物体建模
    [object_field, object_coords] = create_object(...
        object_center, cube_size, sphere_radius, ...
        object_amplitude, object_phase, lambda, pixel_num, holo_size);
    
    % 衍射计算
    [object_field_at_holo, x_holo, y_holo] = angular_spectrum_diffraction(...
        object_field, object_coords, holo_z, lambda, pixel_num, holo_size);
    
    % 参考光和全息生成
    ref_field = compute_reference_field(theta_ref, phi_ref, lambda, x_holo, y_holo);
    [hologram_intensity, hologram_phase] = generate_hologram(...
        object_field_at_holo, ref_field, add_noise, SNR_dB);
    
    fprintf('  ✓ 完成！结果保存到: %s\n', output_dir);
end

%% 示例3：紫外激光模式
function example_uv_laser()
    fprintf('\n示例3：紫外激光模式\n');
    fprintf('========================================\n');
    
    lambda = 405e-9;  % 紫外激光（蓝紫色）
    
    fprintf('  波长: %.1f nm (紫外)\n', lambda*1e9);
    fprintf('  衍射尺度: 约 %.2f mm (相对于可见光)\n', lambda*1e9/632.8);
    
    % 衍射会更强（波长更短），需要调整采样
    pixel_num = 256;  % 降低分辨率以保持衍射特征
    
    % 其他参数类似示例1...
end

%% 示例4：多物体模式
function example_multiple_objects()
    fprintf('\n示例4：多物体场景\n');
    fprintf('========================================\n');
    
    lambda = 632.8e-9;
    holo_z = 150e-3;
    holo_size = 50e-3;
    pixel_num = 512;
    
    % 创建第一个物体（立方体）
    object1_center = [-10e-3, 0, 100e-3];
    [obj1_field, obj1_coords] = create_object(...
        object1_center, 5e-3, 2e-3, 0.8, pi/4, lambda, pixel_num, holo_size);
    
    % 创建第二个物体（球体）
    object2_center = [10e-3, 0, 100e-3];
    [obj2_field, obj2_coords] = create_object(...
        object2_center, 5e-3, 2e-3, 0.7, pi/3, lambda, pixel_num, holo_size);
    
    % 合并物体
    object_coords.x = [obj1_coords.x; obj2_coords.x];
    object_coords.y = [obj1_coords.y; obj2_coords.y];
    object_coords.z = [obj1_coords.z; obj2_coords.z];
    object_coords.amplitude = [obj1_coords.amplitude; obj2_coords.amplitude];
    object_coords.phase = [obj1_coords.phase; obj2_coords.phase];
    object_field = [obj1_field; obj2_field];
    
    fprintf('  物体个数: 2\n');
    fprintf('  总点数: %d\n', length(object_coords.x));
    
    % 继续衍射计算...
end

%% 示例5：观察干涉图的参数依赖性
function example_interference_analysis()
    fprintf('\n示例5：干涉图参数分析\n');
    fprintf('========================================\n');
    
    lambda = 632.8e-9;
    object_center = [0, 0, 100e-3];
    holo_z = 150e-3;
    holo_size = 50e-3;
    pixel_num = 512;
    
    % 测试不同的参考光角度
    theta_values = [5, 10, 15, 20, 25] * pi/180;  % 度数转弧度
    
    fprintf('  测试参考光角度对干涉对比度的影响:\n');
    
    for idx = 1:length(theta_values)
        theta_ref = theta_values(idx);
        phi_ref = 0;
        
        % 建模和衍射
        [object_field, object_coords] = create_object(...
            object_center, 5e-3, 2e-3, 0.8, pi/4, lambda, pixel_num, holo_size);
        
        [object_field_at_holo, x_holo, y_holo] = angular_spectrum_diffraction(...
            object_field, object_coords, holo_z, lambda, pixel_num, holo_size);
        
        ref_field = compute_reference_field(theta_ref, phi_ref, lambda, x_holo, y_holo);
        [hologram_intensity, ~] = generate_hologram(...
            object_field_at_holo, ref_field, false, 30);
        
        % 计算对比度
        contrast = (max(hologram_intensity(:)) - min(hologram_intensity(:))) / ...
                   mean(hologram_intensity(:));
        
        fprintf('    θ = %.0f°: 对比度 = %.4f\n', theta_values(idx)*180/pi, contrast);
    end
end

%% 示例6：噪声影响分析
function example_noise_analysis()
    fprintf('\n示例6：噪声对再现质量的影响\n');
    fprintf('========================================\n');
    
    lambda = 632.8e-9;
    object_center = [0, 0, 100e-3];
    holo_z = 150e-3;
    holo_size = 50e-3;
    pixel_num = 256;  % 较小以加快运算
    
    [object_field, object_coords] = create_object(...
        object_center, 5e-3, 2e-3, 0.8, pi/4, lambda, pixel_num, holo_size);
    
    [object_field_at_holo, x_holo, y_holo] = angular_spectrum_diffraction(...
        object_field, object_coords, holo_z, lambda, pixel_num, holo_size);
    
    theta_ref = 15*pi/180;
    ref_field = compute_reference_field(theta_ref, 0, lambda, x_holo, y_holo);
    
    % 测试不同SNR值
    SNR_values = [20, 30, 40, 50];  % dB
    
    fprintf('  测试不同信噪比的影响:\n');
    
    fig = figure('Position', [100, 100, 1200, 400], 'Visible', 'off');
    
    for idx = 1:length(SNR_values)
        [hologram_intensity, ~] = generate_hologram(...
            object_field_at_holo, ref_field, true, SNR_values(idx));
        
        % 计算统计量
        mean_intensity = mean(hologram_intensity(:));
        std_intensity = std(hologram_intensity(:));
        
        fprintf('    SNR = %.0f dB: 平均强度 = %.4f, 标准差 = %.4f\n', ...
            SNR_values(idx), mean_intensity, std_intensity);
        
        % 可视化
        subplot(1, 4, idx);
        imagesc(x_holo*1e3, y_holo*1e3, hologram_intensity);
        colormap(gca, 'gray');
        title(sprintf('SNR=%.0f dB', SNR_values(idx)));
        axis equal;
        set(gca, 'YDir', 'normal');
    end
    
    sgtitle('噪声对干涉图的影响');
    output_dir = 'hologram_output';
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    saveas(fig, fullfile(output_dir, 'noise_analysis.png'));
    close(fig);
    
    fprintf('  ✓ 分析结果已保存\n');
end

%% 辅助函数：计算参考光场
function ref_field = compute_reference_field(theta_ref, phi_ref, lambda, x_holo, y_holo)
    k = 2*pi/lambda;
    kx_ref = k * sin(phi_ref) * cos(theta_ref);
    ky_ref = k * sin(phi_ref) * sin(theta_ref);
    [X, Y] = ndgrid(x_holo, y_holo);
    ref_field = exp(1i * (kx_ref * X + ky_ref * Y));
end

%% 主函数：运行所有示例
function run_all_examples()
    fprintf('\n');
    fprintf('╔═══════════════════════════════════════════════════════════════╗\n');
    fprintf('║     三维物体数字全息模拟 - 高级示例演示                        ║\n');
    fprintf('╚═══════════════════════════════════════════════════════════════╝\n');
    
    % 用户可以取消注释相应的示例运行
    
    % example_basic();                    % 基础模式
    % example_high_resolution();          % 高分辨率（耗时）
    % example_uv_laser();                % 紫外激光
    % example_multiple_objects();        % 多物体
    example_interference_analysis();     % 干涉图分析
    % example_noise_analysis();          % 噪声分析
    
    fprintf('\n【提示】: 取消注释相应行以运行其他示例\n');
end

%% 如果直接运行此文件，执行主函数
if ~exist('run_main', 'var')
    run_all_examples();
end
