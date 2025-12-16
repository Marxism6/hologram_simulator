%% 数据导出和分析工具
% 用于保存、加载和分析全息数据

%% 保存全息数据到MAT文件
function save_hologram_data(filename, hologram_data)
    % 保存全息相关的所有数据到MAT文件
    % 便于后续处理和分析
    
    fprintf('保存全息数据到: %s\n', filename);
    
    % 保存结构体
    save(filename, 'hologram_data', '-v7.3');  % 支持大文件
    
    fprintf('  ✓ 完成，文件大小: %.2f MB\n', dir(filename).bytes/1e6);
end

%% 加载全息数据
function hologram_data = load_hologram_data(filename)
    fprintf('加载全息数据从: %s\n', filename);
    load(filename, 'hologram_data');
    fprintf('  ✓ 加载完成\n');
end

%% 计算全息图统计参数
function stats = compute_hologram_statistics(hologram_intensity, hologram_phase)
    % 输入: 干涉强度和相位
    % 输出: 统计参数结构体
    
    % 强度统计
    stats.intensity_mean = mean(hologram_intensity(:));
    stats.intensity_std = std(hologram_intensity(:));
    stats.intensity_min = min(hologram_intensity(:));
    stats.intensity_max = max(hologram_intensity(:));
    stats.intensity_median = median(hologram_intensity(:));
    
    % 对比度
    stats.contrast = (stats.intensity_max - stats.intensity_min) / stats.intensity_mean;
    
    % 相位统计
    stats.phase_mean = mean(hologram_phase(:));
    stats.phase_std = std(hologram_phase(:));
    stats.phase_range = max(hologram_phase(:)) - min(hologram_phase(:));
    
    % 频域分析
    FFT_intensity = abs(fft2(hologram_intensity));
    FFT_intensity = fftshift(FFT_intensity);
    stats.frequency_max = max(FFT_intensity(:));
    stats.frequency_mean = mean(FFT_intensity(:));
    
    % 能量分布
    stats.energy_dc = hologram_intensity(1,1);  % DC分量
    stats.energy_total = sum(hologram_intensity(:));
    stats.energy_ac_ratio = 1 - stats.energy_dc / stats.energy_total;
    
end

%% 衍射效率计算
function efficiency = calculate_diffraction_efficiency(...
    hologram_intensity, object_field_at_holo, ref_field)
    
    % 衍射效率 = 衍射光功率 / 入射光功率
    
    % 入射功率（参考光）
    ref_power = sum(abs(ref_field(:)).^2);
    
    % 衍射光功率（物光通过全息图）
    combined_field = object_field_at_holo + ref_field;
    diffracted_power = sum(abs(combined_field(:)).^2);
    
    % 衍射效率
    efficiency = diffracted_power / ref_power;
    
end

%% 模体转移函数 (MTF) 分析
function MTF = compute_modulation_transfer_function(...
    hologram_intensity, x_holo, y_holo)
    
    % 计算全息图的MTF
    % MTF描述了不同空间频率的传递效果
    
    % 2D FFT
    F = fft2(hologram_intensity);
    F_shifted = fftshift(F);
    magnitude = abs(F_shifted);
    
    % 频率轴
    Nx = length(x_holo);
    Ny = length(y_holo);
    dx = x_holo(2) - x_holo(1);
    dy = y_holo(2) - y_holo(1);
    
    fx = (-Nx/2:Nx/2-1) / (Nx*dx);
    fy = (-Ny/2:Ny/2-1) / (Ny*dy);
    
    % 径向频率
    [FX, FY] = meshgrid(fx, fy);
    f_radial = sqrt(FX.^2 + FY.^2);
    
    % MTF = 径向平均的幅度谱
    f_bins = linspace(0, max(f_radial(:)), 100);
    MTF = zeros(size(f_bins));
    
    for i = 1:length(f_bins)-1
        mask = (f_radial >= f_bins(i)) & (f_radial < f_bins(i+1));
        if sum(mask(:)) > 0
            MTF(i) = mean(magnitude(mask));
        end
    end
    
    % 规范化
    MTF = MTF / max(MTF);
    
end

%% 相位梯度计算（测量相位的平滑性）
function phase_gradient = compute_phase_gradient(hologram_phase)
    
    % 计算相位的梯度（使用Sobel算子或简单差分）
    [gx, gy] = gradient(hologram_phase);
    phase_gradient = sqrt(gx.^2 + gy.^2);
    
end

%% 干涉条纹可见度分析
function visibility = compute_fringe_visibility(hologram_intensity)
    
    % 可见度 V = (I_max - I_min) / (I_max + I_min)
    % 值域: 0-1，越高表示干涉条纹越清晰
    
    I_max = max(hologram_intensity(:));
    I_min = min(hologram_intensity(:));
    
    visibility = (I_max - I_min) / (I_max + I_min);
    
end

