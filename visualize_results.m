%% 可视化和输出函数
% 生成二维投影灰度图、三维点云可视化、对比图等
% 保存图像和日志文件
%
% 输入：多个全息相关的数据和参数
% 输出：.fig/.png文件保存到指定目录

function visualize_results(...
    hologram_intensity, hologram_phase, object_field_at_holo, ref_field, ...
    reconstructed_images, theta_range, phi_range, ...
    object_coords, x_holo, y_holo, ...
    output_dir, lambda, pixel_num, SNR_dB, add_noise)

    % ===== 第1部分：全息图可视化 =====
    fig1 = figure('Position', [100, 100, 1200, 500], 'Visible', 'off');
    
    % 子图1：干涉强度图
    subplot(1, 3, 1);
    imagesc(x_holo*1e3, y_holo*1e3, hologram_intensity);
    colormap(gca, 'gray');
    colorbar;
    title('全息干涉强度图', 'FontSize', 12, 'FontName', 'SimSun');
    xlabel('x (mm)', 'FontSize', 10);
    ylabel('y (mm)', 'FontSize', 10);
    axis equal;
    set(gca, 'YDir', 'normal');
    
    % 子图2：相位分布
    subplot(1, 3, 2);
    imagesc(x_holo*1e3, y_holo*1e3, hologram_phase);
    colormap(gca, 'hsv');
    colorbar;
    title('全息相位分布', 'FontSize', 12, 'FontName', 'SimSun');
    xlabel('x (mm)', 'FontSize', 10);
    ylabel('y (mm)', 'FontSize', 10);
    axis equal;
    set(gca, 'YDir', 'normal');
    
    % 子图3：物光场强度
    subplot(1, 3, 3);
    imagesc(x_holo*1e3, y_holo*1e3, abs(object_field_at_holo));
    colormap(gca, 'hot');
    colorbar;
    title('物光场强度分布', 'FontSize', 12, 'FontName', 'SimSun');
    xlabel('x (mm)', 'FontSize', 10);
    ylabel('y (mm)', 'FontSize', 10);
    axis equal;
    set(gca, 'YDir', 'normal');
    
    sgtitle('全息图生成结果', 'FontSize', 14, 'FontName', 'SimSun', 'FontWeight', 'bold');
    
    % 保存图像
    savefig(fig1, fullfile(output_dir, 'hologram_generation.fig'));
    saveas(fig1, fullfile(output_dir, 'hologram_generation.png'));
    fprintf('  ✓ 已保存: hologram_generation.fig/.png\n');
    close(fig1);
    
    % ===== 第2部分：原始物体的三维可视化 =====
    fig2 = figure('Position', [100, 100, 600, 600], 'Visible', 'off');
    scatter3(object_coords.x*1e3, object_coords.y*1e3, object_coords.z*1e3, ...
        5, abs(object_coords.amplitude), 'filled');
    colorbar;
    title('原始物体三维模型', 'FontSize', 14, 'FontName', 'SimSun');
    xlabel('x (mm)');
    ylabel('y (mm)');
    zlabel('z (mm)');
    grid on;
    axis equal;
    view(45, 30);
    
    savefig(fig2, fullfile(output_dir, 'object_3d_model.fig'));
    saveas(fig2, fullfile(output_dir, 'object_3d_model.png'));
    fprintf('  ✓ 已保存: object_3d_model.fig/.png\n');
    close(fig2);
    
    % ===== 第3部分：多视角再现图 =====
    num_theta = length(theta_range);
    num_phi = length(phi_range);
    
    for i = 1:num_theta
        for j = 1:num_phi
            fig3 = figure('Position', [100, 100, 800, 700], 'Visible', 'off');
            
            % 再现强度图
            subplot(2, 1, 1);
            recon_img = reconstructed_images{i, j};
            imagesc(x_holo*1e3, y_holo*1e3, recon_img);
            colormap(gca, 'gray');
            colorbar;
            title(sprintf('再现像 (θ=%.0f°, φ=%.0f°)', theta_range(i), phi_range(j)), ...
                'FontSize', 12, 'FontName', 'SimSun');
            xlabel('x (mm)');
            ylabel('y (mm)');
            axis equal;
            set(gca, 'YDir', 'normal');
            
            % 再现坐标点云（如果有）
            subplot(2, 1, 2);
            recon_coord = reconstructed_images{i, j};  % 这里需要实际的点云数据
            % 为了简化，这里显示再现像的3D表面
            [X_mesh, Y_mesh] = meshgrid(x_holo*1e3, y_holo*1e3);
            surf(X_mesh, Y_mesh, recon_img, 'EdgeColor', 'none');
            colormap(gca, 'hot');
            title(sprintf('再现场三维分布 (θ=%.0f°, φ=%.0f°)', theta_range(i), phi_range(j)), ...
                'FontSize', 12, 'FontName', 'SimSun');
            xlabel('x (mm)');
            ylabel('y (mm)');
            zlabel('强度');
            view(45, 30);
            
            sgtitle(sprintf('视角：方位角θ=%.0f°, 仰角φ=%.0f°', theta_range(i), phi_range(j)), ...
                'FontSize', 13, 'FontName', 'SimSun', 'FontWeight', 'bold');
            
            % 保存
            fig_name = sprintf('reconstruction_theta_%d_phi_%d', theta_range(i), phi_range(j));
            savefig(fig3, fullfile(output_dir, [fig_name '.fig']));
            saveas(fig3, fullfile(output_dir, [fig_name '.png']));
            fprintf('  ✓ 已保存: %s.fig/.png\n', fig_name);
            close(fig3);
        end
    end
    
    % ===== 第4部分：对比图（选定几个视角） =====
    num_view = min(4, num_theta * num_phi);
    fig4 = figure('Position', [100, 100, 1000, 1000], 'Visible', 'off');
    
    view_idx = 1;
    for i = 1:min(2, num_theta)
        for j = 1:min(2, num_phi)
            if view_idx <= 4
                subplot(2, 2, view_idx);
                recon_img = reconstructed_images{i, j};
                imagesc(x_holo*1e3, y_holo*1e3, recon_img);
                colormap(gca, 'gray');
                title(sprintf('θ=%.0f°, φ=%.0f°', theta_range(i), phi_range(j)), ...
                    'FontSize', 11, 'FontName', 'SimSun');
                xlabel('x (mm)');
                ylabel('y (mm)');
                axis equal;
                set(gca, 'YDir', 'normal');
                colorbar;
                view_idx = view_idx + 1;
            end
        end
    end
    
    sgtitle('多视角再现像对比', 'FontSize', 14, 'FontName', 'SimSun', 'FontWeight', 'bold');
    
    savefig(fig4, fullfile(output_dir, 'multi_view_comparison.fig'));
    saveas(fig4, fullfile(output_dir, 'multi_view_comparison.png'));
    fprintf('  ✓ 已保存: multi_view_comparison.fig/.png\n');
    close(fig4);
    
    % ===== 第5部分：参数统计图 =====
    fig5 = figure('Position', [100, 100, 800, 600], 'Visible', 'off');
    
    % 创建信息文本
    info_text = sprintf([...
        '【全息参数统计】\n\n' ...
        '光学参数：\n' ...
        '  波长: %.2f nm\n' ...
        '  像素数: %d × %d\n' ...
        '  全息面大小: %.2f × %.2f mm\n\n' ...
        '物体参数：\n' ...
        '  物体点数: %d\n' ...
        '  振幅透射率: %.2f\n' ...
        '  相位延迟: %.4f rad\n\n' ...
        '再现参数：\n' ...
        '  方位角范围: %.0f° ~ %.0f°\n' ...
        '  仰角范围: %.0f° ~ %.0f°\n' ...
        '  视角数: %d\n\n' ...
        '噪声参数：\n' ...
        '  是否添加噪声: %s\n' ...
        '  信噪比: %.1f dB\n' ...
        ], ...
        lambda*1e9, pixel_num, pixel_num, ...
        50, 50, ...
        length(object_coords.x), 0.8, pi/4, ...
        theta_range(1), theta_range(end), phi_range(1), phi_range(end), ...
        num_theta * num_phi, ...
        string(add_noise), SNR_dB);
    
    text(0.1, 0.5, info_text, 'FontSize', 12, 'FontName', 'Courier', ...
        'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left', ...
        'Interpreter', 'none');
    axis off;
    
    savefig(fig5, fullfile(output_dir, 'parameter_summary.fig'));
    saveas(fig5, fullfile(output_dir, 'parameter_summary.png'));
    fprintf('  ✓ 已保存: parameter_summary.fig/.png\n');
    close(fig5);
    
    % ===== 统计信息输出 =====
    stats_file = fullfile(output_dir, 'hologram_statistics.txt');
    fid = fopen(stats_file, 'w');
    
    fprintf(fid, '========== 全息模拟统计报告 ==========\n\n');
    fprintf(fid, '【光学参数】\n');
    fprintf(fid, '波长: %.3f nm\n', lambda*1e9);
    fprintf(fid, '参考光角度: (θ=15°, φ=0°)\n');
    fprintf(fid, '全息面分辨率: %.2f μm/pixel\n', 50e-3/512*1e6);
    
    fprintf(fid, '\n【物体信息】\n');
    fprintf(fid, '物体点数: %d\n', length(object_coords.x));
    fprintf(fid, '物体范围: [%.3f, %.3f] × [%.3f, %.3f] × [%.3f, %.3f] mm\n', ...
        min(object_coords.x)*1e3, max(object_coords.x)*1e3, ...
        min(object_coords.y)*1e3, max(object_coords.y)*1e3, ...
        min(object_coords.z)*1e3, max(object_coords.z)*1e3);
    
    fprintf(fid, '\n【全息图统计】\n');
    fprintf(fid, '干涉强度范围: [%.4f, %.4f]\n', min(hologram_intensity(:)), max(hologram_intensity(:)));
    fprintf(fid, '干涉对比度: %.4f\n', ...
        (max(hologram_intensity(:)) - min(hologram_intensity(:))) / mean(hologram_intensity(:)));
    fprintf(fid, '物光强度范围: [%.4f, %.4f]\n', ...
        min(abs(object_field_at_holo(:))), max(abs(object_field_at_holo(:))));
    
    fprintf(fid, '\n【再现视角列表】\n');
    fprintf(fid, '方位角: ');
    fprintf(fid, '%.0f° ', theta_range);
    fprintf(fid, '\n仰角: ');
    fprintf(fid, '%.0f° ', phi_range);
    fprintf(fid, '\n总视角数: %d\n', num_theta * num_phi);
    
    fclose(fid);
    fprintf('  ✓ 已保存: hologram_statistics.txt\n');
    
end
