%% LLC 谐振腔增益曲线扫频 (基于 FHA 基波分析法)
% 功能说明：计算并绘制不同品质因数 (Qe) 下，LLC 谐振腔的电压增益曲线 M = |Vout1/Vin1|
% 分析方法：FHA (First Harmonic Approximation)

clear; clc; close all;

%% ================= 1. 设定谐振腔参数 =================
Lr = 70e-6;          % 谐振电感 Lr (H)
Cr = 36e-9;          % 谐振电容 Cr (F)
Lm = 245e-6;         % 激磁电感 Lm (H)

% 衍生参数计算
k    = Lm / Lr;                      % 电感比 (通常取值 3~8)
fr   = 1 / (2*pi*sqrt(Lr*Cr));       % 串联谐振频率 f0 (Hz)
Zr   = sqrt(Lr / Cr);                % 谐振腔特征阻抗 (Ohm)
fp   = 1 / (2*pi*sqrt((Lr+Lm)*Cr));  % 并联谐振频率 (Hz)
fn_p = fp / fr;                      % 归一化第二谐振频率

%% ================= 2. 扫频范围设置 =================
% 归一化频率 fn = fs / fr
fn = linspace(0.2, 3.0, 5000);       % 增加采样点使曲线更平滑
fs = fn * fr;
w  = 2 * pi * fs;

%% ================= 3. FHA 频域计算 (阻抗法) =================
Qe_list = [0, 0.25, 0.443, 0.487]; % 选择要对比的 Qe 列表
M = zeros(numel(Qe_list), numel(fn)); % 预分配内存，提升运行速度

% 计算等效阻抗
Zs = 1j*w*Lr + 1./(1j*w*Cr);          % 谐振腔串联阻抗 (Lr + Cr)
Zm = 1j*w*Lm;                         % 激磁电感阻抗 (Lm)

for ii = 1:numel(Qe_list)
    Qe  = Qe_list(ii);
    Rac = Zr / Qe;                    % 交流等效负载电阻 Rac
    
    Zp = 1 ./ (1./Zm + 1./Rac);       % 激磁电感与负载并联 (Lm // Rac)
    G  = Zp ./ (Zs + Zp);             % 传递函数 Vout1 / Vin1
    M(ii,:) = abs(G);                 % 取模得到电压增益
end

%% ================= 4. 高级图表绘制 (学术排版风格) =================
fig = figure('Name', 'LLC Gain Curves', 'Color', 'w', 'Position', [100, 100, 850, 600]);
hold on; grid on;

% 设置自定义现代配色方案 (Modern Color Palette)
colors = lines(numel(Qe_list)); 
% 为了更好的视觉效果，可以微调线型或颜色，这里使用MATLAB默认的清晰色带

% 绘制主增益曲线
for ii = 1:numel(Qe_list)
    plot(fn, M(ii,:), 'LineWidth', 2.0, 'Color', colors(ii,:));
end

% 绘制辅助参考线
ylim_max = min(max(M(:)) * 1.1, 4);   % 限制最大纵坐标防止过载(例如空载增益极高时)
plot([1, 1], [0, ylim_max], '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.5);
plot([fn_p, fn_p], [0, ylim_max], ':', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.5);
plot([0, 3], [1, 1], '-.', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.0); % 增益为1的参考线

% 坐标轴与标签美化
set(gca, 'FontSize', 12, 'FontName', 'Times New Roman', ...
         'LineWidth', 1.2, 'GridAlpha', 0.2, 'MinorGridAlpha', 0.1);
xlabel('\it{f_n = f_s / f_r} \rm{(Normalized Frequency)}', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('\it{M = |V_{out,1} / V_{in,1}|} \rm{(Voltage Gain)}', 'FontSize', 14, 'FontWeight', 'bold');
title(sprintf('LLC Resonant Tank Gain Sweep (k = L_m/L_r = %.2f)', k), ...
      'FontSize', 16, 'FontWeight', 'bold');

% 图例美化
leg_str = arrayfun(@(q) sprintf('Q_e = %.3f', q), Qe_list, 'UniformOutput', false);
leg_str = [leg_str, {'f_s = f_r (Series Res.)', sprintf('f_p/f_r = %.3f', fn_p)}];
lgd = legend(leg_str, 'Location', 'northeast', 'FontSize', 11);
set(lgd, 'Box', 'off'); % 移除图例边框显得更干净

xlim([fn(1), fn(end)]);
ylim([0, ylim_max]);

%% ================= 5. 输出控制台信息验证 =================
n  = 16;                           % 变压器变比 Np/Ns
Ro = 100.0;                           % 输出直流负载示例 (Ohm)
Rac_from_Ro = (8 * n^2 / pi^2) * Ro;  % 全波整流折算交流阻抗
Qe_from_Ro  = Zr / Rac_from_Ro;       % 反推实际品质因数

% 控制台格式化输出
disp('--------------------------------------------------');
disp('【 LLC 谐振腔特征参数 】');
fprintf('  串联谐振频率 fr  = %6.2f kHz\n', fr / 1e3);
fprintf('  并联谐振频率 fp  = %6.2f kHz\n', fp / 1e3);
fprintf('  归一化频率 fp/fr = %6.3f\n', fn_p);
fprintf('  电感比 k (Lm/Lr) = %6.2f\n', k);
fprintf('  特征阻抗 Zr      = %6.2f Ω\n', Zr);
disp('--------------------------------------------------');
disp('【 负载与 Qe 验证 】');
fprintf('  设定输出直流负载 Ro   = %.2f Ω\n', Ro);
fprintf('  变压器变比 n          = %.2f\n', n);
fprintf('  折算交流等效阻抗 Rac  = %.2f Ω\n', Rac_from_Ro);
fprintf('  对应的品质因数 Qe     = %.4f\n', Qe_from_Ro);
disp('--------------------------------------------------');