%% 再现像质量评估
function quality = evaluate_reconstruction_quality(...
    reconstructed_image, original_object_projection)
    
    % 评估再现像与原始物体的相似度
    % 使用结构相似度 (SSIM) 或峰值信噪比 (PSNR)
    
    % 确保尺寸相同
    if size(reconstructed_image, 1) ~= size(original_object_projection, 1) || ...
       size(reconstructed_image, 2) ~= size(original_object_projection, 2)
        reconstructed_image = imresize(reconstructed_image, size(original_object_projection));
    end
    
    % 峰值信噪比 (PSNR)
    MSE = mean((reconstructed_image(:) - original_object_projection(:)).^2);
    max_val = max(original_object_projection(:));
    quality.PSNR = 10 * log10(max_val^2 / MSE);
    
    % 相关系数
    quality.correlation = corr2(reconstructed_image, original_object_projection);
    
    % 结构相似度 (SSIM) - 简化版本
    mu1 = mean(reconstructed_image(:));
    mu2 = mean(original_object_projection(:));
    sigma1 = std(reconstructed_image(:));
    sigma2 = std(original_object_projection(:));
    sigma12 = cov([reconstructed_image(:), original_object_projection(:)]);
    sigma12 = sigma12(1,2);
    
    c1 = 0.01; c2 = 0.03;
    quality.SSIM = ((2*mu1*mu2 + c1) * (2*sigma12 + c2)) / ...
                   ((mu1^2 + mu2^2 + c1) * (sigma1^2 + sigma2^2 + c2));
    
end

%% 导出再现像为图像文件
function export_reconstruction_images(...
    reconstructed_images, theta_range, phi_range, output_dir)
    
    % 将再现像导出为高质量图像
    
    fprintf('导出再现像...\n');
    
    for i = 1:length(theta_range)
        for j = 1:length(phi_range)
            img = reconstructed_images{i, j};
            
            % 规范化到 0-255
            img_8bit = uint8(255 * img / max(img(:)));
            
            % 生成文件名
            filename = sprintf('reconstruction_%d_%d.png', theta_range(i), phi_range(j));
            filepath = fullfile(output_dir, filename);
            
            % 保存
            imwrite(img_8bit, filepath);
        end
    end
    
    fprintf('  ✓ 共导出 %d 幅再现像\n', length(theta_range)*length(phi_range));
    
end

%% 批量处理多个波长
function multi_wavelength_analysis(wavelengths, output_base_dir)
    
    % 对多个波长进行全息模拟
    % wavelengths: 波长数组 (m)
    
    fprintf('执行多波长分析...\n');
    fprintf('波长数: %d\n', length(wavelengths));
    
    for i = 1:length(wavelengths)
        lambda = wavelengths(i);
        
        % 创建子目录
        subdir = fullfile(output_base_dir, sprintf('lambda_%.1f_nm', lambda*1e9));
        if ~exist(subdir, 'dir')
            mkdir(subdir);
        end
        
        fprintf('  处理 λ = %.1f nm...\n', lambda*1e9);
        
        % 这里调用主要的全息模拟函数
        % (具体实现取决于如何组织main.m)
        
    end
    
end

%% 生成综合分析报告
function generate_analysis_report(hologram_intensity, hologram_phase, ...
    output_dir, lambda, pixel_num)
    
    fprintf('生成分析报告...\n');
    
    % 计算所有统计量
    stats = compute_hologram_statistics(hologram_intensity, hologram_phase);
    visibility = compute_fringe_visibility(hologram_intensity);
    
    % 创建报告
    report_file = fullfile(output_dir, 'analysis_report.txt');
    fid = fopen(report_file, 'w');
    
    fprintf(fid, '========== 全息模拟分析报告 ==========\n\n');
    fprintf(fid, '生成时间: %s\n', datetime('now'));
    fprintf(fid, '波长: %.2f nm\n', lambda*1e9);
    fprintf(fid, '采样率: %d × %d\n\n', pixel_num, pixel_num);
    
    fprintf(fid, '【强度统计】\n');
    fprintf(fid, '  平均值: %.6f\n', stats.intensity_mean);
    fprintf(fid, '  标准差: %.6f\n', stats.intensity_std);
    fprintf(fid, '  最大值: %.6f\n', stats.intensity_max);
    fprintf(fid, '  最小值: %.6f\n', stats.intensity_min);
    fprintf(fid, '  对比度: %.4f\n\n', stats.contrast);
    
    fprintf(fid, '【干涉条纹质量】\n');
    fprintf(fid, '  可见度: %.4f (范围: 0-1，越高越好)\n\n', visibility);
    
    fprintf(fid, '【相位统计】\n');
    fprintf(fid, '  平均相位: %.4f rad\n', stats.phase_mean);
    fprintf(fid, '  相位范围: %.4f rad\n\n', stats.phase_range);
    
    fprintf(fid, '【能量分析】\n');
    fprintf(fid, '  总能量: %.6f\n', stats.energy_total);
    fprintf(fid, '  AC/总能量比: %.4f\n', stats.energy_ac_ratio);
    
    fclose(fid);
    
    fprintf('  ✓ 报告已保存: %s\n', report_file);
    
end
