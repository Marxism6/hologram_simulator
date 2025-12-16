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